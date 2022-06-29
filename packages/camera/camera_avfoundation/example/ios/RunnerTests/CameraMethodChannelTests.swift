//
//  CameraMethodChannelTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/29/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
@testable import camera_avfoundation
import AVFoundation
import XCTest
import Flutter

final class CameraMethodChannelTests: XCTestCase {

  func testCreate_ShouldCallResultOnMainThread() {
    let camera = SwiftCameraPlugin(registry: MockTextureRegistry(), messenger: MockBinaryMessenger())

    let expectation = expectation(description: "Result finished")

    MockCaptureDeviceInput.inputStub = { _ in
      return MockCaptureDeviceInput()
    }

    let mockCaptureSession = MockCaptureSession()
    mockCaptureSession.canSetSessionPresetStub = { _ in true }

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in .authorized }

    let call = FlutterMethodCall(methodName: "create", arguments: ["resolutionPreset": "medium", "enableAudio": NSNumber(booleanLiteral: true)])

    var receivedResult: Any? = nil
    camera.handle(call) { result in
      receivedResult = result
      expectation.fulfill()
    }

    waitForExpectations(timeout: 1)

    let dictionaryResult = receivedResult as? NSDictionary
    XCTAssertNotNil(dictionaryResult)
    XCTAssert(dictionaryResult?.allKeys.contains { $0 == "cameraId" } ?? false)
  }


}
