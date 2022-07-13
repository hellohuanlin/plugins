//
//  SafePhotoDelegate.swift
//  camera_avfoundation
//
//  Created by Huan Lin on 6/20/22.
//

import Foundation
import AVFoundation

public typealias SavePhotoDelegateCompletionHandler = (String?, Error?) -> Void

@objc
public protocol DataWritable {
  @objc(writeToURL:options:error:)
  func write(to url: URL, options writeOptionsMask: NSData.WritingOptions) throws
}

extension NSData: DataWritable {}

public class SavePhotoDelegate: NSObject, CapturePhotoCaptureDelegate {

  enum SavePhotoError: Error {
    case invalidData
  }

  private let path: String
  private let ioQueue: DispatchQueue
  private let completionHandler: SavePhotoDelegateCompletionHandler

  @objc
  public init(
    path: String,
    ioQueue: DispatchQueue,
    completionHandler: @escaping SavePhotoDelegateCompletionHandler)
  {
    self.path = path
    self.ioQueue = ioQueue
    self.completionHandler = completionHandler
  }

  private func handlePhotoCaptureResultWithError(
    _ error: Error?,
    photoDataProvider: @escaping () -> DataWritable?)
  {
    if let error = error {
      completionHandler(nil, error)
      return
    }

    ioQueue.async {
      guard let data = photoDataProvider() else {
        self.completionHandler(nil, SavePhotoError.invalidData)
        return
      }
      do {
        try data.write(to: URL(fileURLWithPath: self.path), options: .atomic)
        self.completionHandler(self.path, nil)
      } catch {
        self.completionHandler(nil, error)
      }
    }
  }

  public func photoOutput(
    _ output: CapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?)
  {
    handlePhotoCaptureResultWithError(error) {
      return photo.fileDataRepresentation() as? NSData
    }
  }

}

#if DEBUG
extension SavePhotoDelegate {
  func test_handlePhotoCaptureResultWithError(
    _ error: Error?,
    photoDataProvider: @escaping () -> DataWritable?)
  {
    handlePhotoCaptureResultWithError(error, photoDataProvider: photoDataProvider)
  }

  @objc
  public var test_completionHandler: SavePhotoDelegateCompletionHandler {
    return completionHandler
  }
}
#endif
