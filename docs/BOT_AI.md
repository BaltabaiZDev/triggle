# TriGrid Bot AI

Status: Milestone 5 implementation  
Authority: bots request moves; `GameEngine` remains the only move authority

## Goals

TriGrid bots use exactly the public information and legal moves available to a
human. They do not mutate `GameState`, bypass `MoveValidator`, or inspect hidden
data. The same implementation supports two to four seats and every board radius
from 2 through 8.

Bot work runs in a Dart isolate through `BotWorker`. The UI sends a serialized
immutable state plus `BotSettings`; the worker returns a serialized
`BotDecision`. The session checks the state revision, player ID, and move
legality again before submitting the request to the authoritative engine.
Results from a paused, restarted, replayed, or otherwise advanced state are
discarded.

## Difficulty levels

| Level | Selection model | Typical behavior |
| --- | --- | --- |
| Beginner | Seeded random; notices an immediate capture 30% of the time | Fast, legal, visibly misses tactics |
| Easy | One-ply ranking with reply-risk checks | Always takes the largest immediate capture and avoids obvious gifts |
| Normal | Iterative deepening to depth 2 | Balances score, reply risk, mobility, and future capture options |
| Hard | Iterative deepening to depth 4 | Alpha-beta for two players; MaxN for three or four |
| Expert | Iterative deepening to depth 5 with a larger budget | Adds multi-capture trap pressure and broader ordered branches |

Search is time-bounded in normal play. Defaults are configured per seat and can
be changed from 50 to 2,000 milliseconds in local setup. The engine always
retains the best move from the last fully completed depth. If the isolate fails,
the session revalidates and submits the first legal move as a safety fallback,
so a bot never forfeits a turn while legal play exists.

For tests and reproducible simulations, `BotSettings.deterministic` replaces
the wall-clock cutoff with a fixed node budget:

- Normal: 1,800 nodes
- Hard: 14,000 nodes
- Expert: 42,000 nodes

Beginner randomness uses a stable integer seed derived from match seed,
revision, seat, difficulty, personality, and `seedOffset`. It does not use
platform hash randomization.

## Search

All levels start with `MoveValidator.legalMoves`. Captures are resolved only by
simulating an ordinary `SubmitMoveAction` through `GameEngine`.

Two-player Hard and Expert use alpha-beta with the root bot maximizing and the
opponent minimizing. Three- and four-player searches use MaxN: each seat chooses
the child that maximizes its own evaluation component. Search uses:

- capture-first move ordering;
- stable move-ID tie breaking;
- branching caps that grow with difficulty;
- SHA-256 state-hash transposition keys;
- terminal winner/tie scoring;
- iterative deepening with last-complete-depth retention.

There is no hidden-information model because TriGrid has perfect information.
Expert opponent modeling comes from MaxN and explicit next-player
multi-capture/trap evaluation rather than privileged data.

## Evaluation

Captured triangles dominate evaluation. Secondary terms break strategically
meaningful ties:

- relative held score;
- maximum immediate capture available;
- count of capturing and multi-capturing replies;
- legal-move mobility;
- new unit-edge expansion;
- remaining band supply;
- distance from the board center as a light opening preference.

Personality changes real weights rather than cosmetic timing:

| Weight | Aggressive | Defensive | Balanced |
| --- | ---: | ---: | ---: |
| Immediate capture | 1,250 | 980 | 1,100 |
| Opponent reply risk | 460 | 920 | 680 |
| Trap risk | 18 | 62 | 38 |
| Expansion | 13 | 8 | 10 |
| Held score | 1,100 | 1,000 | 1,050 |
| Opponent score | 850 | 1,120 | 1,000 |
| Future capture | 145 | 95 | 120 |
| Mobility | 5 | 8 | 7 |

Aggressive bots favor their own capture sequences and expansion. Defensive bots
spend more value denying the next player and preserving options. Balanced bots
split those priorities.

## Performance and determinism

Board geometry is cached by `BoardGenerator`. Search orders and caps moves
before recursion, and transposition tables are scoped to one decision so memory
cannot leak across matches. No AI work runs on Flutter's UI isolate.

Accepted bot actions are stored in the same replay log as human actions. A
replay does not rerun AI; it reapplies those accepted actions, guaranteeing the
same final state and hash even if bot tuning changes later.

## Tests

The bot suite verifies:

- every level returns a legal move on every supported radius 2–8;
- deterministic settings reproduce move, depth, and node count;
- Easy takes the largest available immediate capture;
- with the same configured thinking time, a seeded Beginner can miss that
  capture while Easy takes it, and Normal/Hard/Expert complete distinct
  deterministic depths 2/4/5 on the same Small position;
- four-player MaxN returns a legal decision;
- a real isolate request round-trips correctly;
- bot configuration survives settings and state serialization;
- mixed human/bot turns execute automatically;
- stale bot results are rejected after restart;
- bot-vs-bot debug matches complete autonomously.

Physical-device tuning should still measure perceived thinking delay and battery
use on Large and Huge boards during Milestone 8.
