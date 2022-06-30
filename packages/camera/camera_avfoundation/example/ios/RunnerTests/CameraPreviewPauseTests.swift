//
//  CameraPreviewPauseTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import AVFoundation
import XCTest
@testable import camera_avfoundation;

final class CameraPreviewPauseTests: XCTestCase {

  func testPausePreviewWithResult_shouldPausePreview() {
    let mock = MockThreadSafeFlutterResult()
    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"))
    cam.pausePreview(with: mock)
    XCTAssertTrue(cam.isPreviewPaused)
  }

  func testResumePreviewWithResult_shouldResumePreview() {
    let mock = MockThreadSafeFlutterResult()
    let cam = CameraTestUtils.createCam(on: DispatchQueue(label: "test"))
    cam.resumePreview(with: mock)
    XCTAssertFalse(cam.isPreviewPaused)
  }

}
