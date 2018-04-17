/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScreenshotCommands.h"

#import "XCUIDevice+FBHelpers.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"

@implementation FBScreenshotCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/screenshot"].withoutSession respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"/screenshot"] respondWithTarget:self action:@selector(handleGetScreenshot:)],
    [[FBRoute GET:@"uusense/screenshot"].withoutSession respondWithTarget:self action:@selector(uu_handleGetScreenshot:)],
    [[FBRoute GET:@"uusense/screenshot"] respondWithTarget:self action:@selector(uu_handleGetScreenshot:)],
    [[FBRoute POST:@"/uusense/screenshot2"].withoutSession respondWithTarget:self action:@selector(uu_handlePostScreenshot:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleGetScreenshot:(FBRouteRequest *)request
{
  NSError *error;
  NSData *screenshotData = [[XCUIDevice sharedDevice] fb_screenshotWithError:&error];
  if (nil == screenshotData) {
    return FBResponseWithError(error);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

+ (id<FBResponsePayload>)uu_handleGetScreenshot:(FBRouteRequest *)request
{
  NSError *error;
  NSData *screenshotData = [[XCUIDevice sharedDevice] uu_screenshotWithError:&error];
  if (nil == screenshotData) {
    return FBResponseWithError(error);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

+ (id<FBResponsePayload>)uu_handlePostScreenshot:(FBRouteRequest *)request
{
  NSError *error;
  CGRect rect = CGRectMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue], (CGFloat)[request.arguments[@"width"] doubleValue], (CGFloat)[request.arguments[@"height"] doubleValue]);
  
  NSUInteger quality = (NSUInteger)[request.arguments[@"quality"] unsignedIntegerValue];
  NSData *screenshotData = [[XCUIDevice sharedDevice] uu_screenshotWithSize:rect andQuality:quality andError:&error];
  if (nil == screenshotData) {
    return FBResponseWithError(error);
  }
  NSString *screenshot = [screenshotData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  return FBResponseWithObject(screenshot);
}

@end
