//
//  RunnerTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 7/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import XCTest
import Flutter
@testable import quick_actions_ios

final class RunnerTests: XCTestCase {

  private let testSerializedItem = [
    "type": "Search",
    "localizedTitle": "Search the thing",
  ]

  private let testItem = UIApplicationShortcutItem(
    type: "Search",
    localizedTitle: "Search the thing",
    localizedSubtitle: nil,
    icon: nil,
    userInfo: nil)

  func testHandleMethods_setShortcutItems() {
    let mockChannel = MockMethodChannel()
    let mockShortcutService = MockShortcutService()
    mockShortcutService.setShortcutItemsStub = { items in
      XCTAssertEqual(items as? [[String: String]], [self.testSerializedItem])
    }

    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)

    let setShortcutItemsCall = FlutterMethodCall(
      methodName: "setShortcutItems",
      arguments: [testSerializedItem])

    let expectation = expectation(description: "Reuslt must be called")
    plugin.handle(setShortcutItemsCall) { result in
      XCTAssertNil(result, "Must complete with nil result")
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testHandleMethods_setShortcutItems_invalidArgument() {
    let mockChannel = MockMethodChannel()
    let mockShortcutService = MockShortcutService()
    let shortcutServiceExpectation = expectation(description: "setShortcutItems must be called")
    mockShortcutService.setShortcutItemsStub = { items in
      shortcutServiceExpectation.fulfill()
      XCTAssertEqual(items as? [[String: String]], [])
    }

    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)

    let setShortcutItemsCall = FlutterMethodCall(
      methodName: "setShortcutItems",
      arguments: "an invalid argument")

    let resultExpectation = expectation(description: "Reuslt must be called")
    plugin.handle(setShortcutItemsCall) { result in
      XCTAssertNil(result, "Must complete with nil result")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testHandleMethods_clearShortcutItems() {

    let mockChannel = MockMethodChannel()
    let mockShortcutService = MockShortcutService()
    mockShortcutService.setShortcutItemsStub = { items in
      XCTAssertTrue(items.isEmpty, "The shortcut items must be cleared.")
    }


    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)

    let clearShortcutItemsCall = FlutterMethodCall(
      methodName: "clearShortcutItems",
      arguments: nil)


    let expectation = expectation(description: "Reuslt must be called")
    plugin.handle(clearShortcutItemsCall) { result in
      XCTAssertNil(result, "Must complete with nil result")
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)

  }

  func testHandleMethods_nonExist() {

    let mockChannel = MockMethodChannel()
    let mockShortcutService = MockShortcutService()

    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)

    let nonExistCall = FlutterMethodCall(methodName: "NonExist", arguments: nil)

    let expectation = expectation(description: "Reuslt must be called")
    plugin.handle(nonExistCall) { result in
      XCTAssertEqual(result as? NSObject, FlutterMethodNotImplemented)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testHandleMethod_getLaunchAction() {
    let plugin = QuickActionsPlugin(channel: MockMethodChannel(), shortcutService: MockShortcutService())
    let getLaunchActionCall = FlutterMethodCall(methodName: "getLaunchAction", arguments: nil)

    let expectation = expectation(description: "Reuslt must be called")
    plugin.handle(getLaunchActionCall) { result in
      XCTAssertNil(result, "Must complete with nil for getLaunchAction")
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testApplicationPerformAction() {

    let mockChannel = MockMethodChannel()
    let expectation = expectation(description: "Channel must be called.")
    mockChannel.invokeMethodStub = { method, arguments in
      XCTAssertEqual(method, "launch")
      XCTAssertEqual(arguments as? String, self.testItem.type)
      expectation.fulfill()
    }

    let mockShortcutService = MockShortcutService()
    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)


    let result = plugin.application(
      UIApplication.shared,
      performActionFor: testItem,
      completionHandler: { _ in })

    XCTAssertTrue(result, "Must return true from performAction")
    waitForExpectations(timeout: 1)
  }

  func testApplicationDidFinishLaunchingWithOptions() {
    let mockChannel = MockMethodChannel()
    let mockShortcutService = MockShortcutService()

    let plugin = QuickActionsPlugin(
      channel: mockChannel,
      shortcutService: mockShortcutService)

    let options = [UIApplication.LaunchOptionsKey.shortcutItem: testItem]

    XCTAssertFalse(
      plugin.application(
        UIApplication.shared,
        didFinishLaunchingWithOptions: options),
      "Must return false if item is provided")

    XCTAssertTrue(
      plugin.application(
        UIApplication.shared,
        didFinishLaunchingWithOptions: [:]),
      "Must return true if no item is provided"
    )
  }

  func testApplicationDidBecomeActive() {
    let mockShortcutService = MockShortcutService()
    mockShortcutService.activeShortcutType = "Search"
    let mockChannel = MockMethodChannel()

    let plugin = QuickActionsPlugin(channel: mockChannel, shortcutService: mockShortcutService)

    let expectation = expectation(description: "Channel must be called")

    mockChannel.invokeMethodStub = { method, arguments in
      XCTAssertEqual(method, "launch")
      XCTAssertEqual(arguments as? String, "Search")
      expectation.fulfill()
    }
    plugin.applicationDidBecomeActive(UIApplication.shared)

    XCTAssertNil(mockShortcutService.activeShortcutType, "Must clear out active shortcut type")

    waitForExpectations(timeout: 1)
  }

}
