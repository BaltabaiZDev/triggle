import 'package:trigrid/core/game/trigrid_engine.dart';

class BotLevelRecord {
  const BotLevelRecord({required this.matches, required this.wins});

  factory BotLevelRecord.fromJson(Map<String, Object?> json) {
    return BotLevelRecord(
      matches: json['matches']! as int,
      wins: json['wins']! as int,
    );
  }

  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;

  BotLevelRecord add({required bool won}) {
    return BotLevelRecord(matches: matches + 1, wins: wins + (won ? 1 : 0));
  }

  Map<String, Object> toJson() => {'matches': matches, 'wins': wins};
}

class ModeStatistics {
  const ModeStatistics({
    required this.matchesPlayed,
    required this.wins,
    required this.capturedTriangles,
    required this.largestMultiCapture,
    required this.totalScore,
    required this.botLevelRecords,
  });

  factory ModeStatistics.empty() => const ModeStatistics(
    matchesPlayed: 0,
    wins: 0,
    capturedTriangles: 0,
    largestMultiCapture: 0,
    totalScore: 0,
    botLevelRecords: {},
  );

  factory ModeStatistics.fromJson(Map<String, Object?> json) {
    final recordsJson =
        json['botLevelRecords'] as Map<String, Object?>? ?? const {};
    return ModeStatistics(
      matchesPlayed: json['matchesPlayed']! as int,
      wins: json['wins']! as int,
      capturedTriangles: json['capturedTriangles']! as int,
      largestMultiCapture: json['largestMultiCapture']! as int,
      totalScore: json['totalScore']! as int,
      botLevelRecords: {
        for (final entry in recordsJson.entries)
          BotDifficulty.values.byName(entry.key): BotLevelRecord.fromJson(
            entry.value! as Map<String, Object?>,
          ),
      },
    );
  }

  final int matchesPlayed;
  final int wins;
  final int capturedTriangles;
  final int largestMultiCapture;
  final int totalScore;
  final Map<BotDifficulty, BotLevelRecord> botLevelRecords;

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;

  double get averageScore =>
      matchesPlayed == 0 ? 0 : totalScore / matchesPlayed;

  ModeStatistics record({
    required GameState state,
    required String perspectivePlayerId,
    required int matchLargestMultiCapture,
  }) {
    final player = state.players.firstWhere(
      (candidate) => candidate.id == perspectivePlayerId,
      orElse: () => state.players.first,
    );
    final winners = state.matchResult?.winnerPlayerIds ?? const <String>[];
    final won = winners.length == 1 && winners.contains(player.id);
    final botDifficulties = state.players
        .where(
          (candidate) => candidate.controllerType == PlayerControllerType.bot,
        )
        .map((candidate) => candidate.botSettings!.difficulty)
        .toSet();
    final nextRecords = Map<BotDifficulty, BotLevelRecord>.of(botLevelRecords);
    for (final difficulty in botDifficulties) {
      nextRecords[difficulty] =
          (nextRecords[difficulty] ?? const BotLevelRecord(matches: 0, wins: 0))
              .add(won: won);
    }
    return ModeStatistics(
      matchesPlayed: matchesPlayed + 1,
      wins: wins + (won ? 1 : 0),
      capturedTriangles: capturedTriangles + player.score,
      largestMultiCapture: matchLargestMultiCapture > largestMultiCapture
          ? matchLargestMultiCapture
          : largestMultiCapture,
      totalScore: totalScore + player.score,
      botLevelRecords: Map.unmodifiable(nextRecords),
    );
  }

  Map<String, Object> toJson() => {
    'matchesPlayed': matchesPlayed,
    'wins': wins,
    'capturedTriangles': capturedTriangles,
    'largestMultiCapture': largestMultiCapture,
    'totalScore': totalScore,
    'botLevelRecords': {
      for (final entry in botLevelRecords.entries)
        entry.key.name: entry.value.toJson(),
    },
  };
}

class MatchStatistics {
  const MatchStatistics({required this.local, required this.lan});

  factory MatchStatistics.empty() => MatchStatistics(
    local: ModeStatistics.empty(),
    lan: ModeStatistics.empty(),
  );

  factory MatchStatistics.fromJson(Map<String, Object?> json) {
    return MatchStatistics(
      local: ModeStatistics.fromJson(json['local']! as Map<String, Object?>),
      lan: ModeStatistics.fromJson(json['lan']! as Map<String, Object?>),
    );
  }

  final ModeStatistics local;
  final ModeStatistics lan;

  MatchStatistics copyWith({ModeStatistics? local, ModeStatistics? lan}) {
    return MatchStatistics(local: local ?? this.local, lan: lan ?? this.lan);
  }

  Map<String, Object> toJson() => {
    'local': local.toJson(),
    'lan': lan.toJson(),
  };
}
