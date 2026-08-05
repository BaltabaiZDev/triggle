import 'dart:math' as math;

import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/geometry/board_definition.dart';
import 'package:trigrid/core/game/models/captured_triangle.dart';
import 'package:trigrid/core/game/models/game_action.dart';
import 'package:trigrid/core/game/models/game_settings.dart';
import 'package:trigrid/core/game/models/match_result.dart';
import 'package:trigrid/core/game/models/placed_band.dart';
import 'package:trigrid/core/game/models/player_state.dart';
import 'package:trigrid/core/game/rules/move_validation_result.dart';
import 'package:trigrid/core/game/rules/move_validator.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

class GameTransition {
  const GameTransition({
    required this.state,
    required this.validation,
    required this.action,
  });

  final GameState state;
  final MoveValidationResult validation;
  final SubmitMoveAction action;

  bool get wasAccepted => validation.isValid;
}

class GameEngine {
  GameEngine(GameSettings settings)
    : board = BoardGenerator.generate(settings.boardSize),
      validator = MoveValidator(BoardGenerator.generate(settings.boardSize));

  final BoardDefinition board;
  final MoveValidator validator;

  GameState createInitialState(GameSettings settings) {
    if (settings.boardSize != board.size) {
      throw ArgumentError('Settings do not match this engine board.');
    }
    return GameState.initial(settings);
  }

  GameTransition submitMove(GameState state, SubmitMoveAction action) {
    final validation = validator.validate(state, action);
    if (!validation.isValid) {
      return GameTransition(
        state: state,
        validation: validation,
        action: action,
      );
    }

    final move = validation.move!;
    final captures = validation.newlyCapturedTriangles;
    final actingIndex = state.currentPlayerIndex;
    final actingPlayer = state.currentPlayer;
    final updatedPlayers = [...state.players];
    updatedPlayers[actingIndex] = actingPlayer.copyWith(
      score: actingPlayer.score + captures.length,
      bandsRemaining: actingPlayer.bandsRemaining - 1,
      markersRemaining: math.max(
        0,
        actingPlayer.markersRemaining - captures.length,
      ),
    );

    final updatedCapturedTriangles = {
      ...state.capturedTriangles,
      for (final triangle in captures)
        triangle.id: CapturedTriangle(
          triangleId: triangle.id,
          playerId: actingPlayer.id,
          actionId: action.actionId,
        ),
    };
    final updatedBands = [
      ...state.placedBands,
      PlacedBand(
        move: move,
        playerId: actingPlayer.id,
        actionId: action.actionId,
      ),
    ];
    final updatedEdges = {...state.occupiedEdges, ...move.edges};
    final updatedActionIds = {...state.processedActionIds, action.actionId};
    final nextIndex = _nextEligiblePlayerIndex(updatedPlayers, actingIndex);
    final nextRevision = state.revision + 1;

    var nextState = GameState(
      settings: state.settings,
      players: updatedPlayers,
      currentPlayerIndex: nextIndex ?? actingIndex,
      placedBands: updatedBands,
      occupiedEdges: updatedEdges,
      capturedTriangles: updatedCapturedTriangles,
      processedActionIds: updatedActionIds,
      revision: nextRevision,
    );

    final endReason = _endReason(
      nextState,
      actingPlayerIndex: actingIndex,
      hasEligiblePlayer: nextIndex != null,
    );
    if (endReason != null) {
      nextState = nextState.copyWith(
        matchResult: _createMatchResult(nextState, endReason),
      );
    }

    return GameTransition(
      state: nextState,
      validation: validation,
      action: action,
    );
  }

  MatchEndReason? _endReason(
    GameState state, {
    required int actingPlayerIndex,
    required bool hasEligiblePlayer,
  }) {
    final actingPlayer = state.players[actingPlayerIndex];
    final markerLimitApplies =
        state.settings.ruleset == Ruleset.custom || state.players.length >= 3;
    if (markerLimitApplies && actingPlayer.markersRemaining == 0) {
      return MatchEndReason.markerLimit;
    }
    if (!hasEligiblePlayer ||
        state.players.every((player) => player.bandsRemaining == 0)) {
      return MatchEndReason.bandsExhausted;
    }
    if (validator.legalMoves(state).isEmpty) {
      return MatchEndReason.noLegalMoves;
    }
    return null;
  }

  int? _nextEligiblePlayerIndex(List<PlayerState> players, int actingIndex) {
    for (var offset = 1; offset <= players.length; offset++) {
      final candidate = (actingIndex + offset) % players.length;
      if (players[candidate].bandsRemaining > 0) {
        return candidate;
      }
    }
    return null;
  }

  MatchResult _createMatchResult(GameState state, MatchEndReason reason) {
    final maximumScore = state.players
        .map((player) => player.score)
        .reduce(math.max);
    return MatchResult(
      reason: reason,
      winnerPlayerIds: state.players
          .where((player) => player.score == maximumScore)
          .map((player) => player.id)
          .toList(),
      scores: {for (final player in state.players) player.id: player.score},
      finalRevision: state.revision,
    );
  }
}
