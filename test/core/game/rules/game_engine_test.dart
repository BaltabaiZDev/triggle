import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/coordinates/grid_coordinate.dart';
import 'package:trigrid/core/game/game_state/game_engine.dart';
import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/geometry/board_definition.dart';
import 'package:trigrid/core/game/models/band_move.dart';
import 'package:trigrid/core/game/models/board_size.dart';
import 'package:trigrid/core/game/models/captured_triangle.dart';
import 'package:trigrid/core/game/models/game_action.dart';
import 'package:trigrid/core/game/models/game_settings.dart';
import 'package:trigrid/core/game/models/match_result.dart';
import 'package:trigrid/core/game/models/placed_band.dart';
import 'package:trigrid/core/game/models/player_state.dart';
import 'package:trigrid/core/game/models/triangle_cell.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';
import 'package:trigrid/core/game/replay/game_replay.dart';
import 'package:trigrid/core/game/replay/game_state_hasher.dart';
import 'package:trigrid/core/game/rules/move_validation_result.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

void main() {
  group('MoveValidator', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness(playerCount: 2);
    });

    test('accepts an arbitrary legal first move', () {
      final move = harness.board.bandMoves[17];
      final result = harness.engine.validator.validate(
        harness.initialState,
        harness.action(harness.initialState, move, 'first'),
      );

      expect(result.isValid, isTrue);
      expect(result.errorCode, isNull);
      expect(result.affectedEdges, hasLength(3));
      expect(result.move, move);
    });

    test('requires later moves to connect to the existing network', () {
      final firstMove = harness.board.bandMoves.first;
      final afterFirst = harness.play(harness.initialState, firstMove, 'first');
      final disconnected = harness.board.bandMoves.firstWhere(
        (move) =>
            move.id != firstMove.id && !move.pegs.any(firstMove.pegs.contains),
      );

      final result = harness.engine.validator.validate(
        afterFirst,
        harness.action(afterFirst, disconnected, 'disconnected'),
      );

      expect(result.errorCode, MoveValidationErrorCode.notConnected);
    });

    test('rejects an exactly duplicated band in either direction', () {
      final move = harness.board.bandMoves.first;
      final afterFirst = harness.play(harness.initialState, move, 'first');
      final action = SubmitMoveAction(
        actionId: 'duplicate-band',
        playerId: afterFirst.currentPlayer.id,
        expectedRevision: afterFirst.revision,
        start: move.end,
        end: move.start,
      );

      final result = harness.engine.validator.validate(afterFirst, action);

      expect(result.errorCode, MoveValidationErrorCode.duplicateBand);
    });

    test('allows partial overlap when at least one edge is new', () {
      final firstMove = harness.board.bandMoves.first;
      final afterFirst = harness.play(harness.initialState, firstMove, 'first');
      final partialOverlap = harness.board.bandMoves.firstWhere(
        (move) =>
            move.id != firstMove.id &&
            move.edges.any(firstMove.edges.contains) &&
            move.edges.any((edge) => !firstMove.edges.contains(edge)),
      );

      final result = harness.engine.validator.validate(
        afterFirst,
        harness.action(afterFirst, partialOverlap, 'overlap'),
      );

      expect(result.isValid, isTrue);
    });

    test('rejects a new band template that adds no unit edge', () {
      MoveValidationResult? result;
      for (final target in harness.board.bandMoves) {
        final setupMoves = <BandMove>[];
        var canCover = true;
        for (final edge in target.edges) {
          final alternatives = harness.board.bandMoves.where(
            (move) => move.id != target.id && move.edges.contains(edge),
          );
          if (alternatives.isEmpty) {
            canCover = false;
            break;
          }
          setupMoves.add(alternatives.first);
        }
        if (!canCover) {
          continue;
        }
        final state = _stateWithSetupMoves(harness, setupMoves);
        result = harness.engine.validator.validate(
          state,
          harness.action(state, target, 'no-new-edge'),
        );
        if (result.errorCode == MoveValidationErrorCode.addsNoEdge) {
          break;
        }
      }

      expect(result?.errorCode, MoveValidationErrorCode.addsNoEdge);
    });

    test('rejects a move when the current player has no bands', () {
      final state = harness.initialState.copyWith(
        players: [
          harness.initialState.players[0].copyWith(bandsRemaining: 0),
          harness.initialState.players[1],
        ],
      );

      final result = harness.engine.validator.validate(
        state,
        harness.action(state, harness.board.bandMoves.first, 'no-bands'),
      );

      expect(result.errorCode, MoveValidationErrorCode.noBandsRemaining);
    });

    test('rejects wrong-turn, stale, malformed, and duplicate actions', () {
      final move = harness.board.bandMoves.first;
      final initial = harness.initialState;

      expect(
        harness.engine.validator
            .validate(
              initial,
              SubmitMoveAction(
                actionId: 'wrong-turn',
                playerId: initial.players[1].id,
                expectedRevision: 0,
                start: move.start,
                end: move.end,
              ),
            )
            .errorCode,
        MoveValidationErrorCode.notPlayersTurn,
      );
      expect(
        harness.engine.validator
            .validate(
              initial,
              SubmitMoveAction(
                actionId: 'stale',
                playerId: initial.currentPlayer.id,
                expectedRevision: 1,
                start: move.start,
                end: move.end,
              ),
            )
            .errorCode,
        MoveValidationErrorCode.staleRevision,
      );
      expect(
        harness.engine.validator
            .validate(
              initial,
              SubmitMoveAction(
                actionId: 'unknown',
                playerId: initial.currentPlayer.id,
                expectedRevision: 0,
                start: move.start,
                end: const GridCoordinate(99, 99),
              ),
            )
            .errorCode,
        MoveValidationErrorCode.unknownEndpoint,
      );
      expect(
        harness.engine.validator
            .validate(
              initial,
              SubmitMoveAction(
                actionId: 'wrong-axis',
                playerId: initial.currentPlayer.id,
                expectedRevision: 0,
                start: const GridCoordinate(0, 0),
                end: const GridCoordinate(1, 1),
              ),
            )
            .errorCode,
        MoveValidationErrorCode.wrongAxis,
      );
      expect(
        harness.engine.validator
            .validate(
              initial,
              SubmitMoveAction(
                actionId: 'wrong-length',
                playerId: initial.currentPlayer.id,
                expectedRevision: 0,
                start: const GridCoordinate(0, 0),
                end: const GridCoordinate(2, 0),
              ),
            )
            .errorCode,
        MoveValidationErrorCode.wrongLength,
      );

      final accepted = harness.engine.submitMove(
        initial,
        harness.action(initial, move, 'accepted'),
      );
      final duplicateResult = harness.engine.validator.validate(
        accepted.state,
        SubmitMoveAction(
          actionId: 'accepted',
          playerId: accepted.state.currentPlayer.id,
          expectedRevision: accepted.state.revision,
          start: move.start,
          end: move.end,
        ),
      );
      expect(
        duplicateResult.errorCode,
        MoveValidationErrorCode.duplicateAction,
      );
    });
  });

  group('Capturing and scoring', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness(playerCount: 2);
    });

    test('completes and captures a triangle through affected edges', () {
      final scenario = _findSingleCaptureScenario(harness);
      final validation = harness.engine.validator.validate(
        scenario.state,
        harness.action(scenario.state, scenario.finalMove, 'capture'),
      );

      expect(validation.isValid, isTrue);
      expect(
        validation.newlyCapturedTriangles.map((triangle) => triangle.id),
        contains(scenario.targets.single.id),
      );

      final transition = harness.engine.submitMove(
        scenario.state,
        harness.action(scenario.state, scenario.finalMove, 'capture'),
      );
      final actingPlayer =
          transition.state.players[scenario.state.currentPlayerIndex];

      expect(
        transition
            .state
            .capturedTriangles[scenario.targets.single.id]
            ?.playerId,
        scenario.state.currentPlayer.id,
      );
      expect(actingPlayer.score, validation.newlyCapturedTriangles.length);
      expect(
        actingPlayer.markersRemaining,
        scenario.state.currentPlayer.markersRemaining -
            validation.newlyCapturedTriangles.length,
      );
    });

    test('captures multiple newly completed triangles atomically', () {
      final scenario = _findMultipleCaptureScenario(harness);
      final action = harness.action(
        scenario.state,
        scenario.finalMove,
        'multi-capture',
      );
      final validation = harness.engine.validator.validate(
        scenario.state,
        action,
      );

      expect(validation.isValid, isTrue);
      expect(validation.newlyCapturedTriangles.length, greaterThanOrEqualTo(2));
      expect(
        validation.newlyCapturedTriangles.map((triangle) => triangle.id),
        containsAll(scenario.targets.map((triangle) => triangle.id)),
      );

      final transition = harness.engine.submitMove(scenario.state, action);
      expect(
        transition.state.currentPlayerIndex,
        isNot(scenario.state.currentPlayerIndex),
      );
      expect(
        transition.state.players[scenario.state.currentPlayerIndex].score,
        validation.newlyCapturedTriangles.length,
      );
    });

    test('never changes an already captured triangle owner or score', () {
      final scenario = _findSingleCaptureScenario(harness);
      final target = scenario.targets.single;
      final originalOwner = scenario.state.players[1].id;
      final state = scenario.state.copyWith(
        capturedTriangles: {
          ...scenario.state.capturedTriangles,
          target.id: CapturedTriangle(
            triangleId: target.id,
            playerId: originalOwner,
            actionId: 'earlier-capture',
          ),
        },
      );
      final action = harness.action(state, scenario.finalMove, 'later');
      final validation = harness.engine.validator.validate(state, action);

      expect(
        validation.newlyCapturedTriangles.map((triangle) => triangle.id),
        isNot(contains(target.id)),
      );

      final transition = harness.engine.submitMove(state, action);
      expect(
        transition.state.capturedTriangles[target.id]?.playerId,
        originalOwner,
      );
      expect(
        transition.state.players[state.currentPlayerIndex].score,
        validation.newlyCapturedTriangles.length,
      );
    });
  });

  group('Match ending', () {
    test('ends the two-player variant after both band supplies are used', () {
      final harness = _Harness(playerCount: 2);
      final firstMove = harness.board.bandMoves.first;
      var state = harness.play(harness.initialState, firstMove, 'setup');
      final finalMove = harness.engine.validator
          .legalMoves(state)
          .firstWhere(
            (move) =>
                harness.engine.validator.capturesForMove(state, move).isEmpty,
          );
      state = state.copyWith(
        currentPlayerIndex: 0,
        players: [
          state.players[0].copyWith(score: 3, bandsRemaining: 1),
          state.players[1].copyWith(score: 3, bandsRemaining: 0),
        ],
      );

      final transition = harness.engine.submitMove(
        state,
        harness.action(state, finalMove, 'last-band'),
      );

      expect(transition.state.isGameOver, isTrue);
      expect(
        transition.state.matchResult?.reason,
        MatchEndReason.bandsExhausted,
      );
      expect(transition.state.matchResult?.isTie, isTrue);
      expect(
        transition.state.matchResult?.winnerPlayerIds,
        containsAll(['player-0', 'player-1']),
      );
    });

    test('ends a four-player Classic match at the marker limit', () {
      final harness = _Harness(playerCount: 4);
      final scenario = _findSingleCaptureScenario(harness);
      final players = [...scenario.state.players];
      players[0] = players[0].copyWith(score: 20, markersRemaining: 1);
      final state = scenario.state.copyWith(
        currentPlayerIndex: 0,
        players: players,
      );
      final transition = harness.engine.submitMove(
        state,
        harness.action(state, scenario.finalMove, 'marker-limit'),
      );

      expect(transition.state.isGameOver, isTrue);
      expect(transition.state.matchResult?.reason, MatchEndReason.markerLimit);
      expect(transition.state.matchResult?.winnerPlayerIds, ['player-0']);
      expect(transition.state.players[0].markersRemaining, 0);
    });

    test('rejects further moves after a terminal result', () {
      final harness = _Harness(playerCount: 2);
      final ended = harness.initialState.copyWith(
        matchResult: MatchResult(
          reason: MatchEndReason.noLegalMoves,
          winnerPlayerIds: const ['player-0', 'player-1'],
          scores: const {'player-0': 0, 'player-1': 0},
          finalRevision: 0,
        ),
      );
      final move = harness.board.bandMoves.first;

      final result = harness.engine.validator.validate(
        ended,
        harness.action(ended, move, 'too-late'),
      );

      expect(result.errorCode, MoveValidationErrorCode.gameEnded);
    });

    test('ends when the final unused unit edge removes all legal moves', () {
      final harness = _Harness(playerCount: 2);
      final finalMove = harness.board.bandMoves.first;
      final missingEdge = finalMove.edges.first;
      final connectedSetupMove = harness.board.bandMoves.firstWhere(
        (move) =>
            move.id != finalMove.id && move.pegs.any(finalMove.pegs.contains),
      );
      final state = harness.initialState.copyWith(
        placedBands: [
          PlacedBand(
            move: connectedSetupMove,
            playerId: harness.initialState.players[1].id,
            actionId: 'dense-setup',
          ),
        ],
        occupiedEdges: harness.board.unitEdges
            .where((edge) => edge != missingEdge)
            .toSet(),
        processedActionIds: const {'dense-setup'},
        revision: 1,
      );

      final transition = harness.engine.submitMove(
        state,
        harness.action(state, finalMove, 'last-legal-edge'),
      );

      expect(transition.wasAccepted, isTrue);
      expect(transition.state.matchResult?.reason, MatchEndReason.noLegalMoves);
      expect(harness.engine.validator.legalMoves(transition.state), isEmpty);
    });
  });

  group('Serialization, hashing, and replay', () {
    test('round-trips settings, actions, and non-empty game state', () {
      final harness = _Harness(playerCount: 3);
      final move = harness.board.bandMoves.first;
      final action = harness.action(harness.initialState, move, 'round-trip');
      final state = harness.engine
          .submitMove(harness.initialState, action)
          .state;

      final settingsJson =
          jsonDecode(jsonEncode(harness.settings.toJson()))
              as Map<String, Object?>;
      final actionJson =
          jsonDecode(jsonEncode(action.toJson())) as Map<String, Object?>;
      final stateJson =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, Object?>;

      final restoredSettings = GameSettings.fromJson(settingsJson);
      final restoredAction = GameAction.fromJson(actionJson);
      final restoredState = GameState.fromJson(stateJson);

      expect(restoredSettings.toJson(), harness.settings.toJson());
      expect(restoredAction.toJson(), action.toJson());
      expect(restoredState.toJson(), state.toJson());
      expect(GameStateHasher.hash(restoredState), GameStateHasher.hash(state));
    });

    test('state hashes are stable and change after an accepted action', () {
      final harness = _Harness(playerCount: 2);
      final initialHash = GameStateHasher.hash(harness.initialState);
      final sameHash = GameStateHasher.hash(
        GameState.fromJson(harness.initialState.toJson()),
      );
      final next = harness.play(
        harness.initialState,
        harness.board.bandMoves.first,
        'hash-change',
      );

      expect(sameHash, initialHash);
      expect(GameStateHasher.hash(next), isNot(initialHash));
      expect(GameStateHasher.hash(next), hasLength(64));
    });

    test('optional turn timer survives settings serialization', () {
      final harness = _Harness(playerCount: 2);
      final json = Map<String, Object?>.from(harness.settings.toJson())
        ..['turnTimeSeconds'] = 60;

      final restored = GameSettings.fromJson(json);

      expect(restored.turnTimeSeconds, 60);
      expect(restored.toJson()['turnTimeSeconds'], 60);
    });

    test('state, settings, and generated board collections are immutable', () {
      final harness = _Harness(playerCount: 2);

      expect(
        () => harness.initialState.players.add(
          harness.initialState.players.first,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => harness.initialState.occupiedEdges.add(
          harness.board.unitEdges.first,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => harness.settings.players.add(harness.settings.players.first),
        throwsUnsupportedError,
      );
      expect(
        () => harness.board.bandMoves.add(harness.board.bandMoves.first),
        throwsUnsupportedError,
      );
    });

    test('deterministic replay reproduces revision and final hash', () {
      final harness = _Harness(playerCount: 2);
      var state = harness.initialState;
      final actions = <SubmitMoveAction>[];

      for (var index = 0; index < 8 && !state.isGameOver; index++) {
        final move = harness.engine.validator.legalMoves(state).first;
        final action = harness.action(state, move, 'replay-$index');
        actions.add(action);
        state = harness.engine.submitMove(state, action).state;
      }

      final replay = GameReplay(settings: harness.settings, actions: actions);
      final firstRun = ReplayRunner.run(replay);
      final verifiedReplay = replay.withExpectedFinalHash(firstRun.finalHash);
      final secondRun = ReplayRunner.run(
        GameReplay.fromJson(
          jsonDecode(jsonEncode(verifiedReplay.toJson()))
              as Map<String, Object?>,
        ),
      );

      expect(secondRun.finalState.toJson(), state.toJson());
      expect(secondRun.finalHash, GameStateHasher.hash(state));
      expect(secondRun.finalHash, firstRun.finalHash);
      expect(secondRun.revisionHashes, firstRun.revisionHashes);
    });

    test('replay verification rejects a mismatched final hash', () {
      final harness = _Harness(playerCount: 2);
      final replay = GameReplay(
        settings: harness.settings,
        actions: const [],
        expectedFinalHash: 'not-the-real-hash',
      );

      expect(
        () => ReplayRunner.run(replay),
        throwsA(isA<ReplayVerificationException>()),
      );
    });
  });
}

class _Harness {
  _Harness({required int playerCount})
    : settings = GameSettings(
        matchId: 'test-match-$playerCount',
        boardSize: BoardSize.fromPreset(BoardSizePreset.classic),
        ruleset: Ruleset.classic,
        players: [
          for (var index = 0; index < playerCount; index++)
            PlayerConfiguration(
              id: 'player-$index',
              displayName: 'Player ${index + 1}',
              controllerType: index.isEven
                  ? PlayerControllerType.human
                  : PlayerControllerType.bot,
            ),
        ],
        seed: 12345,
      ) {
    engine = GameEngine(settings);
    board = engine.board;
    initialState = engine.createInitialState(settings);
  }

  final GameSettings settings;
  late final GameEngine engine;
  late final BoardDefinition board;
  late final GameState initialState;

  SubmitMoveAction action(GameState state, BandMove move, String actionId) {
    return SubmitMoveAction(
      actionId: actionId,
      playerId: state.currentPlayer.id,
      expectedRevision: state.revision,
      start: move.start,
      end: move.end,
    );
  }

  GameState play(GameState state, BandMove move, String actionId) {
    final transition = engine.submitMove(state, action(state, move, actionId));
    expect(
      transition.validation.isValid,
      isTrue,
      reason: transition.validation.errorCode?.name,
    );
    return transition.state;
  }
}

class _CaptureScenario {
  const _CaptureScenario({
    required this.state,
    required this.finalMove,
    required this.targets,
  });

  final GameState state;
  final BandMove finalMove;
  final List<TriangleCell> targets;
}

_CaptureScenario _findSingleCaptureScenario(_Harness harness) {
  for (final triangle in harness.board.triangles) {
    for (final missingEdge in triangle.edges) {
      final finalMoves = harness.board.bandMoves.where(
        (move) => move.edges.contains(missingEdge),
      );
      for (final finalMove in finalMoves) {
        final setupMoves = <BandMove>[];
        var canBuild = true;
        for (final requiredEdge in triangle.edges.where(
          (edge) => edge != missingEdge,
        )) {
          final candidates = harness.board.bandMoves.where(
            (move) =>
                move.id != finalMove.id &&
                move.edges.contains(requiredEdge) &&
                !move.edges.contains(missingEdge),
          );
          if (candidates.isEmpty) {
            canBuild = false;
            break;
          }
          setupMoves.add(candidates.first);
        }
        if (!canBuild) {
          continue;
        }
        final state = _stateWithSetupMoves(harness, setupMoves);
        if (!state.occupiedEdges.contains(missingEdge) &&
            triangle.edges
                .where((edge) => edge != missingEdge)
                .every(state.occupiedEdges.contains) &&
            harness.engine.validator
                .validate(state, harness.action(state, finalMove, 'candidate'))
                .isValid) {
          return _CaptureScenario(
            state: state,
            finalMove: finalMove,
            targets: [triangle],
          );
        }
      }
    }
  }
  throw StateError('No single-capture scenario could be generated.');
}

_CaptureScenario _findMultipleCaptureScenario(_Harness harness) {
  for (final finalMove in harness.board.bandMoves) {
    final candidateTriangles = <TriangleCell>{
      for (final edge in finalMove.edges)
        ...harness.board.trianglesByEdge[edge] ?? const [],
    }.toList();
    for (var first = 0; first < candidateTriangles.length; first++) {
      for (
        var second = first + 1;
        second < candidateTriangles.length;
        second++
      ) {
        final targets = [candidateTriangles[first], candidateTriangles[second]];
        final missingEdges = <UnitEdge>{};
        var validTargets = true;
        for (final target in targets) {
          final edgesOnFinalMove = target.edges
              .where(finalMove.edges.contains)
              .toList();
          if (edgesOnFinalMove.length != 1) {
            validTargets = false;
            break;
          }
          missingEdges.add(edgesOnFinalMove.single);
        }
        if (!validTargets) {
          continue;
        }

        final setupMoves = <BandMove>[];
        for (final target in targets) {
          for (final requiredEdge in target.edges.where(
            (edge) => !missingEdges.contains(edge),
          )) {
            final candidates = harness.board.bandMoves.where(
              (move) =>
                  move.id != finalMove.id &&
                  move.edges.contains(requiredEdge) &&
                  move.edges.every((edge) => !missingEdges.contains(edge)),
            );
            if (candidates.isEmpty) {
              validTargets = false;
              break;
            }
            setupMoves.add(candidates.first);
          }
          if (!validTargets) {
            break;
          }
        }
        if (!validTargets) {
          continue;
        }

        final state = _stateWithSetupMoves(harness, setupMoves);
        final validation = harness.engine.validator.validate(
          state,
          harness.action(state, finalMove, 'candidate-multiple'),
        );
        if (validation.isValid &&
            targets.every(
              (target) => validation.newlyCapturedTriangles.contains(target),
            )) {
          return _CaptureScenario(
            state: state,
            finalMove: finalMove,
            targets: targets,
          );
        }
      }
    }
  }
  throw StateError('No multiple-capture scenario could be generated.');
}

GameState _stateWithSetupMoves(
  _Harness harness,
  Iterable<BandMove> setupMoveCandidates,
) {
  final movesById = <String, BandMove>{
    for (final move in setupMoveCandidates) move.id: move,
  };
  final moves = movesById.values.toList();
  final placedBands = <PlacedBand>[
    for (var index = 0; index < moves.length; index++)
      PlacedBand(
        move: moves[index],
        playerId: harness.initialState.players[index % 2].id,
        actionId: 'setup-$index',
      ),
  ];
  return harness.initialState.copyWith(
    currentPlayerIndex: 0,
    placedBands: placedBands,
    occupiedEdges: moves.expand((move) => move.edges).toSet(),
    processedActionIds: {for (final band in placedBands) band.actionId},
    revision: moves.length,
  );
}
