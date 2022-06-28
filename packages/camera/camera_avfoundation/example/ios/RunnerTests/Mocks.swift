//
//  Mocks.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import Flutter
@testable import camera_avfoundation
import XCTest

final class MockCaptureSession: CaptureSession {

  var canAddInputStub: ((CaptureInput) -> Bool)?
  var canAddOutputStub: ((CaptureOutput) -> Bool)?
  var addInputStub: ((CaptureInput) -> Void)?
  var addOutputStub: ((CaptureOutput) -> Void)?
  var removeInputStub: ((CaptureInput) -> Void)?
  var removeOutputStub: ((CaptureOutput) -> Void)?

  var addInputWithNoConnectionsStub: ((CaptureInput) -> Void)?
  var addOutputWithNoConnectionsStub: ((CaptureOutput) -> Void)?
  var addConnectionStub: ((CaptureConnection) -> Void)?

  var startRunningStub: (() -> Void)?

  var stopRunningStub: (() -> Void)?

  var canSetSessionPresetStub: ((AVCaptureSession.Preset) -> Bool)?

  func canAddInput(_ input: CaptureInput) -> Bool {
    return canAddInputStub?(input) ?? false
  }

  func canAddOutput(_ output: CaptureOutput) -> Bool {
    return canAddOutputStub?(output) ?? false
  }

  func addInput(_ input: CaptureInput) {
    addInputStub?(input)
  }

  func addOutput(_ output: CaptureOutput) {
    addOutputStub?(output)
  }

  func removeInput(_ input: CaptureInput) {
    removeInputStub?(input)
  }

  func removeOutput(_ output: CaptureOutput) {
    removeOutputStub?(output)
  }

  var captureInputs: [CaptureInput] = []

  var captureOutputs: [CaptureOutput] = []

  func addInputWithNoConnections(_ input: CaptureInput) {
    addInputWithNoConnectionsStub?(input)
  }

  func addOutputWithNoConnections(_ output: CaptureOutput) {
    addOutputWithNoConnectionsStub?(output)
  }

  func addConnection(_ connection: CaptureConnection) {
    addConnectionStub?(connection)
  }

  func startRunning() {
    startRunningStub?()
  }

  func stopRunning() {
    stopRunningStub?()
  }

  func canSetSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool {
    return canSetSessionPresetStub?(preset) ?? false
  }

  var sessionPreset: AVCaptureSession.Preset = .high
  
}

final class MockCapturePhotoOutput: CapturePhotoOutput {

  var captureConnectionStub: ((AVMediaType) -> CaptureConnection?)? = nil

  var capturePhotoStub: ((AVCapturePhotoSettings, CapturePhotoCaptureDelegate) -> Void)? = nil

  var isHighResolutionCaptureEnabled = false

  var supportedFlashModes: [AVCaptureDevice.FlashMode] = []

  func captureConnection(with mediaType: AVMediaType) -> CaptureConnection? {
    return captureConnectionStub?(mediaType)
  }

  func capturePhoto(with settings: AVCapturePhotoSettings, delegate: CapturePhotoCaptureDelegate) {
    capturePhotoStub?(settings, delegate)
  }

}

final class MockPermissionService: PermissionService {
  static var authorizationStatusForMediaTypeStub: ((AVMediaType) -> AVAuthorizationStatus)? = nil

  static var requestAccessForMediaTypeStub: ((AVMediaType, (Bool) -> Void) -> Void)? = nil

  static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
    guard let stub = authorizationStatusForMediaTypeStub else {
      XCTFail("authorizationStatus must be stubbed before called.")
      return .notDetermined
    }
    return stub(mediaType)
  }

  static func requestAccess(for mediaType: AVMediaType, completionHandler handler: @escaping (Bool) -> Void) {
    requestAccessForMediaTypeStub?(mediaType, handler)
  }


}

public final class MockThreadSafeFlutterResult: NSObject, ThreadSafeFlutterResultProtocol {

  @objc
  public var sendNotImplementedStub: (() -> Void)? = nil

  @objc
  public var sendStub: ((Any?) -> Void)? = nil

  @objc
  public var sendSuccessStub: (() -> Void)? = nil
  @objc
  public var sendSuccessWithDataStub: ((Any) -> Void)? = nil
  @objc
  public var sendErrorStub: ((NSError) -> Void)? = nil
  @objc
  public var sendErrorWithCodeMessageDetailsStub: ((String, String?, Any?) -> Void)? = nil
  
  @objc
  public var sendFlutterErrorStub: ((FlutterError) -> Void)? = nil


  public func sendNotImplemented() {
    sendNotImplementedStub?()
  }

  public func send(_ result: Any?) {
    sendStub?(result)
  }


  
  public func sendSuccess() {
    sendSuccessStub?()
  }

  public func sendSuccess(withData data: Any) {
    sendSuccessWithDataStub?(data)
  }

  public func sendError(_ error: NSError) {
    sendErrorStub?(error)
  }

  public func sendError(code: String, message: String?, details: Any?) {
    sendErrorWithCodeMessageDetailsStub?(code, message, details)
  }

  public func sendFlutterError(_ flutterError: FlutterError) {
    sendFlutterErrorStub?(flutterError)
  }
}

final class MockEventChannel: EventChannel {
  var setStreamHandlerStub: (((FlutterStreamHandler & NSObjectProtocol)?) -> Void)?

  func setStreamHandler(_ handler: (FlutterStreamHandler & NSObjectProtocol)?) {
    setStreamHandlerStub?(handler)
  }

}

final class MockMethodChannel: MethodChannel {

  var invokeMethodStub: ((String, Any?) -> Void)? = nil

  func invokeMethod(_ method: String, arguments: Any?) {
    invokeMethodStub?(method, arguments)
  }
}

class MockTexture: NSObject, FlutterTexture {
  var copyPixelBufferStub: (() -> Unmanaged<CVPixelBuffer>?)? = nil

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    return copyPixelBufferStub?() ?? nil
  }
}

class MockTextureRegistry: NSObject, FlutterTextureRegistry {

  var registerStub: ((FlutterTexture) -> Int64)? = nil
  var unregisterTextureStub: ((Int64) -> Void)? = nil
  var textureFrameAvailableStub: ((Int64) -> Void)? = nil

  func register(_ texture: FlutterTexture) -> Int64 {
    return registerStub?(texture) ?? 0
  }
  func unregisterTexture(_ textureId: Int64) {
    unregisterTextureStub?(textureId)
  }
  func textureFrameAvailable(_ textureId: Int64) {
    textureFrameAvailableStub?(textureId)
  }
}
