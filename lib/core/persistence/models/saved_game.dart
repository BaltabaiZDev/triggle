import 'package:trigrid/core/game/trigrid_engine.dart';

enum MatchMode { local, lan }

class SavedMatchSnapshot {
  const SavedMatchSnapshot({
    required this.state,
    required this.actions,
    required this.stateHash,
    required this.savedAtUtc,
    required this.passAndPlayHandoffs,
  });

  factory SavedMatchSnapshot.fromJson(Map<String, Object?> json) {
    return SavedMatchSnapshot(
      state: GameState.fromJson(json['state']! as Map<String, Object?>),
      actions: (json['actions']! as List<Object?>)
          .map(
            (item) => SubmitMoveAction.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      stateHash: json['stateHash']! as String,
      savedAtUtc: DateTime.parse(json['savedAtUtc']! as String).toUtc(),
      passAndPlayHandoffs: json['passAndPlayHandoffs'] as bool? ?? true,
    );
  }

  final GameState state;
  final List<SubmitMoveAction> actions;
  final String stateHash;
  final DateTime savedAtUtc;
  final bool passAndPlayHandoffs;

  Map<String, Object?> toJson() => {
    'state': state.toJson(),
    'actions': actions.map((action) => action.toJson()).toList(),
    'stateHash': stateHash,
    'savedAtUtc': savedAtUtc.toIso8601String(),
    'passAndPlayHandoffs': passAndPlayHandoffs,
  };
}

class SavedReplayEntry {
  const SavedReplayEntry({
    required this.id,
    required this.mode,
    required this.createdAtUtc,
    required this.replay,
  });

  factory SavedReplayEntry.fromJson(Map<String, Object?> json) {
    return SavedReplayEntry(
      id: json['id']! as String,
      mode: MatchMode.values.byName(json['mode']! as String),
      createdAtUtc: DateTime.parse(json['createdAtUtc']! as String).toUtc(),
      replay: GameReplay.fromJson(json['replay']! as Map<String, Object?>),
    );
  }

  final String id;
  final MatchMode mode;
  final DateTime createdAtUtc;
  final GameReplay replay;

  Map<String, Object?> toJson() => {
    'id': id,
    'mode': mode.name,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'replay': replay.toJson(),
  };
}

class SavedLanSnapshot {
  const SavedLanSnapshot({
    required this.id,
    required this.state,
    required this.stateHash,
    required this.savedAtUtc,
  });

  factory SavedLanSnapshot.fromJson(Map<String, Object?> json) {
    return SavedLanSnapshot(
      id: json['id']! as String,
      state: GameState.fromJson(json['state']! as Map<String, Object?>),
      stateHash: json['stateHash']! as String,
      savedAtUtc: DateTime.parse(json['savedAtUtc']! as String).toUtc(),
    );
  }

  final String id;
  final GameState state;
  final String stateHash;
  final DateTime savedAtUtc;

  Map<String, Object?> toJson() => {
    'id': id,
    'state': state.toJson(),
    'stateHash': stateHash,
    'savedAtUtc': savedAtUtc.toIso8601String(),
  };
}
