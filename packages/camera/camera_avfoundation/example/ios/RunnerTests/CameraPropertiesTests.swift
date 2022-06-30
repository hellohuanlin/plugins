//
//  CameraPropertiesTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/30/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import Flutter
import XCTest
@testable import camera_avfoundation;

final class CameraPropertiesTests: XCTestCase {

  func testFLTGetFLTFlashModeForString() {
    XCTAssertEqual(FLTFlashMode(rawValue: "off"), .off)
    XCTAssertEqual(FLTFlashMode(rawValue: "auto"), .auto)
    XCTAssertEqual(FLTFlashMode(rawValue: "always"), .always)
    XCTAssertEqual(FLTFlashMode(rawValue: "torch"), .torch)
    XCTAssertEqual(FLTFlashMode(rawValue: "unknown"), nil)
  }

  func testFLTGetAVCaptureFlashModeForFLTFlashMode() {
    XCTAssertEqual(FLTFlashMode.off.flashMode, .off)
    XCTAssertEqual(FLTFlashMode.auto.flashMode, .auto)
    XCTAssertEqual(FLTFlashMode.always.flashMode, .on)
    XCTAssertEqual(FLTFlashMode.torch.flashMode, nil)
  }


}
