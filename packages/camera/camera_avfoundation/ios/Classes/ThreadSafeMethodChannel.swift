//
//  ThreadSafeMethodChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

@objc
public protocol MethodChannel {
  func invokeMethod(_ method: String, arguments: Any?)
}

extension FlutterMethodChannel: MethodChannel {}

public final class ThreadSafeMethodChannel: NSObject {
  private let channel: MethodChannel

  @objc
  public init(channel: MethodChannel) {
    self.channel = channel
  }

  @objc
  public func invokeMethod(_ method: String, arguments: Any?) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.channel.invokeMethod(method, arguments: arguments)
    }
  }
}
