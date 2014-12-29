//
//  Event.h
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^event_handler_t)(id arg);
typedef id (^transform_method_t)(id arg);

@interface EventBinding : NSObject

- (void)remove;

@end

@interface Event : NSObject

- (EventBinding *)call:(event_handler_t)handler scopedTo:(id)object;

- (Event *)transformedWith:(transform_method_t)method;

- (Event *)onQueue:(dispatch_queue_t)queue;

- (Event *)onMainQueue;

@end

@interface Fireable : Event

+ (Fireable *)fireable;

- (EventBinding *)call:(event_handler_t)handler scopedTo:(id)object;

- (void)fire:(id)eventArg;

- (void)removeAllBindings;

@end

@interface Scope : NSObject

+ (Scope *)scopeForObject:(id)object;

@end
