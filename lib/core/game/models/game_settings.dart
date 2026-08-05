import 'package:trigrid/core/game/models/board_size.dart';
import 'package:trigrid/core/game/models/player_state.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

class GameSettings {
  factory GameSettings({
    required String matchId,
    required BoardSize boardSize,
    required Ruleset ruleset,
    required List<PlayerConfiguration> players,
    required int seed,
    int? turnTimeSeconds,
  }) {
    if (matchId.trim().isEmpty) {
      throw ArgumentError.value(
        matchId,
        'matchId',
        'Match ID cannot be empty.',
      );
    }
    if (players.length < 2 || players.length > 4) {
      throw RangeError.range(players.length, 2, 4, 'players.length');
    }
    final playerIds = players.map((player) => player.id).toSet();
    if (playerIds.length != players.length) {
      throw ArgumentError('Player IDs must be unique.');
    }
    if (ruleset == Ruleset.classic && !boardSize.isClassic) {
      throw ArgumentError('Classic rules require the Classic radius-3 board.');
    }
    if (turnTimeSeconds != null &&
        (turnTimeSeconds < 10 || turnTimeSeconds > 300)) {
      throw RangeError.range(turnTimeSeconds, 10, 300, 'turnTimeSeconds');
    }
    return GameSettings._(
      matchId: matchId,
      boardSize: boardSize,
      ruleset: ruleset,
      players: List<PlayerConfiguration>.unmodifiable(players),
      seed: seed,
      turnTimeSeconds: turnTimeSeconds,
    );
  }

  const GameSettings._({
    required this.matchId,
    required this.boardSize,
    required this.ruleset,
    required this.players,
    required this.seed,
    required this.turnTimeSeconds,
  });

  factory GameSettings.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported GameSettings schema version $schemaVersion.',
      );
    }
    final rulesVersion = json['rulesVersion']! as int;
    if (rulesVersion != currentRulesVersion) {
      throw FormatException('Unsupported rules version $rulesVersion.');
    }
    return GameSettings(
      matchId: json['matchId']! as String,
      boardSize: BoardSize.fromJson(json['boardSize']! as Map<String, Object?>),
      ruleset: Ruleset.values.byName(json['ruleset']! as String),
      players: (json['players']! as List<Object?>)
          .map(
            (player) =>
                PlayerConfiguration.fromJson(player! as Map<String, Object?>),
          )
          .toList(),
      seed: json['seed']! as int,
      turnTimeSeconds: json['turnTimeSeconds'] as int?,
    );
  }

  static const currentSchemaVersion = 1;
  static const currentRulesVersion = 1;

  final String matchId;
  final BoardSize boardSize;
  final Ruleset ruleset;
  final List<PlayerConfiguration> players;
  final int seed;
  final int? turnTimeSeconds;

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'rulesVersion': currentRulesVersion,
    'matchId': matchId,
    'boardSize': boardSize.toJson(),
    'ruleset': ruleset.name,
    'players': players.map((player) => player.toJson()).toList(),
    'seed': seed,
    'turnTimeSeconds': turnTimeSeconds,
  };
}
