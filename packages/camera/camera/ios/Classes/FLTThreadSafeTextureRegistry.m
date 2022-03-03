// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTThreadSafeTextureRegistry.h"
#import "QueueUtils.h"

@interface FLTThreadSafeTextureRegistry ()
@property(nonatomic, strong) NSObject<FlutterTextureRegistry> *registry;
@end

@implementation FLTThreadSafeTextureRegistry

- (instancetype)initWithTextureRegistry:(NSObject<FlutterTextureRegistry> *)registry {
  self = [super init];
  if (self) {
    _registry = registry;
  }
  return self;
}

- (void)registerTexture:(NSObject<FlutterTexture> *)texture
             completion:(void (^)(int64_t))completion {
  dispatch_block_t block = ^{
    completion([self.registry registerTexture:texture]);
  };
  if (NSThread.isMainThread) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

- (void)textureFrameAvailable:(int64_t)textureId {
  if (NSThread.isMainThread) {
    [self.registry textureFrameAvailable:textureId];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.registry textureFrameAvailable:textureId];
    });
  }
}

- (void)unregisterTexture:(int64_t)textureId {
  if (NSThread.isMainThread) {
    [self.registry unregisterTexture:textureId];
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.registry unregisterTexture:textureId];
    });
  }
}

@end
