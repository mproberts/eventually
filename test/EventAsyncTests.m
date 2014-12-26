//
//  EventAsyncTests.m
//  eventually
//
//  Created by Mike Roberts on 2014-12-26.
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <pthread/pthread.h>
#import "Eventually.h"

@interface EventAsyncTests : XCTestCase

@end

@implementation EventAsyncTests

- (void)testRunOnAnotherQueue
{
    Fireable *fireable = [Fireable fireable];
    Event *event = [fireable onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    __block BOOL onMainThread = YES;
    __block NSNumber *value = nil;
    
    [event handledBy:^(NSNumber *number) {
        onMainThread = pthread_main_np();
        value = number;
    } inScope:self];
    
    [fireable fire:@(1)];
    
    usleep(10);
    
    XCTAssertEqualObjects(@(1), value);
    XCTAssertEqual(NO, onMainThread);
}

@end
