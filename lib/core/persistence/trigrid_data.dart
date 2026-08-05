import 'package:trigrid/core/persistence/models/app_preferences.dart';
import 'package:trigrid/core/persistence/models/match_statistics.dart';
import 'package:trigrid/core/persistence/models/saved_game.dart';

class TriGridData {
  factory TriGridData({
    required AppPreferences preferences,
    required SavedMatchSnapshot? localSnapshot,
    required List<SavedReplayEntry> replays,
    required List<SavedLanSnapshot> lanSnapshots,
    required MatchStatistics statistics,
    required Set<String> completedMatchIds,
  }) {
    return TriGridData._(
      preferences: preferences,
      localSnapshot: localSnapshot,
      replays: List<SavedReplayEntry>.unmodifiable(replays),
      lanSnapshots: List<SavedLanSnapshot>.unmodifiable(lanSnapshots),
      statistics: statistics,
      completedMatchIds: Set<String>.unmodifiable(completedMatchIds),
    );
  }

  const TriGridData._({
    required this.preferences,
    required this.localSnapshot,
    required this.replays,
    required this.lanSnapshots,
    required this.statistics,
    required this.completedMatchIds,
  });

  factory TriGridData.defaults() => TriGridData(
    preferences: AppPreferences.defaults(),
    localSnapshot: null,
    replays: const [],
    lanSnapshots: const [],
    statistics: MatchStatistics.empty(),
    completedMatchIds: const {},
  );

  factory TriGridData.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported TriGrid persistence schema $schemaVersion.',
      );
    }
    return TriGridData(
      preferences: AppPreferences.fromJson(
        json['preferences']! as Map<String, Object?>,
      ),
      localSnapshot: json['localSnapshot'] == null
          ? null
          : SavedMatchSnapshot.fromJson(
              json['localSnapshot']! as Map<String, Object?>,
            ),
      replays: (json['replays']! as List<Object?>)
          .map(
            (item) => SavedReplayEntry.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      lanSnapshots: (json['lanSnapshots'] as List<Object?>? ?? const [])
          .map(
            (item) => SavedLanSnapshot.fromJson(item! as Map<String, Object?>),
          )
          .toList(),
      statistics: MatchStatistics.fromJson(
        json['statistics']! as Map<String, Object?>,
      ),
      completedMatchIds: (json['completedMatchIds']! as List<Object?>)
          .cast<String>()
          .toSet(),
    );
  }

  static const currentSchemaVersion = 1;

  final AppPreferences preferences;
  final SavedMatchSnapshot? localSnapshot;
  final List<SavedReplayEntry> replays;
  final List<SavedLanSnapshot> lanSnapshots;
  final MatchStatistics statistics;
  final Set<String> completedMatchIds;

  TriGridData copyWith({
    AppPreferences? preferences,
    SavedMatchSnapshot? localSnapshot,
    bool clearLocalSnapshot = false,
    List<SavedReplayEntry>? replays,
    List<SavedLanSnapshot>? lanSnapshots,
    MatchStatistics? statistics,
    Set<String>? completedMatchIds,
  }) {
    return TriGridData(
      preferences: preferences ?? this.preferences,
      localSnapshot: clearLocalSnapshot
          ? null
          : (localSnapshot ?? this.localSnapshot),
      replays: replays ?? this.replays,
      lanSnapshots: lanSnapshots ?? this.lanSnapshots,
      statistics: statistics ?? this.statistics,
      completedMatchIds: completedMatchIds ?? this.completedMatchIds,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'preferences': preferences.toJson(),
    'localSnapshot': localSnapshot?.toJson(),
    'replays': replays.map((replay) => replay.toJson()).toList(),
    'lanSnapshots': lanSnapshots.map((snapshot) => snapshot.toJson()).toList(),
    'statistics': statistics.toJson(),
    'completedMatchIds': completedMatchIds.toList()..sort(),
  };
}
