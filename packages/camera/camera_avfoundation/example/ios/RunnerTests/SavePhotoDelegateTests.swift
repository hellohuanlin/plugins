//
//  SavePhotoDelegateTests.swift
//  RunnerTests
//
//  Created by Huan Lin on 6/20/22.
//  Copyright © 2022 The Flutter Authors. All rights reserved.
//

import AVFoundation
import Flutter
import XCTest
@testable import camera_avfoundation

final class SavePhotoDelegateTests: XCTestCase {
  func testHandlePhotoCaptureResult_mustCompleteWithErrorIfFailedToCapture() {
    let completionExpectation = expectation(description: "Must complete with error if failed to capture photo.")
    let captureError = NSError(domain: "test", code: 0)
    let ioQueue = DispatchQueue(label: "test")
    let delegate = SavePhotoDelegate(path: "test", ioQueue: ioQueue) { path, error in
      XCTAssertEqual(captureError, error as? NSError)
      XCTAssertNil(path)
      completionExpectation.fulfill()
    }
    delegate.test_handlePhotoCaptureResultWithError(captureError, photoDataProvider: { nil })

    waitForExpectations(timeout: 1)
  }

  func testHandlePhotoCaptureResult_mustCompleteWithErrorIfFailedToWrite() {
    let completionExpectation = expectation(description: "Must complete with error if failed to write file.")
    let ioQueue = DispatchQueue(label: "test")
    let ioError = NSError(domain: "IOError", code: 0)
    let delegate = SavePhotoDelegate(path: "test", ioQueue: ioQueue) { path, error in
      XCTAssertEqual(ioError, error as? NSError)
      XCTAssertNil(path)
      completionExpectation.fulfill()
    }

    delegate.test_handlePhotoCaptureResultWithError(nil) {
      class MockData: DataWritable {
        let ioError: NSError
        init(ioError: NSError) {
          self.ioError = ioError
        }
        func write(to url: URL, options writeOptionsMask: NSData.WritingOptions) throws {
          throw ioError
        }
      }
      return MockData(ioError: ioError)
    }
    waitForExpectations(timeout: 1)
  }

  func testHandlePhotoCaptureResult_mustCompleteWithFilePathIfSuccessToWrite() {
    let completionExpectation = expectation(description: "Must complete with error if failed to write file.")
    let ioQueue = DispatchQueue(label: "test")
    let filePath = "test"
    let delegate = SavePhotoDelegate(path: filePath, ioQueue: ioQueue) { path, error in
      XCTAssertNil(error)
      XCTAssertEqual(path, filePath)
      completionExpectation.fulfill()
    }
    
    class MockData: DataWritable {
      func write(to url: URL, options writeOptionsMask: NSData.WritingOptions) throws {
        // empty
      }
    }

    delegate.test_handlePhotoCaptureResultWithError(nil) {
      return MockData()
    }
    waitForExpectations(timeout: 1)
  }

  func testHandlePhotoCaptureResult_bothProvideDataAndSaveFileMustRunOnIOQueue() {

    let dataProviderQueueExpectation = expectation(description: "Data provider must run on io queue.")
    let writeFileQueueExpectation = expectation(description: "File writing must run on io queue")
    let completionExpectation = expectation(description: "Must complete with file path if success to write file.")

    let ioQueue = DispatchQueue(label: "test")

    SwiftQueueUtils.setSpecific(.io, for: ioQueue)

    let filePath = "test"
    let delegate = SavePhotoDelegate(path: filePath, ioQueue: ioQueue) { _, _ in
      completionExpectation.fulfill()
    }

    class MockData: DataWritable {
      private let writeFileQueueExpectation: XCTestExpectation
      init(writeFileQueueExpectation: XCTestExpectation) {
        self.writeFileQueueExpectation = writeFileQueueExpectation
      }

      func write(to url: URL, options writeOptionsMask: NSData.WritingOptions) throws {
        if SwiftQueueUtils.isOnQueue(specific: .io) {
          writeFileQueueExpectation.fulfill()
        }
      }
    }

    delegate.test_handlePhotoCaptureResultWithError(nil) {
      if SwiftQueueUtils.isOnQueue(specific: .io) {
        dataProviderQueueExpectation.fulfill()
      }
      return MockData(writeFileQueueExpectation: writeFileQueueExpectation)
    }

    waitForExpectations(timeout: 1)
  }

}
