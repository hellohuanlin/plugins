// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;

NS_ASSUME_NONNULL_BEGIN

/// APIs exposed for unit tests.
@interface FLTQuickActionsPlugin (Test)

/// Initializes a FLTQuickActionsPlugin with the given method channel.
/// API exposed for unit tests.
/// @param channel a method channel
/// @return the initialized FLTQuickActionsPlugin
- (instancetype)initWithChannel:(FlutterMethodChannel *)channel;

@end

NS_ASSUME_NONNULL_END
