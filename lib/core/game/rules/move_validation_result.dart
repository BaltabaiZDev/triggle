import 'package:trigrid/core/game/models/band_move.dart';
import 'package:trigrid/core/game/models/triangle_cell.dart';
import 'package:trigrid/core/game/models/unit_edge.dart';

enum MoveValidationErrorCode {
  gameEnded,
  duplicateAction,
  staleRevision,
  notPlayersTurn,
  noBandsRemaining,
  unknownEndpoint,
  wrongAxis,
  wrongLength,
  outsideBoard,
  duplicateBand,
  addsNoEdge,
  notConnected,
}

class MoveValidationResult {
  MoveValidationResult._({
    required this.isValid,
    required this.errorCode,
    required this.localizedMessage,
    required this.affectedEdges,
    required this.newlyCapturedTriangles,
    required this.move,
  });

  factory MoveValidationResult.valid({
    required BandMove move,
    required List<TriangleCell> newlyCapturedTriangles,
  }) {
    return MoveValidationResult._(
      isValid: true,
      errorCode: null,
      localizedMessage: 'moveValidation.valid',
      affectedEdges: List<UnitEdge>.unmodifiable(move.edges),
      newlyCapturedTriangles: List<TriangleCell>.unmodifiable(
        newlyCapturedTriangles,
      ),
      move: move,
    );
  }

  factory MoveValidationResult.invalid(
    MoveValidationErrorCode errorCode, {
    BandMove? move,
  }) {
    return MoveValidationResult._(
      isValid: false,
      errorCode: errorCode,
      localizedMessage: 'moveValidation.${errorCode.name}',
      affectedEdges: move == null
          ? const []
          : List<UnitEdge>.unmodifiable(move.edges),
      newlyCapturedTriangles: const [],
      move: move,
    );
  }

  final bool isValid;
  final MoveValidationErrorCode? errorCode;
  final String localizedMessage;
  final List<UnitEdge> affectedEdges;
  final List<TriangleCell> newlyCapturedTriangles;
  final BandMove? move;
}
