import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';

class UnitEdge implements Comparable<UnitEdge> {
  factory UnitEdge(GridCoordinate first, GridCoordinate second) {
    if (!first.isAdjacentTo(second)) {
      throw ArgumentError('A unit edge must connect adjacent pegs.');
    }
    return first.compareTo(second) <= 0
        ? UnitEdge._(first, second)
        : UnitEdge._(second, first);
  }

  const UnitEdge._(this.a, this.b);

  factory UnitEdge.fromJson(Map<String, Object?> json) {
    return UnitEdge(
      GridCoordinate.fromJson(json['a']! as Map<String, Object?>),
      GridCoordinate.fromJson(json['b']! as Map<String, Object?>),
    );
  }

  final GridCoordinate a;
  final GridCoordinate b;

  String get id => 'e:${a.id}|${b.id}';

  bool touches(GridCoordinate coordinate) {
    return a == coordinate || b == coordinate;
  }

  Map<String, Object> toJson() => {'a': a.toJson(), 'b': b.toJson()};

  @override
  int compareTo(UnitEdge other) {
    final firstComparison = a.compareTo(other.a);
    return firstComparison != 0 ? firstComparison : b.compareTo(other.b);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitEdge && other.a == a && other.b == b;
  }

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => id;
}
