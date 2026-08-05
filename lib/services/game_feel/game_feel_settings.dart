class GameFeelSettings {
  factory GameFeelSettings({
    double musicVolume = 0.28,
    double soundEffectsVolume = 0.82,
    double ambientVolume = 0.18,
    bool muted = false,
    bool haptics = true,
    bool reducedMotion = false,
    bool particles = true,
    bool screenShake = true,
    double animationSpeed = 1,
  }) {
    return GameFeelSettings._(
      musicVolume: musicVolume.clamp(0, 1),
      soundEffectsVolume: soundEffectsVolume.clamp(0, 1),
      ambientVolume: ambientVolume.clamp(0, 1),
      muted: muted,
      haptics: haptics,
      reducedMotion: reducedMotion,
      particles: particles,
      screenShake: screenShake,
      animationSpeed: animationSpeed.clamp(0.5, 2),
    );
  }

  const GameFeelSettings._({
    required this.musicVolume,
    required this.soundEffectsVolume,
    required this.ambientVolume,
    required this.muted,
    required this.haptics,
    required this.reducedMotion,
    required this.particles,
    required this.screenShake,
    required this.animationSpeed,
  });

  factory GameFeelSettings.fromJson(Map<String, Object?> json) {
    return GameFeelSettings(
      musicVolume: (json['musicVolume']! as num).toDouble(),
      soundEffectsVolume: (json['soundEffectsVolume']! as num).toDouble(),
      ambientVolume: (json['ambientVolume']! as num).toDouble(),
      muted: json['muted']! as bool,
      haptics: json['haptics']! as bool,
      reducedMotion: json['reducedMotion']! as bool,
      particles: json['particles']! as bool,
      screenShake: json['screenShake']! as bool,
      animationSpeed: (json['animationSpeed']! as num).toDouble(),
    );
  }

  final double musicVolume;
  final double soundEffectsVolume;
  final double ambientVolume;
  final bool muted;
  final bool haptics;
  final bool reducedMotion;
  final bool particles;
  final bool screenShake;
  final double animationSpeed;

  double get motionScale => reducedMotion ? 0 : 1 / animationSpeed;

  GameFeelSettings copyWith({
    double? musicVolume,
    double? soundEffectsVolume,
    double? ambientVolume,
    bool? muted,
    bool? haptics,
    bool? reducedMotion,
    bool? particles,
    bool? screenShake,
    double? animationSpeed,
  }) {
    return GameFeelSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      soundEffectsVolume: soundEffectsVolume ?? this.soundEffectsVolume,
      ambientVolume: ambientVolume ?? this.ambientVolume,
      muted: muted ?? this.muted,
      haptics: haptics ?? this.haptics,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      particles: particles ?? this.particles,
      screenShake: screenShake ?? this.screenShake,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }

  Map<String, Object> toJson() => {
    'musicVolume': musicVolume,
    'soundEffectsVolume': soundEffectsVolume,
    'ambientVolume': ambientVolume,
    'muted': muted,
    'haptics': haptics,
    'reducedMotion': reducedMotion,
    'particles': particles,
    'screenShake': screenShake,
    'animationSpeed': animationSpeed,
  };
}
