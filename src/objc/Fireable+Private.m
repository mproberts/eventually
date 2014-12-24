//
//  Fireable+Private.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import "Fireable+Private.h"

@implementation Fireable (Private)

- (instancetype)initWithIsWeak:(BOOL)weak
{
    if (self = [super init]) {
        _isWeak = weak;
    }
    
    return self;
}

@end
