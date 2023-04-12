---
title: "Making C# Go Fast"
date: 2023-03-30T12:20:53+11:00
draft: true
summary: "a short summary of this post"
tags:
- example-tag
---

# Todo
- inline todos
- add TOC
- spell/grammar check

# Notes to self
- proof-reading notes
    - make sure benchmark results, how to measure is explained
    - include advice from perf book

# Introduction
- finished pandemic impl (link). slow. ~7 games/sec!
- goal: 100 games/sec
- YOU ARE THE FUTURE AUDIENCE: notes to self when i want to do perf again
- audience 2: ppl new to profiling/perf improvement
  - not a deep dive into how profiling works etc. A practical post on
    using profilers & benchmarking to guide & measure perf improvement.
- i read book: get name/link
    - note it's a bit dated
        - mentions .NET framework, no mention of records
    - main takeaways: mem, benchmark, GC num1 rule: GC objects in gen 0 or not at all
    - lots of tools and what to look for. I just used rider
        - what's being allocated? how much? by what methods? how much time in GC?
        - rider appears to have most of the important tools, may be missing some
          of the more detailed stuff, eg. ETW analysis
- in intro, give a quick description of what I'm benchmarking, eg.
    - play games
        - loop
            - new game
            - while game not done
                - find best move
                    - score all moves
                    - pick best
                - do move

# Log
Starting state: [3a5ff0a](https://github.com/uozuAho/pandemic_ddd/commit/3a5ff0a)
~7 games per second.

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
Same as round 1, hunting for easy wins.

20% (14/11.7) remove LINQ in hot paths
- [PlayerHandScore: group, filter, sum](https://github.com/uozuAho/pandemic_ddd/commit/d664cea8846c005655f891d20fb08427e6d26258)
- [PenaliseDiscards: filter, cast, group](https://github.com/uozuAho/pandemic_ddd/commit/4c6a8b188cccb11495cbeb59f97d81c989098c67)
- [IsCured: search](https://github.com/uozuAho/pandemic_ddd/commit/08a63cdb9a051c2f2c82b635d0f49e49d04915c8)

41% (19.7/14) [HasEnoughToCure: group, count, search](https://github.com/uozuAho/pandemic_ddd/commit/6055aedbbcdc365bef31d583dc4e690401548ac3)

I didn't bother trying to understand the first three. I wanted to understand how
the last change made such a drastic improvement, but couldn't. With CPU
sampling, I couldn't find what exactly was consuming 41% unnecessary time. The
best I could find was that after the change, 40% less memory was being
allocated. I tried running for a fixed time, then for 100 games, but I couldn't
see where in the CPU profile the 40% was coming from. Running 100 games with
sampling profiling takes 8100ms before the change, and 7550ms after. Not even
10% improvement. The time spend per method looks similar across each run. I can
only think that Benchmark.net is compiling/running the program differently.

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
greedy agent makes over 2000!

## Round 3: from 20 to 50 games/sec
I tried making a few more changes to reduce allocations, but these didn't have
much of an effect. I decided to focus on CPU time instead.

45% (28.6/19.7) use city idx instead of string lookup

- [original change, with lots of other changes](https://github.com/uozuAho/pandemic_ddd/commit/22ff9b59231b10c87cf1df435b8ce1f3d6051baa)
- [validate with just the lookup change](https://github.com/uozuAho/pandemic_ddd/commit/1066696)

The main contributor to the speedup here was replacing the dictionary lookup
with an array lookup.

- 40% (40/28.6) [CubePile: replace dict(colour, int) with just ints](https://github.com/uozuAho/pandemic_ddd/compare/ee6443f..b600a04)

Yet again, getting rid of expensive dictionary lookups. Cubes are used everywhere!

- 25% (50/41) [use ImmutableArray<Player> instead of ImmutableList](https://github.com/uozuAho/pandemic_ddd/commit/15261296d03ae40bf4711ae0b746b4b55bfc88b3)

Before I started focusing on performance, I had changed the cities collection from
a list to an array, and got a considerable speedup. I decided to make this change
since I was "in the area" at the time.

A sampling profile run shows that the list consumes more time dealing with
enumerators than the array:

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

ImmutableArray is more targeted at perf than list, see https://devblogs.microsoft.com/dotnet/please-welcome-immutablearrayt

Advice from there:

Reasons to use immutable array:

    Updating the data is rare or the number of elements is quite small (<16)
    you need to be able to iterate over the data in performance critical sections
    you have many instances of immutable collections and you can’t afford keeping the data in trees

Reasons to stick with immutable list:

    Updating the data is common or the number of elements isn’t expected to be small
    Updating the collection is more performance critical than iterating the contents

If you're unsure, try both & measure.

### Another derpy moment - comparing the wrong thing
This feels really dumb to have to explain, but I was stumped for an
embarrassingly long time by it. This section is for future me.

I was having trouble explaining where the performance gains were coming from
when comparing the benchmarks and the profile results.

I was measuring performance improvement by benchmark results, which gave me a
throughput figure (games per second). However, when running the profiler, I ran
the app for a fixed amount of time. This made it seem as though the benchmark
was giving better results than the profiler run. I'll try to explain with pictures.

Say your app repeatedly calls two methods, A and B. You benchmark the app, and
find that its throughput is 10 (things) per second. To profile it, you run the
app for 1 second:

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

The app spends 333ms of its time calling A, 167ms less than in the previous
profile. You naively see this as only 16.7% of the 33% improvement shown by the
benchmark. Where's the rest?

This is the wrong way of looking at it. Since you've made A 2x as fast,
throughput increases. You're still profiling the app for 1 second, so the app

A takes 0.5 x original time
total calls to A & B = 1/(0.5 + 0.5*0.5) = 1.33


## Round 4: from 50 to ... 200!? Oh...
- 22%
  - Player.HasEnoughToCure: remove LINQ enumerator creation: https://github.com/uozuAho/pandemic_ddd/commit/3a5d3e98e025f59107245527e862fe2591dcfd7f
  - [Deck: prevent list resizing in Deck](https://github.com/uozuAho/pandemic_ddd/commit/183fb212c6010154e7078eb820912d8ab01982e6)

- 23% [yield commands directly instead of building list](https://github.com/uozuAho/pandemic_ddd/commit/b9de07996671770f1ea4ed43f7fed9c07e94fa1f)

When I first made this change, I unintentionally modified the behaviour of the
app. The game rate jumped up drastically (300%!). I just assumed that building &
discarding the list was very expensive, and didn't confirm the sanity of the
change by comparing the before & after CPU profiles. I eventually spotted the
bug I'd introduced ([fixed here](https://github.com/uozuAho/pandemic_ddd/commit/0b70df1))
- I'd allowed the agent to pass its turn. It's a valid move, but not very
effective. The change caused games to be lost a lot sooner, thus allowing the
performance test to run more games.

Lesson learned - have tests in place that ensure your app behaves as expected,
before making performance changes. Also, if the performance jump seems too good
to be true, it may just well be.

## Round 5: from 78 to 124
The biggest improvement in this round came from improving an algorithm, rather
than microoptimisations. When computing the score for research stations, I was
originally running a breadth-first search for the closest stations to the 'best'
cities, scoring higher the closer they were. Instead of running this search, I
pre-computed the cities that would contribute to the score. This gave a 27%
boost.

2a5ecc3: 27%: ResearchStationScore: hard code best, 1st & 2nd neighbours
    - https://github.com/uozuAho/pandemic_ddd/commit/2a5ecc3

A couple more:

e38df63: 10%: cube on city score: inline loop & method call
    - https://github.com/uozuAho/pandemic_ddd/commit/e38df63
de3eced: 6%: remove LINQ `Sum`, compute manually. Simple.
    - https://github.com/uozuAho/pandemic_ddd/commit/de3eced


# Done. What worked?
I had achieved my goal of 100 games/sec! I could have kept going - I had become
addicted to the hit of seeing the benchmark score go up. I guess that's one
reason to set a goal beforehand!

## Effective changes
- replacing dicts & hash sets with arrays
- pre-sizing collections
- ImmutableArray > ImmutableList (measure though)
- replace LINQ with simple loops

## Lessons learned
- profile and benchmark using the same build & run config
    - mistake1: benchmarking in release, profiling in debug
        - benchmark.net doesn't allow you to bench in debug
    - mistake2: benchmark & profiling had different players
    - release build does more optimisations. profile looks different, different
      things will be hotspots. Snapshot: debug = 17 games/sec, release = 46/sec
- be careful comparing different implementations. eg. random vs greedy (see
  round 2).
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
