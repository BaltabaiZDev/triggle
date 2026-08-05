import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/rendering/board_projection.dart';

void main() {
  const projection = BoardProjection(spacing: 100);
  final board = BoardGenerator.generate(
    BoardSize.fromPreset(BoardSizePreset.classic),
  );

  test('projects every lattice direction to equal world distance', () {
    const origin = GridCoordinate(0, 0);
    final originWorld = projection.toWorld(origin);

    for (final direction in GridCoordinate.directions) {
      expect(
        projection.toWorld(direction).distanceTo(originWorld),
        closeTo(100, 0.0001),
      );
    }
  });

  test('selects the nearest peg only within the hit radius', () {
    const coordinate = GridCoordinate(1, -1);
    final point = projection.toWorld(coordinate);

    expect(projection.nearestPeg(point + Vector2(5, 4), board), coordinate);
    expect(
      projection.nearestPeg(
        point + Vector2(70, 70),
        board,
        maximumDistance: 20,
      ),
      isNull,
    );
  });

  test('creates padded bounds containing every generated peg', () {
    final bounds = projection.boardBounds(board, padding: 30);

    for (final peg in board.pegs) {
      final point = projection.toWorld(peg.coordinate);
      expect(bounds.contains(point.toOffset()), isTrue);
    }
    expect(bounds.center.dx, closeTo(0, 0.0001));
    expect(bounds.center.dy, closeTo(0, 0.0001));
  });
}
