//
//  SwiftQueueUtils.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/12/22.
//

import Foundation

@objc public class SwiftQueueUtils: NSObject {

  @objc public enum QueueSpecific: Int {
    case captureSession
    case io
  }

  private static let specificKey = DispatchSpecificKey<QueueSpecific>()

  @objc public static func isOnQueue(specific: QueueSpecific) -> Bool {
    return DispatchQueue.getSpecific(key: specificKey) == specific
  }

  @objc public static func setSpecific(_ specific: QueueSpecific, for queue: DispatchQueue) {
    queue.setSpecific(key: specificKey, value: specific)
  }

}
