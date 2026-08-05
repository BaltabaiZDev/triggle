import 'package:trigrid/core/game/models/band_move.dart';
import 'package:trigrid/core/game/models/bot_settings.dart';

class BotDecision {
  const BotDecision({
    required this.move,
    required this.difficulty,
    required this.estimatedValue,
    required this.nodesVisited,
    required this.completedDepth,
    required this.elapsedMilliseconds,
  });

  factory BotDecision.fromJson(Map<String, Object?> json) {
    return BotDecision(
      move: BandMove.fromJson(json['move']! as Map<String, Object?>),
      difficulty: BotDifficulty.values.byName(json['difficulty']! as String),
      estimatedValue: (json['estimatedValue']! as num).toDouble(),
      nodesVisited: json['nodesVisited']! as int,
      completedDepth: json['completedDepth']! as int,
      elapsedMilliseconds: json['elapsedMilliseconds']! as int,
    );
  }

  final BandMove move;
  final BotDifficulty difficulty;
  final double estimatedValue;
  final int nodesVisited;
  final int completedDepth;
  final int elapsedMilliseconds;

  Map<String, Object> toJson() => {
    'move': move.toJson(),
    'difficulty': difficulty.name,
    'estimatedValue': estimatedValue,
    'nodesVisited': nodesVisited,
    'completedDepth': completedDepth,
    'elapsedMilliseconds': elapsedMilliseconds,
  };
}
