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

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object;

- (Event *)transformedWith:(transform_method_t)method;

@end

@interface Fireable : Event

+ (Fireable *)fireable;

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object;

- (void)fire:(id)eventArg;

@end

@interface Scope : NSObject

+ (Scope *)scopeForObject:(id)object;

@end
