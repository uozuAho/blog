---
title: "Why Is C Faster Than C#?"
date: 2023-11-05T15:42:51+11:00
draft: true
summary: ""
tags:
---

# todo
- **sticky** ignore 2opt for now
- inline todos
- obvious questions
    - what does the assembly look like for `double x = -1.0 + 2.0 * (i & 0x1)` vs `x *= -1`
    - [[cs_c_rust_perf.project]]: why is C 2opt 10x faster? Try C# unsafe?
- extract 2opt to another post?
- put this somewhere: some reading notes
  - https://stackoverflow.com/a/5331574/2670469
    - line by line copy of C# <-> C is pretty meaningless. Language features are
      different
    - JIT is a tradeoff: best optimisations are time consuming
    - conclusion: you can almost always write C/C++ that's faster than C#, but
      not the other way around
  - https://stackoverflow.com/a/37103437/2670469 and links
    - links deep dive into C++ optimisation
    - C# version was a line by line copy of the original C++ code
    - summary: C/C++ can go faster, with effort, if you know what you're doing
  - https://blog.codinghorror.com/the-bloated-world-of-managed-code/
    - managed:
      - con: slower, uses more memory
      - pro: faster dev
  - https://blog.codinghorror.com/on-managed-code-performance/
    - quake 2 .net port was 15% slower after C targeted host CPU
      - 30% slower than hand-optimised assembly version
    - doesn't cater for GC, which is bad for games
- page summary
- page tags

# maybe


# draft

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

## T: what i wanted to achieve
- find out exactly why C is 3 times as fast as C# here: https://github.com/niklas-heer/speed-comparison
- see if I can make my 2-opt implementation faster with C

## A: what i did: speed comparison
- run C and C# on my machine, following readme
- C was even faster on my machine, 35ms vs 155 (4x faster)
- removing fileio and setting `rounds` directly saved 3ms in C, 5ms in C#
- setting `rounds` to 1: C = 64us, C# 30ms. C# has startup (and shutdown?) overhead,
  which I don't really care about.
- disappointingly, AOT for C# had only a small impact. I couldn't get it working
  on linux, but it reduced the run time on Windows from 170ms to 142ms.
- so, C completed the pi calculation in 30ms, while C# took 120ms. Why? I compared
  the assembly
- to see C disassembly, remove the flags `-s -static` and add `-g`. `static`
  generates lots of assembly, making finding your code hard. Then use objdump,
  eg. `objdump -drwlCS -Mintel exe > exe.asm`. Then, figure out what it means!
  I found this [quick introduction to x64 assembly](https://www.intel.com/content/dam/develop/external/us/en/documents/introduction-to-x64-assembly-181178.pdf)
  (pdf) a good primer. Then, [x86 reference](https://www.felixcloutier.com/x86/)
  was a super handy online reference. Easier than reading a pdf.
- to see C# machine code: VS -> debug program -> debug menu -> windows -> disassembly
  The assembly looks slightly different between Debug/Release modes, but not significantly.
  CalcPi was about 44 instructions in Debug, and 42 in Release
- see the disassembly in the appendix
- I played around with the gcc flags to understand what made the speed differences.
  The top contributors were `-O3 -march=native -fassociative-math -fno-signed-zeros -fno-trapping-math`
    - `O3`: highest optimisation setting
    - `-march=native`: compile for the host CPU, using all available instructions
        - note about `march=native`: less portable, usually only big speedups for numerically intensive code: https://stackoverflow.com/questions/52653025/why-is-march-native-used-so-rarely
    - `-fassociative-math`: can reorder floating point operations, possibly causing under/overflow/NaNs
    - `-fno-signed-zeros`: ignore the sign of zeros
    - `-fno-trapping-math` assume that there will be no "division by zero, overflow, underflow, inexact result and invalid operation"
    - i got similar results with `-Ofast -march=native`
    - note that the math flags are 'unsage' - they don't comply with IEEE/ANSI
      standards on floating point math. Indeed they produced a different value
      of pi: still accurate to 7 decimal places, but different.
    - with just `-O3`, C took 120ms, same as C#, `-march=native` didn't make
      a big difference unless unsafe math was enabled. Looking at the generated
      assembly, unsafe math appears to allow reordering of the calculations, and
      native arch enables using ymm registers, which are 256 bits (otherwise
      only 128 bit xmm registers are used).
    - the assembly of `Ofast native` is 20 instructions, vs 11 for `O3 native`. However,
      the fast version only loops 12.5M times, 8x less than the O3 version. It packs
      more into each loop by using the 256 bit registers.
    - note that this line was critical: `double x = -1.0 + 2.0 * (i & 0x1)`
        - tried changing to `x = -x`
        - resulted in 4x slowdown, 32ms -> 120
        - the [comment on this line of C code](https://github.com/niklas-heer/speed-comparison/blob/fbe72677a25df85e1bcc6386c6069dd163f04962/src/leibniz.c#L24)
          says 'allows vectorisation'. I'm assuming this is due to removing the self-reference of x.
        - the assembly for `x = -x` loops 100M times, and doesn't use ymm registers
    - details can be found here: https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
- so there we have it! C# is as fast as standards-compliant C. You can break
  some rules in C to go 4x faster (or whatever your hardware allows), and still
  get correct results.
- what else is taking C# time?
    - what are the hand wavey reasons? do they apply here?
        - array bounds checking: no
        - null pointer checks: no
        - GC, JIT, runtime 'stuff': hmm prob not. Maybe that's what the mystery
          call is every 1000 iterations? If so, it's having negligible impact,
          given it's still running as fast as C.
    - what is that call every 1000 iterations? hard to find answers to this via
      searching. ChatGPT suggests GC, JIT, debugging/profiling tools. I wonder
      if AOT still has it. If not, maybe it's the debugger/profiler running in
      VS.

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


# Appendix: assembly
Assembler for C and C#. Just the looping section of 'CalcPi' is shown.

C (-Ofast -march=native):
```asm
1130:	c5 fd 6f c2          	vmovdqa ymm0,ymm2                           # ymm0 = ymm2
1134:	ff c0                	inc    eax                                  # eax += 1
1136:	c5 ed fe d7          	vpaddd ymm2,ymm2,ymm7                       # ymm2 += (4xi64)ymm7
113a:	c5 fd db ce          	vpand  ymm1,ymm0,ymm6                       # ymm1 = (4xi64)ymm0 & ymm6
113e:	c5 fd 72 f0 01       	vpslld ymm0,ymm0,0x1                        # ymm0 <<= 1, ymm0 *= 2
1143:	c5 fd fe c5          	vpaddd ymm0,ymm0,ymm5                       # ymm0 += ymm5     (ymm5 = -1?, see 1117)
1147:	c5 7e e6 c9          	vcvtdq2pd ymm9,xmm1                         # (4xi64) ymm9 = (4x double?)xmm1 ... https://www.felixcloutier.com/x86/cvtdq2pd
114b:	c4 e3 7d 39 c9 01    	vextracti128 xmm1,ymm1,0x1                  # xmm1 = ymm1[255:128]
1151:	c5 fe e6 c9          	vcvtdq2pd ymm1,xmm1                         # (4xi64) ymm1 = (4x double?)xmm1
1155:	c5 7e e6 d0          	vcvtdq2pd ymm10,xmm0                        # (4xi64) ymm10 = (4x double?)xmm0
1159:	c4 e3 7d 39 c0 01    	vextracti128 xmm0,ymm0,0x1                  # xmm0 = ymm0[255:128]
115f:	c4 62 e5 98 cc       	vfmadd132pd ymm9,ymm3,ymm4                  # (4x double): ymm9 = ymm9 * ymm4 + ymm3
1164:	c5 fe e6 c0          	vcvtdq2pd ymm0,xmm0                         # (4xi64) ymm0 = (4x double?)xmm0
1168:	c4 e2 e5 98 cc       	vfmadd132pd ymm1,ymm3,ymm4                  # (4x double): ymm1 = ymm1 * ymm4 + ymm3
116d:	c4 41 35 5e ca       	vdivpd ymm9,ymm9,ymm10                      # ymm9 /= ymm10
1172:	c5 f5 5e c0          	vdivpd ymm0,ymm1,ymm0                       # ymm0 = ymm1/ymm0
1176:	c5 b5 58 c0          	vaddpd ymm0,ymm9,ymm0                       # ymm0 += ymm9
117a:	c5 3d 58 c0          	vaddpd ymm8,ymm8,ymm0                       # ymm8 += ymm0
117e:	3d 20 bc be 00       	cmp    eax,0xbebc20                         # if eax != 12500000 (=100M/8)
1183:	75 ab                	jne    1130 <main+0x90>                     # goto 1130
```

C (-O3 -march=native, same speed as C# in Release mode)
```asm
1120:	89 c1                	mov    ecx,eax                # ecx = eax
1122:	c5 e3 2a d2          	vcvtsi2sd xmm2,xmm3,edx       # xmm2 = (double)edx?  https://www.felixcloutier.com/x86/cvtsi2sd
1126:	ff c0                	inc    eax                    # eax += 1
1128:	83 c2 02             	add    edx,0x2                # edx += 2
112b:	83 e1 01             	and    ecx,0x1                # ecx &= 1
112e:	c5 e3 2a c9          	vcvtsi2sd xmm1,xmm3,ecx       # xmm1 = (double)ecx?
1132:	c4 e2 d9 99 cd       	vfmadd132sd xmm1,xmm4,xmm5    # xmm1 = xmm1 * xmm5 + xmm4
1137:	c5 f3 5e ca          	vdivsd xmm1,xmm1,xmm2         # xmm1 /= xmm2
113b:	c5 fb 58 c1          	vaddsd xmm0,xmm0,xmm1         # xmm0 += xmm1
113f:	3d 02 e1 f5 05       	cmp    eax,0x5f5e102          # if eax != 100M+2
1144:	75 da                	jne    1120 <main+0x80>       # goto 1120
```

C# (Debug/Release? dunno):
```
00007FFF1835417B  vmovsd      xmm0,qword ptr [rbp-48h]       # xmm0 = *(rbp-48h)
00007FFF18354180  vmulsd      xmm0,xmm0,                     # xmm0 = xmm0 * *(07FFF18354210)    mmword ptr [Program.<<Main>$>g__CalcPi|0_0()+0E0h (07FFF18354210h)]
00007FFF18354188  vmovsd      qword ptr [rbp-48h],xmm0       # *(rbp-48h) = xmm0
00007FFF1835418D  vmovsd      xmm0,qword ptr [rbp-48h]       # xmm0 = *(rbp-48h)
00007FFF18354192  mov         eax,dword ptr [rbp-4Ch]        # eax = *(rbp-4Ch)
00007FFF18354195  lea         eax,[rax*2-1]                  # eax = *(rax*2-1)
00007FFF1835419C  vxorps      xmm1,xmm1,xmm1                 # xmm1 = 0
00007FFF183541A0  vcvtsi2sd   xmm1,xmm1,eax                  # xmm1 = (double)eax?  https://www.felixcloutier.com/x86/cvtsi2sd
00007FFF183541A4  vdivsd      xmm0,xmm0,xmm1                 # xmm0 /= xmm1
00007FFF183541A8  vaddsd      xmm0,xmm0,mmword ptr [rbp-40h] # xmm0 += *(rbp-40h)
00007FFF183541AD  vmovsd      qword ptr [rbp-40h],xmm0       # *(rbp-40h) = xmm0
00007FFF183541B2  mov         eax,dword ptr [rbp-4Ch]        # eax = *(rbp-4Ch)
00007FFF183541B5  inc         eax                            # eax += 1
00007FFF183541B7  mov         dword ptr [rbp-4Ch],eax        # *(rbp-4Ch) = eax
00007FFF183541BA  mov         ecx,dword ptr [rbp-58h]        # ecx = *(rbp-58h)
00007FFF183541BD  dec         ecx                            # ecx -= 1
00007FFF183541BF  mov         dword ptr [rbp-58h],ecx        # *(rbp-58h) = ecx
00007FFF183541C2  cmp         dword ptr [rbp-58h],0          # if *(rbp-58h) > 0
00007FFF183541C6  jg                                         # goto 07FFF183541D6   Program.<<Main>$>g__CalcPi|0_0()+0A6h (07FFF183541D6h)
00007FFF183541C8  lea         rcx,[rbp-58h]                  # rcx = *(rbp-58h)
00007FFF183541CC  mov         edx,33h                        # edx = 51
00007FFF183541D1  call        00007FFF77D8C9B0               # call mystery function
00007FFF183541D6  cmp         dword ptr [rbp-4Ch],5F5E102h   # if *(rbp-4Ch) < 100M +2
00007FFF183541DD  jl                                         # goto 07FFF1835417B
```

# further reading / study
**todo**
- plent ymore to do, see [[cs_c_rust_perf.project]]
