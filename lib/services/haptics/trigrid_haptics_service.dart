import 'package:trigrid/services/game_feel/game_feel_settings.dart';
import 'package:vibration/vibration.dart';

enum GameHaptic { touch, snap, invalid, capture, victory }

class TriGridHapticsService {
  var _settings = GameFeelSettings();
  bool? _available;

  void updateSettings(GameFeelSettings settings) {
    _settings = settings;
  }

  Future<void> play(GameHaptic haptic) async {
    if (!_settings.haptics) {
      return;
    }
    _available ??= await Vibration.hasVibrator();
    if (!(_available ?? false)) {
      return;
    }
    switch (haptic) {
      case GameHaptic.touch:
        await Vibration.vibrate(duration: 16, amplitude: 42);
      case GameHaptic.snap:
        await Vibration.vibrate(duration: 38, amplitude: 92);
      case GameHaptic.invalid:
        await Vibration.vibrate(
          pattern: const [0, 24, 42, 24],
          intensities: const [0, 72, 0, 72],
        );
      case GameHaptic.capture:
        await Vibration.vibrate(duration: 65, amplitude: 145);
      case GameHaptic.victory:
        await Vibration.vibrate(
          pattern: const [0, 55, 45, 80, 55, 140],
          intensities: const [0, 100, 0, 150, 0, 220],
        );
    }
  }
}
