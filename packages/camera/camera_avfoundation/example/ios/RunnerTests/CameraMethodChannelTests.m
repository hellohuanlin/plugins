// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import XCTest;
@import AVFoundation;
@import Flutter;
#import <OCMock/OCMock.h>
#import "MockFLTThreadSafeFlutterResult.h"
@interface CameraMethodChannelTests : XCTestCase
@end

@implementation CameraMethodChannelTests

- (void)testCreate_ShouldCallResultOnMainThread {


  SwiftCameraPlugin *camera = [[SwiftCameraPlugin alloc] initWithRegistry:OCMProtocolMock(@protocol(FlutterTextureRegistry)) messenger:OCMProtocolMock(@protocol(FlutterBinaryMessenger))];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Result finished"];

  // Set up mocks for initWithCameraName method
  id avCaptureDeviceInputMock = OCMClassMock([AVCaptureDeviceInput class]);
  OCMStub([avCaptureDeviceInputMock deviceInputWithDevice:[OCMArg any] error:[OCMArg anyObjectRef]])
      .andReturn([AVCaptureInput alloc]);

  id avCaptureSessionMock = OCMClassMock([AVCaptureSession class]);
  OCMStub([avCaptureSessionMock alloc]).andReturn(avCaptureSessionMock);
  OCMStub([avCaptureSessionMock canSetSessionPreset:[OCMArg any]]).andReturn(YES);


  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:OCMOCK_ANY])
      .andReturn(AVAuthorizationStatusAuthorized);

  // Set up method call
  FlutterMethodCall *call = [FlutterMethodCall
      methodCallWithMethodName:@"create"
                     arguments:@{@"resolutionPreset" : @"medium", @"enableAudio" : @(1)}];

  __block id receivedResult = nil;
  [camera handleMethodCall:call result:^(id  _Nullable result) {
    receivedResult = result;
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];

  // Verify the result
  NSDictionary *dictionaryResult = (NSDictionary *)receivedResult;
  XCTAssertNotNil(dictionaryResult);
  XCTAssert([[dictionaryResult allKeys] containsObject:@"cameraId"]);
}

@end
