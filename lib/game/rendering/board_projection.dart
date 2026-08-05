import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

class BoardProjection {
  const BoardProjection({this.spacing = 112});

  final double spacing;

  Vector2 toWorld(GridCoordinate coordinate) {
    return Vector2(
      spacing * (coordinate.q + coordinate.r / 2),
      spacing * math.sqrt(3) * coordinate.r / 2,
    );
  }

  Vector2 triangleCenter(TriangleCell triangle) {
    final points = triangle.vertices.map(toWorld).toList();
    return points.reduce((a, b) => a + b)..scale(1 / points.length);
  }

  GridCoordinate? nearestPeg(
    Vector2 worldPoint,
    BoardDefinition board, {
    double? maximumDistance,
  }) {
    GridCoordinate? closest;
    var closestDistance = double.infinity;
    for (final peg in board.pegs) {
      final distance = toWorld(peg.coordinate).distanceTo(worldPoint);
      if (distance < closestDistance) {
        closest = peg.coordinate;
        closestDistance = distance;
      }
    }
    final threshold = maximumDistance ?? spacing * 0.34;
    return closestDistance <= threshold ? closest : null;
  }

  Rect boardBounds(BoardDefinition board, {double? padding}) {
    final resolvedPadding = padding ?? spacing * 0.8;
    final points = board.pegs.map((peg) => toWorld(peg.coordinate)).toList();
    final minimumX = points.map((point) => point.x).reduce(math.min);
    final maximumX = points.map((point) => point.x).reduce(math.max);
    final minimumY = points.map((point) => point.y).reduce(math.min);
    final maximumY = points.map((point) => point.y).reduce(math.max);
    return Rect.fromLTRB(
      minimumX - resolvedPadding,
      minimumY - resolvedPadding,
      maximumX + resolvedPadding,
      maximumY + resolvedPadding,
    );
  }
}
