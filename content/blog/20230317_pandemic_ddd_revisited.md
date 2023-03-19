---
title: "Pandemic DDD Revisited"
date: 2023-03-17T14:19:05+11:00
draft: true
summary: "Was it worth it?"
tags:
- DDD
---

### todo
- loop until no changes
    - proof read whole thing
      - audience
        - past me: what would i have liked to know when starting?
        - other devs: what is DDD, is it useful
      - aim
        - decide whether DDD was helpful or not
        - reflect on design decisions
        - advice to past me and others

# Post
# Summary
I review my implementation of the pandemic board game in C#, reflecting on some
design decisions from an earlier post. My implementation is more complex than
a reference implementation done with React.

# Intro
A long time ago, I started building the pandemic board game as a way of learning
domain-driven design (DDD): [original post]({{< ref "20210924_learning_ddd_by_implementing_pandemic" >}}).
I finally finished it! In this post I'll reflect on my early design decisions,
and whether the tactical patterns of DDD helped or not.

I will compare my implementation to [this React implementation](https://github.com/alexzherdev/pandemic).

# Reviewing my design decisions

## Fine-grained commands & events
At the end of my [original post]({{< ref "20210924_learning_ddd_by_implementing_pandemic" >}}),
I had gotten to a stage where I was confident that I could implement the rest of
the game without needing to make many more design decisions. I had found that
breaking the game rules down into fine-grained commands, handlers and events
made them easy to think about and therefore implement. This remained true. There
were a few rules that needed changes to a number of other areas of the program,
but they weren't too costly. This was also due to the way I implemented the
commands - very fine-grained. More on that later.

## How to handle events that trigger other events
Based on [Armadora](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07),
I decided to not to listen for & react to events. I thought doing this would
make chain reactions of events hard to debug & trace in code. Instead, command
handlers would deal with any side effects of events, calling other command
handlers if necessary.

This turned out to be a bit of a mistake. The react implementation reacts to its
own events, which made it very easy to decouple events and their side effects.

Most of the player commands were simple to implement. These are actions made by
a player in the game, that have few effects. An example is driving from one city
to another. In most cases, the only effect of this action is that a player moves
from one city to another.

The most complicated logic in the player commands dealt with conditional side
effects. For example, when curing a disease:

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
[Outbreak](https://github.com/uozuAho/pandemic_ddd/blob/00cf00f4ac76a0ce30583b25f4bf9b05d28943c7/pandemic/Aggregates/Game/CommandHandlers.cs#L824)
and
[EpidemicInfectCity](https://github.com/uozuAho/pandemic_ddd/blob/00cf00f4ac76a0ce30583b25f4bf9b05d28943c7/pandemic/Aggregates/Game/ProcessManagers.cs#L51)

Corresponding react impls:
[yieldOutbreak](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/diseaseSagas.js#L14)
[yieldEpidemic](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/diseaseSagas.js#L108)

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
- simple changes are verbose (more lines of code, see below)
- slow
  - initial perf testing shows that I'm allocating a lot of memory
  - tried mutable at one point, got a 4x speedup

```cs
// lots of lines to update immutable game when dispatcher moves a pawn
private static PandemicGame Apply(PandemicGame game, DispatcherMovedPawnToOther evt)
{
    var dispatcher = game.PlayerByRole(Role.Dispatcher);
    var playerToMove = game.PlayerByRole(evt.Role);
    var destinationPlayer = game.PlayerByRole(evt.DestinationRole);

    return game with
    {
        Players = playerToMove.Role == Role.Dispatcher
            ? game.Players.Replace(playerToMove, playerToMove with
            {
                Location = destinationPlayer.Location,
                ActionsRemaining = playerToMove.ActionsRemaining - 1
            })
            : game.Players.Replace(playerToMove, playerToMove with
            {
                Location = destinationPlayer.Location
            }).Replace(dispatcher, dispatcher with
            {
                ActionsRemaining = dispatcher.ActionsRemaining - 1
            })
    };
}

// mutable equivalent
private static PandemicGame Apply(PandemicGame game, DispatcherMovedPawnToOther evt)
{
    game.PlayerByRole(Role.Dispatcher).ActionsRemaining -= 1;
    game.PlayerByRole(evt.Role).Location = game.PlayerByRole(evt.DestinationRole).Location;
    return game;
}
```

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

Using [cloc](https://github.com/AlDanial/cloc), I compared the lines of code to
implement the game rules. I excluded tests & UI code:

DDD: 3935
react: 3092

I used [polyglot](https://polyglot.korny.info/) to analyse code complexity. The
react implementation scores very well! Mine's not bad, but worse than the react impl.

<figure>
  <img src="/blog/20230317_pandemic_ddd_revisited/20230317_pandemic_ddd_revisited_ddd_indent.png"
  alt=""
  width="892"
  loading="lazy" />
  <figcaption></figcaption>
</figure>

<figure>
  <img src="/blog/20230317_pandemic_ddd_revisited/20230317_pandemic_ddd_revisited_react_indent.png"
  alt=""
  width="885"
  loading="lazy" />
  <figcaption></figcaption>
</figure>

### Subjective
There's enough leeway in DDD to make mistakes. I think my choice to use very
granular move commands & events caused a bunch of accidental complexity. Eg:

Commands & associated events that move a player in my impl:
- airlift
- charter flight
- direct flight
- shuttle flight
- drive/ferry
- dispatcher versions of the above (yes, separate)
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

The tradeoff of granular commands is that handlers for very small, specific
commands are very clear and have less conditional code. Dealing with more
scenarios in a single handler results in more conditional code & complexity to
keep in your head. I prefer the react impl: there's really not that much variation
in what happens when a player moves, thus there's not too much conditional code,
and the react impl saves a lot of lines of code that my impl doesn't.

If I consolidated the above, and maybe reacted to events instead of adding
conditional logic to my command handlers, I may be able to get the line and and
complexity metrics down to a comparable level.

Some more comparisons:
    - Dispatcher move pawn
        - not much special handling:
            - [dispatcher chooses player to move](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/roleSagas.js#L51)
            - player is moved, consequences handled by event handlers:
                - [discard based on move type & current player](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/actionSagas.js#L29)
                    - also handles medic treat cured
    - Scientist cure: [same as rest](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/actionSagas.js#L146)
    - Cp use special event:
        - hard to understand, but dealt with [here](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/eventSagas.js#L46)
        - players reducer sets contingency planner card to null: https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/reducers/playersReducer.js#L62

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


# Other things I learned
- even though I'm not using event sourcing or even the events emitted by
  commands, they have been very useful to debug complex bugs. Having the entire
  event history of a game makes it easy to see where things have gone wrong.
  This would be laborious to step through in the debugger.
- using the rule to only modify aggregates via events has ensured that all game
  state changes are captured. It's a bit of a pain to add a command + handler +
  event + handler, but I think it's been worth it for the above point alone
