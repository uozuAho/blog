---
title: "Why Is C Faster Than C#? Part 2"
date: 2023-11-06T14:08:31+11:00
draft: true
summary: "a short summary of this post"
tags:
---

# todo
- finish speed comparison post first
- obvious questions
    - [[cs_c_rust_perf.project]]: why is C 2opt 10x faster? Try C# unsafe?

## S: intro
- I recently did a course on discrete optimisation ([coursera course here](https://www.coursera.org/learn/discrete-optimization), it's great fun!).
- focus is on approx techniques for large NP-complete problems
- however, fast code is still important
- I used C# for my 'fast code'
- Wondered, would C or rust be faster?
- The general consensus from searching is 'yes', with hand-wavey reasons like GC,
  JIT, runtime overhead etc. etc., but I wasn't satisfied. I wanted to understand
  exactly why two comparable programs performed differently.
- I'm no expert in C, low level code, CLR internals etc. The aim of this post is
  to learn about this stuff by doing it, document my findings, show my workings,
  and share.
- side note: this has been done before, by ppl smarter than me: https://stackoverflow.com/a/37103437/2670469
    - from ~2005
    - non-trivial code
    - line by line copy of the original C++ to C# ended up 13x faster than C++
    - C++ was eventually faster, after a lot of effort
- see if I can make my 2-opt implementation faster with C

## A: what i did: 2-opt
- used chatGPT to rewrite my C# code in C
- it's 3x slower than C#! I assumed ChatGPT had done something silly
- using callgrind, I found a lot of cycles were being spent in clock():

```sh
valgrind --tool=callgrind ./some-program
# creates a file like callgrind.out.1234

# see results with:
callgrind_annotate --auto=yes callgrind.out.1234 > some_file.txt
```

some_file.txt example:
```
-----------------------------------
Ir                    file:function
-----------------------------------
209,307,770 (54.04%)  twoopt.c:main
123,943,848 (32.00%)  ???:clock

...

         .           double distance_squared(Point2D* p1, Point2D* p2) {
23,241,449 ( 6.00%)      double xdiff = p1->x - p2->x;
570 ( 0.00%)  => ???:fopen (1x)
87,793,474 (22.67%)  => ???:clock (2,582,161x)
```

- Ir = "instruction read" = count of (assembly) instructions executed
- Simple way to speed things up: I reduced the number of calls to clock()
  **todo** show code, and got an 80x speedup. C now 10x faster than C#. There's
  probably plenty more I could do.
- why clock() so slow? For some reason, I knew about system calls, and had a hunch
  that clock was one.
    - explain system calls
- easy way to check: `strace`:
- `strace -c ./twoopt ../../data/tsp/tsp_85900_1`
    - before clock call reduction:
    ```
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
    99.03    1.990292          35     56783           clock_gettime
    ```
    - after
    ```
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
    90.18    0.131388           6     19013           clock_gettime
    ```
- there is a _lot_ more here than I want to dive into, eg. thinking about
  instruction & data caching
- side note: ChatGPT wasn't able to tell me that clock() was having such a huge
  performance impact. It saved me typing the code, but didn't stop me needing to
  understand what was happening :)
