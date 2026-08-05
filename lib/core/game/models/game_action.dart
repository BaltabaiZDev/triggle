import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';

sealed class GameAction {
  const GameAction({
    required this.actionId,
    required this.playerId,
    required this.expectedRevision,
  });

  factory GameAction.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported GameAction schema version $schemaVersion.',
      );
    }
    final type = json['type']! as String;
    return switch (type) {
      SubmitMoveAction.typeName => SubmitMoveAction.fromJson(json),
      _ => throw FormatException('Unsupported game action type "$type".'),
    };
  }

  final String actionId;
  final String playerId;
  final int expectedRevision;

  static const currentSchemaVersion = 1;

  String get type;

  Map<String, Object> toJson();
}

final class SubmitMoveAction extends GameAction {
  factory SubmitMoveAction({
    required String actionId,
    required String playerId,
    required int expectedRevision,
    required GridCoordinate start,
    required GridCoordinate end,
  }) {
    if (actionId.trim().isEmpty) {
      throw ArgumentError.value(
        actionId,
        'actionId',
        'Action ID cannot be empty.',
      );
    }
    if (playerId.trim().isEmpty) {
      throw ArgumentError.value(
        playerId,
        'playerId',
        'Player ID cannot be empty.',
      );
    }
    if (expectedRevision < 0) {
      throw RangeError.value(
        expectedRevision,
        'expectedRevision',
        'Revision cannot be negative.',
      );
    }
    return SubmitMoveAction._(
      actionId: actionId,
      playerId: playerId,
      expectedRevision: expectedRevision,
      start: start,
      end: end,
    );
  }

  const SubmitMoveAction._({
    required super.actionId,
    required super.playerId,
    required super.expectedRevision,
    required this.start,
    required this.end,
  });

  factory SubmitMoveAction.fromJson(Map<String, Object?> json) {
    return SubmitMoveAction(
      actionId: json['actionId']! as String,
      playerId: json['playerId']! as String,
      expectedRevision: json['expectedRevision']! as int,
      start: GridCoordinate.fromJson(json['start']! as Map<String, Object?>),
      end: GridCoordinate.fromJson(json['end']! as Map<String, Object?>),
    );
  }

  static const typeName = 'submitMove';

  final GridCoordinate start;
  final GridCoordinate end;

  @override
  String get type => typeName;

  @override
  Map<String, Object> toJson() => {
    'schemaVersion': GameAction.currentSchemaVersion,
    'type': type,
    'actionId': actionId,
    'playerId': playerId,
    'expectedRevision': expectedRevision,
    'start': start.toJson(),
    'end': end.toJson(),
  };
}
