//
//  TheRulesTests.m
//  eventually
//
//  Created by Mike Roberts on 2014-12-24.
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Eventually.h"

@interface TheRulesTests : XCTestCase

@end

@implementation TheRulesTests

- (void)testWhenAScopeIsDestroyedAllHandlersAreUnbound
{
    const int scopeCount = 100;
    
    Fireable *fireable = [Fireable fireable];
    Event *event = fireable;
    
    __block int eventsFired1 = 0;
    __block int eventsFired2 = 0;
    
    NSMutableArray *scopes = [[NSMutableArray alloc] init];
    
    // add 2 handlers per scope
    for (int i = 0; i < scopeCount; ++i) {
        id scope = [[NSObject alloc] init];
        
        [event call:^(id arg) {
            eventsFired1++;
        } scopedTo:scope];
        
        [event call:^(id arg) {
            eventsFired2++;
        } scopedTo:scope];
        
        // hold a reference to the scope so it is not deallocated yet
        [scopes addObject:scope];
    }
    
    // remove each reference to the scopes one-by-one
    while (scopes.count) {
        eventsFired1 = 0;
        eventsFired2 = 0;
        
        // each firing should fire only the remaining scopes, no more
        [fireable fire:@(scopes.count)];
        
        XCTAssertEqual(scopes.count, eventsFired1);
        XCTAssertEqual(scopes.count, eventsFired2);
        
        [scopes removeLastObject];
    }
    
    // ensure that the last remove cleared the remaining handler
    eventsFired1 = 0;
    eventsFired2 = 0;
    
    [fireable fire:@(0)];
    
    XCTAssertEqual(0, eventsFired1);
    XCTAssertEqual(0, eventsFired2);
}

- (void)testWhenUnboundFromAnEventAnySubsqeuntFireDoesntCallTheHandler
{
    Fireable *fireable = [Fireable fireable];
    Event *event = fireable;
    
    __block int eventsFired = 0;
    __block BOOL first = YES;
    
    __block EventBinding *binding = [event call:^(id arg) {
        eventsFired++;
        
        if (first) {
            first = NO;
            
            [binding remove];
            
            [fireable fire:@(1)];
        }
    } scopedTo:self];
    
    [fireable fire:@(0)];
    
    [fireable fire:@(2)];
    
    XCTAssertEqual(1, eventsFired);
}

- (void)testWhenBoundToAnEventAnySubsqeuntFireCallsTheHandler
{
    Fireable *fireable = [Fireable fireable];
    Event *event = fireable;
    
    __block int eventsFired = 0;
    __block BOOL first = YES;
    
    [event call:^(id arg) {
        if (first) {
            first = NO;
            
            [event call:^(id arg) {
                ++eventsFired;
            } scopedTo:self];
            
            [fireable fire:@(0)];
        }
    } scopedTo:self];
    
    [fireable fire:@(0)];
    
    XCTAssertEqual(1, eventsFired);
}

@end
