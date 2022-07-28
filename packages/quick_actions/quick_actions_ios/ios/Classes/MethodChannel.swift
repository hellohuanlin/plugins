//
//  MethodChannel.swift
//  quick_actions_ios
//
//  Created by Huan Lin on 7/27/22.
//

import Flutter

protocol MethodChannel {
  func invokeMethod(_ method: String, arguments: Any?)
}

extension FlutterMethodChannel: MethodChannel {}


