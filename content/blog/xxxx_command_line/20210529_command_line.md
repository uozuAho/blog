---
title: "How I use the command line"
date: 2021-05-29T14:48:00+11:00
draft: true
summary: "How I use the command line"
---

# todo
- put images in static dir

# What I wish I had known
As a budding developer, the command line had always seemed like a relic of an
older time. I didn't know any commands, and the ones I did use for compiling C
were magical. I had grown up using Windows, so was used to having a GUI for
everything.

I wish I'd known otherwise. I now use the command line every day to do
productive work. Like I did in my yesteryears, I still occasionally see a
"Windows developer" creating a GUI to do a simple task that would take minutes
on the command line.

Here's the advice I'd give myself when I was starting out as a programmer.

reasons in priority order
- portable - works anywhere
    - windows
    - docker & kubernetes & linux machines on EC2
        - bash scripts for building etc. have been around for decades - likely
          to stay for a while
    - git - the cli's not the easiest, but at least it works the same everywhere
    - raspberry pi - they're much cheaper to use if you know how to use an ssh
      terminal!
- can do powerful things that you may otherwise use a spreadsheet & lots of
  manual work to do
    - bulk moving/renaming/editing files
- Once you're familiar with a few unix commands, it's a lot easier to learn more,
  as they all share similar patterns.
    - POSIX or other stanards for unix apps?
- what's the shell, terminal, command line, console?

# Where to start?
Hopefully I've convinced you that learning to use a command line is worth your
while. How to start?

## What is a command line?
A command line is a text-based way to interact with a computer. Instead of
clicking on buttons, dragging and dropping files, resizing windows etc., you
enter commands to get work done.

## What is a shell, terminal, console??
There are a bunch of other terms that are often used when talking about the
command line. Shell, terminal, console, command prompt, CLI. What do they all
mean?

In short, a user interacts with a shell through a terminal, which is connected
to the shell via a console/port.

I used these terms interchangeably for years, not really
understanding what they were. Luckily, it doesn't really matter, but to save
years of wondering, here they are:

![](./img/202105201110_command_line_shell_terminal1.png)

todo
- put example OSs under OS

The terms come from the 60/70s, so are easier to explain in that context. The
user on the right interacts with a screen and a keyboard called a terminal. They
give input to the computer via the keyboard, and see results on the screen. The
terminal is connected to a console or port an actual computer (or mainframe back
in those days). The port is the pipe through which text travels to the screen
and from the keyboard.

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
connected to the shell via a console/port.

# Some examples problems that are easily solved in the command line
## Rename a bunch of files
```sh
```
## Move a bunch of files
```sh
```
## Find duplicate filenames
```sh
find . -exec basename {} \; | sort | uniq -d
# dummy input
cat << EOF | xargs basename | sort | uniq -d
/my/music/folder1/song1.mp3
/my/music/folder2/song1.mp3
/my/music/folder3/song1.mp3
/my/music/folder4/other_song.mp3
EOF
```
##

# What I use daily
Typical workflow at work (mostly git):
```sh
woz  # an alias for 'cd /c/woz'. This is where I put all 'my stuff', so that's
     # where I start my day :)
cd some_project
git st  # check the current status of the project. 'st' is an alias for 'status'
git lg  # check the git log. what was I doing recently?
git p   # if there's no local changes, get the latest from the server
        # 'p' is an alias for 'pull --prune'
git cob some_new_work # start a new branch for some changes I want to make
code .  # open VS code in this directory
explorer . # open explorer in this directory, so I can double-click on a visual studio solution file :(
git push -u origin some_new_work
# someone asks me how to connect to a database. I can never remember the command,
# so, you guessed it! I created an alias. I even forget my alias's names, but I
# can search them:
alias | grep db  # all my database aliases have 'db' in them somewhere
```

- aliases
- grep, ls, mkdir, cd, cat, nano, ssh, cat, touch, git, rm
- bash
- raspi
- ssh-ing into pods etc.
- explorer .
- code .

# Times I've used a shell to do useful work
- [ledger cache: searching for bank feed updates](https://myobconfluence.atlassian.net/wiki/spaces/~440109569/blog/2020/10/05/1669763962/Are%2Bbank%2Bfeed%2Bstatuses%2Bout%2Bof%2Bdate%2Bon%2Btransaction%2Bprocessing)
- [getting a postgres database schema](https://myobconfluence.atlassian.net/wiki/spaces/~440109569/blog/2020/12/03/1844710943/Rummaging+around+the+protege+dashboard+databases)
  - note this is out of date, use pg_dump instead
- [ledger cache: getting recently used ledgers](https://myobconfluence.atlassian.net/wiki/spaces/PWT/blog/2020/06/04/1365805259/Ledger%2Bcache%2BCloudWatch%2Binsights%2Bshell%2Btrickery)
- my bank transactions categoriser

- more examples: de-dupe a huge list? count occurrences? execute a command against all files/subset?
        get all dotnet packages used by all projects

# where to start
- my idea of what's useful for programmers
    - basic navigation, creating, editing, moving files
    - composing commands with pipes
      - unix philosophy
      - [[202105151134_unix_pipes]]
    - scripting


# todo
- [[what's the difference between a terminal, shell, command line? | 202105201110_command_line_shell_terminal_difference]]
- [[202105151134_unix_pipes]]
- [[202105151139_sort_unix_vs_python]]
- [[202105130850_peter_command_line_vid]]
- [[202101091028_unix_commands]]
- what do I use daily?
    - bash
    - aliases
    - cat touch mv cp git ls mkdir rm
    - randnote
- https://github.com/MYOB-Technology/tax-list-api-deploy/pull/47
    - quirks of `set -e`, unnecessary pipes, what is && and ||?
- my idea of what's useful for programmers
    - basic navigation, creating, editing, moving files
    - composing commands with pipes
    - scripting
- prolly different to ops/security people, who may need:
    - permissions, common monitoring & ops tools
- learning resources
    - http://www.ee.surrey.ac.uk/Teaching/Unix
        - from the basics: what is kernel, shell, creating files and dirs
    - https://unixgame.io/unix50
        - solve challenges using commands & pipes
        - build command pipelines with graphical editor! neat.
    - https://overthewire.org/wargames/bandit/
        - kinda security focused
        - learn a range of commands and their various options
    - bash scripting: https://tldp.org/HOWTO/Bash-Prog-Intro-HOWTO.html
    - https://www.pluralsight.com/courses/linux-cli-fundamentals
    - [art of unix programming](http://www.catb.org/esr/writings/taoup/)
    - [myob](https://github.com/MYOB-Technology/General_Developer/blob/main/things-we-value/technical/programming/unix-command-line.md)
