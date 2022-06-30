//
//  QueueUtilsTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/30/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
@testable import camera_avfoundation
import AVFoundation
import XCTest
import Flutter

final class QueueUtilsTests: XCTestCase {

  func testEnsureToRunOnMainQueue_ShouldStayOnMainQueueIfCalledFromMainQueue() {

    let expectation = expectation(description: "Block must be run on the main queue.")

    SwiftQueueUtils.ensureToRunOnMainQueue {
      if Thread.isMainThread {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)

  }

  func testEnsureToRunOnMainQueue_ShouldDispatchToMainQueueIfCalledFromBackgroundQueue() {

    let expectation = expectation(description: "Block must be run on the main queue.")

    DispatchQueue.global().async {
      SwiftQueueUtils.ensureToRunOnMainQueue {
        if Thread.isMainThread {
          expectation.fulfill()
        }
      }
    }
    waitForExpectations(timeout: 1)
  }
}
