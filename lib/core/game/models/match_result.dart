enum MatchEndReason { markerLimit, bandsExhausted, noLegalMoves }

class MatchResult {
  MatchResult({
    required this.reason,
    required List<String> winnerPlayerIds,
    required Map<String, int> scores,
    required this.finalRevision,
  }) : winnerPlayerIds = List<String>.unmodifiable(
         [...winnerPlayerIds]..sort(),
       ),
       scores = Map<String, int>.unmodifiable(scores);

  factory MatchResult.fromJson(Map<String, Object?> json) {
    return MatchResult(
      reason: MatchEndReason.values.byName(json['reason']! as String),
      winnerPlayerIds: (json['winnerPlayerIds']! as List<Object?>)
          .cast<String>(),
      scores: (json['scores']! as Map<String, Object?>).map(
        (key, value) => MapEntry(key, value! as int),
      ),
      finalRevision: json['finalRevision']! as int,
    );
  }

  final MatchEndReason reason;
  final List<String> winnerPlayerIds;
  final Map<String, int> scores;
  final int finalRevision;

  bool get isTie => winnerPlayerIds.length > 1;

  Map<String, Object> toJson() {
    final sortedScoreEntries = scores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      'reason': reason.name,
      'winnerPlayerIds': winnerPlayerIds,
      'scores': {
        for (final entry in sortedScoreEntries) entry.key: entry.value,
      },
      'finalRevision': finalRevision,
    };
  }
}
