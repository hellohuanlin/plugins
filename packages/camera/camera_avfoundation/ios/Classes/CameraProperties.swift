//
//  CameraProperties.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/30/22.
//

import Foundation
import Flutter
import AVFoundation

enum FLTFlashMode: String {
  case off = "off"
  case auto = "auto"
  case always = "always"
  case torch = "torch"

  var flashMode: AVCaptureDevice.FlashMode? {
    switch self {
    case .off:
      return .off
    case .auto:
      return .auto
    case .always:
      return .on
    case .torch:
      return nil
    }
  }
}

enum FLTExposureMode: String {
  case auto = "auto"
  case locked = "locked"

  var exposureMode: AVCaptureDevice.ExposureMode {
    switch self {
    case .auto:
      return .autoExpose
    case .locked:
      return .locked
    }
  }
}

enum FLTFocusMode: String {
  case auto = "auto"
  case locked = "locked"

  var focusMode: AVCaptureDevice.FocusMode {
    switch self {
    case .auto:
      return .autoFocus
    case .locked:
      return .locked
    }
  }

}

enum FLTOrientation: String {
  case portraitDown = "portraitDown"
  case landscapeLeft = "landscapeLeft"
  case landscapeRight = "landscapeRight"
  case portraitUp = "portraitUp"


  init(orientation: UIDeviceOrientation) {
    switch orientation {
    case .portrait:
      self = .portraitUp
    case .portraitUpsideDown:
      self = .portraitDown
    case .landscapeLeft:
      self = .landscapeLeft
    case .landscapeRight:
      self = .landscapeRight
    case .faceUp, .faceDown, .unknown:
      self = .portraitUp
    @unknown default:
      self = .portraitUp
    }
  }

  var orientation: UIDeviceOrientation {
    switch self {
    case .portraitDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeLeft
    case .landscapeRight:
      return .landscapeRight
    case .portraitUp:
      return .portrait
    }
  }
}

enum FLTResolutionPreset: String {
  case veryLow = "veryLow"
  case low = "low"
  case medium = "medium"
  case high = "high"
  case veryHigh = "veryHigh"
  case ultraHigh = "ultraHigh"
  case max = "max"
}

enum FLTVideoFormat: String {
  case bgra8888 = "bgra8888"
  case yuv420 = "yuv420"

  static var defaultFormat: FLTVideoFormat = .yuv420

  var videoFormat: OSType {
    switch self {
    case .bgra8888:
      return kCVPixelFormatType_32BGRA
    case .yuv420:
      return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    }
  }
}




