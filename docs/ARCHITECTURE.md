# TriGrid Architecture

Status: Production-feature baseline; physical cross-platform gates remain  
Targets: Android, iOS, phones, and tablets  
Runtime: Flutter + Flame with a pure Dart authoritative engine

## 1. Architectural goals

TriGrid must remain deterministic, offline-capable, testable without a Flutter
binding, responsive during bot search, and safe against untrusted LAN clients.
The main constraint is a one-way dependency rule:

```text
Flutter widgets / Flame scene / LAN adapters
                    |
                    v
          application orchestration
                    |
                    v
        pure Dart game + AI contracts
```

The core game module imports neither Flutter nor Flame. Presentation code may
project logical coordinates into pixels, but core decisions never use screen
coordinates. Visual effects react to accepted actions and cannot mutate
authoritative state.

## 2. Technology decisions

| Concern | Choice | Reason |
| --- | --- | --- |
| App shell | Flutter Material 3 | Adaptive phone/tablet UI and accessibility |
| Game scene | Flame | Camera, components, effects, input, and frame lifecycle |
| Navigation/DI/UI state | GetX | Requested navigation and lightweight bindings |
| Rules engine | Pure Dart value objects and reducers | Deterministic tests and host authority |
| LAN transport | `dart:io` WebSocket server + `web_socket_channel` client | Same-network authoritative messages |
| Discovery | Native DNS-SD/Bonjour plus UDP probe/broadcast fallback | Automatic offline room discovery across mobile OS policies |
| Manual join | IP entry and QR payload | Works when discovery is blocked |
| Serialization | Versioned JSON DTOs with explicit adapters | Debuggable protocol and migrations |
| State hashes | SHA-256 over canonical JSON | Replay and resynchronization checks |
| Persistence | Versioned aggregate JSON in SharedPreferences | Offline, serialized writes, and safe fallback |
| Audio | Flame Audio | Scene-aware effects and pooled playback |
| Localization | Flutter ARB generation | English, Kazakh, and Russian source files |
| Bot workers | Dart isolates | No search work on the UI isolate |

Direct dependency versions are locked in `pubspec.lock`. `flutter pub outdated`
is used before upgrades; dependencies move together only after analyze, tests,
and platform builds pass.

## 3. Package layout

The target structure grows by capability rather than by screen:

```text
lib/
  app/
    bindings/
    routes/
    theme/
    trigrid_app.dart
  core/
    game/
      coordinates/
      geometry/
      game_state/
      models/
      move_generation/
      replay/
      rules/
      scoring/
      triangle_detection/
    ai/
      evaluation/
      search/
      workers/
    network/
      discovery/
      protocol/
      session/
      transport/
    persistence/
      migrations/
      repositories/
    diagnostics/
  game/
    camera/
    components/
    effects/
    input/
    rendering/
  presentation/
    dialogs/
    screens/
    widgets/
  services/
    audio/
    haptics/
    lifecycle/
  l10n/
test/
integration_test/
docs/
```

Directories are created when they receive working code; the repository does not
keep empty placeholder classes.

## 4. Core domain model

The engine uses cube-compatible axial coordinates. Canonical directions and
endpoint ordering remove orientation ambiguity.

- `GridCoordinate`: immutable integer `(q, r)` and derived `s`
- `Peg`: stable coordinate identity
- `UnitEdge`: two adjacent coordinates, stored in canonical endpoint order
- `TriangleCell`: stable ID plus three canonical edges and orientation
- `BandMove`: four ordered pegs and three ordered unit edges
- `BoardDefinition`: immutable generated pegs, cells, adjacency indexes, moves
- `PlayerState`: seat identity, score, supply counts, controller type
- `GameSettings`: rules version, board selection, seats, optional local rules
- `GameState`: immutable authoritative snapshot
- `GameAction`: versioned serializable intent or accepted event
- `MatchResult`: winners, scores, terminal reason, final revision/hash

The full Milestone 2 domain path is implemented: coordinates, generated board
definitions and indexes, immutable state, validation, reduction, captures,
match results, canonical hashes, and deterministic replay. The public engine
surface is exported by `lib/core/game/trigrid_engine.dart`.

Collections exposed by state are unmodifiable. Copy operations replace only
changed fields. Stable IDs are derived from canonical coordinates, not object
identity or insertion order.

## 5. Authoritative action pipeline

Every local, bot, LAN, and replay action follows one path:

```text
requested action
  -> schema/version check
  -> idempotency check
  -> authoritative MoveValidator
  -> pure state reducer
  -> capture and end-condition resolution
  -> revision increment + state hash
  -> persist accepted action
  -> publish accepted event
  -> animate/render
```

The validator returns a structured result with error code, message key, affected
edges, and newly completed cells. Invalid requests do not advance revision.
Accepted action IDs are retained for the match so retries are idempotent.

Triangle completion uses an edge-to-cells adjacency index and checks only cells
touching the three submitted edges. Legal-move caches are invalidated by the
affected edges instead of rescanning geometry every frame.

## 6. Serialization, replay, and hashing

Protocol envelopes, actions, settings, snapshots, and replays carry independent
schema versions. Unknown major versions are rejected; known older versions are
migrated before entering the domain layer.

Canonical hashing recursively sorts object keys while preserving semantically
ordered arrays. Sets and maps are serialized in stable ID order. Transient
fields such as timestamps for display, latency, animation progress, and local
session tokens are excluded. The SHA-256 digest covers rules version, state
revision, and authoritative state.

A replay stores initial settings, deterministic seed, ordered accepted actions,
and optional checkpoints. Loading replays reduces actions through the same
validator and reducer, then verifies checkpoint and final hashes.

## 7. Bot architecture

Bots receive immutable state snapshots and return requested actions. The host
owns bots in LAN matches. Search runs in an isolate with a deadline,
deterministic seed option, and cancellation token tied to match revision.
Responses for stale revisions are discarded.

Beginner through Expert share legal move generation. Difficulty changes
selection and search strength, not delay alone. Two-player Hard/Expert search
uses iterative-deepening alpha-beta; multiplayer search uses MaxN. Searches run
through `BotWorker` in a Dart isolate with revision-gated results, ordered
branches, fixed per-decision transposition tables, and wall-clock or
deterministic node budgets. Accepted bot actions enter the ordinary replay log.
`docs/BOT_AI.md` records the evaluation weights, personalities, and budgets.

## 8. LAN architecture

The host is the only authority. Clients send requests and render accepted
events/snapshots. The implemented version-1 envelope includes:

```json
{
  "protocolVersion": 1,
  "type": "submitMove",
  "messageId": "client:uuid:12",
  "sequence": 12,
  "matchId": "uuid",
  "playerId": "uuid",
  "payload": {
    "action": {
      "actionId": "uuid",
      "expectedRevision": 12
    }
  }
}
```

The session layer owns room seats, readiness, bot configuration, persistent
player tokens, heartbeats, sequence numbers, reconnect grace periods, and
snapshot resynchronization. Tokens are random, match-scoped secrets and are
never placed in discovery broadcasts or QR logs.

Native DNS-SD/Bonjour advertises `_trigrid._tcp` with room metadata and the
fixed gameplay WebSocket port 42422. UDP broadcast on port 42421 supplies a best-effort fallback and
answers active probes where the operating system and network permit raw
broadcast. Manual IP and a versioned QR join payload remain available.
Discovery transports stop when their screen closes.

On backgrounding, clients save their endpoint, reconnect token, last revision,
and hash. On reconnect they authenticate the token and receive a full
hash-verified snapshot. If the host leaves, clients retain the last verified
in-memory snapshot and display a clear terminal state; durable match snapshots
are handled by the persistence layer and host migration is outside version 1.

[`docs/LAN_PROTOCOL.md`](LAN_PROTOCOL.md) freezes message schemas, error codes,
discovery payloads, and the physical-device test matrix.

## 9. Presentation and game scene

Flutter owns menus, lobbies, setup, settings, dialogs, HUD, localization, and
screen-reader structure. Flame owns the board scene, camera, gesture-to-world
projection, elastic visuals, capture effects, and particles. A thin game-session
controller converts accepted domain events into visual commands.

Milestones 3–4 implement this boundary for local play. Flutter owns the responsive
setup, compact HUD, pause surface, and results. Flame renders the generated board
and receives tap/drag/scale gestures through a gated Flutter gesture surface.
`BoardProjection` is the only axial-to-world converter; submitted moves still
contain logical coordinates and pass through the authoritative validator.

The session publishes accepted `GameTransition` objects to an independent
presentation timeline. Band, capture, marker, camera, confetti, and turn-light
progress never enters `GameState`. Replays reduce the original accepted action
log through the engine again and emit the same presentation events; tests verify
that the final replay hash is identical.

Fixed board geometry is cached in picture/component layers. Frequently changing
bands, markers, previews, and particles are separate. Camera bounds include a
recoverable reset transform and clamped inertial pan. Gesture arbitration
distinguishes a board placement from camera movement before submitting a move.

Reduced motion, particle disablement, screen-shake disablement, haptics, and
animation speed are input to visual services only; they never alter rules.

## 10. Persistence

Repositories expose domain-level methods while the storage adapter owns one
versioned aggregate JSON format:

- preferences: language override, audio levels, accessibility, player identity;
- resumable snapshot: one verified local snapshot; LAN credentials use a
  separate match-scoped store;
- replays: bounded verified accepted-action histories;
- LAN archives: bounded last-valid hash-verified positions after host exit;
- statistics: versioned aggregate records separated by local and LAN mode.

`SharedPreferencesAsync` writes are serialized by a lock. Corrupt or
incompatible aggregate data is discarded to safe defaults without crashing
startup. A storage failure never interrupts an active match. Session tokens are
omitted from replay and archived-position data.

## 11. Platform permissions

Android declares internet, network state, Wi-Fi state, multicast, nearby Wi-Fi,
and camera permissions. The LAN entry flow requests nearby-Wi-Fi access when
required by the current target/API combination. The project currently targets
API 36; `ACCESS_LOCAL_NETWORK` must be added and requested before targeting API
37 or later. iOS declares local-network, the active `_trigrid._tcp` Bonjour
service, and camera usage. Local-network permission behavior still requires the
documented physical Android/iOS release matrix.

The temporary IDs are `com.trigrid.game` and `com.trigrid.game.RunnerTests`.
Release IDs, signing, privacy declarations, icons, and store metadata require a
publisher-owned identity before shipping.

## 12. Testing and quality gates

The core engine gets exhaustive unit coverage for coordinates, generation,
validation, captures, scoring, termination, serialization, hashes, and replay
determinism. Property-style loops assert invariants across all generated moves
and board presets. Every bot level is tested against generated legal states.

LAN tests use loopback transports first, then physical-device same-Wi-Fi and
hotspot matrices. Widget and golden tests cover major localized and accessible
states. Performance tests and the reproducible benchmark measure board
generation, legal-move caching, full simulation, hashing, and search budgets
for Large, Huge, and maximum Custom boards. Runtime FPS and frame time are
exposed by the debug-build diagnostics panel. See `docs/PERFORMANCE.md`.

Milestone completion requires:

```sh
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

iOS configuration is inspected on every platform; compilation is run on macOS.
No milestone is marked complete with analyzer or test errors.

## 13. Recorded decisions and open validation

- The game uses a native Flutter/Flame path; browser-game engines are not part
  of this project.
- Classic rules are locked to radius 3. Any other size is visibly Custom.
- Custom radii 2–8 are supported and exposed; radius 8 is the benchmarked safe
  maximum. Larger radii are rejected.
- Multi-capture resolution is atomic even when it reaches a marker limit.
- Version 1 deliberately omits host migration.
- The present visual mark and generated WAV pack are original project-authored
  assets. Final store iconography and any replacement texture/audio production
  require explicit licensing records.
