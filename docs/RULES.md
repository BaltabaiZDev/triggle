# TriGrid Rules

Status: product rules, version 2 (2026-09-12).

The requested larger band supply is an explicit versioned change. New matches
use v2; saved v1 matches and replays still load with their original 10/12-band
Classic supplies, original custom formula, first seat, and state hashes. New
LAN matches require protocol 2 on every device. Geometry, move legality,
capturing, scoring, and ties are unchanged.

## 1. Objective

Players place straight bands across pegs. A player captures a small triangular
cell when their newly accepted band completes that cell's third boundary edge.
Each captured triangle is worth one point. The player with the most points at
the end wins; tied scores produce a tied result.

## 2. Board geometry

The board is a finite hexagon cut from a triangular lattice. Logical geometry
uses integer axial coordinates `(q, r)` with the derived cube coordinate
`s = -q - r`. A peg is inside a radius-`R` board exactly when:

```text
max(abs(q), abs(r), abs(s)) <= R
```

The three undirected lattice axes are represented by canonical directions
`(1, 0)`, `(0, 1)`, and `(1, -1)`. Screen positions never determine legality.

For radius `R`:

- peg count is `1 + 3R(R + 1)`;
- unit triangular-cell count is `6R²`;
- possible four-peg band templates are `9R² - 9R - 6`, for `R >= 2`.

The Classic board has radius 3, 37 pegs, 54 unit triangles, and 48 distinct
four-peg band templates.

## 3. Match setup

A match has two, three, or four seats. Each seat is occupied by a human or bot.
Board size remains selectable independently, except radius 2 is limited to two
players in v2. Choosing a third/fourth local player on Small promotes the board
to Classic. A LAN host cannot shrink a board if occupied seats would be lost.

### Classic, two players

- Classic radius-3 board
- 14 bands per player (v1: 10)
- 21 capture markers available per player
- the match ends after both players use all 14 bands, unless no legal move
  remains earlier

### Classic, three or four players

- Classic radius-3 board
- 16 bands per player (v1: 12)
- 21 capture markers per player
- a player must make a legal move on their turn when one is available

Classic rules can only be selected with the Classic board. Other board sizes
are labeled **Custom rules**.

## 4. A legal band move

A band move is an ordered run of three unit edges connecting exactly four
consecutive pegs on one lattice axis. The authoritative validator applies these
checks in a stable order:

1. The game has not ended.
2. The action ID has not already been accepted or rejected for this match.
3. The acting seat is the current seat.
4. The player has at least one band remaining.
5. Both submitted endpoints exist on the board.
6. The endpoints are separated by exactly three unit steps.
7. All four consecutive pegs exist and use one legal lattice direction.
8. The full segment is inside the board and follows lattice edges; it therefore
   cannot pass through the center of a triangular cell.
9. The exact four-peg band has not already been placed in either endpoint order.
10. At least one of its three unit edges is not already occupied.
11. Except for the first accepted move, at least one of its four pegs belongs
    to the existing band network.

Partial overlap is legal when the new band adds at least one unused unit edge.
Crossing at a peg is legal because it shares that peg. A move is never legal
merely because a client displayed it as legal; local play, bots, the LAN host,
replays, and tests all use the same validator.

The first accepted move may be placed anywhere that satisfies every rule other
than the existing-network connection rule.

## 5. Capturing triangles

Unit-edge occupancy is global: an edge counts as present regardless of which
player placed the band covering it.

After a legal band is applied, the engine examines the triangular cells
adjacent to its three affected edges. Every unclaimed cell whose three boundary
edges are now occupied is captured by the acting player in the same atomic
action. One move can capture multiple triangles.

- Previously captured triangles never change owner.
- Every newly captured triangle adds one point.
- A marker or accessible player symbol is rendered inside each captured cell.
- Capturing does not grant an extra turn; after capture resolution, play
  advances to the next eligible seat.

The action remains atomic if a multi-capture reaches the marker limit: all cells
completed by that move receive the same owner, the displayed remaining-marker
count stops at zero, and the applicable marker-limit end condition is evaluated
immediately. This resolution prevents network peers from applying only part of
one deterministic action.

## 6. Turn progression

Turns advance in configured seat order. A player with no bands remaining is
skipped. A player may not voluntarily pass when a legal move is available.

V2 records `startingPlayerIndex` in match settings. Restarting locally creates
a new match ID and rotates the first seat; replaying keeps the original ID,
seed, rules version, and first seat. Fresh local/LAN setups rotate by completed
local/LAN match count respectively. Alternation spreads turn-order advantage
across rounds; it does not promise a balanced result in every single match.

If no legal band template remains for the current board state, the match ends.
Because all active players share the same board geometry, legality differs by
seat only when a seat has no bands remaining.

## 7. End conditions

The host or local engine evaluates end conditions after each atomic action and
before requesting another turn.

### Classic, two players

The match ends when both players have used 14 bands (10 in v1) or when no legal move
remains earlier.

### Classic, three or four players

The match ends when the first applicable condition occurs:

1. a player reaches the 21-marker limit;
2. every available player band has been played;
3. no legal move remains.

The winner is the player or tied group with the highest captured-triangle
score. No secondary tie-breaker is used in Classic rules.

## 8. Non-Classic boards

Presets are Small (radius 2), Classic (radius 3), Large (radius 4), and Huge
(radius 5). Custom radii are represented by the engine from 2 through 8. The UI
does not expose a radius above 8. Milestone 8 benchmarks and regression tests
record radius 8 as the safe maximum in `docs/PERFORMANCE.md`.

All non-Classic sizes keep the exact four-consecutive-peg placement and capture
rules, but use **Custom rules** supply limits:

```text
T = 6R²                         // unit triangles
M = 9R² - 9R - 6               // band templates
B = 14 for two players, else 16   // v1: 10 / 12

bands per player =
  min(max(1, round(B × M / 48)), max(1, floor(M / playerCount)))

markers per player =
  max(1, round(21 × T / 54))
```

V2 radius-2 matches use 6 bands per player, covering all 12 possible templates
between two players. The formula still determines their marker supply (9).
This is a special supply override, not a new capture or scoring rule.

For scaled non-Classic boards, the fair-share cap ensures total initial bands never exceed the number of
distinct move templates. Custom matches end when a player reaches the custom
marker limit, all supplied bands are exhausted, or no legal move remains. Ties
are supported.

## 9. Validation result contract

Validation returns data, not only a Boolean:

```text
MoveValidationResult
  isValid
  errorCode
  localizedMessageKey
  affectedEdges
  newlyCapturedTriangles
```

Stable error codes include `gameEnded`, `duplicateAction`, `notPlayersTurn`,
`noBandsRemaining`, `unknownEndpoint`, `wrongLength`, `wrongAxis`,
`outsideBoard`, `duplicateBand`, `addsNoEdge`, and `notConnected`.
Human-readable messages are localized by the presentation layer; the pure Dart
engine returns codes and message keys.

## 10. Determinism

Given the same board definition, rules version, player configuration, initial
seed, and ordered accepted actions, every device must reproduce identical:

- occupied unit edges and placed bands;
- captured-triangle ownership;
- scores and remaining supplies;
- active seat and match result;
- canonical state hash.

Animation timing, particles, sound, camera position, and previews are never part
of authoritative state.
