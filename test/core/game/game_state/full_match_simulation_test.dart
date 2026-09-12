import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/game_state/game_engine.dart';
import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/models/board_size.dart';
import 'package:trigrid/core/game/models/game_action.dart';
import 'package:trigrid/core/game/models/game_settings.dart';
import 'package:trigrid/core/game/models/player_state.dart';
import 'package:trigrid/core/game/replay/game_state_hasher.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

void main() {
  group('complete deterministic matches', () {
    for (final playerCount in [2, 3, 4]) {
      test('Classic supports $playerCount players from start to result', () {
        _playCompleteMatch(
          boardSize: BoardSize.fromPreset(BoardSizePreset.classic),
          ruleset: Ruleset.classic,
          playerCount: playerCount,
        );
      });
    }

    for (
      var radius = BoardSize.minimumRadius;
      radius <= BoardSize.maximumRadius;
      radius++
    ) {
      test('Custom radius $radius completes independently of seats', () {
        _playCompleteMatch(
          boardSize: BoardSize.fromPreset(
            BoardSizePreset.custom,
            customRadius: radius,
          ),
          ruleset: Ruleset.custom,
          playerCount: radius > 2 && radius.isEven ? 4 : 2,
        );
      });
    }
  });
}

void _playCompleteMatch({
  required BoardSize boardSize,
  required Ruleset ruleset,
  required int playerCount,
}) {
  final settings = GameSettings(
    matchId: 'simulation-r${boardSize.radius}-p$playerCount',
    boardSize: boardSize,
    ruleset: ruleset,
    players: [
      for (var index = 0; index < playerCount; index++)
        PlayerConfiguration(
          id: 'player-$index',
          displayName: 'Player ${index + 1}',
          controllerType: PlayerControllerType.bot,
        ),
    ],
    seed: 8675309,
  );
  final engine = GameEngine(settings);
  var state = engine.createInitialState(settings);
  final maximumTurns = state.players.fold<int>(
    0,
    (total, player) => total + player.bandsRemaining,
  );
  final stateHashes = <String>{GameStateHasher.hash(state)};

  while (!state.isGameOver) {
    final legalMoves = engine.validator.legalMoves(state);
    expect(
      legalMoves,
      isNotEmpty,
      reason: 'A non-terminal state must offer a legal move.',
    );
    final move = legalMoves.first;
    final action = SubmitMoveAction(
      actionId: 'action-${state.revision}',
      playerId: state.currentPlayer.id,
      expectedRevision: state.revision,
      start: move.start,
      end: move.end,
    );
    final previousRevision = state.revision;
    final transition = engine.submitMove(state, action);

    expect(transition.wasAccepted, isTrue);
    state = transition.state;
    expect(state.revision, previousRevision + 1);
    expect(state.revision, lessThanOrEqualTo(maximumTurns));
    _expectStateInvariants(state, engine);
    expect(
      stateHashes.add(GameStateHasher.hash(state)),
      isTrue,
      reason: 'Every accepted revision must have a distinct state hash.',
    );
  }

  expect(state.matchResult, isNotNull);
  expect(state.matchResult!.finalRevision, state.revision);
  expect(state.matchResult!.winnerPlayerIds, isNotEmpty);
  expect(
    state.matchResult!.scores.values.reduce((a, b) => a > b ? a : b),
    state.players
        .where(
          (player) => state.matchResult!.winnerPlayerIds.contains(player.id),
        )
        .first
        .score,
  );
}

void _expectStateInvariants(GameState state, GameEngine engine) {
  expect(state.placedBands, hasLength(state.revision));
  expect(state.processedActionIds, hasLength(state.revision));
  expect(
    state.placedBands.map((band) => band.move.id).toSet(),
    hasLength(state.placedBands.length),
  );
  expect(
    state.placedBands.expand((band) => band.move.edges).toSet(),
    state.occupiedEdges,
  );
  expect(
    state.players.fold<int>(0, (total, player) => total + player.score),
    state.capturedTriangles.length,
  );
  for (final player in state.players) {
    expect(player.score, greaterThanOrEqualTo(0));
    expect(player.bandsRemaining, greaterThanOrEqualTo(0));
    expect(player.markersRemaining, greaterThanOrEqualTo(0));
  }
  for (final capture in state.capturedTriangles.values) {
    final triangle = engine.board.triangleById[capture.triangleId];
    expect(triangle, isNotNull);
    expect(triangle!.edges.every(state.occupiedEdges.contains), isTrue);
    expect(
      state.players.map((player) => player.id),
      contains(capture.playerId),
    );
  }
}
