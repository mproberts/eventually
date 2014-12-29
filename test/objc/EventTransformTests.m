//
//  EventTransformTests.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Eventually.h"

@interface EventTransformTests : XCTestCase

@end

@implementation EventTransformTests

- (void)testBasicTransform
{
    Fireable *fireable = [Fireable fireable];
    Event *event = [fireable transformedWith:^(NSNumber *number) {
        return @(number.intValue *2);
    }];
    
    __block NSNumber *value = nil;
    
    [event handledBy:^(NSNumber *number) {
        value = number;
    } inScope:self];
    
    [fireable fire:@(1)];
    
    XCTAssertEqualObjects(@(2), value);
    
    [fireable fire:@(7)];
    
    XCTAssertEqualObjects(@(14), value);
}

@end
