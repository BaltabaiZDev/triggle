import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/services/audio/sound_mix_policy.dart';

void main() {
  test('caps simultaneous effects and drops bursts without a queue', () {
    final mix = SoundMixPolicy<String>();
    expect(mix.admit('tap', nowMs: 0, durationMs: 100, priority: 0), isEmpty);
    expect(mix.admit('tap', nowMs: 20, durationMs: 100, priority: 0), isNull);
    expect(
      mix.admit('select', nowMs: 20, durationMs: 100, priority: 0),
      isEmpty,
    );
    expect(mix.admit('turn', nowMs: 30, durationMs: 100, priority: 0), isNull);
    expect(mix.admit('tap', nowMs: 150, durationMs: 100, priority: 0), isEmpty);
  });
  test(
    'reward preempts taps; victory preempts reward; lower priority is silent',
    () {
      final mix = SoundMixPolicy<String>();
      mix.admit('tap', nowMs: 0, durationMs: 100, priority: 0);
      expect(mix.admit('capture', nowMs: 10, durationMs: 400, priority: 2), {
        'tap',
      });
      expect(
        mix.admit('turn', nowMs: 11, durationMs: 200, priority: 0),
        isNull,
      );
      expect(mix.admit('victory', nowMs: 20, durationMs: 1250, priority: 3), {
        'capture',
      });
      expect(mix.admit('tap', nowMs: 500, durationMs: 90, priority: 0), isNull);
      expect(
        mix.admit('tap', nowMs: 1300, durationMs: 90, priority: 0),
        isEmpty,
      );
    },
  );
  test('mute/background reset leaves no stale reservations', () {
    final mix = SoundMixPolicy<String>();
    mix.admit('victory', nowMs: 0, durationMs: 1250, priority: 3);
    mix.clear();
    expect(mix.admit('tap', nowMs: 10, durationMs: 90, priority: 0), isEmpty);
  });
}
