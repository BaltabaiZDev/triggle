import 'dart:async';

import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/services/audio/trigrid_audio_service.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';
import 'package:trigrid/services/haptics/trigrid_haptics_service.dart';

abstract interface class GameFeedback {
  Future<void> initialize(GameFeelSettings settings);

  Future<void> updateSettings(GameFeelSettings settings);

  Future<void> pegTouch();

  Future<void> elasticStretch();

  Future<void> elasticSnap();

  Future<void> invalidMove();

  Future<void> capture(int count);

  Future<void> turnChange();

  Future<void> buttonPress();

  Future<void> playerJoin();

  Future<void> countdown();

  Future<void> victory();

  Future<void> defeat();

  Future<void> draw();

  Future<void> matchEnd(MatchResult result);

  Future<void> dispose();
}

class NoopGameFeedback implements GameFeedback {
  const NoopGameFeedback();

  @override
  Future<void> initialize(GameFeelSettings settings) async {}

  @override
  Future<void> updateSettings(GameFeelSettings settings) async {}

  @override
  Future<void> pegTouch() async {}

  @override
  Future<void> elasticStretch() async {}

  @override
  Future<void> elasticSnap() async {}

  @override
  Future<void> invalidMove() async {}

  @override
  Future<void> capture(int count) async {}

  @override
  Future<void> turnChange() async {}

  @override
  Future<void> buttonPress() async {}

  @override
  Future<void> playerJoin() async {}

  @override
  Future<void> countdown() async {}

  @override
  Future<void> victory() async {}

  @override
  Future<void> defeat() async {}

  @override
  Future<void> draw() async {}

  @override
  Future<void> matchEnd(MatchResult result) async {}

  @override
  Future<void> dispose() async {}
}

class GameFeedbackCoordinator implements GameFeedback {
  GameFeedbackCoordinator({
    TriGridAudioService? audio,
    TriGridHapticsService? haptics,
  }) : _audio = audio ?? TriGridAudioService(),
       _haptics = haptics ?? TriGridHapticsService();

  final TriGridAudioService _audio;
  final TriGridHapticsService _haptics;

  @override
  Future<void> initialize(GameFeelSettings settings) {
    _haptics.updateSettings(settings);
    return _safe(() => _audio.initialize(settings));
  }

  @override
  Future<void> updateSettings(GameFeelSettings settings) {
    _haptics.updateSettings(settings);
    return _safe(() => _audio.updateSettings(settings));
  }

  @override
  Future<void> pegTouch() async {
    await Future.wait([
      _safe(() => _audio.play(GameSound.pegTouch)),
      _safe(() => _haptics.play(GameHaptic.touch)),
    ]);
  }

  @override
  Future<void> elasticStretch() {
    return _safe(() => _audio.play(GameSound.elasticStretch));
  }

  @override
  Future<void> elasticSnap() async {
    await Future.wait([
      _safe(() => _audio.play(GameSound.elasticSnap)),
      _safe(() => _haptics.play(GameHaptic.snap)),
    ]);
  }

  @override
  Future<void> invalidMove() async {
    await Future.wait([
      _safe(() => _audio.play(GameSound.invalidMove)),
      _safe(() => _haptics.play(GameHaptic.invalid)),
    ]);
  }

  @override
  Future<void> capture(int count) async {
    await Future.wait([
      _safe(
        () => _audio.play(
          count > 1 ? GameSound.captureCombo : GameSound.triangleCapture,
        ),
      ),
      _safe(() => _haptics.play(GameHaptic.capture)),
    ]);
  }

  @override
  Future<void> turnChange() {
    return _safe(() => _audio.play(GameSound.turnChange));
  }

  @override
  Future<void> buttonPress() {
    return _safe(() => _audio.play(GameSound.buttonPress));
  }

  @override
  Future<void> playerJoin() {
    return _safe(() => _audio.play(GameSound.playerJoin));
  }

  @override
  Future<void> countdown() {
    return _safe(() => _audio.play(GameSound.countdown));
  }

  @override
  Future<void> victory() async {
    await Future.wait([
      _safe(() => _audio.play(GameSound.victory)),
      _safe(() => _haptics.play(GameHaptic.victory)),
    ]);
  }

  @override
  Future<void> defeat() {
    return _safe(() => _audio.play(GameSound.defeat));
  }

  @override
  Future<void> draw() {
    return _safe(() => _audio.play(GameSound.draw));
  }

  @override
  Future<void> matchEnd(MatchResult result) {
    return result.isTie ? draw() : victory();
  }

  @override
  Future<void> dispose() => _safe(_audio.dispose);

  Future<void> _safe(Future<void> Function() operation) async {
    try {
      await operation();
    } on Object {
      // Audio and haptic feedback must never interrupt authoritative play.
    }
  }
}

void playFeedback(Future<void> feedback) {
  unawaited(feedback);
}
