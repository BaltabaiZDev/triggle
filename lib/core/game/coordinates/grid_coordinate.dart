import 'dart:math' as math;

class CubeCoordinate {
  const CubeCoordinate(this.x, this.y, this.z)
    : assert(x + y + z == 0, 'Cube coordinates must sum to zero.');

  final int x;
  final int y;
  final int z;

  Map<String, int> toJson() => {'x': x, 'y': y, 'z': z};

  @override
  bool operator ==(Object other) {
    return other is CubeCoordinate &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);
}

class GridCoordinate implements Comparable<GridCoordinate> {
  const GridCoordinate(this.q, this.r);

  factory GridCoordinate.fromCube(CubeCoordinate cube) {
    return GridCoordinate(cube.x, cube.z);
  }

  factory GridCoordinate.fromJson(Map<String, Object?> json) {
    return GridCoordinate(json['q'] as int, json['r'] as int);
  }

  static const directions = <GridCoordinate>[
    GridCoordinate(1, 0),
    GridCoordinate(1, -1),
    GridCoordinate(0, -1),
    GridCoordinate(-1, 0),
    GridCoordinate(-1, 1),
    GridCoordinate(0, 1),
  ];

  static const canonicalAxes = <GridCoordinate>[
    GridCoordinate(1, 0),
    GridCoordinate(0, 1),
    GridCoordinate(1, -1),
  ];

  final int q;
  final int r;

  int get s => -q - r;

  String get id => '$q,$r';

  CubeCoordinate toCube() => CubeCoordinate(q, s, r);

  GridCoordinate operator +(GridCoordinate other) {
    return GridCoordinate(q + other.q, r + other.r);
  }

  GridCoordinate operator -(GridCoordinate other) {
    return GridCoordinate(q - other.q, r - other.r);
  }

  GridCoordinate scale(int factor) => GridCoordinate(q * factor, r * factor);

  int distanceTo(GridCoordinate other) {
    final difference = this - other;
    return math.max(
      difference.q.abs(),
      math.max(difference.r.abs(), difference.s.abs()),
    );
  }

  bool isAdjacentTo(GridCoordinate other) => distanceTo(other) == 1;

  bool isAlignedWith(GridCoordinate other) {
    final difference = other - this;
    return difference.q == 0 ||
        difference.r == 0 ||
        difference.q + difference.r == 0;
  }

  GridCoordinate? unitDirectionTo(GridCoordinate other) {
    if (this == other || !isAlignedWith(other)) {
      return null;
    }
    final difference = other - this;
    final distance = distanceTo(other);
    return GridCoordinate(difference.q ~/ distance, difference.r ~/ distance);
  }

  Map<String, int> toJson() => {'q': q, 'r': r};

  @override
  int compareTo(GridCoordinate other) {
    final qComparison = q.compareTo(other.q);
    return qComparison != 0 ? qComparison : r.compareTo(other.r);
  }

  @override
  bool operator ==(Object other) {
    return other is GridCoordinate && other.q == q && other.r == r;
  }

  @override
  int get hashCode => Object.hash(q, r);

  @override
  String toString() => 'GridCoordinate($q, $r)';
}
