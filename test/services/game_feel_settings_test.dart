import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

void main() {
  test('game-feel settings clamp, copy, and serialize', () {
    final settings = GameFeelSettings(
      musicVolume: -1,
      soundEffectsVolume: 2,
      ambientVolume: 0.4,
      muted: true,
      haptics: false,
      reducedMotion: true,
      particles: false,
      screenShake: false,
      animationSpeed: 4,
    );

    expect(settings.musicVolume, 0);
    expect(settings.soundEffectsVolume, 1);
    expect(settings.animationSpeed, 2);
    expect(settings.motionScale, 0);

    final restored = GameFeelSettings.fromJson(settings.toJson());
    expect(restored.toJson(), settings.toJson());

    final copied = restored.copyWith(
      muted: false,
      reducedMotion: false,
      animationSpeed: 0.5,
    );
    expect(copied.muted, isFalse);
    expect(copied.motionScale, 2);
    expect(copied.particles, isFalse);
  });
}
