import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';

enum TriangleOrientation { up, down }

class TriangleCell implements Comparable<TriangleCell> {
  factory TriangleCell(
    GridCoordinate first,
    GridCoordinate second,
    GridCoordinate third,
  ) {
    final vertices = [first, second, third]..sort();
    if (vertices.toSet().length != 3 ||
        !vertices[0].isAdjacentTo(vertices[1]) ||
        !vertices[1].isAdjacentTo(vertices[2]) ||
        !vertices[0].isAdjacentTo(vertices[2])) {
      throw ArgumentError(
        'A unit triangle requires three distinct, pairwise-adjacent pegs.',
      );
    }
    return TriangleCell._(List.unmodifiable(vertices));
  }

  const TriangleCell._(this.vertices);

  factory TriangleCell.fromJson(Map<String, Object?> json) {
    final verticesJson = json['vertices']! as List<Object?>;
    return TriangleCell(
      GridCoordinate.fromJson(verticesJson[0]! as Map<String, Object?>),
      GridCoordinate.fromJson(verticesJson[1]! as Map<String, Object?>),
      GridCoordinate.fromJson(verticesJson[2]! as Map<String, Object?>),
    );
  }

  final List<GridCoordinate> vertices;

  String get id => 't:${vertices.map((vertex) => vertex.id).join('|')}';

  TriangleOrientation get orientation {
    final sums = vertices.map((vertex) => vertex.q + vertex.r).toList();
    final minimum = sums.reduce((a, b) => a < b ? a : b);
    final minimumCount = sums.where((value) => value == minimum).length;
    return minimumCount == 1
        ? TriangleOrientation.up
        : TriangleOrientation.down;
  }

  List<UnitEdge> get edges {
    final result = [
      UnitEdge(vertices[0], vertices[1]),
      UnitEdge(vertices[1], vertices[2]),
      UnitEdge(vertices[0], vertices[2]),
    ]..sort();
    return List.unmodifiable(result);
  }

  Map<String, Object> toJson() => {
    'vertices': vertices.map((vertex) => vertex.toJson()).toList(),
  };

  @override
  int compareTo(TriangleCell other) => id.compareTo(other.id);

  @override
  bool operator ==(Object other) {
    return other is TriangleCell && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
