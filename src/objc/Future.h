//
//  Future.h
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"
#import "CallOnBindFireable.h"

@interface Future : NSObject {
    CallOnBindFireable *_when;
    CallOnBindFireable *_failed;
    CallOnBindFireable *_failedOrCancelled;
    CallOnBindFireable *_cancelled;
    CallOnBindFireable *_any;
    
    volatile int _state;
    NSObject *_stateLock;
    
    id _value;
    NSException *_exception;
}

@property (nonatomic, readonly) Event *when;
@property (nonatomic, readonly) Event *failed;
@property (nonatomic, readonly) Event *failedOrCancelled;
@property (nonatomic, readonly) Event *cancelled;
@property (nonatomic, readonly) Event *any;

- (instancetype)init;

+ (instancetype)future;

@end

@interface CancellableFuture : Future

+ (instancetype)future;

- (instancetype)cancel;

@end

@interface ResolvableFuture : CancellableFuture

+ (instancetype)future;

- (instancetype)resolve:(id)value;

- (instancetype)fail:(NSException *)exception;

@end
