//
//  Event.h
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^event_handler_t)(id arg);

@interface EventBinding : NSObject

- (void)remove;

@end

@interface Event : NSObject {
    BOOL _isWeak;
}

@property (nonatomic, readonly) BOOL isWeak;

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object;

@end

@interface Fireable : Event

+ (Fireable *)fireable;

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object;

- (void)fire:(id)eventArg;

@end

@interface Scope : NSObject

+ (Scope *)scopeForObject:(id)object;

@end
