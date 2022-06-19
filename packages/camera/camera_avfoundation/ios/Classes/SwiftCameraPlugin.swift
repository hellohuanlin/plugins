//
//  SwiftCameraPlugin.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/12/22.
//

import Foundation
import Flutter
import AVFoundation

public final class SwiftCameraPlugin: NSObject, FlutterPlugin {
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plugins.flutter.io/camera", binaryMessenger: registrar.messenger())
    let instance = SwiftCameraPlugin(
      registry: registrar.textures(),
      messenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let textureRegistry: ThreadSafeTextureRegistry
  private let messenger: FlutterBinaryMessenger

  private let captureSessionQueue: DispatchQueue

  private let deviceEventMethodChannel: FLTThreadSafeMethodChannel

  @objc
  public var camera: FLTCam? = nil

  @objc
  public init(
    registry: FlutterTextureRegistry,
    messenger: FlutterBinaryMessenger)
  {
    self.textureRegistry = ThreadSafeTextureRegistry(registry: registry)
    self.messenger = messenger
    captureSessionQueue = DispatchQueue(label: "io.flutter.camera.captureSessionQueue")


    SwiftQueueUtils.setSpecific(.captureSession, for: captureSessionQueue)

    let methodChannel = FlutterMethodChannel(name: "flutter.io/cameraPlugin/device", binaryMessenger: messenger)

    deviceEventMethodChannel = FLTThreadSafeMethodChannel(methodChannel: methodChannel)

    super.init()


    startOrientationListener()

  }

  private func startOrientationListener() {
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()

    NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)

  }

  @objc
  public func orientationChanged(_ notification: NSNotification) {
    let device = notification.object as! UIDevice
    let orientation = device.orientation

    if orientation == .faceUp || orientation == .faceDown {
      return
    }

    captureSessionQueue.async {
      self.camera?.setDeviceOrientation(orientation)
      self.sendDeviceOrientation(orientation)
    }

  }

  @objc
  private func sendDeviceOrientation(_ orientation: UIDeviceOrientation) {
    deviceEventMethodChannel.invokeMethod("orientation_changed", arguments: ["orientation": FLTGetStringForUIDeviceOrientation(orientation)])
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    captureSessionQueue.async {
      let result = FLTThreadSafeFlutterResult(result: result)
      self.handleAsync(call, result: result)
    }
  }

  @objc
  public func handleAsync(_ call: FlutterMethodCall, result: FLTThreadSafeFlutterResult) {

    switch call.method {
    case "availableCameras":
      var discoveryDevices: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]

      if #available(iOS 13.0, *) {
        discoveryDevices += [.builtInUltraWideCamera]
      }

      let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: discoveryDevices, mediaType: .video, position: .unspecified)

      let devices = discoverySession.devices

      let reply: [[String:Any?]] = devices.map { device in
        let lensFacing: String?
        switch device.position {
        case .back:
          lensFacing = "back"
        case .front:
          lensFacing = "front"
        case .unspecified:
          lensFacing = "external"
        @unknown default:
          lensFacing = nil
        }
        return [
          "name": device.uniqueID,
          "lensFacing": lensFacing,
          "sensorOrientation": NSNumber(integerLiteral: 90),
        ]
      }
      result.sendSuccess(withData: reply)
    case "create":
      handleCreateCall(call, result: result)
    case "startImageStream":
      camera?.startImageStream(with: messenger)
      result.sendSuccess()
    case "stopImageStream":
      camera?.stopImageStream()
      result.sendSuccess()
    case _:
      let argsMap = call.arguments as? [String:Any]
      let cameraId = (argsMap?["cameraId"] as? NSNumber)?.int64Value ?? 0

      switch call.method {
      case "initialize":
        guard let camera = camera else { return }
        if let videoFormatValue = argsMap?["imageFormatGroup"] as? String {
          camera.videoFormat = FLTGetVideoFormatFromString(videoFormatValue)
        }

        camera.onFrameAvailable = { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.textureRegistry.textureFrameAvailable(cameraId)
        }

        let methodChannel = FlutterMethodChannel(name: String(format: "flutter.io/cameraPlugin/camera%lu", cameraId), binaryMessenger: messenger)
        let threadSafeMethodChannel = FLTThreadSafeMethodChannel(methodChannel: methodChannel)

        camera.methodChannel = threadSafeMethodChannel
        threadSafeMethodChannel.invokeMethod("initialized", arguments: [
          "previewWidth": camera.previewSize.width,
          "previewHeight": camera.previewSize.height,
          "exposureMode": FLTGetStringForFLTExposureMode(camera.exposureMode),
          "focusMode": FLTGetStringForFLTFocusMode(camera.focusMode),
          "exposurePointSupported": NSNumber(booleanLiteral: camera.captureDevice.isExposurePointOfInterestSupported),
          "focusPointSupported": NSNumber(booleanLiteral: camera.captureDevice.isFocusPointOfInterestSupported),
        ])

        sendDeviceOrientation(UIDevice.current.orientation)

        camera.start()
        result.sendSuccess()
      case "takePicture":
        camera?.capture(toFile: result)
      case "dispose":
        textureRegistry.unregisterTexture(cameraId)
        camera?.close()
        result.sendSuccess()
      case "prepareForVideoRecording":
        camera?.setUpCaptureSessionForAudio()
        result.sendSuccess()
      case "startVideoRecording":
        camera?.startVideoRecording(with: result)
      case "stopVideoRecording":
        camera?.stopVideoRecording(with: result)
      case "pauseVideoRecording":
        camera?.pauseVideoRecording(with: result)
      case "resumeVideoRecording":
        camera?.resumeVideoRecording(with: result)
      case "getMaxZoomLevel":
        camera?.getMaxZoomLevel(with: result)
      case "getMinZoomLevel":
        camera?.getMinZoomLevel(with: result)
      case "setZoomLevel":
        guard let zoom = (argsMap?["zoom"] as? NSNumber)?.floatValue else { return }
        camera?.setZoomLevel(CGFloat(zoom), result: result)
      case "setFlashMode":
        guard let mode = argsMap?["mode"] as? String else { return }
        camera?.setFlashModeWith(result, mode: mode)
      case "setExposureMode":
        guard let mode = argsMap?["mode"] as? String else { return }
        camera?.setExposureModeWith(result, mode: mode)
      case "setExposurePoint":
        let reset = (argsMap?["reset"] as? NSNumber)?.boolValue ?? false
        let x = reset ? 0.5 : (argsMap?["x"] as? NSNumber)?.doubleValue ?? 0
        let y = reset ? 0.5 : (argsMap?["y"] as? NSNumber)?.doubleValue ?? 0

        camera?.setExposurePointWith(result, x: x, y: y)

      case "getMinExposureOffset":
        guard let camera = camera else { return }
        result.sendSuccess(withData: camera.captureDevice.minExposureTargetBias)
      case "getMaxExposureOffset":
        guard let camera = camera else {
          return
        }
        result.sendSuccess(withData: camera.captureDevice.maxExposureTargetBias)
      case "getExposureOffsetStepSize":
        result.sendSuccess(withData: NSNumber(floatLiteral: 0))
      case "setExposureOffset":
        camera?.setExposureOffsetWith(result, offset: (argsMap?["offset"] as? NSNumber)?.doubleValue ?? 0)
      case "lockCaptureOrientation":
        guard let orientation = argsMap?["orientation"] as? String else { return }
        camera?.lockCaptureOrientation(with: result, orientation: orientation)
      case "unlockCaptureOrientation":
        camera?.unlockCaptureOrientation(with: result)
      case "setFocusMode":
        guard let mode = argsMap?["mode"] as? String else { return }

        camera?.setFocusModeWith(result, mode: mode)
      case "setFocusPoint":
        let reset = (argsMap?["reset"] as? NSNumber)?.boolValue ?? false
        let x = reset ? 0.5 : (argsMap?["x"] as? NSNumber)?.doubleValue ?? 0
        let y = reset ? 0.5 : (argsMap?["y"] as? NSNumber)?.doubleValue ?? 0

        camera?.setFocusPointWith(result, x: x, y: y)
      case "pausePreview":
        camera?.pausePreview(with: result)
      case "resumePreview":
        camera?.resumePreview(with: result)
      case _:
        result.sendNotImplemented()
      }
    }
  }


  private func handleCreateCall(_ call: FlutterMethodCall, result: FLTThreadSafeFlutterResult) {

    guard let argMap = call.arguments as? [String:Any] else { return }

    FLTRequestCameraPermissionWithCompletionHandler { error in
      if let error = error {
        result.send(error)
      } else {
        let audioEnabled = (argMap["enableAudio"] as? NSNumber)?.boolValue ?? false
        if audioEnabled {

          FLTRequestAudioPermissionWithCompletionHandler { error in
            if let error = error {
              result.send(error)
            } else {
              self.createCameraOnSessionQueue(createMethodCall: call, result: result)
            }
          }

        } else {
          self.createCameraOnSessionQueue(createMethodCall: call, result: result)
        }
      }
    }

  }

  private func createCameraOnSessionQueue(createMethodCall call: FlutterMethodCall, result: FLTThreadSafeFlutterResult) {
    guard let argMap = call.arguments as? [String:Any] else { return }

    let enableAudio = (argMap["enableAudio"] as? NSNumber)?.boolValue ?? false
    let cameraName = argMap["cameraName"] as? String ?? ""
    let resolutionPreset = argMap["resolutionPreset"] as? String ?? ""

    captureSessionQueue.async {

      var error: NSError?
      let cam = FLTCam(
        cameraName: cameraName,
        resolutionPreset: resolutionPreset,
        enableAudio: enableAudio,
        orientation: UIDevice.current.orientation,
        captureSessionQueue: self.captureSessionQueue,
        error: &error)

      if let error = error {
        result.sendError(error)
      } else {
        self.camera?.close()
        self.camera = cam
        self.textureRegistry.register(cam) { textureId in
          result.sendSuccess(withData: [
            "cameraId": NSNumber(integerLiteral: Int(textureId)),
          ])
        }
      }
    }
  }
}

#if DEBUG
extension SwiftCameraPlugin {

  @objc
  public var test_captureSessionQueue: DispatchQueue {
    return self.captureSessionQueue
  }

}
#endif
