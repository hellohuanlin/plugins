//
//  ThreadSafeEventChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

@objc
public protocol EventChannel {
  func setStreamHandler(_ handler: (FlutterStreamHandler & NSObjectProtocol)?)
}

extension FlutterEventChannel: EventChannel {}

public final class ThreadSafeEventChannel: NSObject {
  private let channel: EventChannel
  @objc
  public init(channel: EventChannel) {
    self.channel = channel
  }

  @objc
  public func setStreamHandler(_ handler: (FlutterStreamHandler & NSObjectProtocol)?, completion: @escaping () -> Void) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.channel.setStreamHandler(handler)
      completion()
    }
  }
}
