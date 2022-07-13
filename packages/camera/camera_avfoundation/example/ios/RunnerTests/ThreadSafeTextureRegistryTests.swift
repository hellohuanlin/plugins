//
//  ThreadSafeTextureRegistryTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/18/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
import XCTest
@testable import camera_avfoundation;

final class ThreadSafeTextureRegistryTests: XCTestCase {


  func testShouldStayOnMainThreadIfCalledFromMainThread() {

    let registerTextureExpectation = expectation(description: "registerTexture must be called on the main thread");
    let unregisterTextureExpectation = expectation(description:"unregisterTexture must be called on the main thread");
    let textureFrameAvailableExpectation = expectation(description:"textureFrameAvailable must be called on the main thread");
    let registerTextureCompletionExpectation = expectation(description: "registerTexture's completion block must be called on the main thread");

    let mockRegistry = MockTextureRegistry()
    mockRegistry.registerStub = { _ in
      if Thread.isMainThread {
        registerTextureExpectation.fulfill()
      }
      return 0
    }
    mockRegistry.unregisterTextureStub = { _ in
      if Thread.isMainThread {
        unregisterTextureExpectation.fulfill()
      }
    }
    mockRegistry.textureFrameAvailableStub = { _ in
      if Thread.isMainThread {
        textureFrameAvailableExpectation.fulfill()
      }
    }

    let registry = ThreadSafeTextureRegistry(registry: mockRegistry)
    let mockTexture = MockTexture()
    registry.register(mockTexture) { _ in
      if Thread.isMainThread {
        registerTextureCompletionExpectation.fulfill()
      }
    }

    registry.textureFrameAvailable(0)
    registry.unregisterTexture(0)

    waitForExpectations(timeout: 1)
  }

  func testShouldDispatchToMainThreadIfCalledFromBackgroundThread() {


    let registerTextureExpectation = expectation(description: "registerTexture must be called on the main thread");
    let unregisterTextureExpectation = expectation(description:"unregisterTexture must be called on the main thread");
    let textureFrameAvailableExpectation = expectation(description:"textureFrameAvailable must be called on the main thread");
    let registerTextureCompletionExpectation = expectation(description: "registerTexture's completion block must be called on the main thread");

    let mockRegistry = MockTextureRegistry()
    mockRegistry.registerStub = { _ in
      if Thread.isMainThread {
        registerTextureExpectation.fulfill()
      }
      return 0
    }
    mockRegistry.unregisterTextureStub = { _ in
      if Thread.isMainThread {
        unregisterTextureExpectation.fulfill()
      }
    }
    mockRegistry.textureFrameAvailableStub = { _ in
      if Thread.isMainThread {
        textureFrameAvailableExpectation.fulfill()
      }
    }
    let registry = ThreadSafeTextureRegistry(registry: mockRegistry)
    let mockTexture = MockTexture()
    DispatchQueue.global().async {
      registry.register(mockTexture) { _ in
        if Thread.isMainThread {
          registerTextureCompletionExpectation.fulfill()
        }
      }
      registry.textureFrameAvailable(0)
      registry.unregisterTexture(0)
    }

    waitForExpectations(timeout: 1)
  }
}
