//
//  Event.m
//  eventually
//
//  Copyright (c) 2014 Mike Roberts. All rights reserved.
//

#import "Event.h"
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>

#define EVENTUALLY_BOUND_SCOPE "com.mproberts.eventually.EVENTUALLY_BOUND_SCOPE"

@interface BoundBlock : NSObject

@property (nonatomic, copy) event_handler_t handler;
@property (nonatomic, weak) id scope;
@property (nonatomic, retain) Event *event;

- (instancetype)initWithBlock:(event_handler_t)handler scope:(id)scope event:(Event *)event;

@end

@implementation BoundBlock

- (instancetype)initWithBlock:(event_handler_t)handler scope:(id)scope event:(Event *)event
{
    if (self = [super init]) {
        self.handler = handler;
        self.scope = scope;
        self.event = event;
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
    volatile int32_t _fireCallStackDepth;
    volatile uint32_t _bindingsDirty;
}

@property (nonatomic, retain) NSObject *bindingLock;
@property (nonatomic, retain) NSMutableArray *bindings;
@property (nonatomic, retain) NSMutableArray *temporaryBindingsToAdd;

@end

@implementation Event

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object
{
    @throw @"Not Implemented";
}

- (Event *)transformedWith:(transform_method_t)method
{
    Fireable *fireable = [[Fireable alloc] init];
    
    // bind the fireable to itself, this will have to be retained by
    // any interested events
    [self handledBy:^(id arg) {
        [fireable fire:method(arg)];
    } inScope:fireable];
    
    return fireable;
}

@end

@implementation Fireable

- (instancetype)init
{
    if (self = [super init]) {
        self.bindings = [[NSMutableArray alloc] init];
        self.temporaryBindingsToAdd = [[NSMutableArray alloc] init];
        
        self.bindingLock = [[NSObject alloc] init];
        
        _fireCallStackDepth = 0;
        _bindingsDirty = 0;
    }
    
    return self;
}

+ (Fireable *)fireable
{
    return [[Fireable alloc] init];
}

- (EventBinding *)handledBy:(event_handler_t)handler inScope:(id)object
{
    Scope *scope = [Scope scopeForObject:object];
    BoundBlock *blockBinding = [[BoundBlock alloc] initWithBlock:handler scope:object event:self];
    
    WeaklyBoundBlock *weakBinding = [[WeaklyBoundBlock alloc] init];
    StronglyBoundBlock *strongBinding = [[StronglyBoundBlock alloc] init];
    
    weakBinding.binding = blockBinding;
    strongBinding.binding = blockBinding;
    
    @synchronized (self.bindingLock) {
        if (_fireCallStackDepth > 0) {
            _bindingsDirty = YES;
            
            // make a copy of the existing handler list so the currently iterating
            // fire method doesn't break
            self.bindings = [NSMutableArray arrayWithArray:self.bindings];
        }
        
        [self.bindings addObject:weakBinding];
    }
    
    // strongly retain the handler
    [scope retainBinding:strongBinding];
    
    return [[EventBinding alloc] initWithBinding:strongBinding scope:scope];
}

- (void)fire:(id)eventArg
{
    OSAtomicIncrement32(&_fireCallStackDepth);
    
    size_t position = 0;
    NSArray *currentBindings = self.bindings;
    NSMutableArray *bindingsToKeep = nil;
    
    for (WeaklyBoundBlock *weakBinding in currentBindings) {
        event_handler_t handler = weakBinding.binding.handler;
        id retainedScope = weakBinding.binding.scope;
        
        ++position;
        
        if (retainedScope && handler) {
            handler(eventArg);
            
            // if we are building a keep list currently and the effort is not futile
            if (bindingsToKeep && !_bindingsDirty) {
                // keep around this binding since it's a good one
                [bindingsToKeep addObject:weakBinding];
            }
        }
        else {
            bindingsToKeep = [NSMutableArray arrayWithArray:[self.bindings subarrayWithRange:NSMakeRange(0, position-1)]];
        }
    }
    
    if (OSAtomicDecrement32(&_fireCallStackDepth) == 0) {
        if (bindingsToKeep && !_bindingsDirty) {
            @synchronized (self.bindingLock) {
                if (!_bindingsDirty) {
                    // if the bindings are definitely not dirty,
                    // update the bindings with the cleaned up copy
                    self.bindings = bindingsToKeep;
                }
            }
        }
        
        if (_bindingsDirty) {
            @synchronized (self.bindingLock) {
                _bindingsDirty = NO;
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
    
    // destroy the binding context
    BoundBlock *boundBlock = self.binding.binding;
    
    boundBlock.scope = nil;
    boundBlock.handler = nil;
    boundBlock.event = nil;
}

@end
