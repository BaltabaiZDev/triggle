import 'dart:collection';

import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/geometry/board_definition.dart';
import 'package:trigrid/core/game/models/band_move.dart';
import 'package:trigrid/core/game/models/game_action.dart';
import 'package:trigrid/core/game/models/triangle_cell.dart';
import 'package:trigrid/core/game/rules/move_validation_result.dart';

class MoveValidator {
  MoveValidator(this.board);

  final BoardDefinition board;
  final Expando<List<BandMove>> _legalMoveCache = Expando('legal-moves');
  final Expando<Map<String, List<TriangleCell>>> _captureCache = Expando(
    'captures',
  );

  MoveValidationResult validate(GameState state, SubmitMoveAction action) {
    _requireMatchingBoard(state);

    if (state.isGameOver) {
      return MoveValidationResult.invalid(MoveValidationErrorCode.gameEnded);
    }
    if (state.processedActionIds.contains(action.actionId)) {
      return MoveValidationResult.invalid(
        MoveValidationErrorCode.duplicateAction,
      );
    }
    if (action.expectedRevision != state.revision) {
      return MoveValidationResult.invalid(
        MoveValidationErrorCode.staleRevision,
      );
    }
    if (action.playerId != state.currentPlayer.id) {
      return MoveValidationResult.invalid(
        MoveValidationErrorCode.notPlayersTurn,
      );
    }
    if (state.currentPlayer.bandsRemaining <= 0) {
      return MoveValidationResult.invalid(
        MoveValidationErrorCode.noBandsRemaining,
      );
    }
    if (!board.containsPeg(action.start) || !board.containsPeg(action.end)) {
      return MoveValidationResult.invalid(
        MoveValidationErrorCode.unknownEndpoint,
      );
    }
    if (!action.start.isAlignedWith(action.end)) {
      return MoveValidationResult.invalid(MoveValidationErrorCode.wrongAxis);
    }
    if (action.start.distanceTo(action.end) != 3) {
      return MoveValidationResult.invalid(MoveValidationErrorCode.wrongLength);
    }

    final move = board.moveBetween(action.start, action.end);
    if (move == null || !move.pegs.every(board.containsPeg)) {
      return MoveValidationResult.invalid(MoveValidationErrorCode.outsideBoard);
    }

    final geometryError = _resolvedMoveError(state, move);
    if (geometryError != null) {
      return MoveValidationResult.invalid(geometryError, move: move);
    }

    return MoveValidationResult.valid(
      move: move,
      newlyCapturedTriangles: capturesForMove(state, move),
    );
  }

  List<BandMove> legalMoves(GameState state) {
    _requireMatchingBoard(state);
    if (state.isGameOver || state.currentPlayer.bandsRemaining <= 0) {
      return const [];
    }
    final cached = _legalMoveCache[state];
    if (cached != null) {
      return cached;
    }
    Iterable<BandMove> candidates = board.bandMoves;
    if (state.networkPegs.isNotEmpty) {
      final connected = SplayTreeMap<String, BandMove>();
      for (final peg in state.networkPegs) {
        for (final move in board.movesByPeg[peg] ?? const <BandMove>[]) {
          connected[move.id] = move;
        }
      }
      candidates = connected.values;
    }
    final result = List<BandMove>.unmodifiable(
      candidates.where((move) => _resolvedMoveError(state, move) == null),
    );
    _legalMoveCache[state] = result;
    return result;
  }

  List<TriangleCell> capturesForMove(GameState state, BandMove move) {
    final byMove = _captureCache[state] ?? <String, List<TriangleCell>>{};
    _captureCache[state] = byMove;
    final cached = byMove[move.id];
    if (cached != null) {
      return cached;
    }
    final occupiedAfterMove = {...state.occupiedEdges, ...move.edges};
    final candidates = SplayTreeMap<String, TriangleCell>();
    for (final edge in move.edges) {
      for (final triangle in board.trianglesByEdge[edge] ?? const []) {
        candidates[triangle.id] = triangle;
      }
    }
    final result = List<TriangleCell>.unmodifiable(
      candidates.values.where(
        (triangle) =>
            !state.capturedTriangles.containsKey(triangle.id) &&
            triangle.edges.every(occupiedAfterMove.contains),
      ),
    );
    byMove[move.id] = result;
    return result;
  }

  MoveValidationErrorCode? _resolvedMoveError(GameState state, BandMove move) {
    if (state.placedBandIds.contains(move.id)) {
      return MoveValidationErrorCode.duplicateBand;
    }
    if (move.edges.every(state.occupiedEdges.contains)) {
      return MoveValidationErrorCode.addsNoEdge;
    }
    if (state.placedBands.isNotEmpty) {
      final networkPegs = state.networkPegs;
      if (!move.pegs.any(networkPegs.contains)) {
        return MoveValidationErrorCode.notConnected;
      }
    }
    return null;
  }

  void _requireMatchingBoard(GameState state) {
    if (state.settings.boardSize != board.size) {
      throw StateError(
        'The validator board does not match the game state board.',
      );
    }
  }
}
