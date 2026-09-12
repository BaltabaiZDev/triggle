enum BoardSizePreset {
  small(radius: 2),
  classic(radius: 3),
  large(radius: 4),
  huge(radius: 5),
  custom(radius: null);

  const BoardSizePreset({required this.radius});

  final int? radius;
}

class BoardSize {
  const BoardSize._({required this.preset, required this.radius});

  factory BoardSize.fromPreset(BoardSizePreset preset, {int? customRadius}) {
    final radius = preset.radius ?? customRadius;
    if (radius == null) {
      throw ArgumentError.value(
        customRadius,
        'customRadius',
        'A radius is required for the custom preset.',
      );
    }
    if (radius < minimumRadius || radius > maximumRadius) {
      throw RangeError.range(radius, minimumRadius, maximumRadius, 'radius');
    }
    return BoardSize._(preset: preset, radius: radius);
  }

  factory BoardSize.fromJson(Map<String, Object?> json) {
    final presetName = json['preset'] as String;
    final preset = BoardSizePreset.values.byName(presetName);
    return BoardSize.fromPreset(preset, customRadius: json['radius'] as int?);
  }

  static const minimumRadius = 2;
  static const maximumRadius = 8;

  final BoardSizePreset preset;
  final int radius;

  bool get isClassic => preset == BoardSizePreset.classic && radius == 3;

  int get maximumPlayers => radius == 2 ? 2 : 4;

  int get expectedPegCount => 1 + 3 * radius * (radius + 1);

  int get expectedTriangleCount => 6 * radius * radius;

  int get potentialBandMoveCount => 9 * radius * radius - 9 * radius - 6;

  Map<String, Object> toJson() => {'preset': preset.name, 'radius': radius};

  @override
  bool operator ==(Object other) {
    return other is BoardSize &&
        other.preset == preset &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(preset, radius);
}
