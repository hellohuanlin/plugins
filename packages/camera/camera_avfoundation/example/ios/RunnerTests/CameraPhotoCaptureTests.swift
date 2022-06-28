//
//  CameraPhotoCaptureTests.swift
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

final class CameraPhotoCaptureTests: XCTestCase {
  func testCaptureToFile_mustReportErrorToResultIfSavePhotoDelegateCompletionsWithError() {

    let errorExpectation = expectation(description: "Must send error to result if save photo delegate completes with error.")

    let captureSessionQueue = DispatchQueue(label: "test")
    SwiftQueueUtils.setSpecific(.captureSession, for: captureSessionQueue)

    let mockOutput = MockCapturePhotoOutput()

    let cam = CameraTestUtils.createCam(on: captureSessionQueue, capturePhotoOutput: mockOutput)

    let mockResult = MockThreadSafeFlutterResult()
    mockResult.sendErrorStub = { _ in
      errorExpectation.fulfill()
    }

    mockOutput.capturePhotoStub = { _, delegate in
      // minic capture failure on io queue
      let ioQueue = DispatchQueue(label: "io")
      SwiftQueueUtils.setSpecific(.io, for: ioQueue)
      ioQueue.async {
        let error = NSError(domain: "test", code: 0)

        (delegate as? SavePhotoDelegate)?.test_completionHandler(nil, error)
      }
    }


    captureSessionQueue.async {
      cam.captureToFile(with: mockResult)
    }

    waitForExpectations(timeout: 1)
  }

  func testCaptureToFile_mustReportPathToResultIfSavePhotoDelegateCompletionsWithPath() {

    let pathExpectation = expectation(description: "Must send file path to result if save photo delegate completes with file path.")


    let captureSessionQueue = DispatchQueue(label: "test")
    SwiftQueueUtils.setSpecific(.captureSession, for: captureSessionQueue)

    let mockCapturePhotoOutput = MockCapturePhotoOutput()
    let cam = CameraTestUtils.createCam(on: captureSessionQueue, capturePhotoOutput: mockCapturePhotoOutput)

    let filePath = "test"
    let mockResult = MockThreadSafeFlutterResult()
    mockResult.sendSuccessWithDataStub = { _ in
      pathExpectation.fulfill()
    }

    mockCapturePhotoOutput.capturePhotoStub = { _, delegate in
      // minic capture failure on io queue
      let ioQueue = DispatchQueue(label: "io")
      SwiftQueueUtils.setSpecific(.io, for: ioQueue)
      ioQueue.async {
        (delegate as? SavePhotoDelegate)?.test_completionHandler(filePath, nil)
      }
    }

    captureSessionQueue.async {
      cam.captureToFile(with: mockResult)
    }

    waitForExpectations(timeout: 1)
  }
  
}
