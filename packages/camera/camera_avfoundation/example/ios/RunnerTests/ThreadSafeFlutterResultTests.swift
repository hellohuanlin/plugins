//
//  ThreadSafeFlutterResultTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/19/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import XCTest
import camera_avfoundation

final class ThreadSafeFlutterResultTests: XCTestCase {

  func testSendSuccess_ShouldCallResultOnMainThreadIfCalledFromMainThread() {

    let mainThreadExpectation = expectation(description: "Flutter result should be called on main thread")
    let wrapper = ThreadSafeFlutterResult { _ in
      if Thread.isMainThread {
        mainThreadExpectation.fulfill()
      }
    }
    wrapper.sendSuccess()
    waitForExpectations(timeout: 1)
  }

  func testSendSuccess_ShouldCallResultOnMainThreadIfCalledFromNonMainThread() {

    let mainThreadExpectation = expectation(description: "Flutter result should be called on main thread")
    let wrapper = ThreadSafeFlutterResult { _ in
      if Thread.isMainThread {
        mainThreadExpectation.fulfill()
      }
    }

    DispatchQueue.global().async {
      wrapper.sendSuccess()
    }

    waitForExpectations(timeout: 1)
  }

  func testSendNotImplemented_ShouldSendNotImplementedToFlutterResult() {
    let mainThreadExpectation = expectation(description: "Flutter result should be called on main thread")
    let wrapper = ThreadSafeFlutterResult { _ in
      if Thread.isMainThread {
        mainThreadExpectation.fulfill()
      }
    }

    DispatchQueue.global().async {
      wrapper.sendNotImplemented()
    }

    waitForExpectations(timeout: 1)
  }

}
