//
//  DefaultShortcutServiceTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 7/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import XCTest
@testable import quick_actions_ios

final class DefaultShortcutServiceTests: XCTest {

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

  func testSetShortcutItems() {

    let mockService = MockTypedShortcutService()
    let service = DefaultShortcutService(service: mockService)

    service.setShortcutItems([testSerializedItem])

    XCTAssertEqual(mockService.shortcutItems, [testItem], "Incorrect serlialization of item")
  }

  func testSetShortcutItemsWithError() {
    let mockService = MockTypedShortcutService()
    let service = DefaultShortcutService(service: mockService)

    // missing localized title
    service.setShortcutItems([["type": "Search"]])

    XCTAssert(mockService.shortcutItems?.isEmpty ?? true, "Should not set invalid item")

  }




}
