---
title: "Learning DDD by making Pandemic"
date: 2021-09-24T16:40:58+10:00
draft: true
summary: "Learning the lower-level details of domain-drive design, through implementing the Pandemic board game"
tags:
- DDD
---

# todo
- proof read sweep 1: up to 'moving away from event sourcing'
- add near the start: skip to 'lets just start' if you want
- does this need to go anywhere?:
  - When exactly should events be sent?
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
- add links to ddd concepts appendix
- center images
- does navigating to/from header links work nicely?
- domain event: only events domain experts care about?
  - what if there are events that are useful to manage the software?
- make sure all refs are included at the end

Join me on my quest to learn some DDD while making a board game. This is my
longest post yet, so I've included a table of contents for your convenience :)

# Contents
{{< toc >}}

# Intro
I have tried a number of times to implement the board game
[Pandemic](https://en.wikipedia.org/wiki/Pandemic_%28board_game%29), so that I
can set AI upon it. Each attempt was a failure, due to the complexity of the
game rules causing my code to turn into a complex ball of mud. Recently I have
been inspired to try again, after having the idea that [domain-driven design
(DDD)](https://en.wikipedia.org/wiki/Domain-driven_design) may help me deal with
the complexity.

I have known of domain-driven design for years, but had never looked closely
into it. I had a very basic understanding of some DDD concepts, such as breaking
complex systems into 'bounded contexts', and using 'anti corruption layers' to
keep the domain model clean, but that was about it. It was only after starting
work on this post that I realised that DDD covers a huge landscape of software
development, including many low-level concepts that can be applied even within
small applications, such as board games!

In this post I will focus on some of these low-level 'tactical' aspects of DDD,
and implementing them in C#. Note that these low level details are only a small
part of DDD as originally described by Eric Evans in his now famous ['Blue
book'](https://www.goodreads.com/book/show/179133.Domain_Driven_Design). See the
references and further reading section at the end of this post for more
resources on DDD.

A disclaimer before I go on: I haven't read Eric Evans's book. It has a
reputation for being long and boring, and I was keen to get started. Most of the
information in this post has come from various online sources, which are linked
throughout and at the end of this post.


# It's been done
A quick search revealed that someone else had already tried DDD on another board
game. In [DDD in action: Armadora - The board
game](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07),
Thomas Ferro describes how he implemented a simple board game using DDD concepts
and event sourcing. This post, accompanied by [Summary of a four days DDD
training](https://dev.to/thomasferro/summary-of-a-four-days-ddd-training-5a3c)
were just the crash course I needed to see how the concepts could be applied for
someone new to DDD. However, the simplicity of the Armadora game left me
wondering how more complex games like pandemic would be implemented.

I also found what looks to be a [complete implementation of
Pandemic](https://github.com/alexzherdev/pandemic), using React & Redux. You can
play it online [here](https://epidemic.netlify.app/play). Have a go, it's really
well done! I don't think DDD was an influence on this implementation, however it
was useful to have as another reference.


# Applying DDD tactics to Pandemic
My stumbling point in the past has been the complex game rules of Pandemic.
Certain player actions result in chain reactions of side effects. For example,
in Pandemic, if you pick up an 'epidemic' card, a series of events can occur,
based on certain conditions:

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

One way DDD attempts to simplify complex domains is by breaking down complex
processes such as the one above into sequences of 'domain events'. A domain
event represents any change to the system. Events are emitted as a result of
commands issued within the system. Using the above flowchart as an example,
the player issues the 'do action' command. If it was the player's last action,
then two 'card drawn' events could be emitted. If either of those cards were an
epidemic card, then more epidemic events are emitted.


## How to handle events that trigger other events
Breaking down the complex rules into small commands and events sounds like a
good way to keep the underlying software parts small and manageable. However,
I'm worried about managing and debugging the explosion of events that may occur.
Are events supposed to trigger other events in DDD?

From what I've read so far, a domain model in DDD is made up of 'aggregates',
which are always internally consistent. Multiple aggregates are brought into a
consistent state asynchronously, by the publishing of domain events. So in
theory, an endless sequence of domain events could be emitted as multiple
aggregates react to events sent by other aggregates. Presumably this is an
undesirable condition to find your software in.
[Armadora](https://dev.to/thomasferro/ddd-in-action-armadora-the-board-game-2o07)
uses a single aggregate to represent the current state of the game, thus
removing the complication of keeping multiple aggregates in sync. Additionally,
events do not trigger any other events. Commands may emit multiple events, and
I found one example of a [command calling another command](https://github.com/ThomasFerro/armadora/blob/84db3e24a57aaccad72953ae3ab484f410663bec/server/game/command/pass_turn.go#L38).
This is what I will do for now.


## Let's just start
OK, I think I have got enough to start. I'll figure out the rest as I go. To
start, I will use:

- one aggregate to represent the current state of the game
- immutable everything, including aggregates and entities. This does not follow
  DDD, but will be useful for AI algorithms that will need to search and keep
  track of many game states.
- event sourcing, mainly as I've never used it before, and it appears to remove
  some of the hassle of state management, and keep the code more functional (as
  in functional programming)
- C#, as I'm most familiar with it, and I would like to get more experience with
  some of its newer functional capabilities (mainly records and pattern
  matching)

My goal for now is to implement enough game rules to be able to play a game to
completion. I will pick the simplest rules to start with. Once that's done, I
can start adding rules incrementally, until the whole game is implemented.

Since an aggregate is responsible for maintaining its own consistency, I think I
need to implement all command handlers in the aggregate. I am a little worried
about how big the aggregate is going to be, but I think the process of breaking
down the rules into discrete commands and events will help keep the
corresponding code manageable.


## Baby steps
Here's my initial aggregate:

```cs
// My one aggregate - the state of the game
public record PandemicGame
{
    public Difficulty Difficulty { get; init; }

    // Create the game aggregate from an event log
    public static PandemicGame FromEvents(IEnumerable<IEvent> events) =>
        events.Aggregate(new PandemicGame(), Apply);

    // This is the 'set difficulty' command. Commands yield events.
    // Since I am using event sourcing, there is no need to mutate the
    // aggregate within the commands. The current state of the aggregate can
    // be built on demand from the event log.
    public static IEnumerable<IEvent> SetDifficulty(List<IEvent> log, Difficulty difficulty)
    {
        yield return new DifficultySet(difficulty);
    }

    // 'Apply' an event to the aggregate. Returns an updated aggregate.
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
point: how to implement the sequence of events that occur when a player does
their last action? Here's what my current `DriveOrFerryPlayer` command looks
like:

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

I did a mini [event storming]({{< ref "#event_storming" >}}) to determine
commands and events involved in the above flowchart. There's only one aggregate
(the game), so I've omitted it from the image. Commands with no human player
next to them are issued by the 'game'.

<figure>
  <img src="/blog/20210924_learning_ddd/end_turn_flow_simple_event_storm.png"
  alt=""
  width="492"
  loading="lazy" />
  <figcaption>Event storming a simple 'end of player turn' flow.
  Commands are blue, events are orange.</figcaption>
</figure>


Here's the `DriveOrFerryPlayer` command after adding the above events:

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

    // This looks a little weird - why isn't this block executed when the player
    // has zero actions remaining? Because the `PlayerMoved` event emitted above
    // does not affect the state of the aggregate built from the event log at
    // the start of this method. We know that the player will have one less
    // action after the `PlayerMoved` event is applied, thus this block needs to
    // execute when the player initially had 1 action remaining.
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

private static IEnumerable<IEvent> InfectCity(List<IEvent> log)
{
    var state = FromEvents(log);
    var infectionCard = state.InfectionDrawPile.Last();
    yield return new InfectionCardDrawn(infectionCard.City);
    yield return new CubeAddedToCity(infectionCard.City);
}
```

It's not as bad as I thought it would be! I separated out the private
`InfectCity` command for convenience. It's not a command a player can issue, but
makes the `DriveOrFerryPlayer` code easier to understand from a domain
perspective. The aggregate is getting large (200 lines so far), but all the code
seems to belong to it.


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

As per my current understanding of DDD, my `PandemicGame` class is the
aggregate. It contains the entire game state, as a graph of entities and value
objects. I have made it immutable, since this will come in handy when building
AI agents that will need to explore a tree of game states, potentially keeping
track of many individual game states at a time. This goes against the DDD
literature I have read so far, which states that aggregates and entities can
mutate their own state via commands. I don't see a downside to keeping
everything immutable at this stage. Here's the data in the aggregate:

```cs
public record PandemicGame
{
    public bool IsOver { get; init; };
    public Difficulty Difficulty { get; init; }
    public int InfectionRate { get; init; }
    public int OutbreakCounter { get; init; }
    public int CurrentPlayerIdx { get; init; }
    public ImmutableList<Player> Players { get; init; }
    public ImmutableList<City> Cities { get; init; }
    public ImmutableList<InfectionCard> InfectionDrawPile { get; init; }
    public ImmutableList<InfectionCard> InfectionDiscardPile { get; init; }
    public ImmutableDictionary<Colour, int> Cubes { get; init; } =
        Enum.GetValues<Colour>().ToImmutableDictionary(c => c, _ => 24);
```

There are many command and event handlers on the aggregate, but they are all
following an emerging pattern:

```cs
// Command handlers are public methods on the aggregate. They take parameters
// relevant to the command, and return a new game aggregate and a collection of
// events that occurred as a result of the command.
public (PandemicGame, ICollection<IEvent>) Command(arg1, arg2, ...) {}

// Event handlers are private static methods (pure functions) that apply a
// single event to the given aggregate, returning a resultant aggregate.
private static PandemicGame HandleEvent(PandemicGame game, IEvent @event) {}

// 'Internal command handlers' are convenient ways to break down larger
// commands, that involve many events and conditional logic.
private static PandemicGame InternalCommand(
    PandemicGame currentState,
    ICollection<IEvent> events) {}
```

Let's see it in action. This is the current state of my `DriveOrFerryPlayer`
command handler, which needs to perform a number of actions when the player has
performed the last action for their turn:

```cs
public (PandemicGame, ICollection<IEvent>) DriveOrFerryPlayer(Role role, string city)
{
    if (!Board.IsCity(city))
        throw new InvalidActionException($"Invalid city '{city}'");

    var player = PlayerByRole(role);

    if (player.ActionsRemaining == 0)
        throw new GameRuleViolatedException(
            $"Action not allowed: Player {role} has no actions remaining");

    if (!Board.IsAdjacent(player.Location, city))
    {
        throw new InvalidActionException(
            $"Invalid drive/ferry to non-adjacent city: {player.Location} to {city}");
    }

    var (currentState, events) = ApplyEvents(new PlayerMoved(role, city));

    if (currentState.CurrentPlayer.ActionsRemaining == 0)
        currentState = DoStuffAfterActions(currentState, events);

    return (currentState, events);
}

private static PandemicGame DoStuffAfterActions(
    PandemicGame currentState,
    ICollection<IEvent> events)
{
    currentState = PickUpCard(currentState, events);
    currentState = PickUpCard(currentState, events);

    currentState = InfectCity(currentState, events);
    currentState = InfectCity(currentState, events);

    return currentState;
}
```

I think `DriveOrFerryPlayer` is going to continue to grow as I add more game
logic. I'm a little worried about that. I _could_ move it to a process manager,
but that would just result it a complicated process manager. Additionally, I
think the purpose of a process manager is to orchestrate effects across multiple
aggregates, which I don't have.

I don't really like the difference in method signatures between the public and
private command handlers. I like that the public handlers from a consumer point
of view: you issue a command, and receive an updated aggregate and associated
events. The private command handlers make handling multiple intermediate states
easier though, such as the check for the player's final action in
`DriveOrFerryPlayer`. Additionally, the private command handlers make it easier
to append multiple events to the same list, instead of having to unpack the
events returned by the public handlers.




# Conclusion
Anyway, I'm at a point where I think I can continue to incrementally add game
rules until I have a full game implementation. The biggest benefit DDD has
provided is a way of breaking down the game rules into fine grained events that
are easy to reason about and implement.


# Appendix: DDD concepts used in this post
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

## Event storming {#event_storming}
Typically, event storming is a session where domain, product, and technical
experts come together to explore and model a domain, starting by brainstorming
events that can occur within the domain.

In my case, these were little 'pen & paper' sessions where I mapped out a
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
      a reputation for being overly verbose and boring.
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
