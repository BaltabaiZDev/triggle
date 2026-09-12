# Game-feel audit — 2026-09-08

Scope: existing Flutter/Flame game, not a new game or engine migration. Retain compact, angular, board-first visual language and all authoritative mechanics/LAN behavior.

## Before changes (source + existing phone/tablet golden review)

| Priority | Surface | Application-like behavior | Incremental treatment |
| --- | --- | --- | --- |
| P0 | Shared controls | Most Material controls have only an ink ripple; custom menu presses use a 70ms tween | Reusable damped-spring tactile wrapper; immediate native callbacks, disabled controls stay disabled |
| P0 | Audio/haptics | Per-event playback can allocate players/overlap; music forcibly disabled; no music slider | Preloaded bounded effects, drop stale low-priority sounds, native loop/fade, lifecycle pause, volume control |
| P1 | Game HUD | Scores and player name jump; small active marker has little emphasis | Value-keyed spring/glow accents and animated text |
| P1 | Pause/handoff/network/result | Conditional widgets appear/disappear instantly; result has one fixed tween; existing board confetti clock stops early | Shared entrance/exit transitions; finite result particles, repair finite board clock |
| P1 | Main menu/splash | Small static logo and flat actions centered on a densely hatched screen | Original board hero, quiet lighting/depth, bounded floating entrance |
| P1 | Local setup | Segmented count, switches and dropdowns read like a settings form; dependent fields jump | Tactile controls, selected seat pop, animated layout changes |
| P1 | LAN menu/host/join/lobby | Static action/list cards, abrupt busy/error/seat/color changes | Same control language, animated occupancy/selection and layout |
| P2 | Tutorial | Static lesson icons and instant page indicators | Shared motion, spring paging and selected indicator accents |
| P2 | Settings | Static administrative sections; no music control | Shared entrance/control motion, accessible volume/motion controls |
| P2 | Rules/bot guide/about | Plain list-based reference screens | Retain readable content, shared depth/entrance; no decorative buttons |
| P2 | Statistics/replays | Static cards/numbers and abrupt collection changes | Value accents and shared card/route motion |
| P2 | QR scanner | Camera preview is already live | Preserve scanner lifecycle; animate only chrome/route, not camera pixels |

## Guardrails

- No new gameplay, delays before input, network protocol changes, or copied commercial artwork.
- No full-screen blur, animated layout every frame, perpetual board effects, or synthetic 120-FPS claims.
- Reuse Flame geometry caches; isolate decorative repaints. Respect reduced motion and app lifecycle.
- Validate controller/engine/network regressions, widget semantics and reduced motion, audio admission policy, phone/tablet goldens, analysis and Android build.
- Real-device sustained frame/thermal measurements remain necessary for 60/120 Hz certification; emulator and unit timings cannot certify them.

## Implemented incrementally

- Shared `GamePress`, `GameReveal`, `GameSwitcher`, `GamePulse`, route springs, a cached menu float and finite celebration painter. Outgoing overlays cannot intercept input; disabled/cancelled controls stay silent. OS and in-game reduced-motion settings are respected.
- Tactile controls across menus, setup, LAN, settings and supporting pages; animated turn/score/seat changes, pause/handoff/result transitions, trophy/confetti, short invalid-placement shake and selection/capture accents. Core move validation, bot strategy and LAN protocol are unchanged.
- Fixed the elastic entrance discontinuity and the prematurely frozen celebration clock. Board effects finish and return to idle. Capture glow uses layered strokes instead of a per-triangle blur; the game widget is cached behind a repaint boundary.
- A fixed preloaded sound bank, at most two admitted effects, priority preemption, short cooldowns and stale-event dropping replace unbounded overlapping playback. Native audio position polling is disabled. Looping music has an independent volume slider, short volume fades, reward ducking and lifecycle pause. Haptic requests are cached/debounced.
- Latest requested setup redesign removes the centered outer card, nested seat cards, switches, board dropdown and long rules paragraph. Count choices, compact human/bot rows and board choices are visible directly; the start action stays below the scroll area. Bot difficulty appears only for bots. Solo still retains an opponent when reducing the seat count.
- Golden previews now load real SDK Roboto and Material icons instead of Ahem rectangles. Added Kazakh standard/small-phone setup coverage alongside existing phone/tablet layouts.

## Physical-device evidence and limits

Xiaomi 2201117TG, profile build with real audio, one 20-move classic match, recorded 2026-09-08 16:53 UTC (`build/game-feel-device/game_feel.json`):

| Metric | Observed |
| --- | --- |
| Recorded frames | 700 |
| Build P90 | 6.633 ms |
| Raster P90 | 15.927 ms |
| Raster P99 | 27.637 ms |
| Raster frames above 16 ms | 53 |

This is a short smoke measurement, **not** sustained 60 FPS, 120 Hz or thermal certification. The layered-stroke optimization and newest setup layout were made afterwards; their attempted phone reinstallation was cancelled with `INSTALL_FAILED_USER_RESTRICTED`, so those revisions have not been physically remeasured. Do not describe them as device-verified. The successful test's result screenshot is valid; its menu screenshot was stale and must not be used as menu evidence. The capture test now waits for the actual menu before capturing it.

**Device-test cleanup incident:** the successful `flutter drive` run used its default cleanup, which stops and uninstalls the target package. The SDK's `drive_service.dart` confirms that behavior, and a subsequent `pm path com.trigrid.game` found no installed package. This was not intended; preservation/recovery of prior local saves cannot be guaranteed. The user was notified. Do not run that default workflow on the user's installed game again. Any future authorized device test must use a separate test application ID/device, or explicitly account for cleanup (including `--keep-app-running`) and back up existing data first. Final installation requires renewed user confirmation after the cancelled attempt; use direct `adb install -r`, never an uninstall fallback.

Release APKs in this repository still use the existing debug signing configuration. They are for local testing, not a Play Store signing handoff.

Follow-up on 2026-09-08: after renewed user authorization, direct `adb install -r`
succeeded on the Xiaomi and the app was launched. This installation did not
rerun the frame/thermal benchmark. The 2026-09-12 changes are documented in
`SEPTEMBER_POLISH.md`; no device installation or device-test cleanup was run
for that revision.

## Final automated verification

- `flutter test --no-pub`: **181 passed**, including strict image comparisons (without updating goldens), all existing engine/controller/LAN tests and new motion/audio/setup coverage.
- `flutter analyze --no-pub`: **no issues found**.
- `flutter build apk --release --target=lib/main.dart`: **passed**, latest APK at `build/app/outputs/flutter-apk/app-release.apk` (70.7 MB). Build after tests, or let the build refresh plugins: integration-test/debug registration can otherwise leak into the release Java registrant. No generated source was hand-edited.
- `git diff --check`: clean.
- Kazakh setup previews cover 430×900 and 320×568 with four seats; the bottom start action remains reachable while settings scroll. Phone/tablet game, handoff, pause and result previews were refreshed with readable fonts.
- Golden updates stage and rename PNGs instead of truncating files held by Windows preview/indexer processes. Normal comparisons remain exact.
