//
//  FLTCam.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/20/22.
//

import Foundation
import Flutter
import AVFoundation

final class ImageStreamHandler: NSObject, FlutterStreamHandler {
  init(captureSessionQueue: DispatchQueue) {
    self.captureSessionQueue = captureSessionQueue
  }

  private let captureSessionQueue: DispatchQueue
  private(set) var eventSink: FlutterEventSink? = nil

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    captureSessionQueue.async {
      self.eventSink = nil
    }
    return nil
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    captureSessionQueue.async {
      self.eventSink = events
    }
    return nil
  }
}

public final class FLTCam: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, FlutterTexture {

  private let captureVideoOutput: AVCaptureVideoDataOutput
  private let capturePhotoOutput: AVCapturePhotoOutput
  private var isStreamingImages: Bool
  private var inProgressSavePhotoDelegates = [Int64:SavePhotoDelegate]()

  let captureDevice: AVCaptureDevice
  var previewSize: CGSize
  private var isPreviewPaused: Bool
  var onFrameAvailable: (() -> Void)?
  var methodChannel: ThreadSafeMethodChannel!
  let resolutionPreset: FLTResolutionPreset
  private(set) var exposureMode: FLTExposureMode
  private(set) var focusMode: FLTFocusMode
  private(set) var flashMode: FLTFlashMode
  var videoFormat: FourCharCode

  private var textureId: Int64
  private let enableAudio: Bool
  private var imageStreamHandler: ImageStreamHandler?
  private let captureSession: AVCaptureSession
  private let captureVideoInput: AVCaptureInput
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


  init?(cameraName: String, resolutionPreset: String, enableAudio: Bool, orientation: UIDeviceOrientation, captureSession: AVCaptureSession, captureSessionQueue: DispatchQueue) throws {

    self.resolutionPreset = FLTGetFLTResolutionPresetForString(resolutionPreset)

    self.enableAudio = enableAudio
    self.captureSessionQueue = captureSessionQueue
    self.pixelBufferSynchronizationQueue = DispatchQueue(label: "io.flutter.camera.pixelBufferSynchronizationQueue")
    self.photoIOQueue = DispatchQueue(label: "io.flutter.camera.photoIOQueue")
    self.captureSession = captureSession
    self.captureDevice = AVCaptureDevice(uniqueID: cameraName)!
    self.flashMode = captureDevice.hasFlash ? .auto : .off
    self.exposureMode = .auto
    self.focusMode = .auto
    self.lockedCaptureOrientation = .unknown
    self.deviceOrientation = orientation
    self.videoFormat = kCVPixelFormatType_32BGRA
    self.maxStreamingPendingFramesCount = 4
    try self.captureVideoInput = AVCaptureDeviceInput(device: captureDevice)

    self.captureVideoOutput = AVCaptureVideoDataOutput()
    captureVideoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey):Int(videoFormat)]

    captureVideoOutput.alwaysDiscardsLateVideoFrames = true

    let connection = AVCaptureConnection(inputPorts: captureVideoInput.ports, output: captureVideoOutput)

    if captureDevice.position == .front {
      connection.isVideoMirrored = true
    }

    captureSession.addInputWithNoConnections(captureVideoInput)
    captureSession.addOutputWithNoConnections(captureVideoOutput)
    captureSession.addConnection(connection)

    capturePhotoOutput = AVCapturePhotoOutput()
    capturePhotoOutput.isHighResolutionCaptureEnabled = true
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

  func setDeviceOrientation(_ orientation: UIDeviceOrientation) {
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

  private func updateOrientation(_ orientation: UIDeviceOrientation, forCaptureOutput captureOutput: AVCaptureOutput?) {
    guard let captureOutput = captureOutput else {
      return
    }

    if let connection = captureOutput.connection(with: .video), connection.isVideoOrientationSupported {
      connection.videoOrientation = getVideoOrientationForDeviceOrientation(orientation)
    }

  }

  func captureToFile(with result: ThreadSafeFlutterResultProtocol) {
    let settings = AVCapturePhotoSettings()
    if resolutionPreset == .max {
      settings.isHighResolutionPhotoEnabled = true
    }
    let avFlashMode = FLTGetAVCaptureFlashModeForFLTFlashMode(flashMode)
    settings.flashMode = avFlashMode

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

    let file = (fileDir.appendingPathComponent(fileName) as NSString).appendingPathComponent(`extension`)

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
        previewSize = CGSize(width: Int(captureDevice.activeFormat.highResolutionStillImageDimensions.width), height: Int(captureDevice.activeFormat.highResolutionStillImageDimensions.height))
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

      var previousPixelBuffer: CVPixelBuffer?
      pixelBufferSynchronizationQueue.sync {
        previousPixelBuffer = self.latestPixelBuffer
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
    for input in captureSession.inputs {
      captureSession.removeInput(input)
    }
    for output in captureSession.outputs {
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
    // TODO: try catch this
    let orientation = FLTGetUIDeviceOrientationForString(orientationStr)
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
    let mode = FLTGetFLTFlashModeForString(modeStr)
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

      let avFlashMode = FLTGetAVCaptureFlashModeForFLTFlashMode(mode)
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

    let mode = FLTGetFLTExposureModeForString(modeStr)

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
    let mode = FLTGetFLTFocusModeForString(modeStr)

    focusMode = mode
    try applyFocusMode()
    result.sendSuccess()
  }

  func applyFocusMode() throws {
    try captureDevice.lockForConfiguration()
    switch focusMode {
    case .locked:
      // TODO: original implementation is wrong
      captureDevice.focusMode = .locked
    case .auto:
      if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
        captureDevice.focusMode = .continuousAutoFocus
      } else if captureDevice.isFocusModeSupported(.autoFocus) {
        captureDevice.focusMode = .autoFocus
      }
    @unknown default:
      fatalError("this should not happen")
    }
    captureDevice.unlockForConfiguration()
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

  func setExposurePoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double) throws {
    if !captureDevice.isExposurePointOfInterestSupported {
      result.sendError(code: "setExposurePointFailed", message: "Device does not have exposure point capabilities", details: nil)
      return
    }

    let orientation = UIDevice.current.orientation
    try captureDevice.lockForConfiguration()
    captureDevice.exposurePointOfInterest = getCGPointForCoordsWithOrientation(orientation, x: x, y: y)
    captureDevice.unlockForConfiguration()
    try self.applyExposureMode()
    result.sendSuccess()
  }


  func setFocusPoint(with result: ThreadSafeFlutterResultProtocol, x: Double, y: Double) throws {
    if !captureDevice.isFocusPointOfInterestSupported {
      result.sendError(code: "setFocusPointFailed", message: "Device does not have focus point capabilities", details: nil)
      return
    }

    let orientation = UIDevice.current.orientation
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
