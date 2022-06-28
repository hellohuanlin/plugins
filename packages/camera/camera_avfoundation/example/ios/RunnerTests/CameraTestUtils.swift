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


  static func createCam(
    on captureSessionQueue: DispatchQueue,
    captureSession: CaptureSession = MockCaptureSession(),
    capturePhotoOutput: CapturePhotoOutput = MockCapturePhotoOutput()) -> FLTCam
  {
    return try! FLTCam(
      cameraName: "camera",
      resolutionPreset: "medium",
      enableAudio: true,
      orientation: .portrait,
      captureSession: captureSession,
      captureSessionQueue: captureSessionQueue,
      capturePhotoOutput: capturePhotoOutput)!
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
