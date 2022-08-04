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

  private let channel: MethodChannel
  private let shortcutService: ShortcutItemsService

  init(
    channel: MethodChannel,
    shortcutService: ShortcutItemsService = DefaultShortcutService())
  {
    self.channel = channel
    self.shortcutService = shortcutService
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setShortcutItems":
      let items = call.arguments as? [[String:Any]] ?? []
      shortcutService.setShortcutItems(items)
      result(nil)
    case "clearShortcutItems":
      shortcutService.setShortcutItems([])
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
      self.shortcutService.activeShortcutType = shortcutItem.type
      return false
    }
    return true
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    if let shortcutType = shortcutService.activeShortcutType {
      handleShortcut(shortcutType)
      shortcutService.activeShortcutType = nil
    }
  }

  private func handleShortcut(_ shortcut: String) {
    channel.invokeMethod("launch", arguments: shortcut)
  }

}
