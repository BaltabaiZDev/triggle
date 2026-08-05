# TriGrid Acceptance Audit

Audit date: 2026-07-31  
Source specification: `pasted-text-1.txt` supplied with the project task  
Toolchain: Flutter 3.41.4 stable, Dart 3.11.1, Android SDK 37.0.0

This is an evidence map, not a substitute for the remaining physical-device
matrix. `Verified` means the behavior has executable automated evidence or was
observed on a real target. `Implemented` means the complete code path exists
but still needs the explicitly listed external device gate.

## Automated and build evidence

- `dart format .`: clean.
- `flutter analyze`: no issues.
- `flutter test`: 150 tests passed.
- `flutter test test/performance/large_board_performance_test.dart`: all three
  Large/Huge/maximum-Custom gates passed.
- `dart run tool/performance_benchmark.dart`: radius-8 generation 8.677 ms,
  cached legal lookup ×10,000 0.240 ms, complete deterministic match
  181.293 ms, Normal bot 83 ms on the recorded Windows/JIT host.
- `flutter build apk --debug`: succeeded.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`, 214,644,258 bytes,
  SHA-256
  `13C6DB5DFAEC0DF6F297120B8E4DCF0C7DF7F2B7757138F44E344925275756F0`.
- Current acceptance build ID:
  `debf8b3c8ed2309dfd1c7f35d9e90fbcd4494f1cec3ea836bae5effef88fd1bc`.
- APK inspection: application ID `com.trigrid.game`, minimum SDK 24, target
  SDK 36, expected LAN/camera/vibration permissions present.
- Physical Android 13 replace-install and cold launch: succeeded; the process
  remained alive, the localized main menu rendered, music/ambient playback
  started, and the sampled log contained no fatal exception. Screenshot:
  `build/device-smoke/main-menu-final.png`.
- A profile-build integration run on that phone registered
  `_trigrid._tcp` through the native `nsd` plugin and rediscovered/decoded its
  own room at `192.168.8.15:43119`. The same run navigated the real app from
  the English main menu into a Classic local match, submitted a legal move,
  verified revision 1 and the private pass-device block, and captured
  `build/device-acceptance/physical_android_game.png`.
- The hardened functional harness was rerun successfully on the same
  machine-reported physical Xiaomi 2201117TG running Android 13. It recorded
  `isPhysicalDevice: true`, rediscovered `_trigrid._tcp` at
  `192.168.8.15:43119`, completed the menu-to-Classic-match move/handoff flow,
  and passed the strict functional verifier. Fresh screenshots are
  `build/device-acceptance/android_2201117tg_20260731_board.png` and
  `build/device-acceptance/android_2201117tg_20260731_handoff.png`.
- Those physical screenshots predate the subsequent full-surface handoff and
  match-result modal fixes. The corrected behavior has current widget/golden
  evidence, but the APK above still requires a final physical replace-install
  and rerun before those UI refinements can be called physically verified.
- Physical evidence is now cryptographically bound to the current production,
  platform, dependency, and acceptance-harness inputs. The historical Android
  report has no `acceptanceBuildId`, so the strengthened verifier intentionally
  rejects it as stale until the current harness is rerun on that phone.
- The complete build-bound functional pipeline was validated on a labeled
  Android 16 emulator negative control. Identity, native DNS-SD, revision-1
  gameplay, full-surface private handoff, and both screenshots all recorded the
  current acceptance build ID. The strict verifier then failed only the three
  machine-reported physical-device checks, proving that current-build virtual
  evidence still cannot be promoted to a release pass. Evidence screenshots:
  `build/device-acceptance/buildid_validation_emulator_v3_board.png` and
  `build/device-acceptance/buildid_validation_emulator_v3_handoff.png`.
- The same current-build emulator then completed all six profile scenarios.
  Every case recorded 20 moves and 230 frames with correct radius/effects
  metadata. Build p90 ranged from 5.425–12.279 ms, while software-emulated
  raster p90 ranged from 51.132–80.306 ms. The independent verifier rejected
  every case for both the virtual target and raster budget, with no missing,
  stale-build, scenario-label, sampling, or profile-mode diagnostic.
- The radius-8 profile collector was separately validated with 230 rendered
  frames and 20 moves on a labeled Pixel 9a API 36 emulator. Its build p90
  (24.942 ms) and raster p90 (112.519 ms) correctly failed the hardware budget,
  so this is retained as a negative harness control, not a physical 60 FPS
  claim. Full data is in
  `build/device-acceptance/device_acceptance.json`.
- The device gate now covers all six Large/Huge/radius-8 × effects-on/off
  scenarios and preserves evidence under scenario/device-specific keys. A
  second emulator control proved the new Large/effects-off path with 230
  frames, 20 moves, build p90 8.189 ms, and an expected raster-budget failure
  at 45.213 ms.
- `tool/verify_device_acceptance.dart` rejects virtual-device, incomplete,
  undersampled, non-profile, over-budget, or internally contradictory device
  reports. Every run records a target-identity entry, and every scenario carries
  the platform plugin's machine-reported physical-device flag and model. It
  also recomputes a SHA-256 acceptance build ID and rejects identities,
  functional flows, screenshots, and profiles captured from another source
  state. Focused tests prove the full-pass, stale-build rejection,
  virtual-device rejection, and failure-diagnostic paths.
- `tool/verify_lan_device_matrix.dart` defines a strict nine-scenario release
  gate for same-Wi-Fi, Android/iOS hotspot, reconnect/resync, terminal-hash,
  offline-operation, screenshot, and client-isolation evidence. Its regression
  tests prove complete-pass and malformed/virtual/mismatched/stale-build
  rejection paths. A safe current-build template generator now prepopulates
  every required scenario and join route, refuses accidental overwrite, and
  intentionally fails verification until physical observations replace its
  placeholders. A read-only progress inspector groups the strict checks per
  scenario and supports human-readable or JSON output for incremental device
  collection. A non-destructive merge tool accepts only a complete
  current-build matrix, preserves the source report, refuses output overwrite,
  and requires explicit authority for LAN-key collisions. No physical LAN
  matrix entries exist yet, so this is tooling rather than a release-pass
  claim.
- `tool/create_physical_acceptance_kit.dart` creates a non-overwriting,
  build-ID-named hardware handoff directory containing the exact Android APK,
  fresh LAN scaffold, cross-platform runbook, and SHA-256 manifest. Its
  verifier rejects tampered files or a kit whose build ID differs from current
  source. The kit remains a transport aid, not physical acceptance evidence.

## 1. Product, originality, targets, and technology — Verified/Implemented

- The product and package surfaces use the temporary title **TriGrid**.
- UI, board mark, vector rendering, effects, and generated WAV files are
  project-authored. `ASSET_LICENSES.md` records authorship and replacement
  instructions; no Triggle or Antiyoy assets/source are included.
- Flutter widgets implement product surfaces and overlays; Flame implements
  the board scene and frame lifecycle; GetX implements navigation/DI/reactive
  session state.
- `lib/core/game/` has no Flutter or Flame import. Logical rules use axial/cube
  lattice coordinates, never screen coordinates.
- Gameplay has no Firebase, remote backend, or internet service dependency.
  LAN transport is local WebSocket; discovery is native DNS-SD/Bonjour with
  UDP fallback; manual IP and QR joining are present.
- Android phone execution is physically smoke-tested. Responsive constraints,
  orientation declarations, widget/golden coverage, and iPhone/iPad project
  settings implement phone/tablet and iOS support. iOS compilation and
  cross-platform physical play remain external gates.

## 2. Required modes — Verified/Implemented

- `LocalGameSetupScreen` configures Solo, pass-and-play, two to four players,
  and arbitrary human/bot mixes.
- Every bot seat has independent difficulty/personality/thinking settings.
- Pass-and-play uses a blocking private handoff before the next human can act;
  controller coverage proves the block and confirmation path. Physical
  screenshot review found and fixed a contradictory exposed HUD around the
  board-only overlay: the handoff now covers the complete safe game surface,
  pointer-blocks and excludes the underlying game from semantics, and has a
  dedicated phone golden.
- Golden screenshot review likewise found and fixed a board-only match-result
  modal. Results now dim the complete safe game surface while preserving the
  final board behind the panel, block and semantically exclude the underlying
  toolbar/board/scores, and retain only the result actions as interactive.
- `LanHostServer`, `LanClientConnection`, and the LAN setup/lobby screens
  implement same-Wi-Fi/hotspot architecture with two to four human/bot seats.
- `TutorialScreen` provides guided playable tutorial content.
- The local setup exposes a debug-only bot-vs-bot start, and an automated test
  proves autonomous completion.
- Full deterministic simulations prove complete two-, three-, and four-player
  matches. Widget tests prove mixed human/bot setup and all main menu flows.

## 3. Canonical and scalable rules — Verified

- `docs/RULES.md` freezes Classic rules before the engine implementation.
- `BoardDefinition` algorithmically generates pegs, unit triangles, canonical
  edges, adjacency indexes, and every four-peg/three-edge move.
- Tests prove Classic radius 3 has 37 pegs and 54 triangles; every move contains
  four aligned consecutive pegs and exactly three canonical unit edges.
- `MoveValidator` proves turn, supply, endpoint, length/alignment, board bounds,
  duplicate action/band, at-least-one-new-edge, post-first connectivity, and
  terminal-state constraints.
- Partial overlap with a new edge is accepted; exact/no-new-edge overlap is
  rejected. First placement may be anywhere legal.
- Capture resolution examines cells adjacent to affected edges, captures every
  newly completed unit triangle atomically, never changes an existing owner,
  and derives score from captures.
- Tests prove single and multiple capture, retained ownership, score changes,
  Classic two-player exhaustion/tie behavior, Classic four-player marker-limit
  behavior, no-legal-move termination, and rejection after game end.
- Small, Classic, Large, Huge, and Custom radii 2–8 are independent of player
  count. Non-Classic sizes force Custom rules. `SupplyPolicy` documents and
  tests scaling while preserving exact Classic 2-player and 3–4-player stock.

## 4. Engine architecture, validation, state, and replay — Verified

- All requested core models exist under `lib/core/game/`.
- State and exposed collections are immutable/unmodifiable and safely copied.
- Settings, state, actions, bot settings, results, and protocol DTOs have
  explicit JSON adapters and schema/protocol versions.
- `MoveValidationResult` contains validity, machine error code, localization
  key, affected edges, and newly captured triangles.
- Local sessions, bot move selection, LAN host authority, replay, and tests all
  call the same `GameEngine`/`MoveValidator`; LAN clients never commit a move.
- Canonical JSON and SHA-256 state hashes are deterministic. Replay tests prove
  the ordered accepted actions reproduce revision and final hash, and corrupt
  expected hashes are rejected.
- Presentation timing/progress lives in session/Flame code and never enters
  authoritative `GameState`.

## 5. Bot AI — Verified

- Beginner, Easy, Normal, Hard, and Expert use distinct selection/search
  behavior, not delay-only differences.
- Beginner randomness/capture chance, Easy capture/offer heuristics, Normal
  limited lookahead, and Hard/Expert bounded search are implemented in
  `BotEngine`.
- Two-player deep search uses iterative-deepening alpha-beta; multiplayer uses
  MaxN. Move ordering, transposition caching, capture/defense/future-connection
  evaluation, trap/multi-capture terms, and deadlines/node budgets are present.
- Aggressive, Defensive, and Balanced personalities adjust original
  evaluation weights.
- `BotWorker` executes search in a Dart isolate; stale-revision decisions are
  discarded by the controller/host. Configurable time and deterministic
  seed/node-budget paths are present.
- Tests prove every level returns a legal move on every supported radius,
  seeded repeatability, forced-capture behavior, four-player MaxN, background
  isolate execution, serialization, and autonomous bot matches. A
  same-thinking-time contrast proves Beginner can miss a maximum capture that
  Easy takes, while Normal/Hard/Expert complete progressively deeper 2/4/5-ply
  searches on the same Small position.
- The LAN host owns and runs bot turns. `docs/BOT_AI.md` records the algorithms,
  personalities, budgets, and evaluation.

## 6. Authoritative LAN multiplayer — Verified/Implemented

- The host owns lobby/settings/turns/bots/engine and publishes only accepted
  actions and periodic/full snapshots. Clients send requests and animate only
  host-confirmed transitions.
- The lobby implements create/join, player name, unique color/symbol selection,
  ready state, two to four seats, add/remove bot, per-bot level, board/ruleset,
  optional timer, room code, and host-only start.
- Native `_trigrid._tcp` DNS-SD/Bonjour discovery is primary. Versioned room
  TXT metadata has strict codec tests. IPv4 UDP broadcast/probe port 42421 is a
  fallback. Manual IP and versioned QR joining are independent fallbacks.
- Version-1 envelopes carry type, message ID, sequence, match/player identity,
  revision, idempotent action ID, and payload. State snapshots carry a canonical
  hash.
- The host rejects malformed, incompatible, duplicate, stale, out-of-turn,
  paused, and identity-mismatched requests. Retries are idempotent.
- Heartbeat/ping latency, connection status, background credential save,
  persistent random player tokens, bounded reconnect retries, full hash-checked
  resynchronization, disconnect pause, and wait/remove/replace-with-bot host
  decisions are implemented.
- Host exit emits a clear terminal condition, clears the invalid reconnect
  token, and offers archival of the last verified state.
- A real loopback WebSocket integration test proves host create, two clients,
  lobby/color/bot/timer updates, ready/start, accepted move, invalid rejection,
  duplicate action behavior, disconnect pause, persistent-token reconnect,
  snapshot/hash restore, resume, second disconnect, and bot replacement.
- Platform declarations include Android network/Wi-Fi/multicast/nearby
  permissions and an in-app nearby-Wi-Fi request path, plus iOS local-network
  usage and the active Bonjour service. API 37 migration guidance is documented.
- `docs/LAN_PROTOCOL.md` freezes schemas, errors, discovery, lifecycle, and the
  release physical-device matrix.

## 7. Visual style, accessibility, input, animation, and game feel — Verified

- The board uses an original warm material palette, cached raised-board layer,
  deterministic soft grain, rim/depth shadows, raised pegs, thick highlighted
  elastic bands, and markers inside captures.
- Player identity combines four distinct colors with circle/square/diamond/
  triangle symbols. High-contrast mode and theme/appearance settings are
  persisted; state is never communicated by color alone.
- Tap-start/tap-end and drag placement share logical hit testing. Valid ends,
  snap target, bend/tension preview, peg compression, release overshoot, and
  invalid elastic return are implemented.
- Gesture arbitration prevents camera movement from submitting a band.
  Optional move confirmation is widget-tested; host-accepted LAN actions have
  no undo path.
- Capture presentation includes glow/fill, sequential multi-capture timing,
  marker drop/bounce, particles, score tween, and capture/combo feedback.
- Turn presentation changes the active panel and board rim/ambient color with
  sound/haptic feedback.
- End presentation reframes the board, pulses winning markers, counts scores,
  emits original confetti, identifies winner/tie, and provides replay/restart/
  menu actions.
- Camera supports start framing, pinch zoom, inertial bounded pan, min/max
  zoom, double-tap reset, toolbar reset, and clamping that keeps reset recovery
  available.
- Reduced motion, particles, screen shake, animation speed, haptics, high
  contrast, and move confirmation are configurable.
- Fixed board geometry is recorded once; dynamic bands/captures/effects render
  separately. Golden tests cover the main menu plus live, handoff, pause, and
  result states on a phone. Portrait and landscape tablet goldens additionally
  prove that the board retains most of the viewport, the score rail stays
  outside the playfield, orientation resizing refits the board, and the
  full-surface result modal remains correctly bounded.

## 8. Audio and haptics — Verified

- Flame Audio loads original PCM WAV assets for peg touch, stretch, snap,
  invalid move, capture, multi-capture, turn, button, lobby join, countdown,
  victory, defeat, and draw, plus separate music and ambient loops.
- Unit tests prove every declared asset exists, is non-empty, and has a valid
  PCM WAV header. `tool/generate_placeholder_audio.dart` reproduces the
  documented original placeholder pack.
- App-wide initialization provides music/ambient and button feedback before a
  match. Explicit ownership prevents a closed session from disposing the
  shared service. Lobby occupancy increases play the join cue.
- Result feedback uses the local human/LAN player perspective, with tests
  proving distinct victory and defeat selection; ties select draw.
- Music, sound effect, and ambient levels, mute, and haptics are independently
  persisted and editable from global and pause settings.
- Touch, snap, capture, invalid, and victory haptics use distinct strengths;
  all feedback failures are isolated from authoritative play.

## 9. Screens, HUD, localization, and product surfaces — Verified

- Splash and main menu are dedicated screens.
- Local setup composes the required new-local, solo, and pass-and-play setup
  variants.
- LAN menu, host setup/lobby, join/discovery/lobby, and QR scanner are complete.
- Game, pause, rules, playable tutorial, bot explanation, results, replay
  library/viewer, statistics, settings, and about/licenses are implemented.
- The main menu exposes Continue, Solo, one-phone play, LAN, Tutorial, Rules,
  Settings, plus statistics/replays/bot guide/about.
- The HUD exposes current player, all scores, band/marker stock, bot thinking,
  LAN state/latency, pause, camera reset, optional legal hint, and host timer.
  Responsive layout keeps the Flame board as the dominant surface.
- English, Kazakh, and Russian ARB catalogs expose identical message keys.
  Widget tests prove Kazakh device-locale selection. A catalog test enforces all
  requested Kazakh terms, including “Жеңімпаз”.
- A source scan finds no direct user-facing string literals in widgets; network
  machine codes are mapped to localized UI text.

## 10. Persistence and statistics — Verified

- The versioned SharedPreferences aggregate stores language/theme/accessibility,
  player name/appearance, audio/game-feel settings, last local/LAN setup,
  verified local snapshot/action log/hash, bounded verified replays, archived
  LAN snapshots, and statistics.
- LAN reconnect credentials use a separate persistent store containing the
  endpoint, identity, match, token, last revision/hash, and timestamp; secrets
  are excluded from advertisements, QR, replays, and archives.
- Statistics track matches, wins, captures, largest multi-capture, average
  score, per-bot-level wins/matches, and separate local/LAN aggregates.
- Tests prove versioned round trips, serialized writes, corrupt/mismatched
  snapshot rejection, LAN archive restore, and statistics separation.

## 11. Testing, performance, and diagnostics — Verified

- Required coordinate, geometry, move, capture, score, supply, termination,
  tie, serialization, replay, hash, and bot legality cases have direct tests.
- Required LAN lifecycle cases have real socket integration coverage. Two
  independent clients also complete an authoritative match to terminal state,
  agreeing with the host on every revision and state hash.
- A widget/socket integration test now drives `GameScreen` through paused and
  resumed lifecycle states, proves reconnect credentials are persisted, closes
  the original WebSocket, reconnects with the same player token, and verifies
  the restored authoritative state hash.
- Widget, controller, projection, Flame presentation, persistence, sound-asset,
  localization, platform-configuration, golden, and performance tests are part
  of the 159-test passing suite.
- The device harness adds real Android native DNS-SD discovery, menu-to-match
  UI navigation, legal gameplay/private handoff, screenshots, and profile
  `FrameTiming` capture without weakening the 16.67 ms p90 gate.
- Board definitions, edge-to-triangle indexes, state legal-move results, and
  fixed render geometry are cached. Bot work is isolated. Dynamic presentation
  avoids whole-board logical scans per frame.
- Large, Huge, and maximum Custom boards pass bounded generation, cache, and
  complete-simulation tests. `docs/PERFORMANCE.md` records the reproducible
  benchmark and safe Custom radius 2–8.
- Debug builds expose localized FPS, frame time, legal moves, bot nodes, LAN
  latency, revision, and state hash.

## 12. Remaining mandatory external acceptance gates

These requirements cannot be honestly marked verified from the available
Windows host and single Android phone:

1. Compile the iOS app with Xcode on macOS.
2. Replace-install the current Android APK and rerun the functional flow,
   including full-surface private handoff and match-result modal checks.
3. Run Android↔Android, Android↔iOS, and iOS↔iOS full matches on the same Wi-Fi.
4. Repeat full-match discovery/fallback/reconnect tests through Android and iOS
   phone hotspots.
5. Exercise background/foreground reconnect and router client isolation on the
   physical matrix.
6. Capture profile-mode frame charts on representative mid-range Android and
   iOS hardware to prove the 60 FPS target for Large, Huge, and radius-8 boards.

Until those gates pass, the strict acceptance statement “Android and iOS
devices can play together over LAN” and the physical 60 FPS target remain
implemented but not proven.
