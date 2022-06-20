//
//  CameraPermissionUtilsTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/20/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import Foundation
@testable import camera_avfoundation
import AVFoundation
import XCTest

final class CameraPermissionUtilsTests: XCTestCase {

  func testRequestCameraPermission_completeWithoutErrorIfPreviouslyAuthorized() {
    let expectation = expectation(description: "Must copmlete without error if camera access was previously authorized.")

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in
      return .authorized
    }

    CameraPermissionUtils.requestCameraPermissionWithPermissionService(permissionService: MockPermissionService.self) { error in
      if error == nil {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)
  }


  func testRequestCameraPermission_completeWithErrorIfPreviouslyDenied() {

    let expectation = expectation(description: "Must complete with error if camera access was previously denied.")
    let expectedError = FlutterError(code: "CameraAccessDeniedWithoutPrompt", message: "User has previously denied the camera access request. Go to Settings to enable camera access.", details: nil)

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in
      return .denied
    }

    CameraPermissionUtils.requestCameraPermissionWithPermissionService(permissionService: MockPermissionService.self) { error in
      if let error = error, error.isEqual(expectedError) {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)

  }

  func testRequestCameraPermission_completeWithErrorIfRestricted() {

    let expectation = expectation(description: "Must complete with error if camera access was previously denied.")
    let expectedError = FlutterError(code: "CameraAccessRestricted", message: "Camera access is restricted.", details: nil)

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in
      return .restricted
    }

    CameraPermissionUtils.requestCameraPermissionWithPermissionService(permissionService: MockPermissionService.self) { error in
      if let error = error, error.isEqual(expectedError) {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)

  }

  func testRequestCameraPermission_completeWithoutErrorIfUserGrantAccess() {
    let expectation = expectation(description: "Must complete without error if user choose to grant access")

    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in
      return .notDetermined
    }

    MockPermissionService.requestAccessForMediaTypeStub = { _, handler in
      handler(true)
    }

    CameraPermissionUtils.requestAudioPermissionWithCompletionHandler(permissionService: MockPermissionService.self) { error in
      if error == nil {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)


  }

  func testRequestCameraPermission_completeWithErrorIfUserDenyAccess() {
    let expectation = expectation(description: "Must complete with error if user choose to deny access")
    let expectedError = FlutterError(code: "CameraAccessDenied", message: "User denied the camera access request.", details: nil)


    MockPermissionService.authorizationStatusForMediaTypeStub = { _ in
      return .notDetermined
    }

    MockPermissionService.requestAccessForMediaTypeStub = { _, handler in
      handler(false)
    }

    CameraPermissionUtils.requestCameraPermissionWithPermissionService(permissionService: MockPermissionService.self) { error in
      if let error = error, error.isEqual(expectedError) {
        expectation.fulfill()
      }
    }

    waitForExpectations(timeout: 1)
  }

  


}

