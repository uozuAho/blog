---
title: "Pandemic DDD Revisited"
date: 2023-03-17T14:19:05+11:00
draft: true
summary: "Was it worth it?"
tags:
- DDD
---

### todo
- inline todos
- loop until no changes
    - proof read whole thing
    - edits etc.
- note near start: using react impl as a comparison
- view in browser/phone. Needs pictures?


# Post
A long time ago, I started building the pandemic board game as a way of learning
domain-driven design. I finally finished it! In this post I'll reflect on what
went well, what didn't etc.

At the end of my [original post]({{< ref "20210924_learning_ddd_by_implementing_pandemic" >}}),
I had gotten to a stage where I was confident that I could implement the rest of
the game without needing to make many more design decisions. I had found that
breaking the game rules down into fine-grained commands, handlers and events
made them easy to think about and therefore implement. This remained true. There
were a few rules that needed changes to a number of other areas of the program,
but they weren't too costly. This was also due to the way I implemented the
commands - very fine-grained. More on that later.


# Reviewing my design decisions

## How to handle events that trigger other events
decision: based on [Armadora](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07),
I decided to not react to events, and allow commands to call other commands. Why?
- I thought chain reactions of events would be hard to debug & trace in code

I only used events to update the game state. I used commands and handlers
to implement all logic. This turned out to be a bit of a mistake. The react
implementation reacts to its own events, which made dealing with unbounded side
effects easy.

Most of the player commands were simple to implement. These are actions made by
a player in the game, that have few effects. An example is driving from one city
to another. In most cases, the only effect of this action is that a player moves
from one city to another.

The most complicated logic in the player commands dealt with conditional side effects.
For example, when curing a disease:

```cs
// A disease is cured by discarding cards.
// The result of ApplyEvents is the updated game state.
game = ApplyEvents(cmd.Cards
    .Select(c => new PlayerCardDiscarded(cmd.Role, c))
    .Concat<IEvent>(new[] { new CureDiscovered(colour) }), events);

// If a medic is on a city with cubes for the disease that has
// just been discovered, then those cubes are removed.
game = game.ApplyEvents(game.AnyMedicAutoRemoves(), events);

// If the cube pile is full (has all 24 cubes) for the cured disease,
// then the disease is eradicated.
if (game.Cubes.NumberOf(colour) == 24)
    game = game.ApplyEvent(new DiseaseEradicated(colour), events);

return (game, events);
```

how the react version does this:
- cure managed as [saga](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/actionSagas.js#L146)
- curing emits PLAYER_CURE_DISEASE_COMPLETE: https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/containers/BottomBar.js#L107
    - [watched by medic for curing](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/roleSagas.js#L55)
        - emits MEDIC_TREAT_CURED_DISEASES
        - eradication is checked on these events: treat disease, treat all, cure
            - not MEDIC_TREAT_CURED_DISEASES though? Bug?
    - continues saga
- saga discards cards

Handling chain reactions of events caused the highest complexity. For example,
see `Outbreak` and `EpidemicInfectCity` **todo** link to code. **todo check react impl**
To manage this, I added extra state attributes to the game aggregate, then after
each player action, looped until it was time for another player action:

```py
# pseudo
def do_player_action(game, action):
  validate(game, action)

  game = do(game, action)

  while not game.available_player_commands.any?:
    game = do(game, game.next_step())

  return game
```

## Everything is immutable
Good
- easier to debug (probably)
- no need to implement deep clone

Bad
- simple changes are verbose (more lines of code)
  **todo: get the example of dispatcher move**
- slow
  - initial perf testing shows that I'm allocating a lot of memory
  - tried mutable at one point, got a 4x speedup

## One aggregate
I was worried about how big the aggregate was getting.

I'm torn about this one. I still think it's a good decision, but there's a lot
of code in the aggregate. I actually split it into multiple files to make it
easier to manage (using C# partials). Game data, command handlers, event handlers
and process managers. Regions are another option. There's about 2200 total lines
across those files. I find them easy to navigate, as they're mostly made of small
methods that deal with specific commands and events. No need to split them up.

Using the command pattern has been useful. This has made it easy to do
cross-cutting stuff like command validation & post-command actions, keeping
command handlers small as a result. `DoStuffAfterActions` is now the non-player stepper thing


# Thoughts on the finished product
## DDD intends to manage complexity. Did it?
### Objective
I used a few tools to objectively compare the complexity of my code to the react
implementation. My code failed all metrics by a modest margin:

- Total lines of code
- Indentation (proxy for complexity)

**todo** show polyglot screenshots, give LOC numbers & reasoning & links to tools used

### Subjective
There's enough leeway in DDD to make mistakes. I think my choice to use very granular
move commands & events caused a bunch of accidental complexity. Eg:

Commands that move a player in my impl:
- airlift
- charter flight
- direct flight
- shuttle flight
- drive/ferry
- dispatcher versions of the above (yes, separate) **todo**: why?
- dispatcher move pawn to other
- opex discard to move

in React impl:
- [move to city](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/actions/mapActions.js#L12)
  - watched by
    - [move to city](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/actionSagas.js#L172)
      - discards card for direct & charter flights & opex move
      - treats cured diseases if the medic moved
- [airlift move to city](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/actions/mapActions.js#L44)
  - watched by
    - [medic move](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/roleSagas.js#L43)

If I consolidated the above, and maybe reacted to events instead of adding conditional
logic to my command handlers, I may be able to get the line and and complexity
metrics down to a comparable level.

What I liked, that I got from DDD:
- keep all consistency logic in the same aggregate
- arbitrarily fine grained commands and events
    - although the above could have been done more efficiently
    - eg. there's some difference between contingency planner using a stored
      event card and other players using an event. To keep logic simple and
      manageable, treat these with different commands and events.


# Unexplored areas of DDD, remaining questions
Many, since this is a small monolithic application. Hardly an ideal use of DDD,
although it was a good test given the complexity of the game rules. Here are some:
- aggregate design. The entire game state needs to be consistent at all times,
  so there's been no need/opportunity to create smaller aggregates
- eventual consistency: same reason as above
- strategic design: bounded contexts, domains
- lots of stuff becoming public to aid testing & state management of complex
  logic. **todo**: check how much of this actually needs to be public. Can I
  only expose meaningful game state as public?


# Other things I learned
- fuzz testing is great! it has turned up so many bugs that I hadn't covered
  with simple unit tests
- even though I'm not using event sourcing or even the events emitted by
  commands, they have been very useful to debug complex bugs. Having the entire
  event history of a game makes it easy to see where things have gone wrong.
  This would be laborious to step through in the debugger.
- using the rule to only modify aggregates via events has ensured that all game
  state changes are captured. It's a bit of a pain to add a command + handler +
  event + handler, but I think it's been worth it for the above point alone
