# TriGrid Asset Licenses

No third-party visual, music, or sound assets are currently shipped. Every
asset listed below was created specifically for this project and contains no
external samples.

The geometric board mark in
`lib/presentation/widgets/trigrid_board_mark.dart` is original programmatic
artwork created for TriGrid. The board, peg, elastic, capture-fill, marker-shape,
and preview rendering in `lib/game/components/trigrid_board_component.dart` is
also original programmatic artwork. Flutter's generated platform launcher icons
remain temporary development assets and must be replaced by original TriGrid
icons before release.

## Original generated audio

The WAV files in `assets/audio/` are original synthesized placeholder assets
created by `tool/generate_placeholder_audio.dart`. The generator writes
mono, 16-bit PCM at 22,050 Hz from mathematical oscillators and envelopes.
They are project-authored assets intended for TriGrid and require no
attribution.

Included hooks:

- peg touch, elastic stretch/snap, invalid move;
- triangle capture and multi-capture combo;
- turn change, button press, player join, and countdown;
- victory, defeat, and draw;
- original looping music and ambient beds.

Regenerate them from the repository root with:

```sh
dart run tool/generate_placeholder_audio.dart
```

To replace a sound, keep its existing filename and supply a loop-safe WAV for
the two loop assets. Update this file with the creator, source, license,
modifications, and attribution before committing any replacement. Do not use
samples with unclear provenance.

Every future media asset must record:

- file path;
- creator or source;
- license and proof/link;
- modification notes;
- attribution text, if required.

Assets with unknown provenance or incompatible licenses must not enter the
repository.
