//
//  UUMonkeyXCTestPrivate.m
//  monkeyios
//
//  Created by 刘 晓东 on 2018/3/2.
//  Copyright © 2018年 刘 晓东. All rights reserved.
//

#import "UUMonkeyXCTestPrivate.h"

@implementation UUMonkey (MonkeyXCTestPrivate)

- (void)addDefaultXCTestPrivateActions {
    
}

- (void)addXCTestTapAction:(double)weight multipleTapProbability:(double)multipleTapProbability   multipleTouchProbability:(double)multipleTouchProbability {
    
     __weak __typeof(self) weakself = self;
    [self addActionWithWeight:weight andAction:^{
        CGRect rect = [weakself randomRect];
        CGPoint tapPoint = [weakself randomPointInRect:rect];
        [[XCEventGenerator sharedGenerator] pressAtPoint:tapPoint forDuration:0 orientation:0 handler:^(XCSynthesizedEventRecord *record, NSError *error) {}];
    }];
    
}

- (void)addXCTestTapAction:(double)weight {
    [self addXCTestTapAction:weight multipleTapProbability:0.05 multipleTouchProbability:0.05];
}

- (void)addXCTestLongPressAction:(double) weight {
    
}

- (void)addXCTestDragAction:(double) weight {
    
}

- (void)addXCTestPinchCloseAction:(double) weight {
    
}

- (void)addXCTestPinchOpenAction:(double) weight {
    
}

- (void)addXCTestRotateAction:(double) weight {
    
}

- (void)addXCTestOrientationAction:(double) weight {
    
}


@end
