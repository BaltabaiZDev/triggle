import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

enum AppThemePreference { system, light, dark }

class LocalSetupPreferences {
  const LocalSetupPreferences({
    required this.playerCount,
    required this.boardPreset,
    required this.customRadius,
    required this.useClassicRules,
  });

  factory LocalSetupPreferences.defaults() {
    return LocalSetupPreferences(
      playerCount: 2,
      boardPreset: BoardSizePreset.classic,
      customRadius: 6,
      useClassicRules: true,
    );
  }

  factory LocalSetupPreferences.fromJson(Map<String, Object?> json) {
    return LocalSetupPreferences(
      playerCount: (json['playerCount']! as int).clamp(2, 4),
      boardPreset: BoardSizePreset.values.byName(
        json['boardPreset']! as String,
      ),
      customRadius: (json['customRadius']! as int).clamp(
        BoardSize.minimumRadius,
        BoardSize.maximumRadius,
      ),
      useClassicRules: json['useClassicRules']! as bool,
    );
  }

  final int playerCount;
  final BoardSizePreset boardPreset;
  final int customRadius;
  final bool useClassicRules;

  Map<String, Object?> toJson() => {
    'playerCount': playerCount,
    'boardPreset': boardPreset.name,
    'customRadius': customRadius,
    'useClassicRules': useClassicRules,
  };
}

class LanSetupPreferences {
  const LanSetupPreferences({
    required this.roomName,
    required this.boardPreset,
    required this.ruleset,
    this.botSeats = const {},
    this.turnTimeSeconds,
  });

  factory LanSetupPreferences.defaults() => const LanSetupPreferences(
    roomName: '',
    boardPreset: BoardSizePreset.classic,
    ruleset: Ruleset.classic,
  );

  factory LanSetupPreferences.fromJson(Map<String, Object?> json) {
    return LanSetupPreferences(
      roomName: json['roomName']! as String,
      boardPreset: BoardSizePreset.values.byName(
        json['boardPreset']! as String,
      ),
      ruleset: Ruleset.values.byName(json['ruleset']! as String),
      turnTimeSeconds: json['turnTimeSeconds'] as int?,
      botSeats: {
        for (final entry
            in (json['botSeats'] as Map<String, Object?>? ?? const {}).entries)
          int.parse(entry.key): BotSettings.fromJson(
            entry.value! as Map<String, Object?>,
          ),
      },
    );
  }

  final String roomName;
  final BoardSizePreset boardPreset;
  final Ruleset ruleset;
  final Map<int, BotSettings> botSeats;
  final int? turnTimeSeconds;

  LanSetupPreferences copyWith({
    String? roomName,
    BoardSizePreset? boardPreset,
    Ruleset? ruleset,
    Map<int, BotSettings>? botSeats,
    int? turnTimeSeconds,
    bool clearTurnTime = false,
  }) {
    return LanSetupPreferences(
      roomName: roomName ?? this.roomName,
      boardPreset: boardPreset ?? this.boardPreset,
      ruleset: ruleset ?? this.ruleset,
      botSeats: Map.unmodifiable(botSeats ?? this.botSeats),
      turnTimeSeconds: clearTurnTime
          ? null
          : (turnTimeSeconds ?? this.turnTimeSeconds),
    );
  }

  Map<String, Object?> toJson() => {
    'roomName': roomName,
    'boardPreset': boardPreset.name,
    'ruleset': ruleset.name,
    'botSeats': {
      for (final entry in botSeats.entries)
        '${entry.key}': entry.value.toJson(),
    },
    'turnTimeSeconds': turnTimeSeconds,
  };
}

class AppPreferences {
  const AppPreferences({
    required this.playerName,
    required this.localeCode,
    required this.themePreference,
    required this.highContrast,
    required this.alwaysShowPlayerSymbols,
    required this.confirmMoves,
    required this.gameFeel,
    required this.soloSetup,
    required this.passAndPlaySetup,
    required this.lanSetup,
  });

  factory AppPreferences.defaults() => AppPreferences(
    playerName: '',
    localeCode: null,
    themePreference: AppThemePreference.system,
    highContrast: false,
    alwaysShowPlayerSymbols: true,
    confirmMoves: false,
    gameFeel: GameFeelSettings(),
    soloSetup: LocalSetupPreferences.defaults(),
    passAndPlaySetup: LocalSetupPreferences.defaults(),
    lanSetup: LanSetupPreferences.defaults(),
  );

  factory AppPreferences.fromJson(Map<String, Object?> json) {
    return AppPreferences(
      playerName: json['playerName'] as String? ?? '',
      localeCode: json['localeCode'] as String?,
      themePreference: AppThemePreference.values.byName(
        json['themePreference'] as String? ?? AppThemePreference.system.name,
      ),
      highContrast: json['highContrast'] as bool? ?? false,
      alwaysShowPlayerSymbols: json['alwaysShowPlayerSymbols'] as bool? ?? true,
      confirmMoves: json['confirmMoves'] as bool? ?? false,
      gameFeel: json['gameFeel'] == null
          ? GameFeelSettings()
          : GameFeelSettings.fromJson(
              json['gameFeel']! as Map<String, Object?>,
            ),
      soloSetup: json['soloSetup'] == null
          ? LocalSetupPreferences.defaults()
          : LocalSetupPreferences.fromJson(
              json['soloSetup']! as Map<String, Object?>,
            ),
      passAndPlaySetup: json['passAndPlaySetup'] == null
          ? LocalSetupPreferences.defaults()
          : LocalSetupPreferences.fromJson(
              json['passAndPlaySetup']! as Map<String, Object?>,
            ),
      lanSetup: json['lanSetup'] == null
          ? LanSetupPreferences.defaults()
          : LanSetupPreferences.fromJson(
              json['lanSetup']! as Map<String, Object?>,
            ),
    );
  }

  final String playerName;
  final String? localeCode;
  final AppThemePreference themePreference;
  final bool highContrast;
  final bool alwaysShowPlayerSymbols;
  final bool confirmMoves;
  final GameFeelSettings gameFeel;
  final LocalSetupPreferences soloSetup;
  final LocalSetupPreferences passAndPlaySetup;
  final LanSetupPreferences lanSetup;

  AppPreferences copyWith({
    String? playerName,
    String? localeCode,
    bool clearLocale = false,
    AppThemePreference? themePreference,
    bool? highContrast,
    bool? alwaysShowPlayerSymbols,
    bool? confirmMoves,
    GameFeelSettings? gameFeel,
    LocalSetupPreferences? soloSetup,
    LocalSetupPreferences? passAndPlaySetup,
    LanSetupPreferences? lanSetup,
  }) {
    return AppPreferences(
      playerName: playerName ?? this.playerName,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      themePreference: themePreference ?? this.themePreference,
      highContrast: highContrast ?? this.highContrast,
      alwaysShowPlayerSymbols:
          alwaysShowPlayerSymbols ?? this.alwaysShowPlayerSymbols,
      confirmMoves: confirmMoves ?? this.confirmMoves,
      gameFeel: gameFeel ?? this.gameFeel,
      soloSetup: soloSetup ?? this.soloSetup,
      passAndPlaySetup: passAndPlaySetup ?? this.passAndPlaySetup,
      lanSetup: lanSetup ?? this.lanSetup,
    );
  }

  Map<String, Object?> toJson() => {
    'playerName': playerName,
    'localeCode': localeCode,
    'themePreference': themePreference.name,
    'highContrast': highContrast,
    'alwaysShowPlayerSymbols': alwaysShowPlayerSymbols,
    'confirmMoves': confirmMoves,
    'gameFeel': gameFeel.toJson(),
    'soloSetup': soloSetup.toJson(),
    'passAndPlaySetup': passAndPlaySetup.toJson(),
    'lanSetup': lanSetup.toJson(),
  };
}
