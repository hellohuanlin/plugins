//
//  ThreadSafeEventChannelTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import XCTest
import camera_avfoundation

final class ThreadSafeEventChannelTests: XCTestCase {


  func testSetStreamHandler_shouldStayOnMainThreadIfCalledFromMainThread() {

    let mainThreadExpectation = expectation(description: "setStreamHandler must be called on the main thread")
    let completionExpectation = expectation(description: "setStreamHandler's completion block must be called on the main thread")
    let mock = MockEventChannel()
    mock.setStreamHandlerStub = { _ in
      if Thread.isMainThread {
        mainThreadExpectation.fulfill()
      }
    }

    let threadSafeEventChannel = ThreadSafeEventChannel(channel: mock)
    threadSafeEventChannel.setStreamHandler(nil) {
      if Thread.isMainThread {
        completionExpectation.fulfill()
      }
    }
    waitForExpectations(timeout: 1)
  }

  func testSetStreamHandler_shouldDispatchToMainThreadIfCalledFromBackgroundThread() {

    let mainThreadExpectation = expectation(description: "setStreamHandler must be called on the main thread")
    let completionExpectation = expectation(description: "setStreamHandler's completion block must be called on the main thread")
    let mock = MockEventChannel()
    mock.setStreamHandlerStub = { _ in
      if Thread.isMainThread {
        mainThreadExpectation.fulfill()
      }
    }

    let threadSafeEventChannel = ThreadSafeEventChannel(channel: mock)

    DispatchQueue.global().async {
      threadSafeEventChannel.setStreamHandler(nil) {
        if Thread.isMainThread {
          completionExpectation.fulfill()
        }
      }
    }

    waitForExpectations(timeout: 1)
  }

}
