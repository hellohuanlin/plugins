//
//  CameraPermissionUtils.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/19/22.
//

import Foundation
import Flutter
import AVFoundation

typealias CameraPermissionRequestCompletionHandler = (FlutterError?) -> Void

protocol PermissionService {
  static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus
  static func requestAccess(for mediaType: AVMediaType,
                            completionHandler handler: @escaping (Bool) -> Void)
}

extension AVCaptureDevice: PermissionService {}

enum CameraPermissionUtils {

  static func requestCameraPermissionWithPermissionService(
    permissionService: PermissionService.Type = AVCaptureDevice.self,
    completionHandler handler: @escaping CameraPermissionRequestCompletionHandler)
  {
    requestPermission(forAudio: false, permissionService: permissionService, handler: handler)
  }

  static func requestAudioPermissionWithCompletionHandler(
    permissionService: PermissionService.Type = AVCaptureDevice.self,
    completionHandler handler: @escaping CameraPermissionRequestCompletionHandler)
  {
    requestPermission(forAudio: true, permissionService: permissionService, handler: handler)
  }

  private static func requestPermission(
    forAudio: Bool,
    permissionService: PermissionService.Type,
    handler: @escaping CameraPermissionRequestCompletionHandler)
  {

    let mediaType: AVMediaType = forAudio ? .audio : .video

    switch permissionService.authorizationStatus(for: mediaType) {
    case .authorized:
      handler(nil)
    case .denied:

      let error: FlutterError
      if forAudio {
        error = FlutterError(
          code: "AudioAccessDeniedWithoutPrompt",
          message: "User has previously denied the audio access request. Go to Settings to enable audio access.",
          details: nil)
      } else {
        error = FlutterError(
          code: "CameraAccessDeniedWithoutPrompt",
          message: "User has previously denied the camera access request. Go to Settings to enable camera access.",
          details: nil)
      }

      handler(error)

    case.restricted:

      let error: FlutterError
      if forAudio {
        error = FlutterError(
          code: "AudioAccessRestricted",
          message: "Audio access is restricted.",
          details: nil)
      } else {
        error = FlutterError(
          code: "CameraAccessRestricted",
          message: "Camera access is restricted.",
          details: nil)
      }
      handler(error)
    case .notDetermined:
      permissionService.requestAccess(for: mediaType) { granted in
        // handler can be invoked on an arbitrary dispatch queue.
        if granted {
          handler(nil)
        } else {
          let error: FlutterError
          if forAudio {
            error = FlutterError(
              code: "AudioAccessDenied",
              message: "User denied the audio access request.",
              details: nil)
          } else {
            error = FlutterError(
              code: "CameraAccessDenied",
              message: "User denied the camera access request.",
              details: nil)
          }
          handler(error)
        }
      }
    @unknown default:
      fatalError("Unknown case. Won't happen")
    }
  }
}



