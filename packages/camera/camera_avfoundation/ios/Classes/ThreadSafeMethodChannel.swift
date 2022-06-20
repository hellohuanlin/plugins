//
//  ThreadSafeMethodChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

public final class ThreadSafeMethodChannel: NSObject {
  private let channel: FlutterMethodChannel

  @objc
  public init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  @objc
  public func invokeMethod(_ method: String, arguments: Any?) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.channel.invokeMethod(method, arguments: arguments)
    }
  }
}
