//
//  eventually.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import "Eventually.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>

#define EVENTUALLY_BOUND_SCOPE "com.mproberts.eventually.EVENTUALLY_BOUND_SCOPE"

@interface BoundBlock : NSObject

@property (nonatomic, copy) event_handler_t handler;

- (instancetype)initWithBlock:(event_handler_t)handler;

@end

@implementation BoundBlock

- (instancetype)initWithBlock:(event_handler_t)handler
{
    if (self = [super init]) {
        self.handler = handler;
    }
    
    return self;
}

@end

@interface WeaklyBoundBlock : NSObject

@property (nonatomic, weak) BoundBlock *binding;
@property (nonatomic, readonly) event_handler_t handler;

@end

@interface StronglyBoundBlock : NSObject

@property (nonatomic, strong) BoundBlock *binding;
@property (nonatomic, readonly) event_handler_t handler;

@end

@implementation WeaklyBoundBlock

- (event_handler_t)handler
{
    return self.binding.handler;
}

@end

@implementation StronglyBoundBlock

- (event_handler_t)handler
{
    return self.binding.handler;
}

@end

@interface EventBinding ()

@property (nonatomic, weak) StronglyBoundBlock *binding;
@property (nonatomic, weak) Scope *scope;

- (instancetype)initWithBinding:(StronglyBoundBlock *)binding scope:(Scope *)scope;

@end

@interface Scope ()

@property (nonatomic, retain) NSMutableArray *bindings;

- (void)retainBinding:(StronglyBoundBlock *)binding;

- (void)removeBinding:(StronglyBoundBlock *)binding;

@end

@interface Fireable () {
    volatile int32_t _firingDepth;
    volatile uint32_t _pendingAdds;
}

@property (nonatomic, retain) NSObject *bindingLock;
@property (nonatomic, retain) NSMutableArray *bindings;
@property (nonatomic, retain) NSMutableArray *temporaryBindingsToAdd;
@property (nonatomic, retain) NSMutableArray *temporaryBindingsToRemove;

@end

@implementation Fireable

- (instancetype)init
{
    if (self = [super init]) {
        self.bindings = [[NSMutableArray alloc] init];
        self.temporaryBindingsToAdd = [[NSMutableArray alloc] init];
        self.temporaryBindingsToRemove = [[NSMutableArray alloc] init];
        
        self.bindingLock = [[NSObject alloc] init];
        
        _firingDepth = 0;
        _pendingAdds = 0;
    }
    
    return self;
}

+ (Fireable *)fireable
{
    return [[Fireable alloc] init];
}

- (EventBinding *)on:(event_handler_t)handler scope:(id)object
{
    Scope *scope = [Scope scopeForObject:object];
    BoundBlock *blockBinding = [[BoundBlock alloc] initWithBlock:handler];
    
    WeaklyBoundBlock *weakBinding = [[WeaklyBoundBlock alloc] init];
    StronglyBoundBlock *strongBinding = [[StronglyBoundBlock alloc] init];
    
    weakBinding.binding = blockBinding;
    strongBinding.binding = blockBinding;
    
    @synchronized (self.bindingLock) {
        if (_firingDepth > 0) {
            OSAtomicTestAndSet(0, &_pendingAdds);
            
            // this binding will get added in the next pass
            [self.temporaryBindingsToAdd addObject:weakBinding];
        }
        else {
            [self.bindings addObject:weakBinding];
        }
    }
    
    // strongly retain the handler
    [scope retainBinding:strongBinding];
    
    return [[EventBinding alloc] initWithBinding:strongBinding scope:scope];
}

- (void)fire:(id)eventArg
{
    OSAtomicIncrement32(&_firingDepth);
    
    size_t position = 0;
    BOOL buildingRemovalList = NO;
    
    NSMutableArray *bindingsToKeep = nil;
    
    for (WeaklyBoundBlock *binding in self.bindings) {
        event_handler_t handler = binding.handler;
        
        ++position;
        
        if (handler) {
            handler(eventArg);
            
            if (buildingRemovalList) {
                [bindingsToKeep addObject:binding];
            }
        }
        else {
            buildingRemovalList = YES;
            bindingsToKeep = [NSMutableArray arrayWithArray:[self.bindings subarrayWithRange:NSMakeRange(0, position-1)]];
        }
    }
    
    if (OSAtomicDecrement32(&_firingDepth) == 0) {
        if (OSAtomicTestAndClear(0, &_pendingAdds)) {
            if (self.temporaryBindingsToRemove.count) {
                [self.bindings removeObjectsInArray:self.temporaryBindingsToRemove];
                
                [self.temporaryBindingsToRemove removeAllObjects];
            }
            
            @synchronized (self.bindingLock) {
                if (self.temporaryBindingsToAdd.count) {
                    [self.bindings addObjectsFromArray:self.temporaryBindingsToAdd];
                    
                    [self.temporaryBindingsToAdd removeAllObjects];
                }
            }
        }
    }
}

@end

@implementation Scope

+ (Scope *)scopeForObject:(id)object
{
    Scope *scope = objc_getAssociatedObject(object, EVENTUALLY_BOUND_SCOPE);
    
    if (!scope) {
        scope = [[Scope alloc] init];
        objc_setAssociatedObject(object, EVENTUALLY_BOUND_SCOPE, scope, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return scope;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.bindings = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)retainBinding:(StronglyBoundBlock *)binding
{
    [self.bindings addObject:binding];
}

- (void)removeBinding:(StronglyBoundBlock *)binding
{
    [self.bindings removeObject:binding];
}

@end

@implementation EventBinding

- (instancetype)initWithBinding:(StronglyBoundBlock *)binding scope:(Scope *)scope
{
    if (self = [super init]) {
        self.binding = binding;
        self.scope = scope;
    }
    
    return self;
}

- (void)remove
{
    [self.scope removeBinding:self.binding];
}

@end
