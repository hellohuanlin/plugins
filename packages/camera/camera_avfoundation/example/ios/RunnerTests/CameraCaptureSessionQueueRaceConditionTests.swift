//
//  CameraCaptureSessionQueueRaceConditionTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/29/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import Flutter
import XCTest
@testable import camera_avfoundation;

final class CameraCaptureSessionQueueRaceConditionTests: XCTestCase {
  func testFixForCaptureSessionQueueNullPointerCrashDueToRaceCondition() {
    let cam = SwiftCameraPlugin(registry: MockTextureRegistry(), messenger: MockBinaryMessenger())

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in .authorized }

    let disposeExpectation = expectation(description: "dispose's result block must be called")
    let createExpectation = expectation(description: "create's result block must be called")
    let disposeCall = FlutterMethodCall(methodName: "dispose", arguments: nil)
    let createCall = FlutterMethodCall(methodName: "create", arguments: ["resolutionPreset": "medium", "enableAudio": NSNumber(booleanLiteral: true)])


    // Mimic a dispose call followed by a create call, which can be triggered by slightly dragging the
    // home bar, causing the app to be inactive, and immediately regain active.

    cam.handle(disposeCall) { _ in
      disposeExpectation.fulfill()
    }

    cam.handle(createCall) { _ in
      createExpectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    // `captureSessionQueue` must not be nil after `create` call. Otherwise a nil
    // `captureSessionQueue` passed into `AVCaptureVideoDataOutput::setSampleBufferDelegate:queue:`
    // API will cause a crash.
    
    XCTAssertNotNil(cam.test_captureSessionQueue, "captureSessionQueue must not be nil after create method. ")



  }
}
