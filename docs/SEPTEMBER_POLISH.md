# Match-flow and minimalist UI update — 2026-09-12

Scope: improve the existing Flutter/Flame game, investigate unspecified LAN
failures, increase supplies, simplify game controls, preserve saved replays,
and publish the tested source. No engine rewrite or copied game artwork.

## Findings and priorities

1. Terminal snapshots could reveal results immediately, before the last move
   finished animating. Post-match disconnects could reintroduce pause controls.
2. A restarted local round reused its match identity. Completion deduplication
   and saved Continue state could therefore disagree about the new round.
3. Closing a room and opening another could overlap asynchronous resource
   shutdown; lobby UI did not observe terminal connection status. One generic
   connection error hid different causes, and copied IP:port values could gain
   a second port. Late WebSocket connection completion could leak a socket.
4. Radius-2 boards allowed too many seats, and their short supplies made ties
   common. Adding bands alone cannot eliminate inherent turn-order advantage.
5. Text-heavy setup, pause, and result panels obscured primary game actions.
   Valid-endpoint rings and hit areas shrank with the world-space camera zoom.

## Changes

- Final board presentation precedes results by 1.9 seconds at normal speed
  (motion-speed adjusted, bounded to 1.6–3 seconds; 700 ms with reduced motion).
  Repeated snapshots cannot bypass/reset that delay. End-of-match audio plays
  with the reveal. Finished games cannot resume/restart as an independent LAN
  client or enter a disconnect-pause loop.
- Fresh local restarts get new IDs and alternate the first seat. Replay keeps
  original settings. Completed/untouched/corrupt local saves cannot produce a
  Continue action; completion of another match cannot erase a valid newer save.
  An old asynchronous bot result cannot clear a newer bot request's busy state.
- LAN room exit awaits resource cleanup; join failures use typed localized
  reasons. Closed lobbies show a usable exit. Active games stop advertising.
  Lower-revision snapshots are ignored, expired-token reconnect attempts stop,
  late sockets are closed, and manual host addresses are normalized.
- Small boards allow two seats with six bands each. New Classic supplies are
  14 each for two seats, 16 each for three/four. Larger/custom boards retain the
  scaling formula with the new baseline. Rules v1 saves retain old supplies and
  serialization; rules v2 adds a serialized first-seat index. LAN protocol is
  now 2, so **every device must update together**.
- Shared icon actions have press feedback, accessible labels and tooltips.
  Board choices are original dot-lattice icons, with only the selected size's
  caption. Pause/result/disconnection panels use compact actions and no nested
  form cards. Small-phone spacing is denser; Start stays outside the scroll area.
- Legal endpoint targets are 48 logical pixels across at every zoom, rings are
  36 pixels with a stable stroke, and nearby valid endpoints take precedence
  over irrelevant pegs while completing a move.

## Small-board balance evidence

`dart run tool/small_board_balance.dart` performs exact offline minimax over
the real radius-2 two-human engine. This probe is never used on the UI isolate
or the player's device. Scores below are optimal first-seat minus second-seat:

| Bands per seat | Optimal score difference | Unique non-terminal states |
| --- | --- | --- |
| 3 (previous supply) | 0 | 2,504 |
| 4 | -1 | 7,878 |
| 5 | -2 | 11,833 |
| 6 (new supply) | -2 | 12,421 |

The new supply lengthens opportunities; it does **not** prove single-round
fairness. Alternating the starting seat shares that advantage across rounds.
Ties remain legitimate results, with no artificial winner or score bonus.

## Verification boundary

Final automated checks: `flutter test --no-pub` — **193 passed** (including
strict golden comparisons, without updating baselines); `flutter analyze
--no-pub` — **no issues found**. `dart format lib test tool integration_test`
completed. Tests/build logs are local artifacts under `build/sep12-*.log`.

`flutter build apk --release --target=lib/main.dart` — **passed**. The universal
Android APK is `build/app/outputs/flutter-apk/app-release.apk` (70.7 MB), built
after all tests with normal plugin regeneration. Build artifacts are ignored
by Git and are not uploaded with the source.

Regression coverage includes old-rule replay hashes, both completed rounds in
statistics, Continue cleanup, delayed results/cancelled timers, zoomed targets,
three real-loopback close/reopen cycles on one port, stale codes, seat capacity,
terminal snapshots, foreground recovery, and closed-lobby navigation. Golden
coverage checks phone/tablet game surfaces and Kazakh small-phone setup.

Automated loopback tests cannot certify phone-to-emulator routing, multicast
permissions, real Wi-Fi/hotspot behavior, sustained FPS, or device temperature.
No phone installation or device-test cleanup was performed for this revision.
The existing Android release configuration uses debug signing; store signing
and the physical device matrix remain separate release requirements.
