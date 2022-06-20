//
//  CameraPreviewPauseTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import XCTest
@testable import camera_avfoundation;

final class CameraPreviewPauseTests: XCTestCase {
  func testPausePreviewWithResult_shouldPausePreview() {
    let mock = MockThreadSafeFlutterResult()
    let camera = FLTCam()
    camera.pausePreview(withResult: mock)
    XCTAssertTrue(camera.isPreviewPaused)
  }

  func testResumePreviewWithResult_shouldResumePreview() {
    let mock = MockThreadSafeFlutterResult()
    let camera = FLTCam()
    camera.resumePreview(withResult: mock)
    XCTAssertFalse(camera.isPreviewPaused)
  }

}
