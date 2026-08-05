import 'package:trigrid/core/game/models/band_move.dart';

class PlacedBand {
  const PlacedBand({
    required this.move,
    required this.playerId,
    required this.actionId,
  });

  factory PlacedBand.fromJson(Map<String, Object?> json) {
    return PlacedBand(
      move: BandMove.fromJson(json['move']! as Map<String, Object?>),
      playerId: json['playerId']! as String,
      actionId: json['actionId']! as String,
    );
  }

  final BandMove move;
  final String playerId;
  final String actionId;

  Map<String, Object> toJson() => {
    'move': move.toJson(),
    'playerId': playerId,
    'actionId': actionId,
  };
}
