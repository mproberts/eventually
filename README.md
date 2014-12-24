# Eventually

## Events

## Scope

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

- (void)fetchUpdatedScores
{
    // ...

    [_onScoreUpdated fire:score];
}

@end

// Consume an event
[game.onScoreUpdated handledBy:^(Score *score) {
    [viewController updateScore:score];
} inScope:viewController];

```
