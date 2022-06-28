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
    let cam = CameraTestUtils.createCam(on: captureSessionQueue, captureSession: AVCaptureSession())

    let settings = AVCapturePhotoSettings()


    let mockResult = MockThreadSafeFlutterResult()
    mockResult.sendErrorStub = { _ in
      errorExpectation.fulfill()
    }






  }
}
