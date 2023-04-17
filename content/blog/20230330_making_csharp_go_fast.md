---
title: "Making C# Go Fast"
date: 2023-03-30T12:20:53+11:00
draft: true
summary: "a short summary of this post"
tags:
- example-tag
---

# Todo
- add TOC
- spell/grammar check
- proof read
- better titles?
- add summary
- add tags
- keep the remaining questions section?

# Notes to self
- proof-reading notes
    - make sure benchmark results, how to measure is explained
    - include advice from perf book

# Introduction
I finally finished my implementation of the pandemic board game
([original post]({{< ref "20210924_learning_ddd_by_implementing_pandemic" >}})).
I didn't focus on making the implementation fast, so it wasn't much of a surprise
to see that it could only play about 7 games per second. I want to be
able to run search algorithms to win each game, and 7 games/second is ... slow.

I learned some things about performance improvement and got performance up to
100 games per second. This post is a bit of a diary of improvements, mistakes
and lessons learned along the way. If you want to skip the diary and just see
the lessons, go to **todo: link here**.

This won't be a deep dive into profiling or C#. It's mainly a log for me for
nnext time.

As part of this project, I read "Writing High-Performance .NET Code" [1] by Ben
Watson. It helped me understand what to do with profiler results. It's a little
dated now (C#7 was the latest at the time of writing), but I still found a large
amount of useful information. There's a lot of Window-only tools mentioned in
the book. I used Rider to do all my performance analysis.

## What I'm optimising
### The game
If you're unfamiliar with pandemic, here's a very simplified explanation:

<figure>
  <img
    src="/blog/20230330_making_csharp_go_fast/intro_pandemic_example.png"
    loading="lazy" />
</figure>

A player is currently in Melbourne. There is a high level of 'red' disease in
Hobart, represented by the three disease cubes there. There's a research station
in Sydney. The objective for all players in the game is to cure all diseases
before they run rampant across the world. Diseases are cured by players at
research stations, by spending cards that they pick up at the end of each turn.

In the scenario above, the player has a decision to make:
- go to Hobart to treat the red disease, before an outbreak occurs and spreads
  the disease to more cities?
- go to Sydney to cure a disease?

### My code
The code I wanted to optimise looks something like this:

```py
while True:
  game = newGame()
  while not game.over:
    move = agent.move(game)
    game = game.do(move)
```

The agent I wanted to optimise is a greedy agent, which tries all legal moves
from each state, and picks the move the results in the best game state. 'Best'
is determined by a score, which I coded:

```py
class GreedyAgent:
  def move(game):
    return best([score(move) for move in game.legal_moves()])

  def score(game):
    """ A combination of things, including:

        - How many disease cubes are on cities?
        - How many diseases have been cured?
        - Does any player have enough cards to cure a disease?
        - How far are players away from important cities?
    """
    ...
```


# Log
Let's get cracking. Starting state: [3a5ff0a](https://github.com/uozuAho/pandemic_ddd/commit/3a5ff0a)
~7 games per second.

## Plan
The performance book [1] has a short chapter that can be used as a runsheet on
how to improve performance, which I decided to follow as a starting point. In
short, the steps are:

1. define a performance goal & metrics
2. create an environment that allows you to run repeatable benchmarks (I added
   this step)
3. profile and analyse:
    - CPU usage
    - mem usage, time in GC
    - time spent in JIT
    - async/threads

My plan:

1. I want 100 games/sec avg, on my machine
2. I created a quick console app that could do fixed-time runs for profiling, and
   run benchmarks using [BenchmarkDotNet](https://benchmarkdotnet.org/):
   [my benchmarking app](https://github.com/uozuAho/pandemic_ddd/blob/3a5ff0afafcfaa823098ca3b8792eae0ede5bae6/pandemic.perftest/Program.cs#L5)
3. Rider tools:
    - CPU: profile with sampling, timeline, tracing
    - Memory: profile with timeline, memory profile with full allocations
    - JIT: timeline
    - async: no need, since my app is synchronous

To measure the performance gain from each change, I compared the time per game
before and after the change. `Percent improvement = 100 * (msec/game before /
msec/game after) - 100`.

## Round 1: from 7 to 12 games/sec
Inspired by the performance book, I started by looking at allocations. The most
allocations by size were the (city, distance) tuples, in the
`ClosestResearchStationTo` method. This method was doing a breadth-first search
from the given city, until it found a city with a research station. It used a
hash set to store visited cities, and a queue to enqueue the next neighbouring
cities to visit. Given there's a constant 48 cities in the game, it was
straightforward to [convert this method to use simple integer arrays](https://github.com/uozuAho/pandemic_ddd/commit/02d44b3a5c65260fb9d33af429e2f5e7aff5fee2).

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/round_1_mem_profile.png"
  alt=""
  width="999"
  loading="lazy" />
  <figcaption>Memory profiler analysis. Time spent in GC is shown at the bottom right.</figcaption>
</figure>

This resulted in a 23% improvement. The biggest saving was actually from removing
the `HashSet`, as the app was spending about 20% of its time looking for items
in the set. Look up "Contains" in the [HashSet implementation](https://source.dot.net/#q=hashset)
to see why. Although array and hash set lookup is constant time (`O(1)`), don't
forget there may be a large constant being hidden by that Big O notation.

There were no more (city, distance) tuples being allocated, however the time
spent in GC was still about 10%. I think the reason for this is due to the .NET
GC design - as long as the memory you allocate is out of scope by the next GC,
it won't affect the time the GC takes to run. The rule from the perf book is
"collect objects in gen 0 or not at all".

The next highest allocations were of `System.Collections.Immutable.ImmutableDictionary+<get_Values>d__27<Colour, Int32>`,
coming from the [MaxNumCubes](https://github.com/uozuAho/pandemic_ddd/blob/3239ab12ade8a2a118e74b9243699336a7837735/pandemic/Values/City.cs#L16)
method. My understanding of what's happening here is that each call to
`ImmutableDictionary.Values` instantiates a new iterator that traverses all items
in the dictionary. This is due to `Values` being a [iterator method](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/iterators).
([ImmutableDictionary.Values implementation](https://source.dot.net/#System.Collections.Immutable/System/Collections/Immutable/ImmutableDictionary_2.cs,fcef75d0d45c76eb,references)).

I tried to find the naming convention for generated code like this, but I couldn't
find an authoritative source. Here's a [JetBrains article that talks about code
that gets generated from lambdas and closures](https://blog.jetbrains.com/dotnet/2019/01/23/c-classes-memory-snapshots/).

[Removing Values and Max from MaxNumCubes](https://github.com/uozuAho/pandemic_ddd/commit/f172f390696ea7be93a65ffa89849710dfb47da6)
gave a 36% speedup. This removed a lot of LINQ code, that was iterating over the
dictionary and sorting the elements.

## Round 2: from 12 to 20 games/sec
I was on a roll with following memory allocations, so I continued in this round.

I made 60% improvement by removing LINQ in hot paths:
- [PlayerHandScore: group, filter, sum](https://github.com/uozuAho/pandemic_ddd/commit/d664cea8846c005655f891d20fb08427e6d26258)
- [PenaliseDiscards: filter, cast, group](https://github.com/uozuAho/pandemic_ddd/commit/4c6a8b188cccb11495cbeb59f97d81c989098c67)
- [IsCured: search](https://github.com/uozuAho/pandemic_ddd/commit/08a63cdb9a051c2f2c82b635d0f49e49d04915c8)
- [HasEnoughToCure: group, count, search](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)

The last change alone contributed 40%. I wanted to understand exactly where this
drastic improvement came from, but couldn't. The benchmark appeared to be giving
different results to the profiling run. I could only see about 10% improvement
when profiling with CPU sampling, and a 40% reduction in memory allocations.

**todo: get a repeatable benchmark vs profile comparison here, eg. dotnet run -c Release**

### A derpy moment
For a while I was confused as to why playing random games was so much faster
than greedy games. Greedy games were spending about 50% of their CPU time making
moves, and the other 50% searching for the best move. I thought this meant that
greedy games should be running at ~50% of random speed, they actually ran at
less than 1% of the speed. I'd had my head stuck in the profiler for too long.
The greedy agent tries all possible moves before choosing the best one, thus
it's spending a lot less time actually progressing the game than the random
agent.

This can be seen by profiling with tracing. Tracing counts calls to every method
in the program:
- greedy agent calls to `Do()`: 4358. Random agent: 9550.
- greedy agent calls to `CreateNewGame`: 2. Random agent: 226

The random agent makes on average 42 calls to `Do()` per game, whereas the
greedy agent makes over 2000.

## Round 3: from 20 to 50 games/sec
I tried making a few more changes to reduce allocations, but these didn't have
much of an effect. For this round, I decided to focus on CPU time instead.

45%: looking up cities by array index instead of from a name:city dictionary.

- [original change, with lots of other changes](https://github.com/uozuAho/pandemic_ddd/commit/22ff9b59231b10c87cf1df435b8ce1f3d6051baa)
- [validate with just the lookup change](https://github.com/uozuAho/pandemic_ddd/commit/1066696)

Similar to round 1, looking up cities with a dictionary is much more expensive
than an array.

40%: [Storing cubes counts as integer fields rather than colour:int dictionaries](https://github.com/uozuAho/pandemic_ddd/compare/ee6443f..b600a04)

Yet again, getting rid of expensive dictionary lookups.

25%: [use ImmutableArray instead of ImmutableList for Players](https://github.com/uozuAho/pandemic_ddd/commit/15261296d03ae40bf4711ae0b746b4b55bfc88b3)

ImmutableArray is more targeted at performance than ImmutableList. There's advice in
[this post](https://devblogs.microsoft.com/dotnet/please-welcome-immutablearrayt)
on when to use each. In this case, the top reason appears to be better performance
when iterating over the array in performance critical sections. A before & after
profile shows that the list consumes more time dealing with enumerators than the
array:

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/round_3_immutable_list.png"
  alt=""
  width="784"
  loading="lazy" />
  <figcaption>ImmutableList operations, before switching to ImmutableArray</figcaption>
</figure>

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/round_3_immutable_array.png"
  alt=""
  width="737"
  loading="lazy" />
  <figcaption>ImmutableArray operations</figcaption>
</figure>


### Another derpy moment - comparing the wrong thing
This feels really dumb to have to explain, but I was stumped for an
embarrassingly long time by it. This section is for future me.

I was having trouble explaining where the performance gains were coming from
when comparing the benchmarks and the profile results.

I was measuring performance improvement by benchmark results, which gave me a
throughput figure (games per second). However, when running the profiler, I ran
the app for a fixed amount of time. This made it seem as though the benchmark
was giving better results than the profiler run. I'll try to explain with
pictures.

Say your app repeatedly calls two methods, A and B. You benchmark the app, and
find that its throughput is 10 per second. To profile it, you run the app for 1
second:

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/derp_profile_1.png"
  alt=""
  loading="lazy" />
  <figcaption></figcaption>
</figure>

You then optimise A, and measure again. The benchmark shows a 33% improvement -
throughput is now 13.3 per second. However, the profile looks like this:

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/derp_profile_2.png"
  alt=""
  loading="lazy" />
  <figcaption></figcaption>
</figure>

It looks as though you've made A 167ms faster, which is 16.7% of the time the
app runs. Where's the rest of the 33% improvement?

It's there, but profiling the app for a fixed amount of time makes it harder to
see.

- xA = 0.5s
- yB = 0.5s

improvement increases calls to A and B by the same factor, n
- nxA^ = 0.333s
- nyB = 0.666s

yB = 0.5
nyB = 0.666
want to know how many more calls to B, ie. n

n = nyB / yB = 0.666 / 0.5 = 1.333, ie a 33% improvement

It's easier to see where the performance gain was made by running the app for a
certain number of iterations. Say you run it for 10 iterations. Before the optimisation,
the run takes 1 second. Afterwards, it takes 750ms. The 33% improvement is much
easier to see there.

<figure>
  <img src="/blog/20230330_making_csharp_go_fast/derp_profile_3.png"
  loading="lazy" />
  <figcaption></figcaption>
</figure>

Note there's still times when benchmarking may give quite different results to
the profiling run, as happened in round 2. I think this is due to the way the
benchmark and profiling apps are configured, compiled and run.

## Round 4: from 50 to ... 200!? Oh...
22% from:
  - [Player.HasEnoughToCure: iterate over cards directly instead of using iterator method](https://github.com/uozuAho/pandemic_ddd/commit/3a5d3e98e025f59107245527e862fe2591dcfd7f)
  - [Deck: use pre-sized array instead of list](https://github.com/uozuAho/pandemic_ddd/commit/183fb212c6010154e7078eb820912d8ab01982e6)

### Mistake!
[Yielding available commands instead returning a list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)
made a 310% improvement! I felt very satisfied and assumed that building the list
was expensive. I wasn't carefully checking each improvement I was making at the time.
A little bit later, I happened to notice I'd modified the app's behaviour in a way
that made it run games a lot faster. I'd made the 'sensible' command generator
generate pass commands, which makes the current player give up their turn. This
is almost never useful in a game, and thus caused games to be lost a lot quicker
than before. The benchmark and profiler didn't mind though! More games = better!

Lesson learned - have tests in place that ensure your app behaves as expected,
before making performance changes.  Also, be wary of large performance changes
that you can't explain.


## Round 5: from 78 to 124
The biggest improvement in this round came from improving an algorithm, rather
than micro-optimisations. When computing the score for research stations, I was
originally running a breadth-first search for the closest stations to the 'best'
cities, scoring higher the closer they were. Instead of running this search, I
[pre-computed the scores that cities would contribute](https://github.com/uozuAho/pandemic_ddd/commit/2a5ecc3).
This gave a 27% boost.

A couple more to finish off:
- 10%: [cubes on city score: inline loop & method call](https://github.com/uozuAho/pandemic_ddd/commit/e38df63)
- 6%: [remove LINQ `Sum`, compute manually](https://github.com/uozuAho/pandemic_ddd/commit/de3eced)

# I made it!
I achieved my goal of 100 games/sec! I could have kept going - I had become
addicted to the hit of seeing the benchmark score go up. That's a good reason to
set a goal beforehand.

## All changes, ranked by % speedup
45 [validate with just the lookup change](https://github.com/uozuAho/pandemic_ddd/commit/1066696)
40 [Storing cubes counts as integer fields rather than colour:int dictionaries](https://github.com/uozuAho/pandemic_ddd/compare/ee6443f..b600a04)
40 [HasEnoughToCure: group, count, search](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)
36 [Removing Values and Max from MaxNumCubes](https://github.com/uozuAho/pandemic_ddd/commit/f172f390696ea7be93a65ffa89849710dfb47da6)
27 [pre-computed the scores that cities would contribute](https://github.com/uozuAho/pandemic_ddd/commit/2a5ecc3).
25 [use ImmutableArray instead of ImmutableList for Players](https://github.com/uozuAho/pandemic_ddd/commit/15261296d03ae40bf4711ae0b746b4b55bfc88b3)
23 [convert this method to use simple integer arrays](https://github.com/uozuAho/pandemic_ddd/commit/02d44b3a5c65260fb9d33af429e2f5e7aff5fee2).
22 from:
    - [Player.HasEnoughToCure: iterate over cards directly instead of using iterator method](https://github.com/uozuAho/pandemic_ddd/commit/3a5d3e98e025f59107245527e862fe2591dcfd7f)
    - [Deck: use pre-sized array instead of list](https://github.com/uozuAho/pandemic_ddd/commit/183fb212c6010154e7078eb820912d8ab01982e6)
20
    - [PlayerHandScore: group, filter, sum](https://github.com/uozuAho/pandemic_ddd/commit/d664cea8846c005655f891d20fb08427e6d26258)
    - [PenaliseDiscards: filter, cast, group](https://github.com/uozuAho/pandemic_ddd/commit/4c6a8b188cccb11495cbeb59f97d81c989098c67)
    - [IsCured: search](https://github.com/uozuAho/pandemic_ddd/commit/08a63cdb9a051c2f2c82b635d0f49e49d04915c8)
20 [Yielding available commands instead returning a list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)
10 [cubes on city score: inline loop & method call](https://github.com/uozuAho/pandemic_ddd/commit/e38df63)
6 [remove LINQ `Sum`, compute manually](https://github.com/uozuAho/pandemic_ddd/commit/de3eced)

general:
    - replacing .NET collections with arrays where possible
    - pre-sizing arrays and collections
    - ImmutableArray > ImmutableList (measure it)
    - replace LINQ with simple loops

## Lessons learned
- profile and benchmark using the same build & run config
    - mistake1: benchmarking in release, profiling in debug
        - benchmark.net doesn't allow you to bench in debug
        - release build does more optimisations. profile looks different,
          different things will be hotspots. Snapshot: debug = 17 games/sec,
          release = 46/sec
    - mistake2: benchmark & profiling had different players
- compare the same thing: stay aware of what you're profiling: see derpy moment
  one
- (derp): when trying to correlate profile results with benchmark gains, it's
  easier to compare when running a fixed number of iterations when profiling. If
  you run for a fixed time, you'll fit more iterations into an optimised run,
  thus making it harder to compare the two profile results.
    - draw some box diagrams for this :facepalm:
- if results look too good to be true, they might be. See round 4.
- improvement strategy. IMO, you could spend days analysing where perf gains
  could be made. If perf hasn't been a focus at all, then it's very likely
  there'll be some cheap gains to be made. Timebox it and just follow the
  profiler.
- each profiling type yields slightly different results, since they are
  more/less intrusive on your application. For example, a timeline profiling run
  shows GC wait time as 7%, while running the memory profiler shows the app
  spent 11% in GC.
- when viewing/comparing profiler results in rider, ensure you select the main
  thread (if your app is single threaded). Annoyingly, CLR worker and finalizer
  threads are selected by default

## General tips
- perf improvements lead to more code, harder to read
    - LINQ is nice to read, but slow, esp in tight loops
- from book: make sure to comment why the code is hard to read, otherwise
  others may come along and 'clean up' your performant code
- quick list of improvements (ymmv, measure)
    - replace linq with simple loops and arrays
    - replace dicts and sets with arrays
    - use immutableArray instead of list
    - size collections before use

## Advice to self, if doing again
If my sole goal was to improve perf: just have at it. You haven't focused on
perf for the whole project, so there will be many easy wins.

Follow the run sheet. Don't attempt to explain improvements, just loop:
- profile CPU
- profile mem
- tackle biggest time consumers/allocators first. Follow tips above

# Remaining questions
- [HasEnoughToCure: group, count, search](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)
    - Why does benchmarking show a 40% improvement here, while a regular run only shows about 10%?
      See Round 2.

# References & further reading
- [rider profiling tute series](https://www.jetbrains.com/dotnet/guide/tutorials/rider-profiling/)
    - small intro to profiling in rider, with demo apps
    - [modes](https://www.jetbrains.com/dotnet/guide/tutorials/rider-profiling/profiling-modes/)
        - timeline: like sampling, but collects events for more info on GC,
          threads, allocs
    - [DPA](https://www.jetbrains.com/dotnet/guide/tutorials/rider-profiling/dynamic-program-analysis/)
        - using DPA to improve example Sudoku solver
        - can highlight memory pressure issues
- [Rider DPA: fixing memory issues](https://www.jetbrains.com/help/rider/Fixing_Issues_Found_by_DPA.html)
    - mem allocation is cheap, but GC can be expensive
    - main strategy when using lambdas is avoiding closures
    - C# compiler generates delegates for closures: `<>c__DisplayClass...` and `Func<...>`
    - method groups allocate delegates, use same caution as for lambdas
    - boxing: if DPA shows issue with allocating a value type, boxing is occurring
    - allocations themselves may not be expensive, but may indicate
      inefficiencies, eg boxing, incorrect collection sizing
    - strongly recommends [Heap Allocations Viewer](https://plugins.jetbrains.com/plugin/9223-heap-allocations-viewer/reviews)
- [stackify: .NET Performance Optimization: Everything You Need To Know](https://stackify.com/net-application-optimization/)
    - profiles some sample apps
        - CPU bound, mem bound
    - covers benchmarking, and using BenchmarkDotNet [Diagnosers](https://benchmarkdotnet.org/articles/configs/diagnosers.html)
        - cross platform CPU + mem stats, alternative to profiling
    - common perf problems (some)
        - using string.substring instead of Span
        - using string interpolation/format

# References
**todo: this isn't rendering**
- [1]: https://www.writinghighperf.net (Writing High-Performance .NET Code, 2nd ed.)
