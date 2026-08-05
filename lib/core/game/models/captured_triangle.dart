class CapturedTriangle implements Comparable<CapturedTriangle> {
  const CapturedTriangle({
    required this.triangleId,
    required this.playerId,
    required this.actionId,
  });

  factory CapturedTriangle.fromJson(Map<String, Object?> json) {
    return CapturedTriangle(
      triangleId: json['triangleId']! as String,
      playerId: json['playerId']! as String,
      actionId: json['actionId']! as String,
    );
  }

  final String triangleId;
  final String playerId;
  final String actionId;

  Map<String, Object> toJson() => {
    'triangleId': triangleId,
    'playerId': playerId,
    'actionId': actionId,
  };

  @override
  int compareTo(CapturedTriangle other) {
    return triangleId.compareTo(other.triangleId);
  }
}
