---
title: "Making C# Go Fast"
date: 2023-03-30T12:20:53+11:00
draft: true
summary: "a short summary of this post"
tags:
- example-tag
---

# Todo
- pick out perf wins you can explain. Get
    - screenshots?, how to analyse in rider
    - benchmark results, how to measure
    - explantion of what improved perf
    - advice from perf book
- pick perf wins you can't explain ... do same as above?

# Notes to self
- YOU ARE THE FUTURE AUDIENCE: notes to self when i want to do perf again
- ppl new to profiling/perf improvement
  - not a deep dive into how profiling works etc. A practical post on
    using profilers & benchmarking to guide & measure perf improvement.

# Post structure (draft)
- intro
    - finished pandemic impl (link). slow. ~7 games/sec!
    - goal: 100 games/sec
- i read book: get name/link
    - note it's a bit dated
        - mentions .NET framework, no mention of records
    - main takeaways: mem, benchmark, GC num1 rule: GC objects in gen 0 or not at all
    - lots of tools and what to look for. I just used rider
        - what's being allocated? how much? by what methods? how much time in GC?
        - rider appears to have most of the important tools, may be missing some
          of the more detailed stuff, eg. ETW analysis
- log
- most effective changes
- review
    - what was most effective
    - what did i learn
    - what would i do next time
      - run sheet?
- general tips etc
    - perf improvements lead to more code, harder to read
        - LINQ is nice to read, but slow, esp in tight loops
    - from book: make sure to comment why the code is hard to read, otherwise
      others may come along and 'clean up' your performant code
    - quick list of improvements (ymmv, measure)
        - replace linq with simple loops and arrays
        - replace dicts and sets with arrays
        - use immutableArray instead of list
        - size collections before use
- further reading

# Introduction

# Log
## Plan
Following the runsheet from the book. Summary of what I ended up doing:
- pregame:
    - define metrics: I want 100 games/sec avg, on my machine
    - create repeatable test runs for profiling and benchmarking: https://github.com/uozuAho/pandemic_ddd/blob/3a5ff0afafcfaa823098ca3b8792eae0ede5bae6/pandemic.perftest/Program.cs#L5
- profile with sampling: quick picture of where the CPU is spending its time
- profile with timeline: better understanding of top allocators, GC time, JIT time
- profile with full allocations: easiest way to trace allocations
- focus on where the CPU spends most of its time (sampling). Use mem profiler
  if undecided, or for hints on what is taking the time

## Round 1
- start state: [3a5ff0a](https://github.com/uozuAho/pandemic_ddd/commit/3a5ff0a)

Inspired by the performance book, I started by looking at allocations. The most
allocations by size were the (city, distance) tuples, in the
`ClosestResearchStationTo` method. This method was doing a breadth-first search
from the given city, until it found a city with a research station. It used a
hash set to store visited cities, and a queue to enqueue the next neighbouring
cities to visit. Given there's a constant 48 cities in the game, it was
straightforward to [convert this method to use simple integer arrays](https://github.com/uozuAho/pandemic_ddd/commit/02d44b3a5c65260fb9d33af429e2f5e7aff5fee2).
This resulted in a 23% improvement. The biggest saving was actually from removing
the `HashSet`, as the app was spending about 20% of its time looking for items
in the set. Look up "Contains" in the [HashSet implementation](https://source.dot.net/#q=hashset)
to see why. `O(n) != O(n)` :).

There were no more (city, distance) tuples being allocated, however the time
spent in GC was still about 10%. I think the reason for this is due to the .NET
GC design - as long as the memory you allocate is out of scope by the next GC,
it won't affect the time the GC takes to run. The rule from the perf book is
"collect objects in gen 0 or not at all".

- **improvements**
    - **improvement measured by** 100 * ((new games/sec) / (previous games/sec) - 1)
        - benchmark gives msec per game. it's easy to show that old ms / new ms
          is same as the above measure
    - 23% (8.6/7) [remove tuple and queue allocations](https://github.com/uozuAho/pandemic_ddd/commit/02d44b3a5c65260fb9d33af429e2f5e7aff5fee2)
        - biggest saving here was from removing hashset
            - contains() was the biggest time consumer. Just remember O(n) != O(n)!
        - valuetuple allocations don't seem to have actually consumed much time
            - hashset was bigger
            - all allocs removed after change, but GC time about the same
            - why? allocced & killed very quickly
            - removing allocations still useful: they were actually a hint
              of the unnecessary hashset & queue growing
        - does time saving make sense?
            - yep these total about 20%
            - total time 3978
            - hashset total: 714
                - contains 498 : https://source.dot.net/#System.Private.CoreLib/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/HashSet.cs,210
                - add 192 : https://source.dot.net/#System.Private.CoreLib/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/HashSet.cs,1070
                - ctor 24
            - queue total: 156
                - enqueue 126: https://source.dot.net/#System.Private.CoreLib/src/libraries/System.Private.CoreLib/src/System/Collections/Generic/Queue.cs,171
                - deq 18
                - ctor 12
    - 36% (11.7/8.6) [remove use of Dict.Values](https://github.com/uozuAho/pandemic_ddd/commit/f172f390696ea7be93a65ffa89849710dfb47da6)
## round 2
- same as before, look at CPU sampling, timeline, mem profile
- **improvements**
    - 20% (14/11.7) remove LINQ
        - https://github.com/uozuAho/pandemic_ddd/commit/d664cea8846c005655f891d20fb08427e6d26258)
        - https://github.com/uozuAho/pandemic_ddd/commit/4c6a8b188cccb11495cbeb59f97d81c989098c67)
        - https://github.com/uozuAho/pandemic_ddd/commit/08a63cdb9a051c2f2c82b635d0f49e49d04915c8
    - 41% (19.7/14) [remove LINQ](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)
    - not much improvement by these, **why?**
        - https://github.com/uozuAho/pandemic_ddd/commit/8896808a86dac98a0a3186993f62b39b37288f8a
        - https://github.com/uozuAho/pandemic_ddd/commit/23806b9a7d572222a47868f1d2e85d0d8327d3fa
        - https://github.com/uozuAho/pandemic_ddd/commit/a0c2b59d7a272c5e69c37130ce5e2cf3f3fb4d60
## aside: why random so much faster than greedy?
- Do() & Score() are taking roughly 50% of sampler's time when profiling So why
  does playing random games (mostly Do() calls) so much faster than greedy
  games?
    - trace greedy: 4358 calls to Do
    - trace random: 9550 calls. Roughly double, makes sense.
    - trace random: 226 calls to CreateNewGame
    - trace greedy: 2 calls to CreateNewGame!
        - greedy.NextCommand = 194 calls, makes 4164 calls to Do
            - avg 21 Do() calls per command, vs 1 for random
## round 3
- seem to be getting diminishing returns from focusing on allocations, let's
  look at CPU
- 45% (28.6/19.7) [use city idx instead of string lookup](https://github.com/uozuAho/pandemic_ddd/commit/22ff9b59231b10c87cf1df435b8ce1f3d6051baa)
- 40% (40/28.6) [replace dict(colour, int) with just ints](https://github.com/uozuAho/pandemic_ddd/commit/b600a041a6d6e06129a9e282360eeb2d11849c73)
- 25% (50/41) [use ImmutableArray<Player> instead of ImmutableList](https://github.com/uozuAho/pandemic_ddd/commit/15261296d03ae40bf4711ae0b746b4b55bfc88b3)
## round 4
- 310% (155/50) [yield commands directly instead of building list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)
    - BAH I just can't explain this one! in theory, there should be something
      that was taking 66% of program time, now not taking that long. AllSensibleCommands
      was taking 865ms, then 2.7ms after improvement. GC time is the same. mem
      allocations are suspiciously the same (total MB, not types). No longer
      allocating heaps of IPlayerCommand[]. The only diff is yielding directly
      instead of populating a list first. I was expecting to see list.grow
      taking up the majority of the time, but nope.
        **ruh roh**: just found a mistake: generating Pass commands makes the
        benchmark > 2x as slow, likely due to losing games sooner if the agent
        is passing.
        back to 12.77ms/game, 78.3.
        tried building the list again and comparing perf
          - this makes a 4ms difference: 16 vs 12ms/game. Still a 25% improvement
          - CPU profile makes sense: nearly 1s in sens commands vs ~200ms without list
- 22% (189/155)
  - remove enumerator usage (yield): https://github.com/uozuAho/pandemic_ddd/commit/3a5d3e98e025f59107245527e862fe2591dcfd7f
  - [prevent list resizing in Deck](https://github.com/uozuAho/pandemic_ddd/commit/183fb212c6010154e7078eb820912d8ab01982e6)

# Lessons learned
- profile and benchmark using the same build & run config
    - mistake1: benchmarking in release, profiling in debug
        - benchmark.net doesn't allow you to bench in debug
    - mistake2: benchmark & profiling had different players
    - release build does more optimisations. profile looks different, different
      things will be hotspots. Snapshot: debug = 17 games/sec, release = 46/sec
- (derp): when trying to correlate profile results with benchmark gains, it's
  easier to compare when running a fixed number of iterations when profiling.
  If you run for a fixed time, you'll fit more iterations into an optimised run,
  thus making it harder to compare the two profile results.
    - draw some box diagrams for this :facepalm:
- if results look too good to be true, they might be. My mistake: when making a
  perf change, I unintentionally modified the app (command generator generated
  pass commands). The game rate jumped up drastically (300%!), because games
  ended sooner when players passed, not because I'd improved performance. Make
  sure you're covered by tests, and make as small changes as possible.
- improvement strategy. IMO, you could spend days analysing where perf gains
  could be made. If perf hasn't been a focus at all, then it's very likely
  there'll be some cheap gains to be made. Timebox it and just follow the
  profiler. **todo** List out things that worked for me, eg. remove linq, array
  > hash set, array > dict, ImmutableArray, unnecessary allocs, more?
- be careful comparing different implementations. eg. random vs greedy.
- each profiling type yields slightly different results, since they are
  more/less intrusive on your application. For example, a timeline profiling run
  shows GC wait time as 7%, while running the memory profiler shows the app
  spent 11% in GC.
- when viewing/comparing profiler results in rider, ensure you select the main thread
  (if your app is single threaded). Annoyingly, CLR worker and finalizer threads
  are selected by default

# Further reading
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

# notes and resources
## all improvements, in chron order
23% (8.6/7) [remove tuple and queue allocations](https://github.com/uozuAho/pandemic_ddd/commit/02d44b3a5c65260fb9d33af429e2f5e7aff5fee2)
36% (11.7/8.6) [remove use of Dict.Values](https://github.com/uozuAho/pandemic_ddd/commit/f172f390696ea7be93a65ffa89849710dfb47da6)
20% (14/11.7) remove LINQ
    - https://github.com/uozuAho/pandemic_ddd/commit/d664cea8846c005655f891d20fb08427e6d26258)
    - https://github.com/uozuAho/pandemic_ddd/commit/4c6a8b188cccb11495cbeb59f97d81c989098c67)
    - https://github.com/uozuAho/pandemic_ddd/commit/08a63cdb9a051c2f2c82b635d0f49e49d04915c8
41% (19.7/14) [remove LINQ](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)
45% (28.6/19.7) [use city idx instead of string lookup](https://github.com/uozuAho/pandemic_ddd/commit/22ff9b59231b10c87cf1df435b8ce1f3d6051baa)
40% (40/28.6) [replace dict(colour, int) with just ints](https://github.com/uozuAho/pandemic_ddd/commit/b600a041a6d6e06129a9e282360eeb2d11849c73)
25% (50/41) [use ImmutableArray<Player> instead of ImmutableList](https://github.com/uozuAho/pandemic_ddd/commit/15261296d03ae40bf4711ae0b746b4b55bfc88b3)
25% [yield commands directly instead of building list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)
22%
  - remove enumerator usage (yield): https://github.com/uozuAho/pandemic_ddd/commit/3a5d3e98e025f59107245527e862fe2591dcfd7f
  - [prevent list resizing in Deck](https://github.com/uozuAho/pandemic_ddd/commit/183fb212c6010154e7078eb820912d8ab01982e6)
## top 3 improvements with explanations
45% (28.6/19.7) [use city idx instead of string lookup](https://github.com/uozuAho/pandemic_ddd/commit/22ff9b59231b10c87cf1df435b8ce1f3d6051baa)
  - recheck: 1066696: 64% 46.3 -> 75.9
      - argh yet another one I'm having trouble explaining. City name->idx
        lookup was consuming ~600ms before change, let's say 0% after. That
        only explains 4/3.4 = 18% of the speedup. Where'd the other 50% come
        from?
          - my only idea ATM is that the program runs differently under
            sampling/debug than Release/optimised build.
            - pre:  closest research: 40%, 1674ms of 4000ms
              - mostly dict.findvalue
            - post: closest research: 12%, 486 of 4000ms
            - accounts for 42% by this calc: 4000 - (4000 - (1674 - 486))
            - BUT let's try running a fixed number of games (100)
                - pre: closest:  1687 of 3632
                - post: closest: 264 of 2298
                - total runtime reduction = 3632 - 2298 = 1334
                - closest reduction = 1687 - 264 = 1423
                - % improve:
                    100games/3632ms -> 100games/2298ms
                    = 1game/36.32 -> 1game/22.98
                    = 27.53 -> 43.52 games/sec
                    = 27.53 + 27.53n = 43.52
                    = n = (43.52 - 27.53) / 27.53 = 58%
                    **My quick version: runtime** = 3632/2298 = 58%
                    **My quick version: games/sec** = 43.52/27.53 = 58%
                    **My quick version: ms/game** = 36.32/22.98 = 58%
40% (40/28.6) [replace dict(colour, int) with just ints](https://github.com/uozuAho/pandemic_ddd/compare/ee6443f..b600a04)
  - rebench:
    - pre (ee6443f):  35.02 ms
    - post (b600a04): 20ms
  - sampling differences
    - get item from immut dict main contributor here
## others with explanations

- 25% [yield commands directly instead of building list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)
  - tried building the list again and comparing perf
    - this makes a 4ms difference: 16 vs 12ms/game. Still a 25% improvement
    - CPU profile makes sense: nearly 1s in sens commands vs ~200ms without list
  - note the commit above has a bug, fixed here: https://github.com/uozuAho/pandemic_ddd/commit/0b70df1ab4d10dcd08bb41b49f7c487ccc528d9a
    - was generating pass commands, not 'sensible'
## can't explain
41% (19.7/14) [remove LINQ](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)
  - recheck:
      - 69.33 ms -> 49.97 ms = 39%
      - 70.58 ms -> 50.58ms
  - sampling with 4s runtime doesn't show what made the improvement
  - running 100 games doesn't either
  - mem profile ran in 76s vs 53 (43%) (GC time constant 11%)
      - also 800MB less allocated (2.59 vs 1.84, 40%)
  - argggghhh i give up. Can't explain this one
  - tried again, now benchmarks aren't showing 40% gain. Meh.
      - make same change again
        - pre without 4:5 cure fix: 13.68
        - pre:  13.84
        - post: 11.12 -> 24%
