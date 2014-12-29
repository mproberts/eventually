# Eventually

Lightweight, scoped eventing framework for Objective-c (and other languages).

## Events

In the eventually system, everything is based on events. Events are objects to which you can
bind a handler which will be called the next time something interesting happens.

## Scope

The scope object provided when binding an event handler dictates the lifecycle for the 
binding. As long as the object exists, the binding will be valid. As long as the binding 
exists, the scope object will exist. This relationship means that you can trust that your 
scope will be around when your binding method gets called. We can't guarantee that the object
will still be attached to the UI or in an expected state, but it will exist.

## Examples

### Objective-C

```objective-c
#include "Eventually.h"

// Expose an event for others to consume
@interface Game : NSObject {
    Fireable *_onScoreUpdated;
}

@property (nonatomic, readonly) Event *onScoreUpdated;

@end

@implementation Game

@synthesize onScoreUpdated = _onScoreUpdated;

- (void)periodicScoreUpdates
{
    // ...

    [_onScoreUpdated fire:score];
}

- (CancellableFuture *)getPlayerInfo:(NSString *)playerId
{
    ResolvableFuture *playerInfoFuture = [ResolvableFuture future];

    // ...

    return playerInfoFuture;
}

@end

// Consume an event
[game.onScoreUpdated call:^(Score *score) {
    [viewController updateScore:score];
} scopedTo:viewController];

// Bind to a future
CancellableFuture *playerInfo = [game getPlayerInfo:@"tom"];

[playerInfo.when call:^(PlayerInfo *info) {
    [viewController updatePlayerInfo:info];
} scopedTo:viewController];

[playerInfo.failedOrCancelled call:^(NSException *ex) {
    [viewController showErrorDialog:ex];
} scopedTo:viewController];

```
