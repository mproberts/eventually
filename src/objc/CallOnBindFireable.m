//
//  CallOnBindFireable.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import "CallOnBindFireable.h"

@implementation CallOnBindFireable

@synthesize onBindHandler;

- (instancetype)init
{
    if (self = [super init]) {
    }
    
    return self;
}

- (BOOL)onBind:(event_handler_t)handler
{
    if (self.onBindHandler) {
        return self.onBindHandler(handler);
    }
    
    return YES;
}

@end
