//
//  QuickActionsPlugin.swift
//  quick_actions_ios
//
//  Created by Huan Lin on 7/27/22.
//

import Flutter

public final class QuickActionsPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/quick_actions_ios",
      binaryMessenger: registrar.messenger())
    let instance = QuickActionsPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  private let channel: FlutterMethodChannel
  private var shortcutType: String? = nil

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setShortcutItems":
      setShortcutItems(call.arguments as? [[String:Any]] ?? [])
      result(nil)
    case "clearShortcutItems":
      UIApplication.shared.shortcutItems = []
      result(nil)
    case "getLaunchAction":
      result(nil)
    case _:
      result(FlutterMethodNotImplemented)
    }
  }

  public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) -> Bool {
    handleShortcut(shortcutItem.type)
    return true
  }

  public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
    let shortcutItem = launchOptions[UIApplication.LaunchOptionsKey.shortcutItem]
    if let shortcutItem = shortcutItem as? UIApplicationShortcutItem {
      self.shortcutType = shortcutItem.type
      return false
    }
    return true
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    if let shortcutType = shortcutType {
      handleShortcut(shortcutType)
      self.shortcutType = nil
    }
  }

  private func handleShortcut(_ shortcut: String) {
    channel.invokeMethod("launch", arguments: shortcut)
  }


  private func setShortcutItems(_ items: [[String:Any]]) {
    UIApplication.shared.shortcutItems = items.compactMap { deserializeShortcutItem(with:$0) }
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
