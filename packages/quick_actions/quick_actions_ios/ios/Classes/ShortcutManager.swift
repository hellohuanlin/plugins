//
//  ShortcutManager.swift
//  quick_actions_ios
//
//  Created by Huan Lin on 7/27/22.
//

import Foundation

protocol ShortcutManager {
  var shortcutType: String? { get set }
}

final class DefaultShortcutManager {
  var shortcutType: String? = nil
}
