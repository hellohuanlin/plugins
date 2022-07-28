//
//  ShortcutItemsService.swift
//  quick_actions_ios
//
//  Created by Huan Lin on 7/27/22.
//

import Foundation

protocol ShortcutItemsService: AnyObject {
  var activeShortcutType: String? { get set }
  func setShortcutItems(_ items: [[String:Any]])
}

protocol TypedShortcutService: AnyObject {
  var shortcutItems: [UIApplicationShortcutItem]? { get set }
}

extension UIApplication: TypedShortcutService {}

final class DefaultShortcutService: ShortcutItemsService {

  private let service: TypedShortcutService
  init(service: TypedShortcutService = UIApplication.shared) {
    self.service = service
  }

  var activeShortcutType: String? = nil

  func setShortcutItems(_ items: [[String : Any]]) {
    let items = items.compactMap { deserializeShortcutItem(with: $0) }
    service.shortcutItems = items
  }

  private func deserializeShortcutItem(with serialized: [String: Any]) -> UIApplicationShortcutItem? {
    // type and title are required.
    guard
      let type = serialized["type"] as? String,
      let localizedTitle = serialized["localizedTitle"] as? String
    else { return nil }

    let icon = (serialized["icon"] as? String)
      .map { UIApplicationShortcutIcon(templateImageName: $0) }

    return UIApplicationShortcutItem(
      type: type,
      localizedTitle: localizedTitle,
      localizedSubtitle: nil,
      icon: icon,
      userInfo: nil)
  }

}

