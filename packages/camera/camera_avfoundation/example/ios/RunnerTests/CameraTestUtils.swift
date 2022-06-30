//
//  CameraTestUtils.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
@testable import camera_avfoundation
import AVFoundation
import XCTest
import Flutter

enum CameraTestUtils {

  static func createCameraPlugin(
    registry: FlutterTextureRegistry = MockTextureRegistry(),
    messenger: FlutterBinaryMessenger = MockBinaryMessenger(),
    captureSession: CaptureSession = MockCaptureSession(),
    discoverySessionType: DiscoverySession.Type = MockDiscoverySession.self,
    captureDeviceType: CaptureDevice.Type = MockCaptureDevice.self,
    captureDeviceInputType: CaptureDeviceInput.Type = MockCaptureDeviceInput.self,
    captureConnectionType: CaptureConnection.Type = MockCaptureConnection.self,
    threadSafeMethodChannelType: ThreadSafeMethodChannelProtocol.Type = MockThreadSafeMethodChannel.self
  ) -> SwiftCameraPlugin {
    if MockCaptureDevice.deviceStub == nil {
      MockCaptureDevice.deviceStub = { _ in MockCaptureDevice() }
    }
    if MockThreadSafeMethodChannel.methodChannelStub == nil {
      MockThreadSafeMethodChannel.methodChannelStub = { _, _ in
        MockThreadSafeMethodChannel()
      }
    }
    return SwiftCameraPlugin(
      registry: registry,
      messenger: messenger,
      captureSession: captureSession,
      discoverySessionType: discoverySessionType,
      captureDeviceType: captureDeviceType,
      captureDeviceInputType: captureDeviceInputType,
      captureConnectionType: captureConnectionType,
      threadSafeMethodChannelType: threadSafeMethodChannelType)
  }

  static func createCam(
    on captureSessionQueue: DispatchQueue,
    captureSession: CaptureSession = MockCaptureSession(),
    captureDeviceType: CaptureDevice.Type = MockCaptureDevice.self,
    capturePhotoOutput: CapturePhotoOutput = MockCapturePhotoOutput()) -> FLTCam
  {
    return try! FLTCam(
      cameraName: "camera",
      resolutionPreset: "medium",
      enableAudio: true,
      orientation: .portrait,
      captureSession: captureSession,
      captureSessionQueue: captureSessionQueue,
      capturePhotoOutput: capturePhotoOutput,
      captureDeviceType: captureDeviceType,
      captureDeviceInputType: MockCaptureDeviceInput.self,
      captureConnectionType: MockCaptureConnection.self)!
  }

  static func createTestSampleBuffer() -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer!
    CVPixelBufferCreate(kCFAllocatorDefault, 100, 100, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

    var formatDescription: CMFormatDescription!
    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &formatDescription)

    var timingInfo = CMSampleTimingInfo(duration: CMTime(), presentationTimeStamp: CMTime(), decodeTimeStamp: CMTime())
    var sampleBuffer: CMSampleBuffer!
    CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: formatDescription, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)
    return sampleBuffer
  }

}
