import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/geometry/board_definition.dart';
import 'package:trigrid/core/game/models/board_size.dart';

void main() {
  group('GridCoordinate', () {
    test('round-trips between axial and cube coordinates', () {
      const coordinate = GridCoordinate(-3, 5);

      expect(GridCoordinate.fromCube(coordinate.toCube()), coordinate);
      expect(
        coordinate.toCube().x + coordinate.toCube().y + coordinate.toCube().z,
        0,
      );
    });

    test('calculates distance and legal lattice alignment', () {
      const origin = GridCoordinate(0, 0);

      expect(origin.distanceTo(const GridCoordinate(3, -3)), 3);
      expect(origin.isAlignedWith(const GridCoordinate(3, -3)), isTrue);
      expect(origin.isAlignedWith(const GridCoordinate(2, 1)), isFalse);
      expect(
        origin.unitDirectionTo(const GridCoordinate(-3, 3)),
        const GridCoordinate(-1, 1),
      );
    });
  });

  group('BoardGenerator', () {
    test('generates canonical Classic counts and indexes', () {
      final board = BoardGenerator.generate(
        BoardSize.fromPreset(BoardSizePreset.classic),
      );

      expect(board.pegs, hasLength(37));
      expect(board.triangles, hasLength(54));
      expect(board.bandMoves, hasLength(48));
      expect(board.pegByCoordinate, hasLength(37));
      expect(board.triangleById, hasLength(54));
      expect(board.bandMoveById, hasLength(48));
    });

    test('matches the formulas for every supported radius', () {
      for (
        var radius = BoardSize.minimumRadius;
        radius <= BoardSize.maximumRadius;
        radius++
      ) {
        final size = BoardSize.fromPreset(
          BoardSizePreset.custom,
          customRadius: radius,
        );
        final board = BoardGenerator.generate(size);

        expect(board.pegs, hasLength(size.expectedPegCount));
        expect(board.triangles, hasLength(size.expectedTriangleCount));
        expect(board.bandMoves, hasLength(size.potentialBandMoveCount));
      }
    });

    test('generates valid triangles and edge adjacency', () {
      final board = BoardGenerator.generate(
        BoardSize.fromPreset(BoardSizePreset.classic),
      );

      for (final triangle in board.triangles) {
        expect(triangle.vertices.toSet(), hasLength(3));
        expect(triangle.edges, hasLength(3));
        for (final edge in triangle.edges) {
          expect(edge.a.distanceTo(edge.b), 1);
          expect(board.trianglesByEdge[edge], contains(triangle));
        }
      }
    });

    test('every generated move spans four pegs and three unit edges', () {
      for (final preset in [
        BoardSizePreset.small,
        BoardSizePreset.classic,
        BoardSizePreset.large,
        BoardSizePreset.huge,
      ]) {
        final board = BoardGenerator.generate(BoardSize.fromPreset(preset));

        for (final move in board.bandMoves) {
          expect(move.pegs, hasLength(4));
          expect(move.edges, hasLength(3));
          expect(move.start.distanceTo(move.end), 3);
          expect(move.start.isAlignedWith(move.end), isTrue);
          expect(move.pegs.every(board.containsPeg), isTrue);
          expect(move.edges.every(board.unitEdges.contains), isTrue);
        }
      }
    });

    test('reuses immutable generated definitions', () {
      final size = BoardSize.fromPreset(BoardSizePreset.large);

      expect(
        identical(BoardGenerator.generate(size), BoardGenerator.generate(size)),
        isTrue,
      );
    });
  });
}
