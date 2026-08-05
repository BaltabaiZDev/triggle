import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

void main() {
  test('Large, Huge, and maximum custom geometry stay within safe budgets', () {
    for (final radius in [4, 5, BoardSize.maximumRadius]) {
      BoardGenerator.clearCache();
      final size = BoardSize.fromPreset(
        BoardSizePreset.custom,
        customRadius: radius,
      );
      final generation = Stopwatch()..start();
      final board = BoardGenerator.generate(size);
      generation.stop();

      expect(board.pegs, hasLength(size.expectedPegCount));
      expect(board.triangles, hasLength(size.expectedTriangleCount));
      expect(board.bandMoves, hasLength(size.potentialBandMoveCount));
      expect(generation.elapsed, lessThan(const Duration(seconds: 2)));
      expect(identical(board, BoardGenerator.generate(size)), isTrue);
    }
  });

  test('legal moves are cached per immutable state on Huge board', () {
    final settings = _settings(BoardSize.fromPreset(BoardSizePreset.huge));
    final engine = GameEngine(settings);
    final state = engine.createInitialState(settings);

    final first = engine.validator.legalMoves(state);
    final repeated = engine.validator.legalMoves(state);

    expect(first, isNotEmpty);
    expect(identical(first, repeated), isTrue);
  });

  test('maximum custom board completes deterministic engine simulation', () {
    final settings = _settings(
      BoardSize.fromPreset(
        BoardSizePreset.custom,
        customRadius: BoardSize.maximumRadius,
      ),
    );
    final engine = GameEngine(settings);
    var state = engine.createInitialState(settings);
    final elapsed = Stopwatch()..start();

    while (!state.isGameOver) {
      final move = engine.validator.legalMoves(state).first;
      final transition = engine.submitMove(
        state,
        SubmitMoveAction(
          actionId: 'performance:${state.revision}',
          playerId: state.currentPlayer.id,
          expectedRevision: state.revision,
          start: move.start,
          end: move.end,
        ),
      );
      expect(transition.wasAccepted, isTrue);
      state = transition.state;
    }
    elapsed.stop();

    expect(state.revision, greaterThan(0));
    expect(elapsed.elapsed, lessThan(const Duration(seconds: 3)));
  });
}

GameSettings _settings(BoardSize size) {
  return GameSettings(
    matchId: 'performance-${size.radius}',
    boardSize: size,
    ruleset: Ruleset.custom,
    players: [
      PlayerConfiguration(
        id: 'one',
        displayName: 'One',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'two',
        displayName: 'Two',
        controllerType: PlayerControllerType.human,
      ),
    ],
    seed: 87,
  );
}
