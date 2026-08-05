import 'package:trigrid/core/game/game_state/game_engine.dart';
import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/models/game_action.dart';
import 'package:trigrid/core/game/models/game_settings.dart';
import 'package:trigrid/core/game/replay/game_state_hasher.dart';

class GameReplay {
  factory GameReplay({
    required GameSettings settings,
    required List<SubmitMoveAction> actions,
    String? expectedFinalHash,
  }) {
    return GameReplay._(
      settings: settings,
      actions: List<SubmitMoveAction>.unmodifiable(actions),
      expectedFinalHash: expectedFinalHash,
    );
  }

  const GameReplay._({
    required this.settings,
    required this.actions,
    required this.expectedFinalHash,
  });

  factory GameReplay.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported GameReplay schema version $schemaVersion.',
      );
    }
    return GameReplay(
      settings: GameSettings.fromJson(
        json['settings']! as Map<String, Object?>,
      ),
      actions: (json['actions']! as List<Object?>)
          .map((action) => GameAction.fromJson(action! as Map<String, Object?>))
          .cast<SubmitMoveAction>()
          .toList(),
      expectedFinalHash: json['expectedFinalHash'] as String?,
    );
  }

  static const currentSchemaVersion = 1;

  final GameSettings settings;
  final List<SubmitMoveAction> actions;
  final String? expectedFinalHash;

  GameReplay withExpectedFinalHash(String hash) {
    return GameReplay(
      settings: settings,
      actions: actions,
      expectedFinalHash: hash,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'settings': settings.toJson(),
    'actions': actions.map((action) => action.toJson()).toList(),
    'expectedFinalHash': expectedFinalHash,
  };
}

class ReplayResult {
  ReplayResult({
    required this.finalState,
    required this.finalHash,
    required List<String> revisionHashes,
  }) : revisionHashes = List<String>.unmodifiable(revisionHashes);

  final GameState finalState;
  final String finalHash;
  final List<String> revisionHashes;
}

class ReplayVerificationException implements Exception {
  const ReplayVerificationException(this.message);

  final String message;

  @override
  String toString() => 'ReplayVerificationException: $message';
}

abstract final class ReplayRunner {
  static ReplayResult run(GameReplay replay) {
    final engine = GameEngine(replay.settings);
    var state = engine.createInitialState(replay.settings);
    final revisionHashes = <String>[GameStateHasher.hash(state)];

    for (var index = 0; index < replay.actions.length; index++) {
      final transition = engine.submitMove(state, replay.actions[index]);
      if (!transition.wasAccepted) {
        throw ReplayVerificationException(
          'Action $index was rejected with '
          '${transition.validation.errorCode?.name}.',
        );
      }
      state = transition.state;
      revisionHashes.add(GameStateHasher.hash(state));
    }

    final finalHash = revisionHashes.last;
    if (replay.expectedFinalHash != null &&
        replay.expectedFinalHash != finalHash) {
      throw ReplayVerificationException(
        'Final hash mismatch: expected ${replay.expectedFinalHash}, '
        'computed $finalHash.',
      );
    }
    return ReplayResult(
      finalState: state,
      finalHash: finalHash,
      revisionHashes: revisionHashes,
    );
  }
}
