//
//  ThreadSafeMethodChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

public protocol MethodChannel {
  static func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> MethodChannel
  func invokeMethod(_ method: String, arguments: Any?)
}

extension ThreadSafeMethodChannel: MethodChannel {
  public static func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> MethodChannel {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
    return ThreadSafeMethodChannel(channel: channel)
  }
}

extension FlutterMethodChannel: MethodChannel {
  public static func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> MethodChannel {
    return FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
  }
}


public final class ThreadSafeMethodChannel: NSObject {
  private let channel: MethodChannel

  public init(channel: MethodChannel) {
    self.channel = channel
  }

  public func invokeMethod(_ method: String, arguments: Any?) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.channel.invokeMethod(method, arguments: arguments)
    }
  }
}
