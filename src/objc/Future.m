//
//  Future.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import "Future.h"

#define FUTURE_STATE_INCOMPLETE 0
#define FUTURE_STATE_RESOLVED 1
#define FUTURE_STATE_FAILED 2
#define FUTURE_STATE_CANCELLED 3

@interface Future ()

- (void)transitionToState:(int)state call:(void (^)(void))method;

@end

@implementation Future

@synthesize when = _when;
@synthesize failed = _failed;
@synthesize failedOrCancelled = _failedOrCancelled;
@synthesize cancelled = _cancelled;
@synthesize any = _any;

- (instancetype)init
{
    if (self = [super init]) {
        _when = [[CallOnBindFireable alloc] init];
        _failed = [[CallOnBindFireable alloc] init];
        _failedOrCancelled = [[CallOnBindFireable alloc] init];
        _cancelled = [[CallOnBindFireable alloc] init];
        _any = [[CallOnBindFireable alloc] init];
        
        _state = FUTURE_STATE_INCOMPLETE;
    }
    
    return self;
}

+ (instancetype)future
{
    return [[Future alloc] init];
}

- (void)transitionToState:(int)state call:(void (^)(void))method
{
    @synchronized (_stateLock) {
        // only allow the state transition once
        if (_state != FUTURE_STATE_INCOMPLETE) {
            return;
        }
        
        _state = state;
    }

    // modify the state for the future
    if (method) {
        method();
    }
    
    __weak typeof(self) weakSelf = self;
    
    // bind the immediately-firing bind handlers so that all calls to
    // the events return immediately after the state change
    _when.onBindHandler = ^(event_handler_t handler) {
        typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf && handler) {
            handler(strongSelf->_value);
        }
        
        return NO;
    };
    
    _failed.onBindHandler = ^(event_handler_t handler) {
        typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf && handler) {
            handler(strongSelf->_exception);
        }
        
        return NO;
    };
    
    _failedOrCancelled.onBindHandler = ^(event_handler_t handler) {
        typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf && handler) {
            handler(strongSelf->_exception);
        }
        
        return NO;
    };
    
    _cancelled.onBindHandler = ^(event_handler_t handler) {
        typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf && handler) {
            handler(nil);
        }
        
        return NO;
    };
    
    _any.onBindHandler = ^(event_handler_t handler) {
        typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf && handler) {
            handler(nil);
        }
        
        return NO;
    };
    
    // fire the corresponding change event
    switch (state) {
        case FUTURE_STATE_RESOLVED:
            [_when fire:_value];
            break;
            
        case FUTURE_STATE_FAILED:
            [_failed fire:_exception];
            [_failedOrCancelled fire:_exception];
            break;
            
        case FUTURE_STATE_CANCELLED:
            [_cancelled fire:nil];
            [_failedOrCancelled fire:nil];
            break;
    }
    
    // since there was a state change, fire that as well
    [_any fire:nil];
    
    // clear out any retained bindings so they can be collected
    [_when removeAllBindings];
    [_failed removeAllBindings];
    [_failedOrCancelled removeAllBindings];
    [_cancelled removeAllBindings];
    [_any removeAllBindings];
}

@end

@implementation CancellableFuture

+ (instancetype)future
{
    return [[CancellableFuture alloc] init];
}

- (instancetype)cancel
{
    [self transitionToState:FUTURE_STATE_CANCELLED call:nil];
    
    return self;
}

@end

@implementation ResolvableFuture

+ (instancetype)future
{
    return [[ResolvableFuture alloc] init];
}

- (instancetype)resolve:(id)value
{
    [self transitionToState:FUTURE_STATE_RESOLVED call:^(){
        _value = value;
    }];
    
    return self;
}

- (instancetype)fail:(NSException *)exception
{
    [self transitionToState:FUTURE_STATE_FAILED call:^(){
        _exception = exception;
    }];
    
    return self;
}

@end
