import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';

class BandMove implements Comparable<BandMove> {
  factory BandMove.between(
    GridCoordinate firstEndpoint,
    GridCoordinate secondEndpoint,
  ) {
    if (!firstEndpoint.isAlignedWith(secondEndpoint) ||
        firstEndpoint.distanceTo(secondEndpoint) != 3) {
      throw ArgumentError(
        'A band must span exactly four consecutive aligned pegs.',
      );
    }

    final start = firstEndpoint.compareTo(secondEndpoint) <= 0
        ? firstEndpoint
        : secondEndpoint;
    final end = start == firstEndpoint ? secondEndpoint : firstEndpoint;
    final direction = start.unitDirectionTo(end)!;
    final pegs = List<GridCoordinate>.generate(
      4,
      (index) => start + direction.scale(index),
      growable: false,
    );
    final edges = List<UnitEdge>.generate(
      3,
      (index) => UnitEdge(pegs[index], pegs[index + 1]),
      growable: false,
    );
    return BandMove._(
      start: start,
      end: end,
      pegs: List.unmodifiable(pegs),
      edges: List.unmodifiable(edges),
    );
  }

  const BandMove._({
    required this.start,
    required this.end,
    required this.pegs,
    required this.edges,
  });

  factory BandMove.fromJson(Map<String, Object?> json) {
    return BandMove.between(
      GridCoordinate.fromJson(json['start']! as Map<String, Object?>),
      GridCoordinate.fromJson(json['end']! as Map<String, Object?>),
    );
  }

  final GridCoordinate start;
  final GridCoordinate end;
  final List<GridCoordinate> pegs;
  final List<UnitEdge> edges;

  String get id => idFor(start, end);

  static String idFor(GridCoordinate first, GridCoordinate second) {
    final start = first.compareTo(second) <= 0 ? first : second;
    final end = start == first ? second : first;
    return 'b:${start.id}|${end.id}';
  }

  bool containsPeg(GridCoordinate coordinate) => pegs.contains(coordinate);

  Map<String, Object> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };

  @override
  int compareTo(BandMove other) => id.compareTo(other.id);

  @override
  bool operator ==(Object other) => other is BandMove && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
