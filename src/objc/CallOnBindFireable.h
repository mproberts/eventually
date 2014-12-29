//
//  CallOnBindFireable.h
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

@interface CallOnBindFireable : Fireable {
}

@property (nonatomic, copy) BOOL (^onBindHandler)(event_handler_t);

- (instancetype)init;

@end
