import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/models/captured_triangle.dart';
import 'package:trigrid/core/game/models/game_settings.dart';
import 'package:trigrid/core/game/models/match_result.dart';
import 'package:trigrid/core/game/models/placed_band.dart';
import 'package:trigrid/core/game/models/player_state.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

class GameState {
  factory GameState({
    required GameSettings settings,
    required List<PlayerState> players,
    required int currentPlayerIndex,
    required List<PlacedBand> placedBands,
    required Set<UnitEdge> occupiedEdges,
    required Map<String, CapturedTriangle> capturedTriangles,
    required Set<String> processedActionIds,
    required int revision,
    MatchResult? matchResult,
  }) {
    if (players.length != settings.players.length) {
      throw ArgumentError('State players must match settings players.');
    }
    if (currentPlayerIndex < 0 || currentPlayerIndex >= players.length) {
      throw RangeError.index(currentPlayerIndex, players);
    }
    if (revision < 0) {
      throw RangeError.value(revision, 'revision');
    }
    final immutablePlacedBands = List<PlacedBand>.unmodifiable(placedBands);
    return GameState._(
      settings: settings,
      players: List<PlayerState>.unmodifiable(players),
      currentPlayerIndex: currentPlayerIndex,
      placedBands: immutablePlacedBands,
      occupiedEdges: Set<UnitEdge>.unmodifiable(occupiedEdges),
      capturedTriangles: Map<String, CapturedTriangle>.unmodifiable(
        capturedTriangles,
      ),
      processedActionIds: Set<String>.unmodifiable(processedActionIds),
      revision: revision,
      matchResult: matchResult,
      networkPegs: Set<GridCoordinate>.unmodifiable(
        immutablePlacedBands.expand((band) => band.move.pegs),
      ),
      placedBandIds: Set<String>.unmodifiable(
        immutablePlacedBands.map((band) => band.move.id),
      ),
    );
  }

  const GameState._({
    required this.settings,
    required this.players,
    required this.currentPlayerIndex,
    required this.placedBands,
    required this.occupiedEdges,
    required this.capturedTriangles,
    required this.processedActionIds,
    required this.revision,
    required this.matchResult,
    required this.networkPegs,
    required this.placedBandIds,
  });

  factory GameState.initial(GameSettings settings) {
    final supplies = SupplyPolicy.forMatch(
      boardSize: settings.boardSize,
      playerCount: settings.players.length,
      ruleset: settings.ruleset,
      rulesVersion: settings.rulesVersion,
    );
    return GameState(
      settings: settings,
      players: [
        for (var index = 0; index < settings.players.length; index++)
          PlayerState.initial(
            configuration: settings.players[index],
            seatIndex: index,
            supplies: supplies,
          ),
      ],
      currentPlayerIndex: settings.startingPlayerIndex,
      placedBands: const [],
      occupiedEdges: const {},
      capturedTriangles: const {},
      processedActionIds: const {},
      revision: 0,
    );
  }

  factory GameState.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unsupported GameState schema version $schemaVersion.',
      );
    }
    final captures = (json['capturedTriangles']! as List<Object?>)
        .map((item) => CapturedTriangle.fromJson(item! as Map<String, Object?>))
        .toList();
    final matchResultJson = json['matchResult'];
    return GameState(
      settings: GameSettings.fromJson(
        json['settings']! as Map<String, Object?>,
      ),
      players: (json['players']! as List<Object?>)
          .map((item) => PlayerState.fromJson(item! as Map<String, Object?>))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex']! as int,
      placedBands: (json['placedBands']! as List<Object?>)
          .map((item) => PlacedBand.fromJson(item! as Map<String, Object?>))
          .toList(),
      occupiedEdges: (json['occupiedEdges']! as List<Object?>)
          .map((item) => UnitEdge.fromJson(item! as Map<String, Object?>))
          .toSet(),
      capturedTriangles: {
        for (final capture in captures) capture.triangleId: capture,
      },
      processedActionIds: (json['processedActionIds']! as List<Object?>)
          .cast<String>()
          .toSet(),
      revision: json['revision']! as int,
      matchResult: matchResultJson == null
          ? null
          : MatchResult.fromJson(matchResultJson as Map<String, Object?>),
    );
  }

  static const currentSchemaVersion = 1;

  final GameSettings settings;
  final List<PlayerState> players;
  final int currentPlayerIndex;
  final List<PlacedBand> placedBands;
  final Set<UnitEdge> occupiedEdges;
  final Map<String, CapturedTriangle> capturedTriangles;
  final Set<String> processedActionIds;
  final int revision;
  final MatchResult? matchResult;
  final Set<GridCoordinate> networkPegs;
  final Set<String> placedBandIds;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  bool get isGameOver => matchResult != null;

  GameState copyWith({
    List<PlayerState>? players,
    int? currentPlayerIndex,
    List<PlacedBand>? placedBands,
    Set<UnitEdge>? occupiedEdges,
    Map<String, CapturedTriangle>? capturedTriangles,
    Set<String>? processedActionIds,
    int? revision,
    MatchResult? matchResult,
  }) {
    return GameState(
      settings: settings,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      placedBands: placedBands ?? this.placedBands,
      occupiedEdges: occupiedEdges ?? this.occupiedEdges,
      capturedTriangles: capturedTriangles ?? this.capturedTriangles,
      processedActionIds: processedActionIds ?? this.processedActionIds,
      revision: revision ?? this.revision,
      matchResult: matchResult ?? this.matchResult,
    );
  }

  Map<String, Object?> toJson() {
    final sortedEdges = occupiedEdges.toList()..sort();
    final sortedCaptures = capturedTriangles.values.toList()..sort();
    final sortedActionIds = processedActionIds.toList()..sort();
    return {
      'schemaVersion': currentSchemaVersion,
      'settings': settings.toJson(),
      'players': players.map((player) => player.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'placedBands': placedBands.map((band) => band.toJson()).toList(),
      'occupiedEdges': sortedEdges.map((edge) => edge.toJson()).toList(),
      'capturedTriangles': sortedCaptures
          .map((capture) => capture.toJson())
          .toList(),
      'processedActionIds': sortedActionIds,
      'revision': revision,
      'matchResult': matchResult?.toJson(),
    };
  }
}
