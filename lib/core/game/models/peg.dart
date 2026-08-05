import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';

class Peg implements Comparable<Peg> {
  const Peg(this.coordinate);

  factory Peg.fromJson(Map<String, Object?> json) {
    return Peg(
      GridCoordinate.fromJson(json['coordinate']! as Map<String, Object?>),
    );
  }

  final GridCoordinate coordinate;

  String get id => 'p:${coordinate.id}';

  Map<String, Object> toJson() => {'coordinate': coordinate.toJson()};

  @override
  int compareTo(Peg other) => coordinate.compareTo(other.coordinate);

  @override
  bool operator ==(Object other) {
    return other is Peg && other.coordinate == coordinate;
  }

  @override
  int get hashCode => coordinate.hashCode;
}
