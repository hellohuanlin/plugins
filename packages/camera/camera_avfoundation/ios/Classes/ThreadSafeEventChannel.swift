//
//  ThreadSafeEventChannel.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

public final class ThreadSafeEventChannel: NSObject {
  private let channel: FlutterEventChannel
  @objc
  public init(channel: FlutterEventChannel) {
    self.channel = channel
  }

  @objc
  public func setStreamHandler(_ handler: FlutterStreamHandler & NSObjectProtocol, completion: @escaping () -> Void) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.channel.setStreamHandler(handler)
      completion()
    }
  }
}
