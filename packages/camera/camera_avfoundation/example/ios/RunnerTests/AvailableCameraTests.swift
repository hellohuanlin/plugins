//
//  AvailableCameraTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/29/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import Flutter
import XCTest
import AVFoundation
@testable import camera_avfoundation;

final class AvailableCameraTests: XCTestCase {

  func testAvailableCamerasShouldReturnAllCamerasOnMultiCameraIPhone() {

    let camera = CameraTestUtils.createCameraPlugin()

    let expectation = expectation(description: "Result finished")

    let wideAngleCamera = MockCaptureDevice(uniqueID: "1")
    wideAngleCamera.position = .back

    let frontFacingCamera = MockCaptureDevice(uniqueID: "2")
    frontFacingCamera.position = .front

    let ultraWideCamera = MockCaptureDevice(uniqueID: "3")
    ultraWideCamera.position = .back

    let telephotoCamera = MockCaptureDevice(uniqueID: "4")
    telephotoCamera.position = .back

    var devices = [wideAngleCamera, frontFacingCamera, telephotoCamera]

    if #available(iOS 13, *) {
      devices += [ultraWideCamera]
    }

    var requiredTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]

    if #available(iOS 13, *) {
      requiredTypes += [.builtInUltraWideCamera]
    }

    let mockDiscoverySession = MockDiscoverySession()
    MockDiscoverySession.discoverySessionStub = { _, _, _ in mockDiscoverySession }
    mockDiscoverySession.captureDevices = devices

    let call = FlutterMethodCall(methodName: "availableCameras", arguments: nil)
    let result = MockThreadSafeFlutterResult()
    var dictionaryResult: [[String: Any]]?
    result.sendSuccessWithDataStub = { data in
      dictionaryResult = data as? [[String: Any]]
      expectation.fulfill()
    }
    camera.handleAsync(call, result: result)

    if #available(iOS 13.0, *) {
      XCTAssertEqual(dictionaryResult?.count, 4)
    } else {
      XCTAssertEqual(dictionaryResult?.count, 3)
    }

    waitForExpectations(timeout: 1)
  }
}
