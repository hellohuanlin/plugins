//
//  CameraFocusTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import AVFoundation
import Flutter
import XCTest
@testable import camera_avfoundation

final class CameraFocusTests: XCTestCase {

  func testAutoFocusWithContinuousModeSupported_ShouldSetContinuousAutoFocus() {

    let mockDevice = MockCaptureDevice()
    mockDevice.isFocusModeSupportedStub = { mode in
      return mode == .continuousAutoFocus
    }

    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"))

    try? cam.applyFocusMode(.auto, on: mockDevice)
    XCTAssertEqual(mockDevice.focusMode, .continuousAutoFocus)
  }

  func testAutoFocusWithContinuousModeNotSupported_ShouldSetAutoFocus() {

    let mockDevice = MockCaptureDevice()
    mockDevice.isFocusModeSupportedStub = { mode in
      return mode == .autoFocus
    }

    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"))

    try? cam.applyFocusMode(.auto, on: mockDevice)
    XCTAssertEqual(mockDevice.focusMode, .autoFocus)
  }

  func testAutoFocus_ShouldSetLocked() {
    let mockDevice = MockCaptureDevice()
    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"))

    try? cam.applyFocusMode(.locked, on: mockDevice)
    XCTAssertEqual(mockDevice.focusMode, .locked)
  }

  func testSetFocusPointWithResult_SetsFocusPointOfInterest() {

    let mockDevice = MockCaptureDevice()
    MockCaptureDevice.deviceStub = { _ in mockDevice }

    mockDevice.isFocusPointOfInterestSupported = true
    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"), captureDeviceType: MockCaptureDevice.self)
    let mockOrientationProvider = MockDeviceOrientationProvider()
    mockOrientationProvider.orientation = .landscapeLeft
    try? cam.setFocusPoint(with: MockThreadSafeFlutterResult(), x: 1, y: 1, deviceOrientationProvider: mockOrientationProvider)
    XCTAssertEqual(mockDevice.focusPointOfInterest, CGPoint(x: 1, y: 1))
  }


}
