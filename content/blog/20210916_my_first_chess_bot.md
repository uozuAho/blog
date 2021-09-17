---
title: "My first chess bot"
date: 2021-09-16T21:57:19+10:00
draft: true
summary: "Making computers play chess"
tags:
- ai
- chess
- python
---

In my spare time, I've been slowly learning about reinforcement learning. I came
upon [this post](https://healeycodes.com/building-my-own-chess-engine/) by
Andrew Healey about making a chess engine, and thought "I know all about AI,
I'll make a bot that beats his!". Read on to see how that went.


# Step one: Andoma vs. random bot
Andrew's chess engine is called Andoma. See the code [here](https://github.com/healeycodes/andoma).

To get a better understanding of how to use Andoma, I made a random bot that it
could play against. This way, I could quickly see how Andoma performs against
a rubbish opponent. As expected, Andoma wins every game.

```py
def andoma_vs_random():
    board = chess.Board()

    def move():
        return random_move(board) if board.turn == chess.WHITE else andoma_move(board)

    while not board.is_game_over():
        board.push(move())

    print('Random [W] vs Andoma [b]:')
    print(board)
    print(f"\nResult: [W] {board.result()} [b]")

def andoma_move(board: chess.Board) -> chess.Move:
    return next_move(1, board, debug=False)

def random_move(board: chess.Board) -> chess.Move:
    legal_moves = list(board.legal_moves)
    return random.choice(legal_moves)
```

The result:

```
Random [W] vs Andoma [b]:
r . . . . r k .
p p p . . p p p
. . p . . . . .
. . b . . . . .
. . . . . . . .
. . . n p . . .
. . . q . . . P
. . . K . . . R

Result: [W] 0-1 [b]
```

See [notation]({{< ref "#notation" >}}) to understand the output.


# Step two: make a chess bot with OpenSpiel
I've been playing with [OpenSpiel](https://github.com/deepmind/open_spiel),
which comes with a bunch of algorithms and environments. It's got an algorithm I
want to use to fight Andoma, but my first baby step is to just make a simple
bot. Luckily, OpenSpiel comes with its own chess implementation. It should be
simple to make two random bots fight:


```py
""" Two random chess bots fight in OpenSpiel"""
import numpy as np

import pyspiel
from open_spiel.python.bots import uniform_random

game = pyspiel.load_game("chess")
state = game.new_initial_state()
player_1 = uniform_random.UniformRandomBot(0, np.random.RandomState())
player_2 = uniform_random.UniformRandomBot(1, np.random.RandomState())

players = [player_1, player_2]

while not state.is_terminal():
  current_player_idx = state.current_player()
  current_player = players[current_player_idx]
  action = current_player.step(state)
  state.apply_action(action)

print('final state:')
print(state)
is_draw = all((r == 0 for r in state.returns()))
if is_draw:
  print('draw!')
else:
  winner = 'player_1' if state.returns()[0] > 0 else 'player_2'
  print(f'winner: {winner}')

```

```
final state:
8/5k2/8/8/8/1K6/8/8 w - - 0 176
draw!
```

If you're interested in using OpenSpiel, my [OpenSpiel playground](https://github.com/uozuAho/open_spiel_playground)
can get you up and running with relative ease. [OpenSpiel's](https://github.com/deepmind/open_spiel)
documentation is also decent.


# Step 3: Andoma vs MCTS
Time for a stronger opponent. Now that I've got OpenSpiel set up, I want to try
its [Monte Carlo Tree Search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search)
(MCTS) algorithm.

I've recently learned about MCTS. It's more of a planning algorithm than a
learning algorithm, but can be coupled with learning algorithms to make it more
effective. MCTS is somewhat similar to alpha-beta pruning (which Andoma uses),
in that it explores a number of game trajectories from the current game state,
and picks the most promising move based on the outcomes of those trajectories.
The difference is that while Andoma only explores a few moves in advance, MCTS
plays multiple games to completion from the current state. The average outcome
of games played from that state detemines how 'promising' a state it is. For
example, if you see 10 wins and 10 losses from one game state, but 18 wins and
2 losses from another state, then the latter state is more promising.

An advantage of this approach is that MCTS does not need any evaluation of
intermediate game states like Andoma does. MCTS only cares about the outcomes of
completed games. In fact, a simple MCTS implementation can make random moves to
simulate games from the current state.

<figure>
  <img src="/blog/20210916_my_first_chess_bot/alpha-beta-pruning.png"
    alt=""
    width="1024"
    loding="lazy" />
  <figcaption>Alpha-beta pruning. Lower scores are better. Branches that cannot
  achieve the low scores of other branches are abandoned.</figcaption>
</figure>

<figure>
  <img src="/blog/20210916_my_first_chess_bot/MCTS_rollout.png"
    alt=""
    width="684"
    loding="lazy" />
  <figcaption>A representation of MCTS 'rollout'. After playing a number of
  games from the current state, branch B looks the most promising.</figcaption>
</figure>

- MCTS more DFS, AB more depth first
- possible depth of chess games likely a stumbling point for MCTS

drawbacks:
- need complete game information
- need an accurate game model to run simulations, ie. a chess game engine


I wrapped Andoma in an OpenSpiel bot interface (see below). It took a bit of
learning about [[FEN | 202109082025_chess_fen]] and [[chess move notation | 202109082037_chess_notation]]
to map pychess's moves to the valid moves presented by OpenSpiel's chess
implementation.

My code is here: [mcts vs andoma](https://github.com/uozuAho/open_spiel_playground/blob/main/mcts_vs_andoma.py)

```py
class AndomaBot(pyspiel.Bot):
  def __init__(self, search_depth=1):
    pyspiel.Bot.__init__(self)
    self.search_depth = search_depth

  def step(self, state: pyspiel.State) -> int:
    board = chess.Board(str(state))
    move = movegeneration.next_move(self.search_depth, board, debug=False)
    return self._pychess_to_spiel_move(move, state)

  def _pychess_to_spiel_move(self, move: chess.Move, state: pyspiel.State):
    # This is necessary, as openspiel's chess SANs differ from pychess's.
    # For example, in a new game, openspiel lists 'aa3' as a valid action. The
    # file disambiguation is unnecessary here - pychess lists this action as
    # 'a3'.
    board = chess.Board(str(state))

    def action_str(action):
      return state.action_to_string(state.current_player(), action)

    move_map = {board.parse_san(action_str(action)): action for action in state.legal_actions()}

    if move not in move_map:
      raise RuntimeError(f"{move} is not a legal move!")

    return move_map[move]
```

With that thin wrapper, I had the MCTS and Andoma bots fighting!

So far, MCTS is winning every game, even when Andoma's search depth is set to
3 (slow!), and MCTS only does 2 full game simulations on each move. I feel like
I've done something wrong ... is Andoma really that weak?

UPDATE: No! I did something wrong. I was printing MCTS whether it won or lost,
derp. With that fixed, I now find that Andoma with a search depth of 1 beats
MCTS up to 10 simulations + 10 rollouts. Makes sense. MCTS is making random
moves, which, given the number of possible moves in chess, is unlikely to find
winning plays!

Even vs a random player, MCTS didn't win all its games. It had a decent win rate
once the number of simulations and rollouts were > 6, but these games took up to
40s to run. On the other hand, Andoma wins every game against a random opponent,
even at a search depth of 1.


# Step 4: MCTS with Andoma rollout
- just played vs rando. Slower, but wins some
- theory: need more sims, otherwise is not evaluating enough moves
- try a pure greedy bot?


# Appendix: chess notation {#notation}
I had to learn a bunch of chess notation to be able to build these bots. Here's
what I learned.

## Chess pieces
The notation systems here use the following characters to denote chess pieces:
- k = king
- q = queen
- r = rook
- n = knight
- b = bishop
- p = pawn

Lowercase letters are black pieces, uppercase are white.

## Forsyth-Edwards Notation (FEN)
FEN describes the current state of the game with a line of characters. There's
plenty of descriptions of FEN on the internet. If you want more details,
[here's one](https://www.chess.com/terms/fen-chess). Here's my crash course.

A FEN string looks like this:

`rnbqk1nr/p1ppppbp/1p4p1/8/2P5/2Q5/PP1PPPPP/RNB1KBNR b KQkq - 0 1`

The first chunk of characters describes the position of the chess pieces. The
above string translates to:

```
r n b q k . n r
p . p p p p b p
. p . . . . p .
. . . . . . . .
. . P . . . . .
. . Q . . . . .
P P . P P P P P
R N B . K B N R
```

The characters after the piece positions:
- b: it is currently black's turn to move (w for white's move)
- KQkq: castling rights
- -: "en passant targets". I don't really know what this means, but it didn't get
  in the way of making my chess bots.
- 0: halfmove clock: number of moves since a pawn move or a capture. Can call
  the game a draw if this clock reaches 100
- fullmove counter: increments by one after each black move

```
rnbqk1nr/p1ppppbp/1p4p1/8/2P5/2Q5/PP1PPPPP/RNB1KBNR b KQkq - 0 1
───────────┬───────────   ────────────┬──────────── ▲ ──┬─ ▲ ▲ ▲
           │                          │             │   │  │ │ └─fullmove counter
           │                          │             │   │  │ │
           │                          │             │   │  │ └───halfmove clock
           │                          │             │   │  │
           │                          │             │   │  └─────en passant targets
           │                          │             │   │
           │                          │             │   └────────castling rights, white, black
           │                          │             │
           │                          │             └────────────black's move
           │                          │
           │                          └──────────────────────────white pieces are uppercase
           │
           └─────────────────────────────────────────────────────black pieces are lowercase
```


## Move notation
FEN only describes the current game state, not moves that occur within the game.
There are multiple notations, but [algebraic notation](https://en.wikipedia.org/wiki/Algebraic_notation_(chess))
seems to be pretty common.

### Rank & file
- rank = row
- file = column

```
rank
   |
   v

   8   r n b q k . n r
   7   p . p p p p b p
   6   . p . . . . p .
   5   . . . . . . . .
   4   . . P . . . . .
   3   . . Q . . . . .
   2   P P . P P P P P
   1   R N B . K B N R

       a b c d e f g h   <-- file
```

### Moves
Moves are denoted by the letter specifying the piece, and the board position it
moves to. Pawn moves don't use a letter specifier. For example:

- `Nf3`: white knight to f3
- `a3`:  (in the board above): white pawn to a3

Note that without knowledge of the current game state, there is ambiguity in
this move notation: for example, 'a3' could mean different moves, depending on
the current game state.


# References
- [Andrew Healey: Building My Own Chess Engine](https://healeycodes.com/building-my-own-chess-engine/)
- [OpenSpiel](https://github.com/deepmind/open_spiel)
- My [OpenSpiel playground](https://github.com/uozuAho/open_spiel_playground)
- RL book
