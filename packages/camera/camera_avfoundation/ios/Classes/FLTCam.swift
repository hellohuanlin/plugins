//
//  FLTCam.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/20/22.
//

import Foundation
import Flutter
import AVFoundation

public final class ImageStreamHandler: NSObject, FlutterStreamHandler {
  init(captureSessionQueue: DispatchQueue) {
    self.captureSessionQueue = captureSessionQueue
  }

  private let captureSessionQueue: DispatchQueue
  private(set) var eventSink: FlutterEventSink? = nil

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    captureSessionQueue.async {
      self.eventSink = nil
    }
    return nil
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    captureSessionQueue.async {
      self.eventSink = events
    }
    return nil
  }
}

public protocol DeviceOrientationProvider: AnyObject {
  var orientation: UIDeviceOrientation { get }
}

extension UIDevice: DeviceOrientationProvider {}

public protocol CaptureInput: AnyObject {
  var ports: [AVCaptureInput.Port] { get }
}
extension AVCaptureInput: CaptureInput {}

public protocol CaptureOutput: AnyObject {
  func captureConnection(with mediaType: AVMediaType) -> CaptureConnection?
}
extension AVCaptureOutput: CaptureOutput {
  public func captureConnection(with mediaType: AVMediaType) -> CaptureConnection? {
    return connection(with: mediaType)
  }
}

public protocol CapturePhotoCaptureDelegate: AnyObject {
  func photoOutput(
    _ output: CapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?)
}

public protocol CapturePhotoOutput: CaptureOutput {
  func capturePhoto(with settings: AVCapturePhotoSettings,
           delegate: CapturePhotoCaptureDelegate)
  var isHighResolutionCaptureEnabled: Bool { get set }
  var supportedFlashModes: [AVCaptureDevice.FlashMode] { get }
}

extension AVCapturePhotoOutput: CapturePhotoOutput {
  public func capturePhoto(with settings: AVCapturePhotoSettings, delegate: CapturePhotoCaptureDelegate) {
    capturePhoto(with: settings, delegate: delegate as! AVCapturePhotoCaptureDelegate)
  }
}

public protocol CaptureConnection: AnyObject {
  var isVideoOrientationSupported: Bool { get }
  var videoOrientation: AVCaptureVideoOrientation { get set }
  var isVideoMirrored: Bool { get set }
  static func captureConnection(inputPorts: [AVCaptureInput.Port], output: CaptureOutput) -> CaptureConnection
}
extension AVCaptureConnection: CaptureConnection {
  public static func captureConnection(inputPorts: [AVCaptureInput.Port], output: CaptureOutput) -> CaptureConnection {
    return AVCaptureConnection(inputPorts: inputPorts, output: output as! AVCaptureOutput)
  }
}

public protocol CaptureSession: AnyObject {
  func canAddInput(_ input: CaptureInput) -> Bool
  func canAddOutput(_ output: CaptureOutput) -> Bool
  func addInput(_ input: CaptureInput)
  func addOutput(_ output: CaptureOutput)
  func removeInput(_ input: CaptureInput)
  func removeOutput(_ output: CaptureOutput)
  var captureInputs: [CaptureInput] { get }
  var captureOutputs: [CaptureOutput] { get }

  func addInputWithNoConnections(_ input: CaptureInput)
  func addOutputWithNoConnections(_ output: CaptureOutput)
  func addConnection(_ connection: CaptureConnection)

  func startRunning()
  func stopRunning()

  func canSetSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool
  var sessionPreset: AVCaptureSession.Preset { get set }

}

extension AVCaptureSession: CaptureSession {

  public func canAddInput(_ input: CaptureInput) -> Bool {
    return canAddInput(input as! AVCaptureInput)
  }

  public func canAddOutput(_ output: CaptureOutput) -> Bool {
    return canAddOutput(output as! AVCaptureOutput)
  }

  public func addOutput(_ output: CaptureOutput) {
    addOutput(output as! AVCaptureOutput)
  }

  public func addInput(_ input: CaptureInput) {
    addInput(input as! AVCaptureInput)
  }

  public func removeInput(_ input: CaptureInput) {
    removeInput(input as! AVCaptureInput)
  }

  public func removeOutput(_ output: CaptureOutput) {
    removeOutput(output as! AVCaptureOutput)
  }

  public var captureInputs: [CaptureInput] {
    return inputs as [CaptureInput]
  }
  public var captureOutputs: [CaptureOutput] {
    return outputs as [CaptureOutput]
  }

  public func addInputWithNoConnections(_ input: CaptureInput) {
    addInputWithNoConnections(input as! AVCaptureInput)
  }

  public func addOutputWithNoConnections(_ output: CaptureOutput) {
    addOutputWithNoConnections(output as! AVCaptureOutput)
  }

  public func addConnection(_ connection: CaptureConnection) {
    addConnection(connection as! AVCaptureConnection)
  }
}

public protocol CaptureDeviceFormat {
  var highResolutionStillImageDimensions: CMVideoDimensions { get }
}

extension AVCaptureDevice.Format: CaptureDeviceFormat {}

public protocol CaptureDevice: AnyObject {
  
  var uniqueID: String { get }
  var hasFlash: Bool { get }
  var position: AVCaptureDevice.Position { get }
  var activeCaptureFormat: CaptureDeviceFormat { get }
  var lensAperture: Float { get }
  var exposureDuration: CMTime { get }
  var iso: Float { get }

  var hasTorch: Bool { get }
  var isTorchAvailable: Bool { get }
  var torchMode: AVCaptureDevice.TorchMode { get set }
  var exposureMode: AVCaptureDevice.ExposureMode { get set }
  func isExposureModeSupported(_ mode: AVCaptureDevice.ExposureMode) -> Bool
  var focusMode: AVCaptureDevice.FocusMode { get set }
  func isFocusModeSupported(_ mode: AVCaptureDevice.FocusMode) -> Bool

  var isExposurePointOfInterestSupported: Bool { get }
  var exposurePointOfInterest: CGPoint { get set }
  var isFocusPointOfInterestSupported: Bool { get }
  var focusPointOfInterest: CGPoint { get set }

  func setExposureTargetBias(_ bias: Float, completionHandler: ((CMTime) -> Void)?)
  var minExposureTargetBias: Float { get }
  var maxExposureTargetBias: Float { get }

  var minAvailableVideoZoomFactor: CGFloat { get }
  var maxAvailableVideoZoomFactor: CGFloat { get }
  var videoZoomFactor: CGFloat { get set }

  func lockForConfiguration() throws
  func unlockForConfiguration()
}

public protocol CaptureDeviceFactory {
  func captureDevice(uniqueID: String) -> CaptureDevice?
}

extension AVCaptureDevice: CaptureDevice {

  public final class Factory: CaptureDeviceFactory {
    public func captureDevice(uniqueID: String) -> CaptureDevice? {
      return AVCaptureDevice(uniqueID: uniqueID)
    }
  }

  public var activeCaptureFormat: CaptureDeviceFormat {
    return activeFormat
  }

  public static func device(with uniqueID: String) -> CaptureDevice? {
    return AVCaptureDevice(uniqueID: uniqueID)
  }
}

public protocol CaptureDeviceInput: CaptureInput {
  static func input(with device: CaptureDevice) throws -> CaptureDeviceInput
}

extension AVCaptureDeviceInput: CaptureDeviceInput {
  public static func input(with device: CaptureDevice) throws -> CaptureDeviceInput {
    return try AVCaptureDeviceInput(device: device as! AVCaptureDevice)
  }
}


protocol FLTCamProtocol: FlutterTexture {

  var captureVideoOutput: AVCaptureVideoDataOutput { get }
  var captureDevice: CaptureDevice { get }
  var previewSize: CGSize { get }
  var isPreviewPaused: Bool { get }
  var onFrameAvailable: (() -> Void)? { get set }
  var methodChannel: ThreadSafeMethodChannelProtocol! { get set }
  var resolutionPreset: FLTResolutionPreset { get }


  var exposureMode: FLTExposureMode { get }
  var focusMode: FLTFocusMode { get }
  var flashMode: FLTFlashMode { get }

  var videoFormat: FourCharCode { get set }



  func start()
  func stop()

  func setVideoFormat(_ videoFormat: OSType)

  func setDeviceOrientation(_ orientation: UIDeviceOrientation)

  func captureToFile(with result: ThreadSafeFlutterResultProtocol)

  func close()

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>?

  func startVideoRecording(with result: ThreadSafeFlutterResultProtocol)

  func setupWriterForPath(_ path: String?) throws -> Bool
  func setUpCaptureSessionForAudio() throws




  func stopVideoRecording(with result: ThreadSafeFlutterResultProtocol)

  func pauseVideoRecording(with result: ThreadSafeFlutterResultProtocol)

  func resumeVideoRecording(with result: ThreadSafeFlutterResultProtocol)

  func lockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol, orientation orientationStr: String)

  func unlockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol)

  func setFlashMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws

  func setExposureMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws

  func applyExposureMode() throws

  func setFocusMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws

  func applyFocusMode() throws

  func applyFocusMode(_ mode: FLTFocusMode, on device: CaptureDevice) throws

  func pausePreview(with result: ThreadSafeFlutterResultProtocol)

  func resumePreview(with result: ThreadSafeFlutterResultProtocol)

  func getCGPointForCoordsWithOrientation(_ orientation: UIDeviceOrientation, x: Double, y: Double) -> CGPoint

  func setExposurePoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider) throws

  func setFocusPoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider) throws

  func setExposureOffset(with result: ThreadSafeFlutterResultProtocol, offset: Double) throws

  func startImageStream(with messenger: FlutterBinaryMessenger)

  func startImageStream(with messenger: FlutterBinaryMessenger, imageStreamHandler: ImageStreamHandler)

  func stopImageStream()


  func receivedImageStreamData()

  func getMaxZoomLevel(with result: ThreadSafeFlutterResultProtocol)

  func getMinZoomLevel(with result: ThreadSafeFlutterResultProtocol)

  func setZoomLevel(_ zoom: CGFloat, result: ThreadSafeFlutterResultProtocol) throws

  func getMaxAvailableZoomFactor() -> CGFloat

  func getMinAvailableZoomFactor() -> CGFloat


}

public final class FLTCam: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, FLTCamProtocol {

  @objc
  public let captureVideoOutput: AVCaptureVideoDataOutput
  private let capturePhotoOutput: CapturePhotoOutput
  private var isStreamingImages: Bool
  private(set) var inProgressSavePhotoDelegates = [Int64:CapturePhotoCaptureDelegate]()

  let captureDevice: CaptureDevice
  var previewSize: CGSize
  private(set) var isPreviewPaused: Bool
  var onFrameAvailable: (() -> Void)?
  var methodChannel: ThreadSafeMethodChannelProtocol!
  let resolutionPreset: FLTResolutionPreset
  private(set) var exposureMode: FLTExposureMode
  private(set) var focusMode: FLTFocusMode
  private(set) var flashMode: FLTFlashMode
  var videoFormat: FourCharCode

  private var textureId: Int64
  private let enableAudio: Bool
  private var imageStreamHandler: ImageStreamHandler?
  private let captureSession: CaptureSession
  private let captureVideoInput: CaptureInput
  private var latestPixelBuffer: CVPixelBuffer?
  private let captureSize: CGSize
  private var videoWriter: AVAssetWriter!
  private var videoWriterInput: AVAssetWriterInput!
  private var audioWriterInput: AVAssetWriterInput!
  private let videoOutput: AVCaptureVideoDataOutput!
  private var audioOutput: AVCaptureAudioDataOutput!
  private var videoRecordingPath: String?
  private var isRecording: Bool
  private var isRecordingPaused: Bool
  private var videoIsDisconnected: Bool
  private var audioIsDisconnected: Bool
  private var isAudioSetup: Bool

  private var streamingPendingFramesCount: Int
  private let maxStreamingPendingFramesCount: Int


  private var lockedCaptureOrientation: UIDeviceOrientation
  private var lastVideoSampleTime: CMTime
  private var lastAudioSampleTime: CMTime
  private var videoTimeOffset: CMTime
  private var audioTimeOffset: CMTime
  private var videoAdapter: AVAssetWriterInputPixelBufferAdaptor!
  private let captureSessionQueue: DispatchQueue
  private let pixelBufferSynchronizationQueue: DispatchQueue
  private let photoIOQueue: DispatchQueue
  private var deviceOrientation: UIDeviceOrientation


  init?(
    cameraName: String,
    resolutionPreset: String,
    enableAudio: Bool,
    orientation: UIDeviceOrientation,
    captureSession: CaptureSession = AVCaptureSession(),
    captureSessionQueue: DispatchQueue,
    capturePhotoOutput: CapturePhotoOutput = AVCapturePhotoOutput(),
    captureDeviceFactory: CaptureDeviceFactory = AVCaptureDevice.Factory(),
    captureDeviceInputType: CaptureDeviceInput.Type = AVCaptureDeviceInput.self,
    captureConnectionType: CaptureConnection.Type = AVCaptureConnection.self) throws
  {

    if let resolutionPreset = FLTResolutionPreset(rawValue: resolutionPreset) {
      self.resolutionPreset = resolutionPreset
    } else {
      throw NSError(domain: "ResolutionPreset unsupported", code: 1)
    }

    self.enableAudio = enableAudio
    self.captureSessionQueue = captureSessionQueue
    self.pixelBufferSynchronizationQueue = DispatchQueue(label: "io.flutter.camera.pixelBufferSynchronizationQueue")
    self.photoIOQueue = DispatchQueue(label: "io.flutter.camera.photoIOQueue")
    self.captureSession = captureSession
    self.captureDevice = captureDeviceFactory.captureDevice(uniqueID: cameraName)!
    self.flashMode = captureDevice.hasFlash ? .auto : .off
    self.exposureMode = .auto
    self.focusMode = .auto
    self.lockedCaptureOrientation = .unknown
    self.deviceOrientation = orientation
    self.videoFormat = kCVPixelFormatType_32BGRA
    self.maxStreamingPendingFramesCount = 4
    try self.captureVideoInput = captureDeviceInputType.input(with: captureDevice)

    self.captureVideoOutput = AVCaptureVideoDataOutput()
    captureVideoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):Int(videoFormat)]

    captureVideoOutput.alwaysDiscardsLateVideoFrames = true


    let connection = captureConnectionType.captureConnection(inputPorts: captureVideoInput.ports, output: captureVideoOutput)

    if captureDevice.position == .front {
      connection.isVideoMirrored = true
    }

    captureSession.addInputWithNoConnections(captureVideoInput)
    captureSession.addOutputWithNoConnections(captureVideoOutput)
    captureSession.addConnection(connection)

    self.capturePhotoOutput = capturePhotoOutput
    self.capturePhotoOutput.isHighResolutionCaptureEnabled = true
    captureSession.addOutput(capturePhotoOutput)

    // TODO: make these defalt values
    self.isStreamingImages = false
    self.previewSize = .zero
    self.isPreviewPaused = false
    self.onFrameAvailable = { }

    self.textureId = 0
    self.captureSize = .zero
    self.videoWriter = nil
    self.videoWriterInput = nil
    self.audioWriterInput = nil
    self.videoOutput = nil
    self.audioOutput = nil
    self.isRecording = false
    self.isRecordingPaused = false
    self.videoIsDisconnected = false
    self.audioIsDisconnected = false
    self.isAudioSetup = false
    self.streamingPendingFramesCount = 0
    self.lastVideoSampleTime = CMTime()
    self.lastAudioSampleTime = CMTime()
    self.videoTimeOffset = CMTime()
    self.audioTimeOffset = CMTime()
    self.videoAdapter = nil


    super.init()

    try self.setCaptureSessionPreset(resolutionPreset: self.resolutionPreset)
    self.updateOrientation()

    captureVideoOutput.setSampleBufferDelegate(self, queue: captureSessionQueue)
  }


  func start() {
    captureSession.startRunning()
  }

  func stop() {
    captureSession.stopRunning()
  }

  func setVideoFormat(_ videoFormat: OSType) {
    self.videoFormat = videoFormat
    captureVideoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):Int(videoFormat)]
  }

  @objc
  public func setDeviceOrientation(_ orientation: UIDeviceOrientation) {
    if self.deviceOrientation == orientation {
      return
    }

    self.deviceOrientation = orientation
    self.updateOrientation()

  }


  private func updateOrientation() {
    if isRecording {
      return
    }

    let orientation = lockedCaptureOrientation != .unknown ? lockedCaptureOrientation : deviceOrientation

    updateOrientation(orientation, forCaptureOutput: capturePhotoOutput)
    updateOrientation(orientation, forCaptureOutput: captureVideoOutput)
  }

  private func updateOrientation(_ orientation: UIDeviceOrientation, forCaptureOutput captureOutput: CaptureOutput?) {
    guard let captureOutput = captureOutput else {
      return
    }

    if let connection = captureOutput.captureConnection(with: .video), connection.isVideoOrientationSupported {
      connection.videoOrientation = getVideoOrientationForDeviceOrientation(orientation)
    }

  }

  func captureToFile(with result: ThreadSafeFlutterResultProtocol) {
    let settings = AVCapturePhotoSettings()
    if resolutionPreset == .max {
      settings.isHighResolutionPhotoEnabled = true
    }

    if let avFlashMode = flashMode.flashMode {
      settings.flashMode = avFlashMode
    }

    let path: String?
    do {
      path = try getTemporaryFilePathWithExtension("jpg", subfolder: "pictures", prefix: "CAP_")
    } catch {
      result.sendError(error as NSError)
      return
    }

    guard let path = path else {
      result.sendError(NSError(domain: "FLTCam", code: 1))
      return
    }

    let savePhotoDelegate = SavePhotoDelegate(path: path, ioQueue: self.photoIOQueue) { path, error in
      self.captureSessionQueue.async {
        self.inProgressSavePhotoDelegates[settings.uniqueID] = nil
      }
      if let error = error {
        result.sendError(error as NSError)
      } else {
        assert(path != nil, "Path must not be nil if no error")
        result.sendSuccess(withData: path!)
      }
    }

    assert(SwiftQueueUtils.isOnQueue(specific: .captureSession), "save photo delegate references must be updated on the capture session queue")

    inProgressSavePhotoDelegates[settings.uniqueID] = savePhotoDelegate

    capturePhotoOutput.capturePhoto(with: settings, delegate: savePhotoDelegate)
  }

  private func getVideoOrientationForDeviceOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
    switch deviceOrientation {
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    case .portrait, .faceUp, .faceDown, .unknown:
      return .portrait
    @unknown default:
      return .portrait
    }
  }

  private func getTemporaryFilePathWithExtension(_ extension: String, subfolder: String, prefix: String) throws -> String {

    let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString

    let fileDir = (docDir.appendingPathComponent("camera") as NSString).appendingPathComponent(subfolder) as NSString

    let fileName = prefix.appending(UUID().uuidString)

    let file = (fileDir.appendingPathComponent(fileName) as NSString).appendingPathExtension(`extension`)!

    let fm = FileManager.default
    if !fm.fileExists(atPath: fileDir as String) {
      try fm.createDirectory(atPath: fileDir as String, withIntermediateDirectories: true, attributes: nil)
    }
    return file
  }

  private func setCaptureSessionPreset(resolutionPreset: FLTResolutionPreset) throws {
    switch resolutionPreset {
    case .max, .ultraHigh:
      if captureSession.canSetSessionPreset(.hd4K3840x2160) {
        captureSession.sessionPreset = .hd4K3840x2160
        previewSize = CGSize(width: 3840, height: 2160)
      } else if captureSession.canSetSessionPreset(.high) {
        captureSession.sessionPreset = .high
        previewSize = CGSize(width: Int(captureDevice.activeCaptureFormat.highResolutionStillImageDimensions.width), height: Int(captureDevice.activeCaptureFormat.highResolutionStillImageDimensions.height))
      }
    case .veryHigh:
      if captureSession.canSetSessionPreset(.hd1920x1080) {
        captureSession.sessionPreset = .hd1920x1080
        previewSize = CGSize(width: 1920, height: 1080)
      }
    case .high:
      if captureSession.canSetSessionPreset(.hd1280x720) {
        captureSession.sessionPreset = .hd1280x720
        previewSize = CGSize(width: 1280, height: 720)
      }
    case .medium:
      if captureSession.canSetSessionPreset(.vga640x480) {
        captureSession.sessionPreset = .vga640x480
        previewSize = CGSize(width: 640, height: 480)
      }
    case .low:
      if captureSession.canSetSessionPreset(.cif352x288) {
        captureSession.sessionPreset = .cif352x288
        previewSize = CGSize(width: 352, height: 288)
      }
    default:
      if captureSession.canSetSessionPreset(.cif352x288) {
        captureSession.sessionPreset = .cif352x288
        previewSize = CGSize(width: 352, height: 288)
      } else {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "No capture session available for current capture session."])
        throw error
      }
    }
  }

  public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

    if output == captureVideoOutput {

      let newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

      pixelBufferSynchronizationQueue.sync {
        self.latestPixelBuffer = newBuffer
      }
      if let onFrameAvailable = onFrameAvailable {
        onFrameAvailable()
      }
    }

    if !CMSampleBufferDataIsReady(sampleBuffer) {
      methodChannel.invokeMethod("error", arguments: "sample buffer is not ready. Skipping sample")
      return
    }

    if isStreamingImages {

      let eventSink = imageStreamHandler?.eventSink

      if let eventSink = eventSink, streamingPendingFramesCount < maxStreamingPendingFramesCount {
        streamingPendingFramesCount += 1

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)

        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)

        let isPlanar = CVPixelBufferIsPlanar(pixelBuffer)
        let planeCount = isPlanar ? CVPixelBufferGetPlaneCount(pixelBuffer) : 1

        var planes = [[String: Any]]()
        for i in 0..<planeCount {
          let planeAddress: UnsafeMutableRawPointer?
          let bytesPerRow: Int
          let height: Int
          let width: Int
          if isPlanar {

            planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i)

            bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i)

            height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i)
            width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i)

          } else {
            planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            height = CVPixelBufferGetHeight(pixelBuffer)
            width = CVPixelBufferGetWidth(pixelBuffer)
          }

          let length = bytesPerRow * height
          let bytes = NSData(bytes: planeAddress, length: length)


          let planeBuffer: [String: Any] = [
            "bytesPerRow": bytesPerRow,
            "width": width,
            "height": height,
            "bytes": FlutterStandardTypedData(bytes: bytes as Data)
          ]
          planes += [planeBuffer]

        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        let imageBuffer: [String: Any] = [
          "width": imageWidth,
          "height": imageHeight,
          "format": Int(videoFormat),
          "planes": planes,
          "lensAperture": captureDevice.lensAperture,
          "sensorExposureTime": 1_000_000_000 * CMTimeGetSeconds(captureDevice.exposureDuration),
          "sensorSensitivity": captureDevice.iso,
        ]

        DispatchQueue.main.async {
          eventSink(imageBuffer)
        }
      }
    }

    if isRecording && !isRecordingPaused {

      if videoWriter.status == .failed {
        methodChannel.invokeMethod("error", arguments: "\(String(describing: videoWriter.error))")
        return
      }

      var currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

      if videoWriter.status != .writing {

        videoWriter.startWriting()

        videoWriter.startSession(atSourceTime: currentSampleTime)
      }

      if output == captureVideoOutput {
        if videoIsDisconnected {
          videoIsDisconnected = false

          if videoTimeOffset.value == 0 {
            videoTimeOffset = CMTimeSubtract(currentSampleTime, lastVideoSampleTime)
          } else {
            let offset = CMTimeSubtract(currentSampleTime, lastVideoSampleTime)
            videoTimeOffset = CMTimeAdd(videoTimeOffset, offset)
          }
          return
        }


        lastVideoSampleTime = currentSampleTime
        let nextBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let nextSampleTime = CMTimeSubtract(lastVideoSampleTime, videoTimeOffset)
        videoAdapter.append(nextBuffer!, withPresentationTime: nextSampleTime)

      } else {

        let dur = CMSampleBufferGetDuration(sampleBuffer)

        if dur.value > 0 {
          currentSampleTime = CMTimeAdd(currentSampleTime, dur)
        }

        if audioIsDisconnected {
          audioIsDisconnected = false

          if audioTimeOffset.value == 0 {
            audioTimeOffset = CMTimeSubtract(currentSampleTime, lastAudioSampleTime)
          } else {
            let offset = CMTimeSubtract(currentSampleTime, lastAudioSampleTime)
            audioTimeOffset = CMTimeAdd(audioTimeOffset, offset)
          }
          return

        }

        lastAudioSampleTime = currentSampleTime

        if audioTimeOffset.value != 0 {
          let adjustedSampleBuffer = adjustTime(sampleBuffer, by: audioTimeOffset)
          newAudioSample(adjustedSampleBuffer)
        } else {
          newAudioSample(sampleBuffer)
        }
      }

    }

  }

  private func adjustTime(_ sample: CMSampleBuffer, by offset: CMTime) -> CMSampleBuffer {

    var count = CMItemCount()
    CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)

    var info = Array.init(repeating: CMSampleTimingInfo(), count: count)
    CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)

    for i in 0..<count {
      info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset)
      info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset)
    }

    var outBuffer: CMSampleBuffer? = nil
    CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &outBuffer)
    return outBuffer!
  }

  private func newVideoSample(_ sample: CMSampleBuffer) {
    if videoWriter.status != .writing {

      if videoWriter.status == .failed {
        methodChannel.invokeMethod("error", arguments: videoWriter.error.map { "\($0)" })
      }

      return
    }

    if videoWriterInput.isReadyForMoreMediaData {
      if !videoWriterInput.append(sample) {
        methodChannel.invokeMethod("error", arguments: "Unable to write to video input")
      }
    }
  }

  private func newAudioSample(_ sample: CMSampleBuffer) {
    if videoWriter.status != .writing {
      if videoWriter.status == .failed {
        methodChannel.invokeMethod("error", arguments: videoWriter.error.map { "\($0)" })

      }
      return
    }

    if audioWriterInput.isReadyForMoreMediaData {
      if !audioWriterInput.append(sample) {
        methodChannel.invokeMethod("error", arguments: "Unable to write to audio input")
      }
    }
  }

  func close() {
    captureSession.stopRunning()
    for input in captureSession.captureInputs {
      captureSession.removeInput(input)
    }
    for output in captureSession.captureOutputs {
      captureSession.removeOutput(output)
    }
  }

  public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    var pixelBuffer: CVPixelBuffer?
    pixelBufferSynchronizationQueue.sync {
      pixelBuffer = self.latestPixelBuffer
      self.latestPixelBuffer = nil
    }
    return pixelBuffer.map { Unmanaged.passRetained($0) }
  }

  func startVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    if !isRecording {
      let videoRecordingPath: String
      do {
        videoRecordingPath = try      getTemporaryFilePathWithExtension("mp4", subfolder: "videos", prefix: "REC_")
        self.videoRecordingPath = videoRecordingPath
      } catch {
        result.sendError(error as NSError)
        return
      }

      do {
        let success = try setupWriterForPath(videoRecordingPath)
        if !success {
          result.sendError(code: "IOError", message: "Setup writer failed", details: nil)
          return
        }
      } catch {
        result.sendError(error as NSError)
        return
      }

      isRecording = true
      isRecordingPaused = false
      videoTimeOffset = CMTimeMake(value: 0, timescale: 1)
      audioTimeOffset = CMTimeMake(value: 0, timescale: 1)
      videoIsDisconnected = false
      audioIsDisconnected = false
      result.sendSuccess()
    } else {
      result.sendError(code: "Error", message: "Video is already recording", details: nil)
    }
  }

  func setupWriterForPath(_ path: String?) throws -> Bool {
    guard let path = path else {
      return false
    }

    let outputURL = URL(fileURLWithPath: path)

    if enableAudio && !isAudioSetup {
      try setUpCaptureSessionForAudio()
    }

    do {
      videoWriter = try AVAssetWriter(url: outputURL, fileType: AVFileType.mp4)
    } catch {
      methodChannel.invokeMethod("error", arguments: error.localizedDescription)
      return false
    }

    let videoSettings = captureVideoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
    videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

    videoAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: Int(videoFormat)
    ])

    videoWriterInput.expectsMediaDataInRealTime = true

    if enableAudio {

      var acl = AudioChannelLayout()
      acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono

      let audioOutputSettings: [String:Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVChannelLayoutKey: NSData(bytes: &acl, length: MemoryLayout<AudioChannelLayout>.size)
      ]
      audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)

      audioWriterInput.expectsMediaDataInRealTime = true
      videoWriter.add(audioWriterInput)
      audioOutput.setSampleBufferDelegate(self, queue: captureSessionQueue)
    }

    if flashMode == .torch {
      try captureDevice.lockForConfiguration()
      captureDevice.torchMode = .on
      captureDevice.unlockForConfiguration()
    }

    videoWriter.add(videoWriterInput)
    captureVideoOutput.setSampleBufferDelegate(self, queue: captureSessionQueue)
    return true
  }

  func setUpCaptureSessionForAudio() throws {

    let audioDevice = AVCaptureDevice.default(for: .audio)!

    let audioInput: AVCaptureDeviceInput
    do {
      audioInput = try AVCaptureDeviceInput(device: audioDevice)
    } catch {
      methodChannel.invokeMethod("error", arguments: error.localizedDescription)
      return
    }
    audioOutput = AVCaptureAudioDataOutput()
    if captureSession.canAddInput(audioInput) {
      captureSession.addInput(audioInput)
      if captureSession.canAddOutput(audioOutput) {
        captureSession.addOutput(audioOutput)
        isAudioSetup = true
      } else {
        methodChannel.invokeMethod("error", arguments: "Unable to add Audio input/output to session capture")
      }
    } else {
      // TODO: original function incorrect
      methodChannel.invokeMethod("error", arguments: "Unable to add Audio input/output to session capture")
    }










  }






  func stopVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    if isRecording {
      isRecording = false

      if videoWriter.status != .unknown, let path = videoRecordingPath {
        videoWriter.finishWriting {
          if self.videoWriter.status == .completed {
            self.updateOrientation()
            result.sendSuccess(withData: path)
            self.videoRecordingPath = nil
          } else {
            result.sendError(code: "IOError", message: "AVAssetWriter could not finish writing!", details: nil)
          }
        }
      }
    } else {
      let error = NSError(domain: NSCocoaErrorDomain, code: NSURLErrorResourceUnavailable, userInfo: [NSLocalizedDescriptionKey:"Video is not recording!"])
      result.sendError(error)
    }
  }

  func pauseVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    isRecordingPaused = true
    videoIsDisconnected = true
    audioIsDisconnected = true
    result.sendSuccess()
  }

  func resumeVideoRecording(with result: ThreadSafeFlutterResultProtocol) {
    isRecordingPaused = false
    result.sendSuccess()
  }

  func lockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol, orientation orientationStr: String) {
    guard let orientation = FLTOrientation(rawValue: orientationStr)?.orientation else {
      // TODO: handle error here
      return
    }
    if lockedCaptureOrientation != orientation {
      lockedCaptureOrientation = orientation
      updateOrientation()
    }
    result.sendSuccess()
  }

  func unlockCaptureOrientation(with result: ThreadSafeFlutterResultProtocol) {
    lockedCaptureOrientation = .unknown
    self.updateOrientation()
    result.sendSuccess()
  }

  func setFlashMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {
    guard let mode = FLTFlashMode(rawValue: modeStr) else {
      throw NSError(domain: "FLTMode not supported", code: 1)
    }
    if mode == .torch {
      if !captureDevice.hasTorch {
        result.sendError(code: "setFlashModeFailed", message: "Device does not support torch mode", details: nil)
        return
      }
      if !captureDevice.isTorchAvailable {
        result.sendError(code: "setFlashModeFailed", message: "Torch mode is currently not available", details: nil)
        return
      }
      if captureDevice.torchMode != .on {
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = .on
        captureDevice.unlockForConfiguration()
      }
    } else {

      if !captureDevice.hasFlash {
        result.sendError(code: "setFlashModeFialed", message: "Device does not have flash capabilities", details: nil)
        return
      }

      guard let avFlashMode = mode.flashMode else {
        throw NSError(domain: "Flash mode unsupported", code: 1)
      }
      if !capturePhotoOutput.supportedFlashModes.contains(avFlashMode) {
        result.sendError(code: "setFlashModeFailed", message: "Device does not support this specific flash mode", details: nil)
        return
      }

      if captureDevice.torchMode != .off {
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = .off
        captureDevice.unlockForConfiguration()
      }
    }
    flashMode = mode
    result.sendSuccess()
  }

  func setExposureMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {

    guard let mode = FLTExposureMode(rawValue: modeStr) else {
      throw NSError(domain: "Exposure not supported", code: 1)
    }

    exposureMode = mode
    try applyExposureMode()
    result.sendSuccess()
  }

  func applyExposureMode() throws {
    try captureDevice.lockForConfiguration()
    switch exposureMode {
    case .locked:
      // TODO: original implementation is wrong
      captureDevice.exposureMode = .locked
    case .auto:
      if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
        captureDevice.exposureMode = .continuousAutoExposure
      } else {
        captureDevice.exposureMode = .autoExpose
      }
    @unknown default:
      fatalError("this should not happen")
    }
    captureDevice.unlockForConfiguration()
  }

  func setFocusMode(with result: ThreadSafeFlutterResultProtocol, mode modeStr: String) throws {
    guard let mode = FLTFocusMode(rawValue: modeStr) else { throw NSError(domain: "Focus not supported", code: 1) }
    focusMode = mode
    try applyFocusMode()
    result.sendSuccess()
  }

  func applyFocusMode() throws {
    try applyFocusMode(focusMode, on: captureDevice)
  }

  func applyFocusMode(_ mode: FLTFocusMode, on device: CaptureDevice) throws {
    try device.lockForConfiguration()
    switch mode {
    case .locked:
      // TODO: original implementation is wrong
      device.focusMode = .locked
    case .auto:
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      } else if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      }
    @unknown default:
      fatalError("this should not happen")
    }
    device.unlockForConfiguration()
  }

  func pausePreview(with result: ThreadSafeFlutterResultProtocol) {
    isPreviewPaused = true
    result.sendSuccess()
  }

  func resumePreview(with result: ThreadSafeFlutterResultProtocol) {
    isPreviewPaused = false
    result.sendSuccess()
  }

  func getCGPointForCoordsWithOrientation(_ orientation: UIDeviceOrientation, x: Double, y: Double) -> CGPoint {

    switch orientation {
    case .portrait: // 90 ccw
      return CGPoint(x: y, y: 1 - x)
    case .portraitUpsideDown: // 90 cw
      return CGPoint(x: 1 - y, y: x)
    case .landscapeRight: // 180
      return CGPoint(x: 1 - x, y: 1 - y)
    default: // no rotation required
      return CGPoint(x: x, y: y)
    }
  }

  func setExposurePoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider = UIDevice.current) throws {
    if !captureDevice.isExposurePointOfInterestSupported {
      result.sendError(code: "setExposurePointFailed", message: "Device does not have exposure point capabilities", details: nil)
      return
    }

    let orientation = deviceOrientationProvider.orientation
    try captureDevice.lockForConfiguration()
    captureDevice.exposurePointOfInterest = getCGPointForCoordsWithOrientation(orientation, x: x, y: y)
    captureDevice.unlockForConfiguration()
    try self.applyExposureMode()
    result.sendSuccess()
  }

  public func setFocusPoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double, deviceOrientationProvider: DeviceOrientationProvider = UIDevice.current) throws {
    if !captureDevice.isFocusPointOfInterestSupported {
      result.sendError(code: "setFocusPointFailed", message: "Device does not have focus point capabilities", details: nil)
      return
    }

    let orientation = deviceOrientationProvider.orientation
    try captureDevice.lockForConfiguration()

    captureDevice.focusPointOfInterest = getCGPointForCoordsWithOrientation(orientation, x: x, y: y)
    captureDevice.unlockForConfiguration()
    try applyFocusMode()
    result.sendSuccess()
  }

  func setExposureOffset(with result: ThreadSafeFlutterResultProtocol, offset: Double) throws {
    try captureDevice.lockForConfiguration()
    captureDevice.setExposureTargetBias(Float(offset), completionHandler: nil)
    captureDevice.unlockForConfiguration()
    result.sendSuccess(withData: offset)
  }

  func startImageStream(with messenger: FlutterBinaryMessenger) {
    startImageStream(with: messenger, imageStreamHandler: ImageStreamHandler(captureSessionQueue: captureSessionQueue))
  }

  func startImageStream(with messenger: FlutterBinaryMessenger, imageStreamHandler: ImageStreamHandler) {
    if !isStreamingImages {
      let eventChannel = FlutterEventChannel(name: "plugins.flutter.io/camera/imageStream", binaryMessenger: messenger)

      let threadSafeEventChannel = ThreadSafeEventChannel(channel: eventChannel)
      self.imageStreamHandler = imageStreamHandler
      threadSafeEventChannel.setStreamHandler(imageStreamHandler) {
        self.captureSessionQueue.async {
          self.isStreamingImages = true
          self.streamingPendingFramesCount = 0
        }
      }

    } else {
      methodChannel.invokeMethod("error", arguments: "Images from camera are already streaming!")
    }
  }

  func stopImageStream() {
    if isStreamingImages {
      isStreamingImages = false
      imageStreamHandler = nil
    } else {
      methodChannel.invokeMethod("error", arguments: "Images from camera are not stremaing!")
    }
  }



  func receivedImageStreamData() {
    streamingPendingFramesCount -= 1
  }

  func getMaxZoomLevel(with result: ThreadSafeFlutterResultProtocol) {
    let maxZoomFactor = getMaxAvailableZoomFactor()
    result.sendSuccess(withData: NSNumber(floatLiteral: maxZoomFactor))
  }

  func getMinZoomLevel(with result: ThreadSafeFlutterResultProtocol) {
    let minZoomFactor = getMinAvailableZoomFactor()
    result.sendSuccess(withData: NSNumber(floatLiteral: minZoomFactor))
  }

  func setZoomLevel(_ zoom: CGFloat, result: ThreadSafeFlutterResultProtocol) throws {
    let maxAvailableZoomFactor = getMaxAvailableZoomFactor()
    let minAvailableZoomFactor = getMinAvailableZoomFactor()
    if maxAvailableZoomFactor < zoom || minAvailableZoomFactor > zoom {
      let errorMessage = "Zoom level out of bounds (zoom level should be between \(minAvailableZoomFactor) and \(maxAvailableZoomFactor)."
      result.sendError(code: "ZOOM_ERROR", message: errorMessage, details: nil)
      return
    }

    try captureDevice.lockForConfiguration()
    captureDevice.videoZoomFactor = zoom
    captureDevice.unlockForConfiguration()
    result.sendSuccess()
  }



  func getMaxAvailableZoomFactor() -> CGFloat {
    return captureDevice.minAvailableVideoZoomFactor
  }

  func getMinAvailableZoomFactor() -> CGFloat {
    return captureDevice.maxAvailableVideoZoomFactor
  }




}
