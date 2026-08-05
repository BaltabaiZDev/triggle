import 'dart:io';

import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

void main() {
  stdout.writeln(
    'radius,pegs,triangles,moves,generate_us,first_legal_us,'
    'cached_legal_10k_us,full_match_us,hash_1k_us,normal_bot_ms,bot_nodes',
  );
  for (final radius in [4, 5, 8]) {
    BoardGenerator.clearCache();
    final size = BoardSize.fromPreset(
      BoardSizePreset.custom,
      customRadius: radius,
    );

    final generation = Stopwatch()..start();
    final board = BoardGenerator.generate(size);
    generation.stop();

    final settings = _settings(size, radius);
    final engine = GameEngine(settings);
    var state = engine.createInitialState(settings);

    final firstLegal = Stopwatch()..start();
    final legal = engine.validator.legalMoves(state);
    firstLegal.stop();

    final cachedLegal = Stopwatch()..start();
    for (var index = 0; index < 10000; index++) {
      engine.validator.legalMoves(state);
    }
    cachedLegal.stop();

    final fullMatch = Stopwatch()..start();
    while (!state.isGameOver) {
      final move = engine.validator.legalMoves(state).first;
      state = engine
          .submitMove(
            state,
            SubmitMoveAction(
              actionId: 'benchmark:$radius:${state.revision}',
              playerId: state.currentPlayer.id,
              expectedRevision: state.revision,
              start: move.start,
              end: move.end,
            ),
          )
          .state;
    }
    fullMatch.stop();

    final hashing = Stopwatch()..start();
    for (var index = 0; index < 1000; index++) {
      GameStateHasher.hash(state);
    }
    hashing.stop();

    final initial = engine.createInitialState(settings);
    final bot = Stopwatch()..start();
    final decision = BotEngine(settings).chooseMove(
      initial,
      BotSettings(difficulty: BotDifficulty.normal, thinkingTimeMs: 80),
    );
    bot.stop();

    stdout.writeln(
      '$radius,${board.pegs.length},${board.triangles.length},'
      '${board.bandMoves.length},${generation.elapsedMicroseconds},'
      '${firstLegal.elapsedMicroseconds},${cachedLegal.elapsedMicroseconds},'
      '${fullMatch.elapsedMicroseconds},${hashing.elapsedMicroseconds},'
      '${bot.elapsedMilliseconds},${decision.nodesVisited}',
    );
    if (legal.isEmpty) {
      throw StateError('Radius $radius unexpectedly has no legal move.');
    }
  }
}

GameSettings _settings(BoardSize size, int radius) {
  return GameSettings(
    matchId: 'performance-radius-$radius',
    boardSize: size,
    ruleset: Ruleset.custom,
    players: [
      PlayerConfiguration(
        id: 'benchmark-1',
        displayName: 'Benchmark 1',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'benchmark-2',
        displayName: 'Benchmark 2',
        controllerType: PlayerControllerType.human,
      ),
    ],
    seed: 8000 + radius,
  );
}
