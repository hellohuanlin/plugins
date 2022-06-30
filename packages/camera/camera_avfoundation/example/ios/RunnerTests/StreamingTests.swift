//
//  StreamingTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/30/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import Flutter
import XCTest
@testable import camera_avfoundation;

final class StreamingTests: XCTestCase {

  func testExceedMaxStreamingPendingFramesCount() {

    let streamingExpectation = expectation(description: "Must not call handler over maxStreamingPendingFramesCount")
    var fulfillmentCount = 4
    let captureSessionQueue = DispatchQueue(label: "test")
    let mockHandler = ImageStreamHandler(captureSessionQueue: captureSessionQueue)
    let mockMessenger = MockBinaryMessenger()
    _ = mockHandler.onListen(withArguments: nil) { _ in
      fulfillmentCount -= 1
      if fulfillmentCount == 0 {
        streamingExpectation.fulfill()
      }
    }

    let cam = CameraTestUtils.createCam(on: captureSessionQueue)
    cam.startImageStream(with: mockMessenger, imageStreamHandler: mockHandler)

    let sampleBuffer = CameraTestUtils.createTestSampleBuffer()

    let output = AVCaptureVideoDataOutput()
    let connection = AVCaptureConnection(inputPorts: [], output: output)
    for _ in 0..<10 {
      cam.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }

    waitForExpectations(timeout: 1)
  }


  func testReceivedImageStreamData() {

    let streamingExpectation = expectation(description: "Must be able to call the handler again when receivedImageStreamData is called")
    var fulfillmentCount = 5
    let captureSessionQueue = DispatchQueue(label: "test")
    let mockHandler = ImageStreamHandler(captureSessionQueue: captureSessionQueue)
    let mockMessenger = MockBinaryMessenger()
    _ = mockHandler.onListen(withArguments: nil) { _ in
      fulfillmentCount -= 1
      if fulfillmentCount == 0 {
        streamingExpectation.fulfill()
      }
    }

    let cam = CameraTestUtils.createCam(on: captureSessionQueue)
    cam.startImageStream(with: mockMessenger, imageStreamHandler: mockHandler)

    let sampleBuffer = CameraTestUtils.createTestSampleBuffer()

    let output = AVCaptureVideoDataOutput()
    let connection = AVCaptureConnection(inputPorts: [], output: output)
    for _ in 0..<10 {
      cam.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
    cam.receivedImageStreamData()
    cam.captureOutput(output, didOutput: sampleBuffer, from: connection)

    waitForExpectations(timeout: 1)
  }

}

