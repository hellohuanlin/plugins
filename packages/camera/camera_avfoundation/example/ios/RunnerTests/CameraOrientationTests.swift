//
//  CameraOrientationTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/29/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import AVFoundation
import Flutter
import XCTest
@testable import camera_avfoundation

final class CameraOrientationTests: XCTestCase {

  func testOrientationNotifications() {

    let orientationExpectation = expectation(description: "portrait")
    let mockMethodChannel = MockThreadSafeMethodChannel()
    mockMethodChannel.invokeMethodStub = { method, arguments in
      XCTAssertEqual(method, "orientation_changed")
      XCTAssertEqual(arguments as? [String: String], ["orientation": "portraitUp"])
      orientationExpectation.fulfill()
    }

    let mockMessenger = MockBinaryMessenger()
    let camera = CameraTestUtils.createCameraPlugin(messenger: mockMessenger, threadSafeMethodChannelFactory: mockMethodChannel)

    let notification = createMockNotification(for: .portrait)
    camera.orientationChanged(notification as NSNotification)

    waitForExpectations(timeout: 1)
  }

  func createMockNotification(for orientation: UIDeviceOrientation) -> Notification {
    let mockDevice = MockDeviceOrientationProvider()
    mockDevice.orientation = orientation
    return Notification(name: Notification.Name(rawValue: "orientation_test"), object: mockDevice, userInfo: nil)
  }


  func testOrientationUpdateMustBeOnCaptureSessionQueue() {
    let queueExpectation = expectation(description: "Orientation update must happen on the capture session queue")

    let captureSessionQueue = DispatchQueue(label: "test")
    SwiftQueueUtils.setSpecific(.captureSession, for: captureSessionQueue)

    let cam = MockFLTCam()
    let camera = CameraTestUtils.createCameraPlugin()
    camera.camera = cam
    cam.setDeviceOrientationStub = { _ in
      if SwiftQueueUtils.isOnQueue(specific: .captureSession) {
        queueExpectation.fulfill()
      }
    }

    camera.orientationChanged(createMockNotification(for: .landscapeLeft) as NSNotification)

    waitForExpectations(timeout: 1)
  }

}
