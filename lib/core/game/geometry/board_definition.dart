import 'dart:collection';
import 'dart:math' as math;

import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/models/band_move.dart';
import 'package:trigrid/core/game/models/board_size.dart';
import 'package:trigrid/core/game/models/peg.dart';
import 'package:trigrid/core/game/models/triangle_cell.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';

class BoardDefinition {
  BoardDefinition._({
    required this.size,
    required List<Peg> pegs,
    required List<UnitEdge> unitEdges,
    required List<TriangleCell> triangles,
    required List<BandMove> bandMoves,
    required Map<UnitEdge, List<TriangleCell>> trianglesByEdge,
    required Map<GridCoordinate, List<BandMove>> movesByPeg,
  }) : pegs = List<Peg>.unmodifiable(pegs),
       unitEdges = List<UnitEdge>.unmodifiable(unitEdges),
       triangles = List<TriangleCell>.unmodifiable(triangles),
       bandMoves = List<BandMove>.unmodifiable(bandMoves),
       pegByCoordinate = Map<GridCoordinate, Peg>.unmodifiable({
         for (final peg in pegs) peg.coordinate: peg,
       }),
       edgeById = Map<String, UnitEdge>.unmodifiable({
         for (final edge in unitEdges) edge.id: edge,
       }),
       triangleById = Map<String, TriangleCell>.unmodifiable({
         for (final triangle in triangles) triangle.id: triangle,
       }),
       bandMoveById = Map<String, BandMove>.unmodifiable({
         for (final move in bandMoves) move.id: move,
       }),
       trianglesByEdge = Map<UnitEdge, List<TriangleCell>>.unmodifiable({
         for (final entry in trianglesByEdge.entries)
           entry.key: List<TriangleCell>.unmodifiable(entry.value),
       }),
       movesByPeg = Map<GridCoordinate, List<BandMove>>.unmodifiable({
         for (final entry in movesByPeg.entries)
           entry.key: List<BandMove>.unmodifiable(entry.value),
       });

  factory BoardDefinition.fromJson(Map<String, Object?> json) {
    return BoardGenerator.generate(
      BoardSize.fromJson(json['size']! as Map<String, Object?>),
    );
  }

  final BoardSize size;
  final List<Peg> pegs;
  final List<UnitEdge> unitEdges;
  final List<TriangleCell> triangles;
  final List<BandMove> bandMoves;
  final Map<GridCoordinate, Peg> pegByCoordinate;
  final Map<String, UnitEdge> edgeById;
  final Map<String, TriangleCell> triangleById;
  final Map<String, BandMove> bandMoveById;
  final Map<UnitEdge, List<TriangleCell>> trianglesByEdge;
  final Map<GridCoordinate, List<BandMove>> movesByPeg;

  bool containsPeg(GridCoordinate coordinate) {
    return pegByCoordinate.containsKey(coordinate);
  }

  BandMove? moveBetween(
    GridCoordinate firstEndpoint,
    GridCoordinate secondEndpoint,
  ) {
    return bandMoveById[BandMove.idFor(firstEndpoint, secondEndpoint)];
  }

  Map<String, Object> toJson() => {'size': size.toJson()};
}

abstract final class BoardGenerator {
  static final Map<BoardSize, BoardDefinition> _cache = {};

  static BoardDefinition generate(BoardSize size) {
    return _cache.putIfAbsent(size, () => _generateUncached(size));
  }

  static void clearCache() => _cache.clear();

  static BoardDefinition _generateUncached(BoardSize size) {
    final coordinates = _generateCoordinates(size.radius);
    final coordinateSet = coordinates.toSet();
    final pegs = coordinates.map(Peg.new).toList()..sort();

    final edgesById = SplayTreeMap<String, UnitEdge>();
    for (final coordinate in coordinates) {
      for (final direction in GridCoordinate.canonicalAxes) {
        final neighbor = coordinate + direction;
        if (coordinateSet.contains(neighbor)) {
          final edge = UnitEdge(coordinate, neighbor);
          edgesById[edge.id] = edge;
        }
      }
    }

    final trianglesById = SplayTreeMap<String, TriangleCell>();
    for (final coordinate in coordinates) {
      for (var index = 0; index < GridCoordinate.directions.length; index++) {
        final second = coordinate + GridCoordinate.directions[index];
        final third =
            coordinate +
            GridCoordinate.directions[(index + 1) %
                GridCoordinate.directions.length];
        if (coordinateSet.contains(second) && coordinateSet.contains(third)) {
          final triangle = TriangleCell(coordinate, second, third);
          trianglesById[triangle.id] = triangle;
        }
      }
    }

    final bandMovesById = SplayTreeMap<String, BandMove>();
    for (final coordinate in coordinates) {
      for (final direction in GridCoordinate.canonicalAxes) {
        final candidatePegs = List<GridCoordinate>.generate(
          4,
          (index) => coordinate + direction.scale(index),
          growable: false,
        );
        if (candidatePegs.every(coordinateSet.contains)) {
          final move = BandMove.between(
            candidatePegs.first,
            candidatePegs.last,
          );
          bandMovesById[move.id] = move;
        }
      }
    }

    final edgeToTriangles = <UnitEdge, List<TriangleCell>>{
      for (final edge in edgesById.values) edge: [],
    };
    for (final triangle in trianglesById.values) {
      for (final edge in triangle.edges) {
        edgeToTriangles[edge]!.add(triangle);
      }
    }

    final pegToMoves = <GridCoordinate, List<BandMove>>{
      for (final coordinate in coordinates) coordinate: [],
    };
    for (final move in bandMovesById.values) {
      for (final coordinate in move.pegs) {
        pegToMoves[coordinate]!.add(move);
      }
    }

    return BoardDefinition._(
      size: size,
      pegs: pegs,
      unitEdges: edgesById.values.toList(),
      triangles: trianglesById.values.toList(),
      bandMoves: bandMovesById.values.toList(),
      trianglesByEdge: edgeToTriangles,
      movesByPeg: pegToMoves,
    );
  }

  static List<GridCoordinate> _generateCoordinates(int radius) {
    final result = <GridCoordinate>[];
    for (var q = -radius; q <= radius; q++) {
      final minimumR = math.max(-radius, -q - radius);
      final maximumR = math.min(radius, -q + radius);
      for (var r = minimumR; r <= maximumR; r++) {
        result.add(GridCoordinate(q, r));
      }
    }
    result.sort();
    return result;
  }
}
