//
//  UUMonkeySingleton.h
//  WebDriverAgentLib
//
//  Created by 刘 晓东 on 2018/3/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface UUMonkeySingleton : NSObject

@property (nonatomic, weak) XCUIApplication *application;

+ (instancetype)sharedInstance;

@end
