import 'dart:ui';

enum PlayerMarkerShape { circle, diamond, triangle, square }

class PlayerVisuals {
  const PlayerVisuals({required this.color, required this.markerShape});

  final Color color;
  final PlayerMarkerShape markerShape;

  static const bySeat = <PlayerVisuals>[
    PlayerVisuals(
      color: Color(0xFF71C56B),
      markerShape: PlayerMarkerShape.circle,
    ),
    PlayerVisuals(
      color: Color(0xFFD86486),
      markerShape: PlayerMarkerShape.diamond,
    ),
    PlayerVisuals(
      color: Color(0xFF7968C6),
      markerShape: PlayerMarkerShape.triangle,
    ),
    PlayerVisuals(
      color: Color(0xFF58C2BF),
      markerShape: PlayerMarkerShape.square,
    ),
  ];

  static PlayerVisuals forSeat(int seatIndex) {
    return bySeat[seatIndex % bySeat.length];
  }
}
