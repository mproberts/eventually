//
//  FutureTests.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Eventually.h"

@interface FutureTests : XCTestCase

@end

@implementation FutureTests

- (void)testBasic
{
    ResolvableFuture *future = [ResolvableFuture future];
    __block BOOL handled = NO;
        
    [future.when handledBy:^(NSString *result) {
        XCTAssertEqualObjects(@"fancy", result);
        handled = YES;
    } inScope:self];
    
    XCTAssertFalse(handled);
    
    [future resolve:@"fancy"];
    
    XCTAssertTrue(handled);
}

@end
