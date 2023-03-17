---
title: "What I wish I'd known about the command line"
date: 2021-05-29T14:48:00+11:00
draft: true
summary: "The lesson I'd give my past self about the command line"
tags:
- shell
- unix
---

# Contents (WIP)
- intro
  - CLI is useful!
  - reasons to learn CLI
- what is shell, terminal etc?
- some examples of things you can do
- where to start learning?
  - there are good sites. list a few
  - my focus is on unix-style environments
  - my suggestion
    - go through a site or two for the basics. cd, ~, mkdir, ls, pwd
    - pipes
    - common tools
    - aliases

# A lesson for my past self
As a budding developer, the command line had always seemed like a relic of an
older time. I didn't know any commands, and the ones I did use for compiling C
were magical. I had grown up using Windows, so was used to having a GUI for
everything.

I wish I'd known otherwise. I now use the command line every day to do
productive work. It took me too long to get to this point though. I avoided the
command line, seeing it as something people used to show off, or just a
necessity for 'old' software that people couldn't be bothered creating shiny new
GUIs for. How naive!

This post is the advice I wish I'd received when I was starting out as a
programmer. It's geared towards programmers, not operations/security folk.

# Why should I learn how to use the command line?

reasons in priority order
- portable - works anywhere
    - windows
    - docker & kubernetes & linux machines on EC2
        - bash scripts for building etc. have been around for decades - likely
          to stay for a while
    - git - the cli's not the easiest, but at least it works the same everywhere
    - raspberry pi - they're much cheaper to use if you know how to use an ssh
      terminal!
- Linux dev environment. More tools available, open source, common text interfaces
- can do powerful things that you may otherwise use a spreadsheet & lots of
  manual work to do
    - bulk moving/renaming/editing files
- Once you're familiar with a few unix commands, it's a lot easier to learn more,
  as they all share similar patterns.
    - POSIX or other stanards for unix apps?

# Where to start?
Hopefully I've convinced you that learning to use a command line is worth your
while. How to start?

## What is a command line?
Firstly, some definitions. A command line interface (CLI) is a text-based way to
interact with a computer. Instead of clicking on buttons, dragging and dropping
files, resizing windows etc., you enter commands as text to get work done.

## What is a shell, terminal, console??
There are a bunch of other terms that are often used when talking about the
command line. Shell, terminal, console, command prompt, CLI. What do they all
mean?

I used these terms interchangeably for years, not really understanding what they
were. Luckily, it doesn't really matter, but to save years of wondering, here
they are:

![](/blog/xxxx_command_line/command_line_shell_terminal.png)

The terms come from the 60/70s, so are easier to explain in that context. The
user on the right interacts with a screen and a keyboard called a terminal. They
give input to the computer via the keyboard, and see results on the screen. The
terminal is connected via a port to an actual computer (or mainframe back in
those days). The port is the pipe through which text travels to the screen and
from the keyboard. Terminals were sometimes called consoles, and ports seem to
also be called consoles, so I'm still a bit confused.

Next we have the shell. A shell is a program designed for humans to interact
with the operating system (OS). The human interacts with the shell through the
terminal. The shell prompts the human for input, gives the OS instructions based
on the input, and shows the results to the human.

Some other terms I haven't covered:
- command line/prompt: the point at which the shell is prompting the user for
  a command. This is a prompt:

```sh
$
```

This is also a prompt:

```sh
>
```

A prompt is just some visual indicator that the shell is waiting for input.
Commands are generally entered as a single line, with the user pressing enter
being the trigger for the command to be executed. This is probably where the
name 'command line' comes from.

So to summarise, a user interacts with a shell through a terminal, which is
connected to the shell via a console/port. Another quick summary:

- shell: interactive text-based interface for a human to interact with a computer
- terminal:
- console:
- CLI:
- command line:
- prompt:

# Examples of useful things
Just an appetiser before you get bored.
- sort, uniq, comm

# What next
- my idea of what's useful for programmers
    - basic navigation, creating, editing, moving files
    - composing commands with pipes
      - unix philosophy
      - [[202105151134_unix_pipes]]
    - scripting
- aliases
- common tools, common patterns for args etc.
  - find links to docs on this
- grep, ls, mkdir, cd, cat, nano, ssh, cat, touch, git, rm
- bash
- vim???
- raspi
- ssh-ing into pods etc.
- explorer .
- code .
- randnote

# todo
- learning resources
    - [art of unix programming](http://www.catb.org/esr/writings/taoup/)
    - [myob](https://github.com/MYOB-Technology/General_Developer/blob/main/things-we-value/technical/programming/unix-command-line.md)
- integrate/add stuff from this post: https://www.warp.dev/blog/what-happens-when-you-open-a-terminal-and-enter-ls
    - my notes
        - terminal is just another app. its purpose: let you "use the computer":
          run programs
        - terminal spawns a shell
        - login vs non-login shell?
            - login runs .profile
        - shells have their own languages and syntax, although bash influence
          seems strong


# out of scope
- my git workflow
- https://github.com/MYOB-Technology/tax-list-api-deploy/pull/47
    - quirks of `set -e`, unnecessary pipes, what is && and ||?

# References
- [wikipedia: system console](https://en.wikipedia.org/wiki/System_console)
- [wikipedia: command-line interface](https://en.wikipedia.org/wiki/Command-line_interface)
- [wikipedia: computer terminal](https://en.wikipedia.org/wiki/Computer_terminal)

# Learning resources
- http://www.ee.surrey.ac.uk/Teaching/Unix
  - from the basics: what is kernel, shell, creating files and dirs
- https://overthewire.org/wargames/bandit/
  - kinda security focused
  - learn a range of commands and their various options
- https://unixgame.io/unix50
  - solve challenges using commands & pipes
  - build command pipelines with a neat graphical editor!
  - I found it a little confusing, as I am already familiar with typing in
    commands
- [bash programming guide](https://tldp.org/HOWTO/Bash-Prog-Intro-HOWTO.html)
- [the art of unix programming](http://www.catb.org/esr/writings/taoup/html/)
  - an entire book on programming in unix, and the unix philosophy
