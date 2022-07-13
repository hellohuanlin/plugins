//
//  ThreadSafeMethodChannelTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import XCTest
import camera_avfoundation

final class ThreadSafeMethodChannelTests: XCTestCase {

  func testInvokeMethod_shouldStayOnMainThreadIfCalledFromMainThread() {

    let expectation = expectation(description: "invokeMethod must be called on the main thread")
    let mock = MockMethodChannel()
    mock.invokeMethodStub = { _, _ in
      if Thread.isMainThread {
        expectation.fulfill()
      }
    }

    let threadSafeMethodChannel = ThreadSafeMethodChannel(channel: mock)
    threadSafeMethodChannel.invokeMethod("", arguments: nil)
    waitForExpectations(timeout: 1)
  }

  func testInvokeMethod__shouldDispatchToMainThreadIfCalledFromBackgroundThread() {

    let expectation = expectation(description: "invokeMethod must be called on the main thread")
    let mock = MockMethodChannel()
    mock.invokeMethodStub = { _, _ in
      if Thread.isMainThread {
        expectation.fulfill()
      }
    }
    let threadSafeMethodChannel = ThreadSafeMethodChannel(channel: mock)
    DispatchQueue.global().async {
      threadSafeMethodChannel.invokeMethod("", arguments: nil)
    }
    waitForExpectations(timeout: 1)

  }

}
