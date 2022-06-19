//
//  ThreadSafeTextureRegistry.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/18/22.
//

import Foundation
import Flutter

final class ThreadSafeTextureRegistry {
  private let registry: FlutterTextureRegistry

  init(registry: FlutterTextureRegistry) {
    self.registry = registry
  }

  func register(
    _ texture: FlutterTexture,
    completion: @escaping (Int64) -> Void)
  {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      completion(self.registry.register(texture))
    }
  }

  func textureFrameAvailable(_ textureId: Int64) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.registry.textureFrameAvailable(textureId)
    }
  }

  func unregisterTexture(_ textureId: Int64) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.registry.unregisterTexture(textureId)
    }
  }
  
}
