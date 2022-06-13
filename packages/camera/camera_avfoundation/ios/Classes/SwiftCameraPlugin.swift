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
      textureRegistry: registrar.textures(),
      messenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let textureRegistry: FLTThreadSafeTextureRegistry
  private let messenger: FlutterBinaryMessenger
  private let captureSessionQueue: DispatchQueue
  private let deviceEventMethodChannel: FLTThreadSafeMethodChannel

  private var camera: FLTCam? = nil

  init(
    textureRegistry: FlutterTextureRegistry,
    messenger: FlutterBinaryMessenger)
  {
    self.textureRegistry = FLTThreadSafeTextureRegistry(textureRegistry: textureRegistry)
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
  private func orientationChanged(_ notification: NSNotification) {
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



}
