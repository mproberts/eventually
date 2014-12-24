//
//  EventFiringTests.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <libkern/OSAtomic.h>
#import "Eventually.h"

@interface EventFiringTests : XCTestCase

@end

@implementation EventFiringTests

- (void)testBasicFiring
{
    __block NSNumber *result = nil;
    id scope = [[NSObject alloc] init];
    
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    [event handledBy:^(id arg) {
        result = arg;
    } inScope:scope];
    
    [fireable fire:@12];
    
    XCTAssertEqualObjects(@12, result);
    
    [fireable fire:@13];
    
    XCTAssertEqualObjects(@13, result);
}

- (void)testFiringAfterScopeIsCleared
{
    __block NSNumber *result = nil;
    __block int scope1FireCount = 0;;
    
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    id scope1 = [[NSObject alloc] init];
    
    [event handledBy:^(id arg) {
        ++scope1FireCount;
    } inScope:scope1];
    
    {
        id scope2 = [[NSObject alloc] init];
        
        [event handledBy:^(id arg) {
            result = arg;
        } inScope:scope2];
        
        [fireable fire:@12];
        
        XCTAssertEqualObjects(@12, result);
        XCTAssertEqual(1, scope1FireCount);
    }
    
    [fireable fire:@13];
    
    // the event should have been unbound by the scope being destroyed
    XCTAssertEqualObjects(@12, result);
    XCTAssertEqual(2, scope1FireCount);
}

- (void)testRemovingHandler
{
    __block int fireCount = 0;;
    
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    id scope = [[NSObject alloc] init];
    
    EventBinding *binding = [event handledBy:^(id arg) {
        ++fireCount;
    } inScope:scope];
    
    [fireable fire:@1];
    
    XCTAssertEqual(1, fireCount);
    
    [fireable fire:@2];
    
    XCTAssertEqual(2, fireCount);
    
    [binding remove];
    
    [fireable fire:@3];
    
    XCTAssertEqual(2, fireCount);
}

- (void)testRemovingWhileInHandler
{
    __block int fireCount = 0;;
    
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    id scope = [[NSObject alloc] init];
    
    __block EventBinding *binding = [event handledBy:^(id arg) {
        ++fireCount;
        [binding remove];
    } inScope:scope];
    
    [fireable fire:@1];
    
    XCTAssertEqual(1, fireCount);
    
    [fireable fire:@2];
    
    XCTAssertEqual(1, fireCount);
}

- (void)testAddHandlersWhileFiring
{
    __block int addedHandlers = 0;
    __block int handler1Count = 0;
    __block int handler2Count = 0;
    __block int handler3Count = 0;
    
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    id scope = [[NSObject alloc] init];
    
    ++addedHandlers;
    
    [event handledBy:^(id arg) {
        ++handler1Count;
    
        if (addedHandlers == 1) {
            [event handledBy:^(id arg) {
                ++handler2Count;
                
                if (addedHandlers == 2) {
                    [event handledBy:^(id arg) {
                        ++handler3Count;
                    } inScope:scope];
                    
                    ++addedHandlers;
                }
            } inScope:scope];
            
            ++addedHandlers;
        }
    } inScope:scope];
    
    [fireable fire:@1];
    
    XCTAssertEqual(handler1Count, 1);
    XCTAssertEqual(handler2Count, 0);
    XCTAssertEqual(handler3Count, 0);
    
    [fireable fire:@2];
    
    XCTAssertEqual(handler1Count, 2);
    XCTAssertEqual(handler2Count, 1);
    XCTAssertEqual(handler3Count, 0);
    
    [fireable fire:@3];
    
    XCTAssertEqual(handler1Count, 3);
    XCTAssertEqual(handler2Count, 2);
    XCTAssertEqual(handler3Count, 1);
}

- (void)testPerformance
{
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    id scope = [[NSObject alloc] init];
    
    const int handlers = 1000;
    const int iterations = 1000;
    
    __block int runs = 0;
    __block int firedEvents = 0;
    
    for (int i = 0; i < handlers; ++i) {
        [event handledBy:^(id arg) {
            ++firedEvents;
        } inScope:scope];
    }
    
    [self measureBlock:^{
        ++runs;
        
        for (int i = 0; i < iterations; ++i) {
            [fireable fire:@(i)];
        }
    }];
    
    XCTAssertEqual(firedEvents, handlers * iterations * runs);
}

- (void)testHighConcurrency
{
    Fireable *fireable = [Fireable fireable];
    id<Event> event = fireable;
    
    const int queueCount = 20;
    dispatch_queue_t queue[queueCount];
    
    const int eventsToFire = 1000;
    const int handlers = 1000;
    
    __block int remainingEvents = eventsToFire;
    __block int firedEvents = 0;
    __block int activeQueues = 0;
    
    id scope = [[NSObject alloc] init];
    
    for (int i = 0; i < handlers; ++i) {
        [event handledBy:^(id arg) {
            // track the events being fired
            OSAtomicIncrement32(&firedEvents);
        } inScope:scope];
    }

    for (int i = 0; i < queueCount; ++i) {
        OSAtomicIncrement32(&activeQueues);
        queue[i] = dispatch_queue_create("TestQueue", NULL);
        
        dispatch_async(queue[i], ^() {
            int remaining;
            
            while ((remaining = OSAtomicDecrement32(&remainingEvents)) >= 0) {
                [fireable fire:@(remaining)];
                
                // let another queue have a chance 25% of the time
                if (rand() % 4 == 0) {
                    usleep(1);
                }
            }
            
            OSAtomicDecrement32(&activeQueues);
        });
    }

    // wait for all queues to return
    while (activeQueues > 0) {
        usleep(1000);
    }
     
    XCTAssertEqual(firedEvents, eventsToFire * handlers);
}

@end
