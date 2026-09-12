import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 22050;

void main() {
  final outputDirectory = Directory('assets/audio')
    ..createSync(recursive: true);
  final sounds = <String, _SoundSpec>{
    'peg_touch.wav': const _SoundSpec(0.08, [720], decay: 18),
    'elastic_stretch.wav': const _SoundSpec(
      0.14,
      [480, 640],
      sweep: true,
      decay: 5,
    ),
    'elastic_snap.wav': const _SoundSpec(0.2, [980, 620, 330], decay: 13),
    'invalid_move.wav': const _SoundSpec(
      0.3,
      [210, 155],
      decay: 4.5,
      squareBlend: 0.18,
    ),
    'triangle_capture.wav': const _SoundSpec(0.38, [
      523.25,
      659.25,
      783.99,
    ], decay: 2.8),
    'capture_combo.wav': const _SoundSpec(0.62, [
      523.25,
      659.25,
      783.99,
      1046.5,
    ], decay: 1.8),
    'turn_change.wav': const _SoundSpec(0.2, [440, 554.37], decay: 5),
    'button_press.wav': const _SoundSpec(0.09, [410], decay: 16),
    'player_join.wav': const _SoundSpec(0.4, [392, 523.25, 659.25], decay: 2.4),
    'countdown.wav': const _SoundSpec(0.24, [587.33], decay: 6),
    'victory.wav': const _SoundSpec(1.25, [
      392,
      523.25,
      659.25,
      783.99,
      1046.5,
    ], decay: 0.75),
    'defeat.wav': const _SoundSpec(0.9, [392, 329.63, 261.63, 196], decay: 1.1),
    'draw.wav': const _SoundSpec(0.8, [
      392,
      493.88,
      587.33,
      493.88,
    ], decay: 1.2),
  };

  for (final entry in sounds.entries) {
    _writeWave(
      File('${outputDirectory.path}/${entry.key}'),
      _renderSound(entry.value),
    );
  }
  _writeWave(
    File('${outputDirectory.path}/music_loop.wav'),
    _renderMusicLoop(),
  );
  _writeWave(
    File('${outputDirectory.path}/ambient_loop.wav'),
    _renderAmbientLoop(),
  );
}

Float64List _renderSound(_SoundSpec spec) {
  final sampleCount = (spec.duration * _sampleRate).round();
  final samples = Float64List(sampleCount);
  var phase = 0.0;
  for (var index = 0; index < sampleCount; index++) {
    final time = index / _sampleRate;
    final normalized = index / sampleCount;
    final scaledSegment = normalized * spec.frequencies.length;
    final segment = math.min(
      spec.frequencies.length - 1,
      scaledSegment.floor(),
    );
    final next = math.min(spec.frequencies.length - 1, segment + 1);
    final localProgress = scaledSegment - segment;
    final frequency = spec.sweep
        ? _lerp(
            spec.frequencies[segment],
            spec.frequencies[next],
            localProgress,
          )
        : spec.frequencies[segment];
    final envelope =
        math.min(1, time * 90) *
        math.exp(-spec.decay * normalized) *
        math.min(1, (1 - normalized) * 18);
    phase += 2 * math.pi * frequency / _sampleRate;
    final sine = math.sin(phase) + 0.22 * math.sin(phase * 2.01);
    final square = math.sin(phase) >= 0 ? 1.0 : -1.0;
    samples[index] =
        (sine * (1 - spec.squareBlend) + square * spec.squareBlend) *
        envelope *
        0.24;
  }
  return samples;
}

Float64List _renderMusicLoop() {
  const duration = 8.0;
  const notes = [
    261.63,
    329.63,
    392.00,
    523.25,
    392.00,
    329.63,
    293.66,
    392.00,
    246.94,
    329.63,
    392.00,
    493.88,
    392.00,
    329.63,
    293.66,
    261.63,
  ];
  final samples = Float64List((duration * _sampleRate).round());
  for (var index = 0; index < samples.length; index++) {
    final time = index / _sampleRate;
    final notePosition = time / duration * notes.length;
    final noteIndex = notePosition.floor() % notes.length;
    final local = notePosition - notePosition.floor();
    final envelope = math.pow(math.sin(math.pi * local).abs(), 0.45).toDouble();
    final melody =
        math.sin(2 * math.pi * notes[noteIndex] * time) +
        0.18 * math.sin(4 * math.pi * notes[noteIndex] * time);
    final pad =
        math.sin(2 * math.pi * 65.41 * time) +
        math.sin(2 * math.pi * 98.00 * time);
    // Zero-ended seam; quiet plucked melody over a warm pad, no loop click.
    final seam = math.min(1.0, math.min(time, duration - time) / 0.055);
    samples[index] = ((melody * envelope * 0.07) + (pad * 0.018)) * seam;
  }
  return samples;
}

Float64List _renderAmbientLoop() {
  const duration = 6.0;
  final samples = Float64List((duration * _sampleRate).round());
  for (var index = 0; index < samples.length; index++) {
    final time = index / _sampleRate;
    final cycle = time / duration;
    final fade = 0.5 - 0.5 * math.cos(2 * math.pi * cycle);
    final air =
        math.sin(2 * math.pi * 82.41 * time) +
        0.5 * math.sin(2 * math.pi * 123.47 * time + 0.8) +
        0.25 * math.sin(2 * math.pi * 164.81 * time + 1.6);
    samples[index] = air * (0.018 + fade * 0.012);
  }
  return samples;
}

void _writeWave(File file, Float64List samples) {
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);
  _writeAscii(bytes, 0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  _writeAscii(bytes, 8, 'WAVE');
  _writeAscii(bytes, 12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  _writeAscii(bytes, 36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var index = 0; index < samples.length; index++) {
    final sample = (samples[index].clamp(-1, 1) * 32767).round();
    bytes.setInt16(44 + index * 2, sample, Endian.little);
  }
  file.writeAsBytesSync(bytes.buffer.asUint8List(), flush: true);
}

void _writeAscii(ByteData data, int offset, String value) {
  for (var index = 0; index < value.length; index++) {
    data.setUint8(offset + index, value.codeUnitAt(index));
  }
}

double _lerp(double start, double end, double progress) {
  return start + (end - start) * progress;
}

class _SoundSpec {
  const _SoundSpec(
    this.duration,
    this.frequencies, {
    this.sweep = false,
    this.decay = 3,
    this.squareBlend = 0,
  });

  final double duration;
  final List<double> frequencies;
  final bool sweep;
  final double decay;
  final double squareBlend;
}
