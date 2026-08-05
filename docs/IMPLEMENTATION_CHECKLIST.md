# TriGrid Implementation Checklist

This checklist is the delivery map. A checked item means working code or a
verified artifact exists; a folder or stub alone does not count.

## Milestone 1 — Foundation

- [x] Inspect the existing Flutter, Android, and iOS files
- [x] Confirm the local stable Flutter and Dart toolchain
- [x] Record that the directory has no Git metadata
- [x] Adopt the temporary original title TriGrid
- [x] Add and resolve core dependencies
- [x] Establish the pure Dart dependency boundary
- [x] Implement board-size counts and supply policy
- [x] Add unit tests for Classic counts and supply rules
- [x] Add English, Kazakh, and Russian ARB foundations
- [x] Replace the counter template with a TriGrid shell
- [x] Write `docs/RULES.md`
- [x] Write `docs/ARCHITECTURE.md`
- [x] Configure initial Android/iOS LAN and QR permissions
- [x] Pass formatting, analysis, tests, and Android debug build

## Milestone 2 — Pure Dart engine

- [x] Implement axial/cube coordinates and canonical ordering
- [x] Generate all pegs and unit edges
- [x] Generate all triangular cells and edge adjacency indexes
- [x] Generate every four-peg move on radii 2–8
- [x] Implement immutable game settings and state
- [x] Implement the single structured move validator
- [x] Implement reducer, captures, scoring, turn advance, and end conditions
- [x] Implement versioned JSON, canonical hash, and deterministic replay
- [x] Complete all engine unit and invariant tests

## Milestone 3 — Playable local game

- [x] Implement Flame board rendering and logical/world projection
- [x] Implement tap-to-place and drag-to-place input
- [x] Add pan, zoom, reset, framing, and gesture arbitration
- [x] Add scores, supplies, active player, pause, and hints HUD
- [x] Support two to four human seats in local sessions
- [x] Complete a match from setup through full-surface blocking tied/winning
  results

## Milestone 4 — Game feel

- [x] Implement elastic preview, snap, overshoot, and invalid return
- [x] Implement peg compression and valid-target feedback
- [x] Implement capture fill, marker drop, particles, and score animation
- [x] Implement turn and end-game presentation
- [x] Create original placeholder/final audio with full hooks
- [x] Add haptic strengths and accessibility motion controls
- [x] Update `ASSET_LICENSES.md`

## Milestone 5 — Bots

- [x] Support mixed human/bot local matches
- [x] Implement deterministic legal-move worker isolate
- [x] Implement Beginner, Easy, Normal, Hard, and Expert strength behavior
- [x] Add Aggressive, Defensive, and Balanced personalities
- [x] Add iterative deepening, multiplayer search, ordering, and caching
- [x] Test every bot level on every supported board size
- [x] Prove difficulty changes tactical choice and search depth, not only delay
- [x] Write `docs/BOT_AI.md`

## Milestone 6 — Pass-and-play and LAN

- [x] Complete pass-and-play privacy/turn handoff across the full game surface
- [x] Implement authoritative WebSocket host/client protocol
- [x] Implement native DNS-SD/Bonjour discovery, UDP fallback, and manual fallback
- [x] Implement manual IP and versioned QR joining
- [x] Implement lobby seats, ready state, colors, bots, and host controls
- [x] Implement idempotency, ordering, heartbeat, snapshots, and hashes
- [x] Implement persistent-token reconnect and disconnected-player decisions
- [x] Verify background credential persistence and foreground token reconnect
  through the game-screen lifecycle bridge
- [x] Run real WebSocket loopback integration tests
- [x] Complete a two-client authoritative WebSocket match with per-move hash
  agreement
- [ ] Run Android/iOS same-Wi-Fi and hotspot physical-device matrix
- [x] Write `docs/LAN_PROTOCOL.md`

## Milestone 7 — Product surfaces

- [x] Implement all required screens and navigation
- [x] Implement tutorial and rules content
- [x] Complete every visible English/Kazakh/Russian string
- [x] Implement settings, persistence, statistics, and replay viewer
- [x] Add appearance, color-blind symbols/patterns, and high contrast
- [x] Add about, privacy, and third-party license surfaces

## Milestone 8 — Optimization and release validation

- [x] Add debug FPS/frame/search/network/revision/hash overlay
- [x] Benchmark and optimize Large and Huge boards
- [x] Determine and record the safe Custom radius range
- [x] Eliminate unnecessary rebuilds and full-board hot-path scans
- [x] Pass all unit, widget, golden, integration, and replay tests
- [x] Pass `flutter analyze`
- [x] Build Android debug APK
- [x] Run physical Android install, cold-launch, native DNS-SD, and local-game
  handoff acceptance checks
- [x] Add and validate the strict Large/Huge/radius-8 × effects-on/off physical
  profile matrix
- [x] Add a strict per-device evidence verifier that rejects virtual targets
  and incomplete/contradictory functional or performance acceptance
- [x] Bind physical functional, screenshot, performance, and LAN evidence to a
  deterministic acceptance build ID so stale reports cannot pass
- [x] Add a strict physical LAN matrix verifier for same-Wi-Fi, hotspot,
  reconnect/hash, screenshots, and client-isolation evidence
- [x] Add a safe current-build LAN matrix template generator that cannot pass
  with incomplete placeholders
- [x] Add an incremental LAN matrix progress inspector with human-readable and
  JSON output
- [x] Add a strict non-destructive merge path from completed LAN evidence into
  a separately verifiable acceptance report
- [x] Package the current-build APK, LAN scaffold, checksums, and physical
  runbook into a safe self-verifying hardware handoff kit
- [ ] Pass the profile frame budget on representative physical Android/iOS
  hardware
- [x] Validate iOS project configuration and permission declarations
- [ ] Compile the iOS app on macOS with Xcode
- [x] Verify README commands and physical-device LAN instructions
- [x] Confirm implemented acceptance criteria and document external device gates
