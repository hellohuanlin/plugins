//
//  SwiftCameraPlugin.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/12/22.
//

import Foundation
import Flutter
import AVFoundation

protocol DiscoverySession {
  static func discoverySession(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType, position: AVCaptureDevice.Position) -> DiscoverySession

  var captureDevices: [CaptureDevice] { get }
}

extension AVCaptureDevice.DiscoverySession: DiscoverySession {
  static func discoverySession(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType, position: AVCaptureDevice.Position) -> DiscoverySession {
    return AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: position)
  }

  var captureDevices: [CaptureDevice] {
    return devices
  }
}


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
  private let captureSession: CaptureSession
  private let captureSessionQueue: DispatchQueue

  private let deviceEventMethodChannel: ThreadSafeMethodChannelProtocol


  var camera: FLTCamProtocol? = nil
  private let discoverySessionType: DiscoverySession.Type
  private let captureDeviceType: CaptureDevice.Type
  private let captureDeviceInputType: CaptureDeviceInput.Type
  private let captureConnectionType: CaptureConnection.Type
  private let threadSafeMethodChannelFactory: ThreadSafeMethodChannelFactoryProtocol

  init(
    registry: FlutterTextureRegistry,
    messenger: FlutterBinaryMessenger,
    captureSession: CaptureSession = AVCaptureSession(),
    discoverySessionType: DiscoverySession.Type = AVCaptureDevice.DiscoverySession.self,
    captureDeviceType: CaptureDevice.Type = AVCaptureDevice.self,
    captureDeviceInputType: CaptureDeviceInput.Type = AVCaptureDeviceInput.self,
    captureConnectionType: CaptureConnection.Type = AVCaptureConnection.self,
    threadSafeMethodChannelFactory: ThreadSafeMethodChannelFactoryProtocol = ThreadSafeMethodChannel.Factory())
  {
    self.textureRegistry = ThreadSafeTextureRegistry(registry: registry)
    self.messenger = messenger
    self.captureSession = captureSession
    self.discoverySessionType = discoverySessionType
    self.captureDeviceType = captureDeviceType
    self.captureDeviceInputType = captureDeviceInputType
    self.captureConnectionType = captureConnectionType
    self.threadSafeMethodChannelFactory = threadSafeMethodChannelFactory

    captureSessionQueue = DispatchQueue(label: "io.flutter.camera.captureSessionQueue")


    SwiftQueueUtils.setSpecific(.captureSession, for: captureSessionQueue)

    deviceEventMethodChannel = threadSafeMethodChannelFactory.methodChannel(name: "flutter.io/cameraPlugin/device", binaryMessenger: messenger)

    super.init()


    startOrientationListener()

  }

  private func startOrientationListener() {
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()

    NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)

  }

  @objc
  public func orientationChanged(_ notification: NSNotification) {
    let device = notification.object as! DeviceOrientationProvider
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
    let orientation = FLTOrientation(orientation: orientation)
    
    deviceEventMethodChannel.invokeMethod("orientation_changed", arguments: ["orientation": orientation.rawValue])
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    captureSessionQueue.async {
      let result = ThreadSafeFlutterResult(result: result)
      self.handleAsync(call, result: result)
    }
  }

  @objc
  public func handleAsync(_ call: FlutterMethodCall, result: ThreadSafeFlutterResultProtocol) {

    switch call.method {
    case "availableCameras":
      var discoveryDevices: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]

      if #available(iOS 13.0, *) {
        discoveryDevices += [.builtInUltraWideCamera]
      }

      let discoverySession = discoverySessionType.discoverySession(deviceTypes: discoveryDevices, mediaType: .video, position: .unspecified)

      let devices = discoverySession.captureDevices

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
          guard let videoFormat = FLTVideoFormat(rawValue: videoFormatValue)?.videoFormat else {
            // TODO: handle error
            return
         }
         camera.videoFormat = videoFormat
        }

        camera.onFrameAvailable = { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.textureRegistry.textureFrameAvailable(cameraId)
        }

        let methodChannel = threadSafeMethodChannelFactory.methodChannel(name: String(format: "flutter.io/cameraPlugin/camera%lu", cameraId), binaryMessenger: messenger)

        camera.methodChannel = methodChannel
        methodChannel.invokeMethod("initialized", arguments: [
          "previewWidth": camera.previewSize.width,
          "previewHeight": camera.previewSize.height,
          "exposureMode": camera.exposureMode.rawValue,
          "focusMode": camera.focusMode.rawValue,
          "exposurePointSupported": NSNumber(booleanLiteral: camera.captureDevice.isExposurePointOfInterestSupported),
          "focusPointSupported": NSNumber(booleanLiteral: camera.captureDevice.isFocusPointOfInterestSupported),
        ])

        sendDeviceOrientation(UIDevice.current.orientation)

        camera.start()
        result.sendSuccess()
      case "takePicture":
        camera?.captureToFile(with: result)
      case "dispose":
        textureRegistry.unregisterTexture(cameraId)
        camera?.close()
        result.sendSuccess()
      case "prepareForVideoRecording":
        do {
          try camera?.setUpCaptureSessionForAudio()
          result.sendSuccess()
        } catch {
          result.sendError(error as NSError)
        }
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
        try? camera?.setZoomLevel(CGFloat(zoom), result: result)
      case "setFlashMode":
        guard let mode = argsMap?["mode"] as? String else { return }
        try? camera?.setFlashMode(with: result, mode: mode)
      case "setExposureMode":
        guard let mode = argsMap?["mode"] as? String else { return }
        try? camera?.setExposureMode(with: result, mode: mode)
      case "setExposurePoint":
        let reset = (argsMap?["reset"] as? NSNumber)?.boolValue ?? false
        let x = reset ? 0.5 : (argsMap?["x"] as? NSNumber)?.doubleValue ?? 0
        let y = reset ? 0.5 : (argsMap?["y"] as? NSNumber)?.doubleValue ?? 0

        try? camera?.setExposurePoint(with: result, x: x, y: y, deviceOrientationProvider: UIDevice.current)

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
        try?  camera?.setExposureOffset(with: result, offset: (argsMap?["offset"] as? NSNumber)?.doubleValue ?? 0)
      case "lockCaptureOrientation":
        guard let orientation = argsMap?["orientation"] as? String else { return }
        camera?.lockCaptureOrientation(with: result, orientation: orientation)
      case "unlockCaptureOrientation":
        camera?.unlockCaptureOrientation(with: result)
      case "setFocusMode":
        guard let mode = argsMap?["mode"] as? String else { return }
        try? camera?.setFocusMode(with: result, mode: mode)
      case "setFocusPoint":
        let reset = (argsMap?["reset"] as? NSNumber)?.boolValue ?? false
        let x = reset ? 0.5 : (argsMap?["x"] as? NSNumber)?.doubleValue ?? 0
        let y = reset ? 0.5 : (argsMap?["y"] as? NSNumber)?.doubleValue ?? 0

        try? camera?.setFocusPoint(with: result, x: x, y: y, deviceOrientationProvider: UIDevice.current)
      case "pausePreview":
        camera?.pausePreview(with: result)
      case "resumePreview":
        camera?.resumePreview(with: result)
      case _:
        result.sendNotImplemented()
      }
    }
  }


  private func handleCreateCall(_ call: FlutterMethodCall, result: ThreadSafeFlutterResultProtocol) {

    guard let argMap = call.arguments as? [String:Any] else { return }

    CameraPermissionUtils.requestCameraPermissionWithPermissionService { error in
      if let error = error {
        result.send(error)
      } else {
        let audioEnabled = (argMap["enableAudio"] as? NSNumber)?.boolValue ?? false
        if audioEnabled {

          CameraPermissionUtils.requestCameraPermissionWithPermissionService { error in
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

  private func createCameraOnSessionQueue(createMethodCall call: FlutterMethodCall, result: ThreadSafeFlutterResultProtocol) {
    guard let argMap = call.arguments as? [String:Any] else { return }

    let enableAudio = (argMap["enableAudio"] as? NSNumber)?.boolValue ?? false
    let cameraName = argMap["cameraName"] as? String ?? ""
    let resolutionPreset = argMap["resolutionPreset"] as? String ?? ""

    captureSessionQueue.async {
      do {
        if let cam = try FLTCam(
          cameraName: cameraName,
          resolutionPreset: resolutionPreset,
          enableAudio: enableAudio,
          orientation: UIDevice.current.orientation,
          captureSession: self.captureSession,
          captureSessionQueue: self.captureSessionQueue,
          captureDeviceType: self.captureDeviceType,
          captureDeviceInputType: self.captureDeviceInputType,
          captureConnectionType: self.captureConnectionType)
        {
          self.camera?.close()
          self.camera = cam

          self.textureRegistry.register(cam) { textureId in
            result.sendSuccess(withData: [
              "cameraId": NSNumber(integerLiteral: Int(textureId)),
            ])
          }
        } else {
          // TODO: deal with nil result
        }
      } catch {
        result.sendError(error as NSError)
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
