//
//  CameraSampleBufferTests.swift
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

final class CmaeraSampleBufferTests: XCTestCase {

  func testSampleBufferCallbackQueueMustBeCaptureSessionQueue() {
    let captureSessionQueue = DispatchQueue(label: "test")
    let cam = CameraTestUtils.createCam(on: captureSessionQueue, captureSession: AVCaptureSession())
    XCTAssertEqual(captureSessionQueue, cam.captureVideoOutput.sampleBufferCallbackQueue, "Sample buffer callback queue must be the capture session queue.")
  }

  func testCopyPixelBuffer() {
    let captureSessionQueue = DispatchQueue(label: "test")
    let cam = CameraTestUtils.createCam(on: captureSessionQueue, captureSession: AVCaptureSession())
    let capturedSampleBuffer = CameraTestUtils.createTestSampleBuffer()
    let capturedPixelBuffer = CMSampleBufferGetImageBuffer(capturedSampleBuffer)
    cam.captureOutput(cam.captureVideoOutput, didOutput: capturedSampleBuffer, from: AVCaptureConnection(inputPorts: [], output: cam.captureVideoOutput))

    let deliveredPixelBuffer = cam.copyPixelBuffer()?.takeRetainedValue()
    XCTAssertEqual(deliveredPixelBuffer, capturedPixelBuffer, "FLTCam must deliver the latest captured pixel buffer to copyPixelBuffer API.")
  }


}
