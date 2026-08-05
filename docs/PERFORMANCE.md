# TriGrid Performance Record

## Scope

Milestone 8 validates the engine and generated geometry for the Large
(radius 4), Huge (radius 5), and maximum Custom (radius 8) boards. The UI
exposes Custom radii 2–8; values outside that range are rejected by the domain
model and are not supported.

The benchmark is reproducible:

```sh
dart run tool/performance_benchmark.dart
flutter test test/performance/large_board_performance_test.dart
```

## Recorded benchmark

Recorded on 2026-07-30 using Dart 3.11.1 in JIT mode on Windows, on an AMD
Ryzen 5 5600H (6 cores / 12 logical processors). Durations are diagnostic
desktop measurements, not mobile frame-rate claims.

| Radius | Pegs | Triangles | Band templates | Generate | First legal set | Cached legal ×10,000 | Full deterministic match | Hash ×1,000 | Normal bot |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4 | 61 | 96 | 102 | 31.358 ms¹ | 4.586 ms¹ | 3.960 ms | 43.626 ms | 668.858 ms | 84 ms / 28 nodes |
| 5 | 91 | 150 | 174 | 6.138 ms | 0.123 ms | 0.745 ms | 29.657 ms | 817.750 ms | 81 ms / 46 nodes |
| 8 | 217 | 384 | 498 | 8.677 ms | 0.490 ms | 0.240 ms | 181.293 ms | 2,392.190 ms | 83 ms / 23 nodes |

¹ The first row includes Dart JIT warm-up and is retained rather than hidden.

These results establish radius 8 as the safe exposed Custom maximum for the
pure engine on this gate: generation remains under 10 ms after warm-up, a full
maximum-board deterministic match remains under 190 ms, and cached legal-move
lookup is effectively constant for an immutable state. Automated tests use
deliberately wider two- and three-second ceilings to avoid flaky CI failures.

## Implemented hot-path controls

- Board definitions and adjacency indexes are cached by `BoardSize`.
- Legal moves and per-move captures are cached by immutable `GameState`
  identity. Connected positions draw candidates from the peg-to-move index
  instead of scanning unrelated move templates.
- Triangle completion checks only triangles adjacent to the three affected
  edges.
- Bot search runs in a Dart isolate and uses bounded search, ordering, and
  transposition caches.
- The Flame component records the fixed board, base peg geometry, projected
  peg positions, triangle paths, and centers once. Per-frame rendering is
  limited to stateful bands, captures, highlights, effects, and the active rim.
- The debug diagnostics panel refreshes Flutter text twice per second rather
  than rebuilding it every Flame frame.

## Debug overlay

Debug builds show a bug icon in the game toolbar. It toggles an in-app panel
with FPS, average frame time, legal-move count, last bot-search node count, LAN
latency, state revision, and the leading state-hash characters. The panel and
its polling timer are omitted or inactive in release builds.

## Profile-mode device harness

`integration_test/device_acceptance_test.dart` contains a six-case profile-mode
matrix for capture-heavy Large, Huge, and radius-8 play with particles and
screen shake enabled and disabled. Every case submits 20 legal moves, exercises
zoom, pan, and reset, records engine `FrameTiming` data, and requires at least
120 rendered frames with both build and raster p90 at or below 16.67 ms. A
compile-time selector supports isolated reruns. The driver merges every
scenario/device-labeled result into
`build/device-acceptance/device_acceptance.json`.
`tool/verify_device_acceptance.dart` independently requires all six cases,
profile mode, at least 121 frames, at least 16 moves, consistent metadata, and
passing build/raster p90 values before a named device can pass. The harness
records a target-identity entry plus the platform plugin's `isPhysicalDevice`
result and device model in every scenario, and the verifier rejects emulator,
simulator, desktop, and web evidence even if its timings otherwise pass. Every
entry and screenshot must also carry the SHA-256 acceptance build ID produced
by `dart tool/acceptance_build_id.dart`; the verifier recomputes that ID
from production, platform, dependency, and harness inputs and rejects stale
evidence after any of those inputs change.

A 2026-07-31 harness-validation run on the headless Pixel 9a API 36 emulator
recorded 230 frames, 20 submitted moves, build p90 24.942 ms, and raster p90
112.519 ms. The strict gate failed as designed. This software-rendered virtual
device is a negative control, not representative-device evidence; its result
is retained under `radius8_profile_pixel_9a_emulator` so it cannot be mistaken
for a physical pass.

The expanded `large_effects_off` path was also validated on the same class of
software-rendered emulator: 230 frames and 20 moves, build p90 8.189 ms, raster
p90 45.213 ms. It passed the build budget and failed the raster budget as
expected, proving that matrix selection and per-scenario reporting do not
weaken the physical-only gate.

A later current-build negative control exercised the complete six-scenario
matrix on an Android 16 x64 emulator under acceptance build ID
`debf8b3c8ed2309dfd1c7f35d9e90fbcd4494f1cec3ea836bae5effef88fd1bc`.
Every Large, Huge, and radius-8 effects-on/off case recorded 20 moves and 230
frames. Build p90 was 5.425–12.279 ms; software-emulated raster p90 was
51.132–80.306 ms. All six results were correctly marked failed, and the strict
verifier independently rejected their virtual-device identity and raster
budget without reporting missing or stale-build evidence.

## Remaining device gate

The project targets 60 FPS, but desktop/JIT engine timings cannot prove frame
pacing on a mid-range Android device. Before store release, profile Large,
Huge, and radius-8 Custom matches on physical Android and iOS devices with
particles both enabled and disabled. Record raster/UI frame charts and repeat
the LAN physical-device matrix in `docs/LAN_PROTOCOL.md`.
