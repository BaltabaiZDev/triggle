enum BotDifficulty { beginner, easy, normal, hard, expert }

enum BotPersonality { aggressive, defensive, balanced }

class BotSettings {
  factory BotSettings({
    BotDifficulty difficulty = BotDifficulty.normal,
    BotPersonality personality = BotPersonality.balanced,
    int thinkingTimeMs = 350,
    bool deterministic = false,
    int seedOffset = 0,
  }) {
    return BotSettings._(
      difficulty: difficulty,
      personality: personality,
      thinkingTimeMs: thinkingTimeMs.clamp(25, 5000),
      deterministic: deterministic,
      seedOffset: seedOffset,
    );
  }

  const BotSettings._({
    required this.difficulty,
    required this.personality,
    required this.thinkingTimeMs,
    required this.deterministic,
    required this.seedOffset,
  });

  factory BotSettings.fromJson(Map<String, Object?> json) {
    return BotSettings(
      difficulty: BotDifficulty.values.byName(json['difficulty']! as String),
      personality: BotPersonality.values.byName(json['personality']! as String),
      thinkingTimeMs: json['thinkingTimeMs']! as int,
      deterministic: json['deterministic']! as bool,
      seedOffset: json['seedOffset']! as int,
    );
  }

  static final BotSettings standard = BotSettings();

  final BotDifficulty difficulty;
  final BotPersonality personality;
  final int thinkingTimeMs;
  final bool deterministic;
  final int seedOffset;

  BotSettings copyWith({
    BotDifficulty? difficulty,
    BotPersonality? personality,
    int? thinkingTimeMs,
    bool? deterministic,
    int? seedOffset,
  }) {
    return BotSettings(
      difficulty: difficulty ?? this.difficulty,
      personality: personality ?? this.personality,
      thinkingTimeMs: thinkingTimeMs ?? this.thinkingTimeMs,
      deterministic: deterministic ?? this.deterministic,
      seedOffset: seedOffset ?? this.seedOffset,
    );
  }

  Map<String, Object> toJson() => {
    'difficulty': difficulty.name,
    'personality': personality.name,
    'thinkingTimeMs': thinkingTimeMs,
    'deterministic': deterministic,
    'seedOffset': seedOffset,
  };
}
