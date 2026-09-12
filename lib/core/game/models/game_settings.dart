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
    int rulesVersion = currentRulesVersion,
    int startingPlayerIndex = 0,
  }) {
    if (rulesVersion < 1 || rulesVersion > currentRulesVersion) {
      throw FormatException('Unsupported rules version $rulesVersion.');
    }
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
    if (rulesVersion >= 2 && players.length > boardSize.maximumPlayers) {
      throw ArgumentError(
        'This board supports at most ${boardSize.maximumPlayers} players.',
      );
    }
    if (startingPlayerIndex < 0 || startingPlayerIndex >= players.length) {
      throw RangeError.index(
        startingPlayerIndex,
        players,
        'startingPlayerIndex',
      );
    }
    if (rulesVersion == 1 && startingPlayerIndex != 0) {
      throw ArgumentError('Legacy rules always start with the first seat.');
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
      rulesVersion: rulesVersion,
      startingPlayerIndex: startingPlayerIndex,
    );
  }

  const GameSettings._({
    required this.matchId,
    required this.boardSize,
    required this.ruleset,
    required this.players,
    required this.seed,
    required this.turnTimeSeconds,
    required this.rulesVersion,
    required this.startingPlayerIndex,
  });

  factory GameSettings.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported GameSettings schema version $schemaVersion.',
      );
    }
    final rulesVersion = json['rulesVersion']! as int;
    if (rulesVersion < 1 || rulesVersion > currentRulesVersion) {
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
      rulesVersion: rulesVersion,
      startingPlayerIndex: json['startingPlayerIndex'] as int? ?? 0,
    );
  }

  static const currentSchemaVersion = 1;
  static const currentRulesVersion = SupplyPolicy.currentRulesVersion;

  final String matchId;
  final BoardSize boardSize;
  final Ruleset ruleset;
  final List<PlayerConfiguration> players;
  final int seed;
  final int? turnTimeSeconds;
  final int rulesVersion;
  final int startingPlayerIndex;

  GameSettings nextRound({required String matchId}) => GameSettings(
    matchId: matchId,
    boardSize: boardSize,
    ruleset: ruleset,
    players: players,
    seed: seed + 1,
    turnTimeSeconds: turnTimeSeconds,
    rulesVersion: rulesVersion,
    startingPlayerIndex: rulesVersion >= 2
        ? (startingPlayerIndex + 1) % players.length
        : 0,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'rulesVersion': rulesVersion,
    if (rulesVersion >= 2) 'startingPlayerIndex': startingPlayerIndex,
    'matchId': matchId,
    'boardSize': boardSize.toJson(),
    'ruleset': ruleset.name,
    'players': players.map((player) => player.toJson()).toList(),
    'seed': seed,
    'turnTimeSeconds': turnTimeSeconds,
  };
}
