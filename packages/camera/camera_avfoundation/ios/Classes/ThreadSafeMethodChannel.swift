//
//  ThreadSafeMethodChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

public protocol MethodChannel {
  func invokeMethod(_ method: String, arguments: Any?)
}

extension FlutterMethodChannel: MethodChannel {}

public protocol ThreadSafeMethodChannelProtocol {
  func invokeMethod(_ method: String, arguments: Any?)
}

public protocol ThreadSafeMethodChannelFactoryProtocol {
  func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> ThreadSafeMethodChannelProtocol
}

extension ThreadSafeMethodChannel {
  public final class Factory: ThreadSafeMethodChannelFactoryProtocol {
    public func methodChannel(name: String, binaryMessenger: FlutterBinaryMessenger) -> ThreadSafeMethodChannelProtocol {
      let channel = FlutterMethodChannel(name: name, binaryMessenger: binaryMessenger)
      return ThreadSafeMethodChannel(channel: channel)
    }
  }
}

public final class ThreadSafeMethodChannel: NSObject, ThreadSafeMethodChannelProtocol {

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
