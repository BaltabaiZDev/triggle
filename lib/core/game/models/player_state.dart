import 'package:trigrid/core/game/models/bot_settings.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

enum PlayerControllerType { human, bot }

class PlayerConfiguration {
  factory PlayerConfiguration({
    required String id,
    required String displayName,
    required PlayerControllerType controllerType,
    BotSettings? botSettings,
    int? visualIndex,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Player ID cannot be empty.');
    }
    if (displayName.trim().isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'Player name cannot be empty.',
      );
    }
    if (visualIndex != null && (visualIndex < 0 || visualIndex > 3)) {
      throw RangeError.range(visualIndex, 0, 3, 'visualIndex');
    }
    return PlayerConfiguration._(
      id: id,
      displayName: displayName,
      controllerType: controllerType,
      botSettings: controllerType == PlayerControllerType.bot
          ? (botSettings ?? BotSettings.standard)
          : null,
      visualIndex: visualIndex,
    );
  }

  const PlayerConfiguration._({
    required this.id,
    required this.displayName,
    required this.controllerType,
    required this.botSettings,
    required this.visualIndex,
  });

  factory PlayerConfiguration.fromJson(Map<String, Object?> json) {
    return PlayerConfiguration(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      controllerType: PlayerControllerType.values.byName(
        json['controllerType']! as String,
      ),
      botSettings: json['botSettings'] == null
          ? null
          : BotSettings.fromJson(json['botSettings']! as Map<String, Object?>),
      visualIndex: json['visualIndex'] as int?,
    );
  }

  final String id;
  final String displayName;
  final PlayerControllerType controllerType;
  final BotSettings? botSettings;
  final int? visualIndex;

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'controllerType': controllerType.name,
    'botSettings': botSettings?.toJson(),
    'visualIndex': visualIndex,
  };
}

class PlayerState {
  const PlayerState({
    required this.id,
    required this.displayName,
    required this.controllerType,
    required this.botSettings,
    required this.seatIndex,
    required this.visualIndex,
    required this.score,
    required this.bandsRemaining,
    required this.markersRemaining,
  });

  factory PlayerState.initial({
    required PlayerConfiguration configuration,
    required int seatIndex,
    required PlayerSupplies supplies,
  }) {
    return PlayerState(
      id: configuration.id,
      displayName: configuration.displayName,
      controllerType: configuration.controllerType,
      botSettings: configuration.botSettings,
      seatIndex: seatIndex,
      visualIndex: configuration.visualIndex ?? seatIndex,
      score: 0,
      bandsRemaining: supplies.bands,
      markersRemaining: supplies.markers,
    );
  }

  factory PlayerState.fromJson(Map<String, Object?> json) {
    return PlayerState(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      controllerType: PlayerControllerType.values.byName(
        json['controllerType']! as String,
      ),
      botSettings: json['botSettings'] == null
          ? null
          : BotSettings.fromJson(json['botSettings']! as Map<String, Object?>),
      seatIndex: json['seatIndex']! as int,
      visualIndex: json['visualIndex'] as int? ?? json['seatIndex']! as int,
      score: json['score']! as int,
      bandsRemaining: json['bandsRemaining']! as int,
      markersRemaining: json['markersRemaining']! as int,
    );
  }

  final String id;
  final String displayName;
  final PlayerControllerType controllerType;
  final BotSettings? botSettings;
  final int seatIndex;
  final int visualIndex;
  final int score;
  final int bandsRemaining;
  final int markersRemaining;

  PlayerState copyWith({
    String? displayName,
    PlayerControllerType? controllerType,
    BotSettings? botSettings,
    bool clearBotSettings = false,
    int? score,
    int? bandsRemaining,
    int? markersRemaining,
  }) {
    return PlayerState(
      id: id,
      displayName: displayName ?? this.displayName,
      controllerType: controllerType ?? this.controllerType,
      botSettings: clearBotSettings ? null : (botSettings ?? this.botSettings),
      seatIndex: seatIndex,
      visualIndex: visualIndex,
      score: score ?? this.score,
      bandsRemaining: bandsRemaining ?? this.bandsRemaining,
      markersRemaining: markersRemaining ?? this.markersRemaining,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'controllerType': controllerType.name,
    'botSettings': botSettings?.toJson(),
    'seatIndex': seatIndex,
    'visualIndex': visualIndex,
    'score': score,
    'bandsRemaining': bandsRemaining,
    'markersRemaining': markersRemaining,
  };
}
