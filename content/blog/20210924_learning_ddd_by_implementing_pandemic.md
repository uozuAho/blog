---
title: "Learning DDD by making a board game"
date: 2021-09-24T16:40:58+10:00
draft: true
summary: "Learning the lower-level details of domain-drive design, through implementing the Pandemic board game"
tags:
- DDD
---

# todo
- clean up this post
- publish as part 1?
- add somewhere: biggest help from DDD was breaking game rules into small bits -
  events
- compare my DDD description with other known sources
  - armadora
  - MYOB general dev docs
- collapsible code blocks?
- make sure all refs are included at the end
- table of contents?
- 'skip to the details' somewhere in the intro
- compare to my other pandemic impl

I've tried a number of times to implement the board game
[Pandemic](https://en.wikipedia.org/wiki/Pandemic_%28board_game%29), so that I
can set AI upon it. I've failed each time, due to the complexity of the game
rules causing my code to turn into a complex ball of mud. Recently I've been
inspired to try again, after having the idea that domain-driven design (DDD) may
help me deal with the complexity.

I've known of domain-driven design (DDD) for years, but had never looked closely
into it. I had a very basic understanding of some DDD concepts, such as breaking
complex systems into 'bounded contexts', and using 'anti corruption layers' to
keep your domain model clean, but that was about it. It was only after starting
work on this post that I realised that DDD also has many low-level concepts that
can be applied even within small applications, such as board games!

This post will focus on these low-level 'tactical' aspects of DDD. Note that
there is much more to DDD than just low level details - see the references at
the end of this post. Another disclaimer - I haven't read the authoritative
source on DDD - the ['Blue book'](https://www.goodreads.com/book/show/179133.Domain_Driven_Design)
by Eric Evans. I've heard it's long and boring, and it's nearly 20 years old.
Most of the information in this post has come from various online sources, which
I'll link throughout and at the end of the post.


# It's been done
A quick search revealed that someone else had already tried DDD on another board
game. See [DDD in action: Armadora - The board game](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07).
This was just the example I needed to see how the concepts could be applied for
someone new to DDD. However the simplicity of the Armadora game left me
wondering how more complex games like pandemic would be implemented. For
example, in Pandemic, if you pick up an 'epidemic' card, a chain reaction of
events can occur, based on certain conditions:

<figure>
  <img src="/blog/20210924_learning_ddd/end_turn_with_epidemic_flow.png"
  alt=""
  width="773"
  loading="lazy" />
  <figcaption>Some game rules at the end of a player's turn</figcaption>
</figure>

The flowchart above does not even show all the game rules: there are checks for
game end, outbreaks can occur when cities are infected, event cards may be
played, and more!

I also found what looks to be a [complete implementation of Pandemic](https://github.com/alexzherdev/pandemic),
using React & Redux. You can play it online [here](https://epidemic.netlify.app/play).
I don't think DDD was an influence on the game itself, however it was useful to
have as another reference.


# Tactical DDD crash course
Before I go any further, I'll introduce some DDD terms that I'll be using for
the rest of the post.

## Domain
The domain is the problem to be solved, and its surrounding context. In my case,
the domain is the Pandemic board game and its rule book. The people working in
the domain should have a shared understanding of the domain model. It should be
described in non-technical, jargon-free language that everyone can understand.
This 'ubiquitous language' (another DDD term) should be used when discussing
the domain model. Since I'm the only one working in the domain, the Pandemic
rule book will be my domain expert, and I will use language within the rules
when naming the software objects I create to build the game.

## Domain event
A domain event can be any event of interest within the domain. An event is a
result of some action within the domain. For example, in Pandemic, when a player
moves from one city to another, this can be described as a 'player moved' event.
The event contains information about what occurred, eg. which player moved, and
which cities they moved from and to.

## Event storming
Typically, event storming is a session where domain, product, and technical
experts come together to explore and model a domain, starting by brainstorming
events that can occur within the domain.

In my case, these will be little 'pen & paper' sessions where I map out a
sequence of game events and subsequent side effects.

- [Wikipedia: Event storming](https://en.wikipedia.org/wiki/Event_storming)

## Value objects and entities
A value object is an object that is identified by its attributes. If two value
objects have the same attributes, then they are considered equal. For example,
two value objects both representing the same 2D coordinate (1, 2) are considered
to be the same object.

Entities, on the other hand, are identified by some unique identifier. Two
entities with all attributes equal apart from their unique identifier are still
considered to be separate entities. For example, two people with the name 'Jane
Doe' are still two individual people.

- [Enterprise Craftsmanship: Entity vs Value Object: the ultimate list of differences](https://enterprisecraftsmanship.com/posts/entity-vs-value-object-the-ultimate-list-of-differences/)
- [Enterprise Craftsmanship: C# 9 Records as DDD Value Objects](https://enterprisecraftsmanship.com/posts/csharp-records-value-objects/)
    - spoiler: C# records _may_ be a good fit for some value objects, but not in
      all cases. Same story for structs.

## Aggregate
An aggregate is a collection of entities and/or value objects that can be
treated as an individual unit. An example could be an online shopping cart,
which may contain multiple products.

More importantly, an aggregate forms a 'consistency boundary'. The aggregate
ensures that it remains internally consistent. For example, if your domain
contains a rule that a + b = c, then a, b, and c should be within the same
aggregate. The aggregate is responsible for making sure that whenever a or b are
modified, c is updated.

Aggregates process commands, which potentially modify their state. Domain events
can be emitted as a result of these commands. The rest of the domain can listen
for these events and respond to them accordingly, keeping the domain consistent
with as aggregates change.

- [Vaughn Vernon: modeling a single aggregate (pdf)](https://www.dddcommunity.org/wp-content/uploads/files/pdf_articles/Vernon_2011_1.pdf)

## Event sourcing
Not necessarily a part of DDD, however it can be a good fit. The idea is that
application state is stored in an append-only log of events. If the state of the
application at a point in time is needed, it can be built from the log of
events.

## Sagas and process managers
**todo**: needs work

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

- for complex processes, process managers can be used to coordinate the event
  routing and issuing of consequent commands. Process managers can also be
  called sagas, however it's an overloaded term. See
  https://docs.microsoft.com/en-us/previous-versions/msp-n-p/jj591569(v=pandp.10)


Interestingly, someone's
already made the game using react & redux:
[pandemic](https://github.com/alexzherdev/pandemic). The complex processes are
handled by [redux-saga](https://redux-saga.js.org/)s. I don't think this game is
following DDD, but is a useful reference. It's also well done! Have a play!


# Applying DDD tactics to Pandemic
OK, I've read enough, now it's time to implement this thing (again)! Some
initial decisions:

- I'll use one aggregate to represent the current state of the game
- I'll use event sourcing, mainly as I've never used it before, and it appears
  to remove some of the hassle of state management, and keep the code more
  functional (as in functional programming).
- C#. I'm most familiar with C#, and I'd like to get more experience with some
  of its newer functional capabilities (mainly records and pattern matching).

OK, I think I've got enough to start. My goal for now is to implement enough
game rules to be able to play a game to completion. I'll pick the simplest rules
to start with. Once that's done, I can start adding rules incrementally, until
I've implemented the whole game.

As discussed earlier, I'm not sure where all the complexity of the Pandemic game
rules should go. My current understanding is that if I am using a single
aggregate to represent the game state, then it will be responsible for keeping
itself internally consistent. To me, that means implementing all the rules
within the aggregate. I am a little worried about creating the same ball of mud
as I have before, but I think the process of breaking down the rules into
discrete commands and events will help keep the corresponding code manageable.
If the aggregate is getting too large, one idea is to move some of the complex
game processes to process managers.

**todo: fix this for dark**
> Side note:
> One of my doomed attempts to implement pandemic is actually a
> [fork of the above project](https://github.com/uozuAho/pandemic). I was trying
> to get it to play headless (without a human operator), but kept running into
> coupling with the UI that was hard to untangle.


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

## First complex process
After a few hours of coding simple events, I've now come to an interesting
point: how to handle when a player does their last action? Here's what my
current `DriveOrFerryPlayer` command looks like:

```cs
public static IEnumerable<IEvent> DriveOrFerryPlayer(List<IEvent> log, Role role, string city)
{
    if (!Board.IsCity(city)) throw new InvalidActionException($"Invalid city '{city}'");

    var state = FromEvents(log);
    var player = state.PlayerByRole(role);
    if (!Board.IsAdjacent(player.Location, city))
    {
        throw new InvalidActionException(
            $"Invalid drive/ferry to non-adjacent city: {player.Location} to {city}");
    }

    yield return new PlayerMoved(role, city);

    // todo: handle when this was the player's last action
}
```


To make things easier, I won't consider all the rules as shown in the earlier
flowchart. Here's a simplified version:

<figure>
  <img src="/blog/20210924_learning_ddd/end_turn_flow_simple.png"
  alt=""
  width="250"
  loading="lazy" />
  <figcaption>A simplified 'end of player turn' flow</figcaption>
</figure>

I did a 'mini event storming' to determine commands and events involved. For
now, there's only one aggregate (the game), so I've omitted it from the image.
Commands with no human player next to them are issued by the 'game'.

<figure>
  <img src="/blog/20210924_learning_ddd/end_turn_flow_simple_event_storm.png"
  alt=""
  width="492"
  loading="lazy" />
  <figcaption>Event storming a simple 'end of player turn' flow.
  Commands are blue, events are orange.</figcaption>
</figure>

As decided earlier, I'll put all the logic into the aggregate. This means the
aggregate will be responsible for issuing commands like 'infect city'. This is
what Armadora's command handlers do.

Now, to deal with the events that occur after a player has completed their
fourth action:

```cs
public static IEnumerable<IEvent> DriveOrFerryPlayer(List<IEvent> log, Role role, string city)
{
    if (!Board.IsCity(city)) throw new InvalidActionException($"Invalid city '{city}'");

    var state = FromEvents(log);
    var player = state.PlayerByRole(role);

    if (player.ActionsRemaining == 0)
        throw new GameRuleViolatedException($"Action not allowed: Player {role} has no actions remaining");

    if (!Board.IsAdjacent(player.Location, city))
    {
        throw new InvalidActionException(
            $"Invalid drive/ferry to non-adjacent city: {player.Location} to {city}");
    }

    yield return new PlayerMoved(role, city);

    if (player.ActionsRemaining == 1)
    {
        // todo: pick up cards from player draw pile here
        yield return new PlayerCardPickedUp(role, new PlayerCard("Atlanta"));
        yield return new PlayerCardPickedUp(role, new PlayerCard("Atlanta"));
        foreach (var @event in InfectCity(log))
        {
            yield return @event;
        }
        foreach (var @event in InfectCity(log))
        {
            yield return @event;
        }
    }
}

public static IEnumerable<IEvent> InfectCity(List<IEvent> log)
{
    var state = FromEvents(log);
    var infectionCard = state.InfectionDrawPile.Last();
    yield return new InfectionCardDrawn(infectionCard.City);
    yield return new CubeAddedToCity(infectionCard.City);
}
```

It's not as bad as I thought it would be! The `PandemicGame` aggregate is
getting large (200 lines so far), but all the code seems to belong to it. I
could split out the event and command handlers, but I won't for now. Let's keep
going!


# Moving away from event sourcing
The event sourcing approach is making testing difficult. I want to be able to
set up a near-end game state to be able to assert game ending scenarios. With my
current implementation, the only way to create a game aggregate is from an event
log. Although this ensures aggregate is in a valid state, it makes setting up
these test scenarios laborious, and I will need to constantly tweak the test
setup as I add more game rules, to ensure that the events leading to the
game-ending state are valid.

I have decided to stop using event sourcing, and instead pass the current game
state to command handlers. Having an event log is useful for debugging purposes,
so I will keep emitting events for all modifications of the game state. Being
able to create the game aggregate in an invalid state is a hazard, but for my
purposes is very handy for testing. I wonder if there's a way to disable the
usage of dangerous constructors in production code? I'll put that on the 'to do
later' pile.

... many hours later ....

Here's a work in progress, while moving away from event sourcing:

```cs
public (PandemicGame, ICollection<IEvent>) DriveOrFerryPlayer(Role role, string city)
{
    if (!Board.IsCity(city)) throw new InvalidActionException($"Invalid city '{city}'");

    var player = PlayerByRole(role);

    if (player.ActionsRemaining == 0)
        throw new GameRuleViolatedException($"Action not allowed: Player {role} has no actions remaining");

    if (!Board.IsAdjacent(player.Location, city))
    {
        throw new InvalidActionException(
            $"Invalid drive/ferry to non-adjacent city: {player.Location} to {city}");
    }

    var (currentState, events) = ApplyEvents(new PlayerMoved(role, city));

    // todo: extract to method
    if (player.ActionsRemaining == 1)
    {
        // todo: pick up cards from player draw pile here
        var (asdf, newEvents) = currentState.ApplyEvents(
            new PlayerCardPickedUp(role, new PlayerCard("Atlanta")),
            new PlayerCardPickedUp(role, new PlayerCard("Atlanta")));

        currentState = asdf;
        foreach (var @event in newEvents)
        {
            events.Add(@event);
        }

        currentState = InfectCity(currentState, events);
        currentState = InfectCity(currentState, events);
    }

    return (currentState, events);
}
```

I've hit a bit of a challenge:
- lots of side effects hanging off DriveOrFerryPlayer
- without event sourcing, state has to be updated as I go
- I need to be able to pass around 'current state' to various methods, which
  is me use a mix of 'this' and 'current state'. It's looking yuck

This is what I settled on for now:

```cs
public (PandemicGame, ICollection<IEvent>) DriveOrFerryPlayer(Role role, string city)
{
    if (!Board.IsCity(city)) throw new InvalidActionException($"Invalid city '{city}'");

    var player = PlayerByRole(role);

    if (player.ActionsRemaining == 0)
        throw new GameRuleViolatedException($"Action not allowed: Player {role} has no actions remaining");

    if (!Board.IsAdjacent(player.Location, city))
    {
        throw new InvalidActionException(
            $"Invalid drive/ferry to non-adjacent city: {player.Location} to {city}");
    }

    var (currentState, events) = ApplyEvents(new PlayerMoved(role, city));

    if (player.ActionsRemaining == 1)
        currentState = DoStuffAfterActions(currentState, events);

    return (currentState, events);
}

private static PandemicGame DoStuffAfterActions(PandemicGame currentState, ICollection<IEvent> events)
{
    currentState = PickUpCard(currentState, events);
    currentState = PickUpCard(currentState, events);

    currentState = InfectCity(currentState, events);
    currentState = InfectCity(currentState, events);

    return currentState;
}
```

It's working for me. It's not as pretty as I'd hoped.
- in a state now where i think I can keep adding game rules, ddd done for now,
  publish?
- alternative: add list of events to aggregate
- good thing that ddd encouraged: breaking complex game rules into sequence of
  small events. Kept most rule handlers small.
- todo: compare to my other impl.

# Q & A
**todo** figure out where to put this

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

- Should command handlers/services only do the plumbing between aggregates
  and event stores etc.? I feel like the answer is yes.
    - [this answer](https://softwareengineering.stackexchange.com/questions/368358/can-an-aggregate-only-ever-consume-commands-and-produce-events)
      indicates that sagas/process managers are the missing piece here. They
      consume the current state, and decide what happens next, including
      issuing more commands. See [[process manager/saga | 202109241515_process_manager_saga]]


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

# References
- [Pandemic](https://en.wikipedia.org/wiki/Pandemic_%28board_game%29)
- [Pandemic rules](https://www.ultraboardgames.com/pandemic/game-rules.php)
- [DDD in action: Armadora - The board game](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07).
    - [Armadora code](https://github.com/ThomasFerro/armadora)
- [Wikipedia: DDD](https://en.wikipedia.org/wiki/Domain-driven_design)
- [Thomas Fero: summary of a four days ddd training](https://dev.to/thomasferro/summary-of-a-four-days-ddd-training-5a3c)
- domain events
    - [MSDN: Domain events: design and implementation](https://docs.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation)
- entities, value objects
    - [Enterprise Craftsmanship: Entity vs Value Object: the ultimate list of differences](https://enterprisecraftsmanship.com/posts/entity-vs-value-object-the-ultimate-list-of-differences/)
    - [Enterprise Craftsmanship: C# 9 Records as DDD Value Objects](https://enterprisecraftsmanship.com/posts/csharp-records-value-objects/)
- aggregates
    - [Vaughn Vernon: modeling a single aggregate (pdf)](https://www.dddcommunity.org/wp-content/uploads/files/pdf_articles/Vernon_2011_1.pdf)

# Further reading
- The original DDD book ('The Blue Book') by Eric Evans: [Domain-Driven Design](https://www.goodreads.com/book/show/179133.Domain_Driven_Design)
    - Comes highly recommended as the authoritative source for DDD, however has
      a reputation for being too long and boring.
- [Implementing Domain Driven Design - Vaughn Vernon](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon/dp/0321834577)
    - Apparently a shorter and more practical book than the original
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
