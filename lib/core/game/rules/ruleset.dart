import 'dart:math' as math;

import 'package:trigrid/core/game/models/board_size.dart';

enum Ruleset { classic, custom }

class PlayerSupplies {
  const PlayerSupplies({required this.bands, required this.markers});

  factory PlayerSupplies.fromJson(Map<String, Object?> json) {
    return PlayerSupplies(
      bands: json['bands'] as int,
      markers: json['markers'] as int,
    );
  }

  final int bands;
  final int markers;

  Map<String, Object> toJson() => {'bands': bands, 'markers': markers};

  @override
  bool operator ==(Object other) {
    return other is PlayerSupplies &&
        other.bands == bands &&
        other.markers == markers;
  }

  @override
  int get hashCode => Object.hash(bands, markers);
}

abstract final class SupplyPolicy {
  static PlayerSupplies forMatch({
    required BoardSize boardSize,
    required int playerCount,
    required Ruleset ruleset,
  }) {
    if (playerCount < 2 || playerCount > 4) {
      throw RangeError.range(playerCount, 2, 4, 'playerCount');
    }
    if (ruleset == Ruleset.classic) {
      if (!boardSize.isClassic) {
        throw ArgumentError(
          'Classic rules require the Classic radius-3 board.',
        );
      }
      return PlayerSupplies(bands: playerCount == 2 ? 10 : 12, markers: 21);
    }

    final classicBandBaseline = playerCount == 2 ? 10 : 12;
    final scaledBands =
        (classicBandBaseline * boardSize.potentialBandMoveCount / 48).round();
    final maximumFairShare = boardSize.potentialBandMoveCount ~/ playerCount;
    final bands = math.min(
      math.max(1, scaledBands),
      math.max(1, maximumFairShare),
    );
    final markers = math.max(
      1,
      (21 * boardSize.expectedTriangleCount / 54).round(),
    );

    return PlayerSupplies(bands: bands, markers: markers);
  }
}
