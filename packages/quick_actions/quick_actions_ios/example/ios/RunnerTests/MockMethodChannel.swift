//
//  MockMethodChannel.swift
//  RunnerTests
//
//  Created by Huan Lin on 7/27/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
@testable import quick_actions_ios

final class MockMethodChannel: MethodChannel {
  var invokeMethodStub: ((_ methods: String, _ arguments: Any?) -> Void)? = nil
  func invokeMethod(_ method: String, arguments: Any?) {
    invokeMethodStub?(method, arguments)
  }
}
