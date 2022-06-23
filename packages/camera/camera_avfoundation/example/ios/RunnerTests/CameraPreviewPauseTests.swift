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

  private func createCam() -> FLTCam {
    return try! FLTCam(cameraName: "", resolutionPreset: "", enableAudio: true, orientation: .unknown, captureSession: AVCaptureSession(), captureSessionQueue: DispatchQueue(label: "test"))!
  }

  func testPausePreviewWithResult_shouldPausePreview() {
    let mock = MockThreadSafeFlutterResult()
    let camera = createCam()
    camera.pausePreview(with: mock)
    XCTAssertTrue(camera.isPreviewPaused)
  }

  func testResumePreviewWithResult_shouldResumePreview() {
    let mock = MockThreadSafeFlutterResult()
    let camera = createCam()
    camera.resumePreview(with: mock)
    XCTAssertFalse(camera.isPreviewPaused)
  }

}
