//
//  UUElementCommands.m
//  WebDriverAgent
//
//  Created by 刘 晓东 on 2017/6/27.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <sys/utsname.h>
#import <objc/runtime.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import "UUElementCommands.h"

#import "FBApplication.h"
#import "FBKeyboard.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBRunLoopSpinner.h"
#import "FBElementCache.h"
#import "FBErrorBuilder.h"
#import "FBSession.h"
#import "FBApplication.h"
#import "FBMacros.h"
#import "FBMathUtils.h"
#import "NSPredicate+FBFormat.h"
#import "XCUICoordinate.h"
#import "XCUIDevice.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElement+FBPickerWheel.h"
#import "XCUIElement+FBScrolling.h"
#import "XCUIElement+FBTap.h"
#import "XCUIElement+FBTyping.h"
#import "XCUIElement+FBUtilities.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "FBElementTypeTransformer.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"

#import "XCPointerEventPath.h"
#import "XCSynthesizedEventRecord.h"
#import "FBXCTestDaemonsProxy.h"
#import "XCTestManager_ManagerInterface-Protocol.h"
#import "XCUIDevice+FBHelpers.h"

#import "XCEventGenerator.h"

#import "FBXPath.h"
#import "XCUIApplication+FBHelpers.h"
#import "DeviceInfoManager.h"

#import "FBAlert.h"

#import<sys/sysctl.h>
#import<mach/mach.h>

#import <ReplayKit/ReplayKit.h>

@interface UUElementCommands ()

@end

@implementation UUElementCommands

#pragma mark - <FBCommandHandler>

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute GET:@"/applist"].withoutSession respondWithTarget:self action:@selector(handleAPPList:)],
    [[FBRoute POST:@"/uusense/tap"].withoutSession respondWithTarget:self action:@selector(uuHandleTap:)],
    [[FBRoute POST:@"/uusense/touchAndHold"].withoutSession respondWithTarget:self action:@selector(uuHandleTouchAndHoldCoordinate:)],
    [[FBRoute POST:@"/uusense/doubleTap"] respondWithTarget:self action:@selector(uuHandleDoubleTapCoordinate:)],
    [[FBRoute POST:@"/uusense/dragfromtoforduration"].withoutSession respondWithTarget:self action:@selector(uuHandleDragCoordinate:)],
    [[FBRoute GET:@"/uusense/ssid"].withoutSession respondWithTarget:self action:@selector(uuGetSSID:)],
    [[FBRoute GET:@"/uusense/source"].withoutSession respondWithTarget:self action:@selector(uuSource:)],
    [[FBRoute POST:@"/uusense/back"] respondWithTarget:self action:@selector(uuBack:)],
    [[FBRoute GET:@"/uusense/sysinfo"].withoutSession respondWithTarget:self action:@selector(uuGetSysInfo:)],
    [[FBRoute GET:@"/uusense/alert"].withoutSession respondWithTarget:self action:@selector(uuDealAlert:)]
  ];
}

#pragma mark - Commands

+ (id<FBResponsePayload>)uuDealAlert:(FBRouteRequest *)request {
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  FBAlert *alert = [FBAlert alertWithApplication:application];
  NSError *error;
  
  while (alert.isPresent) {
    [alert acceptWithError:&error];
    alert = [FBAlert alertWithApplication:application];
  }
  if (error) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)uuGetSysInfo:(FBRouteRequest *)request
{
  
  vm_statistics_data_t vmStats;
  mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
  kern_return_t kernReturn = host_statistics(mach_host_self(),
                                             HOST_VM_INFO,
                                             (host_info_t)&vmStats,
                                             &infoCount);
  
  if (kernReturn != KERN_SUCCESS) {
    
  }
  
  float cpuUsage = [[DeviceInfoManager sharedManager] getCPUUsage];
  int64_t totalMem = [[DeviceInfoManager sharedManager] getTotalMemory];
  double freeMem = vm_page_size *vmStats.free_count;
  int64_t freeDisk = [[DeviceInfoManager sharedManager] getFreeDiskSpace];
  NSString *networkTypeStr = [[DeviceInfoManager sharedManager] getNettype];
  
  NSString *totalMemStr = [NSString stringWithFormat:@"%.2f", totalMem/1024.0/1024.0];
  NSString *freeMemStr = [NSString stringWithFormat:@"%.2f", freeMem/1024.0/1024.0];
  NSString *freeDiskStr = [NSString stringWithFormat:@"%.2f", freeDisk/1024.0/1024.0];
  
  
  NSMutableDictionary *dic = [NSMutableDictionary dictionary];
  [dic setObject:@(cpuUsage) forKey:@"cpuUsage"];
  [dic setObject:networkTypeStr forKey:@"networkType"];
  [dic setObject:totalMemStr forKey:@"totalMem"];
  [dic setObject:freeDiskStr forKey:@"freeDisk"];
  [dic setObject:freeMemStr forKey:@"freeMem"];
  [dic setObject:@"MB" forKey:@"memeryUnit"];
  
  return FBResponseWithObject(dic);
}

+ (id<FBResponsePayload>)handleAPPList:(FBRouteRequest *)request
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
  Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
  NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
  
  NSArray *appList = [workspace performSelector:@selector(allApplications)];
  Class LSApplicationProxy_class = object_getClass(@"LSApplicationProxy");
  NSMutableArray *result = [NSMutableArray array];
  for (LSApplicationProxy_class in appList)
  {
    NSString *bundleID = [LSApplicationProxy_class performSelector:@selector(applicationIdentifier)] ?:@"";
    NSString *localizedName = [LSApplicationProxy_class performSelector:@selector(localizedName)] ?:@"";
    NSString *shortVersionString =  [LSApplicationProxy_class performSelector:@selector(shortVersionString)] ?:@"";
    if ([bundleID  isEqual: @""] || [bundleID hasPrefix:@"com.apple."] ) {
      continue;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:bundleID forKey:@"bundleID"];
    [dic setObject:shortVersionString forKey:@"version"];
    [dic setObject:localizedName forKey:@"localizedName"];
    [result addObject:dic];
  }
#pragma clang diagnostic pop
  return FBResponseWithObject(result);
}

+ (id<FBResponsePayload>)uuHandleDoubleTapCoordinate:(FBRouteRequest *)request {
  XCUIApplication *application = request.session.uu_application;
  
  CGPoint doubleTapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  XCUICoordinate *doubleTapCoordinate = [self.class uuGestureCoordinateWithCoordinate:doubleTapPoint application:application shouldApplyOrientationWorkaround:YES];
  [doubleTapCoordinate doubleTap];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)uuHandleTouchAndHoldCoordinate:(FBRouteRequest *)request {
  CGPoint touchPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  [[XCEventGenerator sharedGenerator] pressAtPoint:touchPoint forDuration:[request.arguments[@"duration"] doubleValue] orientation:0 handler:^(XCSynthesizedEventRecord *record, NSError *error) {}];
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)uuHandleDragCoordinate:(FBRouteRequest *)request {
  
  CGPoint startPoint = CGPointMake((CGFloat)[request.arguments[@"fromX"] doubleValue], (CGFloat)[request.arguments[@"fromY"] doubleValue]);
  CGPoint endPoint = CGPointMake((CGFloat)[request.arguments[@"toX"] doubleValue], (CGFloat)[request.arguments[@"toY"] doubleValue]);
  NSTimeInterval duration = [request.arguments[@"duration"] doubleValue];
  CGFloat velocity = [request.arguments[@"velocity"] doubleValue];
  
  [[XCEventGenerator sharedGenerator] pressAtPoint:startPoint forDuration:duration liftAtPoint:endPoint velocity:velocity orientation:UIInterfaceOrientationPortrait name:@"uuHandleDrag" handler:^(XCSynthesizedEventRecord *record, NSError *error) {}];
 
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)uuHandleTap:(FBRouteRequest *)request {
  
  CGPoint tapPoint = CGPointMake((CGFloat)[request.arguments[@"x"] doubleValue], (CGFloat)[request.arguments[@"y"] doubleValue]);
  [[XCEventGenerator sharedGenerator] pressAtPoint:tapPoint forDuration:0 orientation:0 handler:^(XCSynthesizedEventRecord *record, NSError *error) {}];

  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleGetWindowSize:(FBRouteRequest *)request {
  
  CGRect frame = request.session.application.wdFrame;
  CGSize screenSize = FBAdjustDimensionsForApplication(frame.size, request.session.application.interfaceOrientation);
  return FBResponseWithStatus(FBCommandStatusNoError, @{
                                                        @"width": @(screenSize.width),
                                                        @"height": @(screenSize.height),
                                                        });
}

+ (id<FBResponsePayload>)uuGetSSID:(FBRouteRequest *)request {
  
  NSString *ssid = nil;
  ssid = [UUElementCommands CurrentSSIDInfo];
  
  return FBResponseWithStatus(FBCommandStatusNoError, @{
                                                        @"ssid": ssid?:@"",
                                                        });
  
}

+ (id<FBResponsePayload>)uuSource:(FBRouteRequest *)request {
  
  CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
  
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  NSString *sourceType = request.parameters[@"format"];
  id result;
  if (!sourceType || [sourceType caseInsensitiveCompare:@"xml"] == NSOrderedSame) {
    //[application fb_waitUntilSnapshotIsStable];
    result = [FBXPath uuXmlStringWithSnapshot:application.lastSnapshot];
  } else if ([sourceType caseInsensitiveCompare:@"json"] == NSOrderedSame) {
    result = application.fb_tree;
  } else {
    return FBResponseWithStatus(
                                FBCommandStatusUnsupported,
                                [NSString stringWithFormat:@"Unknown source type '%@'. Only 'xml' and 'json' source types are supported.", sourceType]
                                );
  }
  if (nil == result) {
    return FBResponseWithErrorFormat(@"Cannot get '%@' source of the current application", sourceType);
  }
  
  CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
  NSLog(@"time cost: %0.3f", end - start);
  return FBResponseWithObject(result);
  
}

+ (id<FBResponsePayload>)uuBack:(FBRouteRequest *)request {
  
  FBApplication *application = request.session.application ?: [FBApplication fb_activeApplication];
  if (application.navigationBars.buttons.count > 0) {
    [[application.navigationBars.buttons elementBoundByIndex:0] tap];
    return FBResponseWithOK();
  }
  return FBResponseWithErrorFormat(@"Cannot back of the current page");
  
}


#pragma mark - Helpers

/**
 Returns gesture coordinate for the application based on absolute coordinate
 
 @param coordinate absolute screen coordinates
 @param application the instance of current application under test
 @shouldApplyOrientationWorkaround whether to apply orientation workaround. This is to
 handle XCTest bug where it does not translate screen coordinates for elements if
 screen orientation is different from the default one (which is portrait).
 Different iOS version have different behavior, for example iOS 9.3 returns correct
 coordinates for elements in landscape, but iOS 10.0+ returns inverted coordinates as if
 the current screen orientation would be portrait.
 @return translated gesture coordinates ready to be passed to XCUICoordinate methods
 */
+ (XCUICoordinate *)uuGestureCoordinateWithCoordinate:(CGPoint)coordinate application:(XCUIApplication *)application shouldApplyOrientationWorkaround:(BOOL)shouldApplyOrientationWorkaround {
  
  CGPoint point = coordinate;
  if (shouldApplyOrientationWorkaround) {
    point = FBInvertPointForApplication(coordinate, application.frame.size, application.interfaceOrientation);
  }
  XCUICoordinate *appCoordinate = [[XCUICoordinate alloc] initWithElement:application normalizedOffset:CGVectorMake(0, 0)];
  return [[XCUICoordinate alloc] initWithCoordinate:appCoordinate pointsOffset:CGVectorMake(point.x, point.y)];
}

+ (NSString *)buildTimestamp {
  
  return [NSString stringWithFormat:@"%@ %@",
          [NSString stringWithUTF8String:__DATE__],
          [NSString stringWithUTF8String:__TIME__]
          ];
}

+ (NSString *)CurrentSSIDInfo {
  
  NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
  NSLog(@"Supported interfaces: %@", ifs);
  id info = nil;
  for (NSString *ifnam in ifs) {
    info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
    NSLog(@"%@ => %@", ifnam, info);
    if (info && [info count]) { break; }
  }
  return [[(NSDictionary*)info objectForKey:@"SSID"] lowercaseString];
}


@end

