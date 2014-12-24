# Eventually

## Events

## Scope

## Examples

### Objective-C

```objective-c
// Expose an event for others to consume
@interface Game : NSObject {
    Fireable *_onScoreUpdated;
}

@property (nonatomic, readonly) id<Event> onScoreUpdated;

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
[game.onScoreUpdated on:^(Score *score) {
    [viewController updateScore:score];
} scope:viewController];

```
