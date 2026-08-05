import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/services/audio/trigrid_audio_service.dart';

void main() {
  test('every declared sound and loop is a non-empty PCM WAV asset', () {
    final names = [
      ...GameSound.values.map((sound) => sound.assetName),
      TriGridAudioService.musicAsset,
      TriGridAudioService.ambientAsset,
    ];

    expect(names.toSet(), hasLength(names.length));
    for (final name in names) {
      final file = File('assets/audio/$name');
      expect(file.existsSync(), isTrue, reason: '$name is missing');
      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThan(44), reason: '$name has no samples');
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE');
    }
  });
}
