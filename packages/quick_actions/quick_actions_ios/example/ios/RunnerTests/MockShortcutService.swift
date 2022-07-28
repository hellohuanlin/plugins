//
//  MockShortcutService.swift
//  RunnerTests
//
//  Created by Huan Lin on 7/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

@testable import quick_actions_ios

final class MockShortcutService: ShortcutItemsService {
  var activeShortcutType: String? = nil

  var setShortcutItemsStub: (([[String: Any]]) -> Void)?

  func setShortcutItems(_ items: [[String : Any]]) {
    setShortcutItemsStub?(items)
  }
}

final class MockTypedShortcutService: TypedShortcutService {
  var shortcutItems: [UIApplicationShortcutItem]? = nil 
}
