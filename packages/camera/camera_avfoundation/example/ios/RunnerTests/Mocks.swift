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
import AVFoundation

final class MockDiscoverySession: DiscoverySession {
  static var discoverySessionStub: (([AVCaptureDevice.DeviceType], AVMediaType, AVCaptureDevice.Position) -> DiscoverySession)? = nil
  var captureDevices: [CaptureDevice] = []

  static func discoverySession(deviceTypes: [AVCaptureDevice.DeviceType], mediaType: AVMediaType, position: AVCaptureDevice.Position) -> DiscoverySession {
    return discoverySessionStub!(deviceTypes, mediaType, position)
  }
}

final class MockFLTCam: NSObject, FLTCamProtocol {
  var captureVideoOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()

  var captureDevice: CaptureDevice = MockCaptureDevice()

  var previewSize: CGSize = .zero

  var isPreviewPaused: Bool = false

  var onFrameAvailable: (() -> Void)? = nil

  var methodChannel: MethodChannel! = MockMethodChannel()

  var resolutionPreset: FLTResolutionPreset = .high

  var exposureMode: FLTExposureMode = .locked

  var focusMode: FLTFocusMode = .locked

  var flashMode: FLTFlashMode = .auto

  var videoFormat: FourCharCode = .max

  var startStub: (() -> Void)? = nil
  var stopStub: (() -> Void)? = nil
  var setVideoFormatStub: ((OSType) -> Void)? = nil
  var setDeviceOrientationStub: ((UIDeviceOrientation) -> Void)? = nil
  var captureToFileStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil
  var closeStub: (() -> Void)? = nil

  func start() {
    startStub?()
  }

  func stop() {
    stopStub?()
  }

  func setVideoFormat(_ videoFormat: OSType) {
    setVideoFormatStub?(videoFormat)
  }

  func setDeviceOrientation(_ orientation: UIDeviceOrientation) {
    setDeviceOrientationStub?(orientation)
  }

  func captureToFile(with result: ThreadSafeFlutterResultProtocol) {
    captureToFileStub?(result)
  }

  func close() {
    closeStub?()
  }

  var copyPixelBufferStub: (() -> Unmanaged<CVPixelBuffer>?)? = nil
  var startVideoRecordingStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil
  var setupWriterForPathStub: ((String?) throws -> Bool)? = nil
  var setupCaptureSessionForAudioStub: (() throws -> Void)? = nil
  var stopVideoRecordingStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil
  var pauseVideoRecordingStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil
  var resumeVideoRecordingStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil


  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    return copyPixelBufferStub?() ?? nil
  }

  func startVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    startVideoRecordingStub?(result)
  }

  func setupWriterForPath(_ path: String?) throws -> Bool {
    return try setupWriterForPathStub?(path) ?? false
  }

  func setUpCaptureSessionForAudio() throws {
    try setupCaptureSessionForAudioStub?()
  }

  func stopVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    stopVideoRecordingStub?(result)
  }

  func pauseVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    pauseVideoRecordingStub?(result)
  }

  func resumeVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    resumeVideoRecordingStub?(result)
  }


  var lockCaptureOrientationStub: ((ThreadSafeFlutterResultProtocol, String) -> Void)? = nil
  var unlockCaptureOrientationStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil
  var setFlashModeStub: ((ThreadSafeFlutterResultProtocol, String) throws -> Void)? = nil
  var setExposureModeStub: ((ThreadSafeFlutterResultProtocol, String) -> Void)? = nil
  var setFocusModeStub: ((ThreadSafeFlutterResultProtocol, String) throws -> Void)? = nil


  func lockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol, orientation orientationStr: String) {
    lockCaptureOrientationStub?(result, orientationStr)
  }

  func unlockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol) {
    unlockCaptureOrientationStub?(result)
  }

  func setFlashMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {
    try setFlashModeStub?(result, modeStr)
  }

  func setExposureMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {
    setExposureModeStub?(result, modeStr)
  }

  var applyExposureModeStub: (() throws -> Void)? = nil
  func applyExposureMode() throws {
    try applyExposureModeStub?()
  }

  func setFocusMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {
    try setFocusModeStub?(result, modeStr)
  }


  var applyFocusModeStub: (() throws -> Void)? = nil
  func applyFocusMode() throws {
    try applyFocusModeStub?()
  }

  var applyFocusModeOnStub: ((FLTFocusMode, CaptureDevice) throws -> Void)? = nil
  func applyFocusMode(_ mode: FLTFocusMode, on device: CaptureDevice) throws {
    try applyFocusModeOnStub?(mode, device)
  }

  var pausePreviewStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil

  func pausePreview(with result: ThreadSafeFlutterResultProtocol) {
    pauseVideoRecordingStub?(result)
  }

  var resumePreviewStub: ((ThreadSafeFlutterResultProtocol) -> Void)? = nil

  func resumePreview(with result: ThreadSafeFlutterResultProtocol) {
    resumePreviewStub?(result)
  }

  var getCGPointForCoordsWithOrientationStub: ((UIDeviceOrientation, Double, Double) -> CGPoint)? = nil
  func getCGPointForCoordsWithOrientation(_ orientation: UIDeviceOrientation, x: Double, y: Double) -> CGPoint {
    return getCGPointForCoordsWithOrientationStub?(orientation, x, y) ?? .zero
  }

  func setExposurePoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider) throws {

  }

  func setFocusPoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider) throws {

  }

  func setExposureOffset(with result: ThreadSafeFlutterResultProtocol, offset: Double) throws {

  }

  func startImageStream(with messenger: FlutterBinaryMessenger) {

  }

  func startImageStream(with messenger: FlutterBinaryMessenger, imageStreamHandler: ImageStreamHandler) {

  }

  func stopImageStream() {

  }

  func receivedImageStreamData() {

  }

  func getMaxZoomLevel(with result: ThreadSafeFlutterResultProtocol) {

  }

  func getMinZoomLevel(with result: ThreadSafeFlutterResultProtocol) {

  }

  func setZoomLevel(_ zoom: CGFloat, result: ThreadSafeFlutterResultProtocol) throws {

  }

  func getMaxAvailableZoomFactor() -> CGFloat {
    return 0
  }

  func getMinAvailableZoomFactor() -> CGFloat {
    return 0
  }


}

final class MockDeviceOrientationProvider: DeviceOrientationProvider {
  var orientation: UIDeviceOrientation = .landscapeLeft
}

final class MockCaptureConnection: CaptureConnection {
  var isVideoOrientationSupported: Bool = false

  var videoOrientation: AVCaptureVideoOrientation = .portrait

  var isVideoMirrored: Bool = false

  static var captureConnectionStub: (([AVCaptureInput.Port], CaptureOutput) -> CaptureConnection)? = nil

  static func captureConnection(inputPorts: [AVCaptureInput.Port], output: CaptureOutput) -> CaptureConnection {
    return captureConnectionStub?(inputPorts, output) ?? MockCaptureConnection()
  }
}

final class MockCaptureDeviceFormat: CaptureDeviceFormat {
  var highResolutionStillImageDimensions: CMVideoDimensions = CMVideoDimensions(width: 0, height: 0)
}
final class MockCaptureDevice: CaptureDevice {

  static var deviceStub: ((String) -> CaptureDevice?)? = nil
  var isExposureModeSupportedStub: ((AVCaptureDevice.ExposureMode) -> Bool)? = nil

  var isFocusModeSupportedStub: ((AVCaptureDevice.FocusMode) -> Bool)? = nil
  var setExposureTargetBiasStub: ((Float, ((CMTime) -> Void)?) -> Void)? = nil
  var lockForConfigurationStub: (() throws -> Void)? = nil
  var unlockForConfigurationStub: (() -> Void)? = nil


  static func device(with uniqueID: String) -> CaptureDevice? {
    return deviceStub?(uniqueID)
  }

  var uniqueID: String = ""

  var hasFlash: Bool = false

  var position: AVCaptureDevice.Position = .front

  var activeCaptureFormat: CaptureDeviceFormat = MockCaptureDeviceFormat()

  var lensAperture: Float = 0

  var exposureDuration: CMTime = CMTime()

  var iso: Float = 0

  var hasTorch: Bool = false

  var isTorchAvailable: Bool = false

  var torchMode: AVCaptureDevice.TorchMode = .auto

  var exposureMode: AVCaptureDevice.ExposureMode = .continuousAutoExposure

  func isExposureModeSupported(_ mode: AVCaptureDevice.ExposureMode) -> Bool {
    return isExposureModeSupportedStub?(mode) ?? false
  }

  var focusMode: AVCaptureDevice.FocusMode = .autoFocus

  func isFocusModeSupported(_ mode: AVCaptureDevice.FocusMode) -> Bool {
    return isFocusModeSupportedStub?(mode) ?? false
  }

  var isExposurePointOfInterestSupported: Bool = false

  var exposurePointOfInterest: CGPoint = .zero

  var isFocusPointOfInterestSupported: Bool = false

  var focusPointOfInterest: CGPoint = .zero

  func setExposureTargetBias(_ bias: Float, completionHandler: ((CMTime) -> Void)?) {
    setExposureTargetBiasStub?(bias, completionHandler)
  }

  var minExposureTargetBias: Float = 0

  var maxExposureTargetBias: Float = 0

  var minAvailableVideoZoomFactor: CGFloat = 0

  var maxAvailableVideoZoomFactor: CGFloat = 0

  var videoZoomFactor: CGFloat = 0

  func lockForConfiguration() throws {
    try lockForConfigurationStub?()
  }

  func unlockForConfiguration() {
    unlockForConfigurationStub?()
  }

  
}

final class MockCaptureDeviceInput: CaptureDeviceInput {
  static var inputStub: ((CaptureDevice) throws -> CaptureDeviceInput)? = nil

  static func input(with device: CaptureDevice) throws -> CaptureDeviceInput {
    return (try? inputStub?(device)) ?? MockCaptureDeviceInput()
  }

  var ports: [AVCaptureInput.Port] = []


}

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

  var isHighResolutionCaptureEnabled: Bool = false

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

  static var mockMethodChannelStub: ((String, FlutterBinaryMessenger) -> MethodChannel)? = nil

  static func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> MethodChannel {
    return mockMethodChannelStub!(name, binaryMessenger)
  }


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

class MockBinaryMessenger: NSObject, FlutterBinaryMessenger {

  var sendOnChannelStub: ((String, Data?) -> Void)? = nil
  var sendOnChannelWithBinaryReplyStub: ((String, Data?, FlutterBinaryReply?) -> Void)? = nil
  var setMessageHandlerOnChannelStub: ((String, FlutterBinaryMessageHandler?) -> FlutterBinaryMessengerConnection)? = nil
  var cleanUpConnectionStub: ((FlutterBinaryMessengerConnection) -> Void)? = nil

  func send(onChannel channel: String, message: Data?) {
    sendOnChannelStub?(channel, message)
  }

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {
    sendOnChannelWithBinaryReplyStub?(channel, message, callback)
  }

  func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil) -> FlutterBinaryMessengerConnection {
    return setMessageHandlerOnChannelStub?(channel, handler) ?? FlutterBinaryMessengerConnection()
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
    cleanUpConnectionStub?(connection)
  }
}
