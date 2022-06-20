//
//  ThreadSafeFlutterResult.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter

public final class ThreadSafeFlutterResult: NSObject {
  private let result: FlutterResult

  @objc
  public init(result: @escaping FlutterResult) {
    self.result = result
  }

  @objc
  public func sendSuccess() {
    send(nil)
  }

  @objc
  public func sendSuccess(withData data: Any) {
    send(data)
  }

  @objc
  public func sendError(_ error: NSError) {
    sendError(code: "Error \(error.code)", message: error.localizedDescription, details: error.domain)
  }

  @objc
  public func sendError(code: String, message: String?, details: Any?) {
    let flutterError = FlutterError(code: code, message: message, details: details)
    send(flutterError)
  }

  @objc
  public func sendFlutterError(_ flutterError: FlutterError) {
    send(flutterError)
  }

  @objc
  public func sendNotImplemented() {
    send(FlutterMethodNotImplemented)
  }

  @objc
  public func send(_ result: Any?) {
    SwiftQueueUtils.ensureToRunOnMainQueue {
      self.result(result)
    }
  }

}
