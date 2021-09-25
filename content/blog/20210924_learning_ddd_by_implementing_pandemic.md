---
title: "Learning DDD by implementing Pandemic"
date: 2021-09-24T16:40:58+10:00
draft: true
summary: "Learning DDD through implementing the Pandemic board game"
tags:
- DDD
---

# todo
- how to handle when player does last action?
  - command handler?
  - event handler?
  - something else?
- try to get a game running to completion (section: let's have a go)
  - player moves back and forth, die by infect/cubes
- clean up this post
- publish as part 1?

Something that has become increasingly relevant. It's a major influence on the
systems I'm using at work (MYOB), and my recent attempt at implementing a board
game (pandemic) has got me interested in whether its ideas can be used.

I've had the [Pandemic](https://en.wikipedia.org/wiki/Pandemic_%28board_game%29)
board game for a long time now, and have always wondered if I could make an AI
agent that could figure out the optimal policy. To do this though, I need a
working implementation of the game. I've tried a few times to implement it
myself, but have always stumbled at the point of implementing some of the
complex chains of events that can occur. I couldn't figure out a neat way to
organise the events.

I had heard of domain-driven design (DDD), but never looked into the details.
For some reason, I eventually had the idea that using DDD may help me design an
elegant implementation of the complex game rules.

This post won't be an in-depth study of DDD, rather, a cherry-picked collection
of DDD tactics. I've heard the 'blue book' is a slog, and I'm impatient :)


# It's been done
Thomas Ferro used the same approach to implement a simpler game in
[DDD in action: Armadora - The board game](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07).
This was an illuminating post for me, however the simplicity of the Armadora
game left me wondering how more complex games like pandemic would be
implemented. For example, in Pandemic, if you pick up an 'epidemic' card, a
chain reaction of events can occur, based on certain conditions:

<figure>
  <img src="/blog/20210924_learning_ddd/pandemic_epidemic_flow.png"
  alt=""
  width="773"
  loading="lazy" />
  <figcaption>Some game rules at the end of a player's turn</figcaption>
</figure>

The flowchart above does not even show all the game rules: there are checks for
game end, outbreaks can occur when cities are infected, event cards may be
played, and more!

Where should all this complexity go? All in the aggregates? What I've read so
far indicates that ideally, aggregates should only return domain events upon
receiving a command, and remain blissfully unaware of other aggregates, routing
of events to handlers etc.

Does that mean the command handlers should manage the flow of events?
Alternatively, should I use process managers / sagas? Interestingly, someone's
already made the game using react & redux:
[pandemic](https://github.com/alexzherdev/pandemic). The complex processes are
handled by [redux-saga](https://redux-saga.js.org/)s. I don't think this game is
following DDD, but is a useful reference. It's also well done! Have a play!

Redux sagas appear to run in a similar way to process managers. They listen for
particular events, and when received, proceed through a defined process that
may trigger side effects and emit more events.
- eg. [saga: movedToCity](https://github.com/alexzherdev/pandemic/blob/364a516d9b9455283a4c3c59bc7cd829b27ff7ce/src/sagas/actionSagas.js#L29)
    - listens for the `ANIMATION_MOVE_COMPLETE` action (event)
    - discards a player card if a direct or charter flight action was used
    - waits for animation of the above action to complete
    - removes disease cubes if the current player is the medic and the disease
      has been cured
    - emits a 'move complete' action

Side note:
Saga is an overloaded term. In this [MSDN article](https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj591569(v=pandp.10)?redirectedfrom=MSDN),
they prefer the term 'process manager' when talking about DDD concepts, to
distinguish the original meaning of an alternative to distributed transactions.

Side note:
**todo** can I make side notes appear differently??
One of my doomed attempts to implement pandemic is actually a
[fork of the above project](https://github.com/uozuAho/pandemic). I was trying
to get it to play headless (without a human operator), but kept running into
coupling with the UI that was hard to untangle.


# Q & A
## how to handle events that trigger other events?
Eg. when the current player does their final action, there are a number of
things that happen next: they pick up cards, and infection cards are revealed.
How to model/implement this in an elegant way?

In [[202109232032_armadora_ddd_board_game]], commands can return multiple
events. These are placed in order on the event log. That's it! Because it uses
event sourcing, the placing of events on the log is what updates the game state.
The `Game` aggregate has a 'replay history' function that builds the current
game state by materializing/folding the event log. In this implementation,
events do not emit more events. Only commands return events. Commands can call
other commands, eg. see [pass turn](https://github.com/ThomasFerro/armadora/blob/84db3e24a57aaccad72953ae3ab484f410663bec/server/game/command/pass_turn.go#L23)
This does appear to embed game logic into the command handlers though.

If the event sourcing approach above is inefficient, it should be easy to extend
the above to keep a persistent 'current' game aggregate that gets mutated with
each processed event.

I'm still not happy with this answer. In [[202109232032_armadora_ddd_board_game]],
commands can emit multiple events and call other commands. This appears to embed game logic in
command handlers though. Shouldn't this all be in the aggregate?

- Should aggregates contain _all_ business logic?
- Should command handlers/services only do the plumbing between aggregates
  and event stores etc.? I feel like the answer is yes.
    - [this answer](https://softwareengineering.stackexchange.com/questions/368358/can-an-aggregate-only-ever-consume-commands-and-produce-events)
      indicates that sagas/process managers are the missing piece here. They
      consume the current state, and decide what happens next, including
      issuing more commands. See [[process manager/saga | 202109241515_process_manager_saga]]

## can DDD be used here? or is DDD for more complex/distributed domains?
The entire DDD toolset is probably a bit much for a board game, as there doesn't
need to be interaction with domain experts. The domain is already completely
specified in the game's rule book! However, some of the 'tactics' of DDD are
useful. For a worked example, see [[202109232032_armadora_ddd_board_game]].

## do I need event sourcing?
Event sourcing is not necessary, but is a good fit. [[202109232032_armadora_ddd_board_game]]
uses event sourcing.

## when exactly should events be sent?
- when aggregate changes need to be committed. This is not a concern of an
  aggregate. Examples:
    - [wikipedia: DDD](https://en.wikipedia.org/wiki/Domain-driven_design)
      says that aggregates are responsible for mutating themselves and
      returning consequent events, and command handlers are responsible for
      persisting/ publishing those changes
    - [[202109222152_dont_publish_domain_events_return_them]]
- should commands modify aggregates, or should emitted events modify
  aggregates? Seems to depend
    - event sourcing requires all state changes are done via events
        - see [[202109222152_dont_publish_domain_events_return_them]]
    - wikipedia says aggregates are responsible for mutating themselves (see
      above)
    - same with both: changes to aggregates and publishing of events must be
      done atomically


# A DDD crash course
I decided to do a bit of reading before trying to work things out for myself.
Here's what I've learned so far:

- the domain model is made up of aggregates, which implement business rules. In
  this case, the pandemic board game rules form the domain model.
- an aggregate is a collection of objects that can be treated as a unit. I'll
  use one aggregate - the current state of the game.
- aggregates process commands, by mutating their state, and returning domain
  events
    - alternatively, an event sourcing approach can keep aggregate command
      handlers pure, using only domain events to modify the game state
- for complex processes, process managers can be used to coordinate the event
  routing and issuing of consequent commands. Process managers can also be
  called sagas, however it's an overloaded term. See
  https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj591569(v=pandp.10)


# Let's have a go
OK, I think I've got enough to start. My goal for now is to implement enough
game rules to be able to play a game to completion. I'll pick the simplest rules
to start with. Once that's done, I can start adding rules incrementally, until
I've implemented the whole game. I'll use:

- TDD
- Event storming
- Event sourcing
  - I may change this ... having the current game state sounds handy. However,
    it'd be interesting to try
- Synchronous event handling, keeping as much as possible in the game aggregate
- C#, including some newer functional capabilities I'm not too familiar with
- nothing distributed - no DB or message queues. This removes a lot of the
  complexity DDD was intended for, but makes my life easy


## Baby steps
Here's my initial aggregate:

```cs
public record PandemicGame
{
    public Difficulty Difficulty { get; init; }

    // create a game state from an event log
    public static PandemicGame FromEvents(IEnumerable<IEvent> events) =>
        events.Aggregate(new PandemicGame(), Apply);

    // commands yield events
    public static IEnumerable<IEvent> SetDifficulty(List<IEvent> log, Difficulty difficulty)
    {
        yield return new DifficultySet(difficulty);
    }

    // Game state is modified by events. Return a new object instead of mutating.
    public static PandemicGame Apply(PandemicGame pandemicGame, IEvent @event)
    {
        return @event switch
        {
            DifficultySet d => pandemicGame with {Difficulty = d.Difficulty},
            _ => throw new ArgumentOutOfRangeException(nameof(@event), @event, null)
        };
    }
}
```

After a few hours of coding simple events, I've now come to an interesting
point: how to handle when a player does their last action? To make things
easier, I won't consider all the rules as shown in the flowchart above. Here's
a simplified version:

<figure>
  <img src="/blog/20210924_learning_ddd/pandemic_epidemic_flow_simple.png"
  alt=""
  width="250"
  loading="lazy" />
  <figcaption>A simplified 'end of player turn' flow</figcaption>
</figure>


# References
- [Pandemic](https://en.wikipedia.org/wiki/Pandemic_%28board_game%29)
- [Pandemic rules](https://www.ultraboardgames.com/pandemic/game-rules.php)
- [DDD in action: Armadora - The board game](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07).
    - [Armadora code](https://github.com/ThomasFerro/armadora)


# Further reading
- play with boardgame.io, eg. chess: https://github.com/boardgameio/boardgame.io/tree/main/examples/react-web/src/chess
    - to answer/explore
        - user provides `G`: this is the 'game' aggregate?
        - user defines commands, which can emit events (DDD wording)
        - events are processed after commands
        - what is `ctx`, from a DDD POV?
        - how do events get processed? can they trigger more events?
    - answered
        - 'moves' are commands issued by players (DDD commands)
        - events are emitted by moves, and placed in a queue for processing: https://boardgame.io/documentation/#/events
