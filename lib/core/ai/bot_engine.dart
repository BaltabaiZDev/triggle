import 'dart:math' as math;

import 'package:trigrid/core/ai/bot_decision.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

class BotEngine {
  BotEngine(GameSettings settings) : engine = GameEngine(settings);

  final GameEngine engine;

  BotDecision chooseMove(GameState state, BotSettings settings) {
    final stopwatch = Stopwatch()..start();
    final legalMoves = engine.validator.legalMoves(state);
    if (legalMoves.isEmpty) {
      throw StateError('The bot was asked to move without a legal move.');
    }
    final rootPlayerIndex = state.currentPlayerIndex;
    final random = math.Random(_seedFor(state, settings));

    switch (settings.difficulty) {
      case BotDifficulty.beginner:
        final capturing = legalMoves
            .where(
              (move) =>
                  engine.validator.capturesForMove(state, move).isNotEmpty,
            )
            .toList();
        final noticesCapture =
            capturing.isNotEmpty && random.nextDouble() < 0.3;
        final candidates = noticesCapture ? capturing : legalMoves;
        final move = candidates[random.nextInt(candidates.length)];
        return BotDecision(
          move: move,
          difficulty: settings.difficulty,
          estimatedValue: _onePlyScore(
            state,
            move,
            rootPlayerIndex,
            settings.personality,
            includeReplyRisk: false,
          ),
          nodesVisited: legalMoves.length,
          completedDepth: 0,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        );
      case BotDifficulty.easy:
        final baseRanking = _rankMoves(
          state,
          rootPlayerIndex,
          settings.personality,
          includeReplyRisk: false,
        );
        final maximumCaptures = legalMoves
            .map((move) => engine.validator.capturesForMove(state, move).length)
            .reduce(math.max);
        final candidates = maximumCaptures == 0
            ? baseRanking.take(18)
            : baseRanking.where(
                (item) =>
                    engine.validator.capturesForMove(state, item.move).length ==
                    maximumCaptures,
              );
        final ranked =
            [
              for (final item in candidates)
                _RankedMove(
                  item.move,
                  _onePlyScore(
                    state,
                    item.move,
                    rootPlayerIndex,
                    settings.personality,
                    includeReplyRisk: true,
                  ),
                ),
            ]..sort((first, second) {
              final byScore = second.score.compareTo(first.score);
              return byScore != 0
                  ? byScore
                  : first.move.id.compareTo(second.move.id);
            });
        final selected = ranked.first;
        return BotDecision(
          move: selected.move,
          difficulty: settings.difficulty,
          estimatedValue: selected.score,
          nodesVisited: legalMoves.length,
          completedDepth: 1,
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        );
      case BotDifficulty.normal:
      case BotDifficulty.hard:
      case BotDifficulty.expert:
        return _search(state, settings, stopwatch, rootPlayerIndex);
    }
  }

  BotDecision _search(
    GameState state,
    BotSettings settings,
    Stopwatch stopwatch,
    int rootPlayerIndex,
  ) {
    final context = _SearchContext(
      engine: engine,
      settings: settings,
      stopwatch: stopwatch,
    );
    final initialRanking = _rankMoves(
      state,
      rootPlayerIndex,
      settings.personality,
      includeReplyRisk: false,
    );
    var bestMove = initialRanking.first.move;
    var bestValue = initialRanking.first.score;
    var completedDepth = 1;
    final maximumDepth = switch (settings.difficulty) {
      BotDifficulty.normal => 2,
      BotDifficulty.hard => 4,
      BotDifficulty.expert => 5,
      _ => 1,
    };

    for (var depth = 2; depth <= maximumDepth; depth++) {
      try {
        final result = state.players.length == 2
            ? _searchTwoPlayerRoot(state, depth, rootPlayerIndex, context)
            : _searchMaxNRoot(state, depth, rootPlayerIndex, context);
        bestMove = result.move;
        bestValue = result.value;
        completedDepth = depth;
      } on _SearchAborted {
        break;
      }
    }

    return BotDecision(
      move: bestMove,
      difficulty: settings.difficulty,
      estimatedValue: bestValue,
      nodesVisited: context.nodes,
      completedDepth: completedDepth,
      elapsedMilliseconds: stopwatch.elapsedMilliseconds,
    );
  }

  _RootResult _searchTwoPlayerRoot(
    GameState state,
    int depth,
    int rootPlayerIndex,
    _SearchContext context,
  ) {
    final moves = _orderedSearchMoves(
      state,
      rootPlayerIndex,
      context,
      isRoot: true,
    );
    var bestMove = moves.first;
    var bestValue = double.negativeInfinity;
    var alpha = double.negativeInfinity;
    const beta = double.infinity;
    for (final move in moves) {
      context.visit();
      final next = _applyMove(state, move);
      final value = _alphaBeta(
        next,
        depth - 1,
        rootPlayerIndex,
        alpha,
        beta,
        context,
      );
      if (value > bestValue ||
          (value == bestValue && move.id.compareTo(bestMove.id) < 0)) {
        bestMove = move;
        bestValue = value;
      }
      alpha = math.max(alpha, bestValue);
    }
    return _RootResult(bestMove, bestValue);
  }

  double _alphaBeta(
    GameState state,
    int depth,
    int rootPlayerIndex,
    double alpha,
    double beta,
    _SearchContext context,
  ) {
    context.visit();
    if (depth <= 0 || state.isGameOver) {
      return _evaluatePlayer(
        state,
        rootPlayerIndex,
        context.settings.personality,
        context.settings.difficulty,
      );
    }
    final key = '${GameStateHasher.hash(state)}:$depth:$rootPlayerIndex';
    final cached = context.scalarTransposition[key];
    if (cached != null) {
      return cached;
    }
    final maximizing = state.currentPlayerIndex == rootPlayerIndex;
    var value = maximizing ? double.negativeInfinity : double.infinity;
    final moves = _orderedSearchMoves(
      state,
      rootPlayerIndex,
      context,
      isRoot: false,
    );
    if (moves.isEmpty) {
      return _evaluatePlayer(
        state,
        rootPlayerIndex,
        context.settings.personality,
        context.settings.difficulty,
      );
    }

    for (final move in moves) {
      final childValue = _alphaBeta(
        _applyMove(state, move),
        depth - 1,
        rootPlayerIndex,
        alpha,
        beta,
        context,
      );
      if (maximizing) {
        value = math.max(value, childValue);
        alpha = math.max(alpha, value);
      } else {
        value = math.min(value, childValue);
        beta = math.min(beta, value);
      }
      if (beta <= alpha) {
        break;
      }
    }
    context.scalarTransposition[key] = value;
    return value;
  }

  _RootResult _searchMaxNRoot(
    GameState state,
    int depth,
    int rootPlayerIndex,
    _SearchContext context,
  ) {
    final moves = _orderedSearchMoves(
      state,
      rootPlayerIndex,
      context,
      isRoot: true,
    );
    var bestMove = moves.first;
    var bestVector = List<double>.filled(
      state.players.length,
      double.negativeInfinity,
    );
    for (final move in moves) {
      context.visit();
      final vector = _maxN(_applyMove(state, move), depth - 1, context);
      if (vector[rootPlayerIndex] > bestVector[rootPlayerIndex] ||
          (vector[rootPlayerIndex] == bestVector[rootPlayerIndex] &&
              move.id.compareTo(bestMove.id) < 0)) {
        bestMove = move;
        bestVector = vector;
      }
    }
    return _RootResult(bestMove, bestVector[rootPlayerIndex]);
  }

  List<double> _maxN(GameState state, int depth, _SearchContext context) {
    context.visit();
    if (depth <= 0 || state.isGameOver) {
      return [
        for (var index = 0; index < state.players.length; index++)
          _evaluatePlayer(
            state,
            index,
            context.settings.personality,
            context.settings.difficulty,
          ),
      ];
    }
    final key = '${GameStateHasher.hash(state)}:$depth:maxn';
    final cached = context.vectorTransposition[key];
    if (cached != null) {
      return cached;
    }
    final activeIndex = state.currentPlayerIndex;
    final moves = _orderedSearchMoves(
      state,
      activeIndex,
      context,
      isRoot: false,
    );
    if (moves.isEmpty) {
      return [
        for (var index = 0; index < state.players.length; index++)
          _evaluatePlayer(
            state,
            index,
            context.settings.personality,
            context.settings.difficulty,
          ),
      ];
    }
    List<double>? best;
    for (final move in moves) {
      final candidate = _maxN(_applyMove(state, move), depth - 1, context);
      if (best == null || candidate[activeIndex] > best[activeIndex]) {
        best = candidate;
      }
    }
    final result = List<double>.unmodifiable(best!);
    context.vectorTransposition[key] = result;
    return result;
  }

  List<BandMove> _orderedSearchMoves(
    GameState state,
    int perspectivePlayerIndex,
    _SearchContext context, {
    required bool isRoot,
  }) {
    final ranked = _rankMoves(
      state,
      perspectivePlayerIndex,
      context.settings.personality,
      includeReplyRisk: false,
    );
    final limit = switch (context.settings.difficulty) {
      BotDifficulty.normal => isRoot ? 14 : 10,
      BotDifficulty.hard => isRoot ? 22 : 14,
      BotDifficulty.expert => isRoot ? 30 : 18,
      _ => ranked.length,
    };
    return ranked
        .take(math.min(limit, ranked.length))
        .map((item) => item.move)
        .toList(growable: false);
  }

  List<_RankedMove> _rankMoves(
    GameState state,
    int perspectivePlayerIndex,
    BotPersonality personality, {
    required bool includeReplyRisk,
  }) {
    final ranked = [
      for (final move in engine.validator.legalMoves(state))
        _RankedMove(
          move,
          _onePlyScore(
            state,
            move,
            perspectivePlayerIndex,
            personality,
            includeReplyRisk: includeReplyRisk,
          ),
        ),
    ];
    ranked.sort((first, second) {
      final byScore = second.score.compareTo(first.score);
      return byScore != 0 ? byScore : first.move.id.compareTo(second.move.id);
    });
    return ranked;
  }

  double _onePlyScore(
    GameState state,
    BandMove move,
    int perspectivePlayerIndex,
    BotPersonality personality, {
    required bool includeReplyRisk,
  }) {
    final captures = engine.validator.capturesForMove(state, move).length;
    final addedEdges = move.edges
        .where((edge) => !state.occupiedEdges.contains(edge))
        .length;
    final centerDistance = move.pegs
        .map((peg) => peg.distanceTo(const GridCoordinate(0, 0)))
        .reduce(math.min);
    final weights = _PersonalityWeights.forPersonality(personality);
    var score =
        captures * weights.immediateCapture +
        addedEdges * weights.expansion -
        centerDistance * 0.35;
    final next = _applyMove(state, move);
    final result = next.matchResult;
    if (result != null) {
      score +=
          result.winnerPlayerIds.contains(
            state.players[perspectivePlayerIndex].id,
          )
          ? 100000
          : -100000;
    }
    if (includeReplyRisk && !next.isGameOver) {
      var maximumReplyCapture = 0;
      var multiCaptureReplies = 0;
      for (final reply in engine.validator.legalMoves(next)) {
        final count = engine.validator.capturesForMove(next, reply).length;
        maximumReplyCapture = math.max(maximumReplyCapture, count);
        if (count > 1) {
          multiCaptureReplies++;
        }
      }
      score -= maximumReplyCapture * weights.replyRisk;
      score -= multiCaptureReplies * weights.trapRisk;
    }
    return score;
  }

  double _evaluatePlayer(
    GameState state,
    int playerIndex,
    BotPersonality personality,
    BotDifficulty difficulty,
  ) {
    final player = state.players[playerIndex];
    final weights = _PersonalityWeights.forPersonality(personality);
    final opponents = state.players.where((candidate) => candidate != player);
    final opponentScore = opponents.isEmpty
        ? 0.0
        : opponents
              .map((candidate) => candidate.score)
              .reduce(math.max)
              .toDouble();
    var value =
        player.score * weights.heldScore -
        opponentScore * weights.opponentScore +
        player.bandsRemaining * 0.45;

    final result = state.matchResult;
    if (result != null) {
      if (result.winnerPlayerIds.contains(player.id)) {
        value += result.isTie ? 250000 : 500000;
      } else {
        value -= 500000;
      }
      return value;
    }

    final moves = engine.validator.legalMoves(state);
    if (moves.isNotEmpty) {
      var maximumCapture = 0;
      var captureMoves = 0;
      var multiCaptureMoves = 0;
      for (final move in moves) {
        final captures = engine.validator.capturesForMove(state, move).length;
        maximumCapture = math.max(maximumCapture, captures);
        if (captures > 0) {
          captureMoves++;
        }
        if (captures > 1) {
          multiCaptureMoves++;
        }
      }
      final isPlayersTurn = state.currentPlayerIndex == playerIndex;
      final sign = isPlayersTurn ? 1.0 : -1.0;
      value += sign * maximumCapture * weights.futureCapture;
      value += sign * captureMoves * weights.optionCount;
      if (difficulty == BotDifficulty.expert) {
        value += sign * multiCaptureMoves * weights.trapRisk;
      }
      value += sign * math.log(moves.length + 1) * weights.mobility;
    }
    return value;
  }

  GameState _applyMove(GameState state, BandMove move) {
    final transition = engine.submitMove(
      state,
      SubmitMoveAction(
        actionId: 'bot-search:${state.revision}:${move.id}',
        playerId: state.currentPlayer.id,
        expectedRevision: state.revision,
        start: move.start,
        end: move.end,
      ),
    );
    if (!transition.wasAccepted) {
      throw StateError(
        'Generated legal move ${move.id} was rejected: '
        '${transition.validation.errorCode}',
      );
    }
    return transition.state;
  }

  int _seedFor(GameState state, BotSettings settings) {
    var seed = 0x4D595DF4;
    for (final value in [
      state.settings.seed,
      state.revision,
      state.currentPlayer.seatIndex,
      settings.seedOffset,
      settings.difficulty.index,
      settings.personality.index,
    ]) {
      seed = (seed * 1664525 + value + 1013904223) & 0x7FFFFFFF;
    }
    return seed;
  }
}

class _SearchContext {
  _SearchContext({
    required this.engine,
    required this.settings,
    required this.stopwatch,
  });

  final GameEngine engine;
  final BotSettings settings;
  final Stopwatch stopwatch;
  final Map<String, double> scalarTransposition = {};
  final Map<String, List<double>> vectorTransposition = {};
  var nodes = 0;

  int get nodeBudget => switch (settings.difficulty) {
    BotDifficulty.normal => 1800,
    BotDifficulty.hard => 14000,
    BotDifficulty.expert => 42000,
    _ => 500,
  };

  void visit() {
    nodes++;
    final exhausted = settings.deterministic
        ? nodes > nodeBudget
        : stopwatch.elapsedMilliseconds >= settings.thinkingTimeMs;
    if (exhausted) {
      throw const _SearchAborted();
    }
  }
}

class _SearchAborted implements Exception {
  const _SearchAborted();
}

class _RootResult {
  const _RootResult(this.move, this.value);

  final BandMove move;
  final double value;
}

class _RankedMove {
  const _RankedMove(this.move, this.score);

  final BandMove move;
  final double score;
}

class _PersonalityWeights {
  const _PersonalityWeights({
    required this.immediateCapture,
    required this.replyRisk,
    required this.trapRisk,
    required this.expansion,
    required this.heldScore,
    required this.opponentScore,
    required this.futureCapture,
    required this.optionCount,
    required this.mobility,
  });

  factory _PersonalityWeights.forPersonality(BotPersonality personality) {
    return switch (personality) {
      BotPersonality.aggressive => const _PersonalityWeights(
        immediateCapture: 1250,
        replyRisk: 460,
        trapRisk: 18,
        expansion: 13,
        heldScore: 1100,
        opponentScore: 850,
        futureCapture: 145,
        optionCount: 8,
        mobility: 5,
      ),
      BotPersonality.defensive => const _PersonalityWeights(
        immediateCapture: 980,
        replyRisk: 920,
        trapRisk: 62,
        expansion: 8,
        heldScore: 1000,
        opponentScore: 1120,
        futureCapture: 95,
        optionCount: 4,
        mobility: 8,
      ),
      BotPersonality.balanced => const _PersonalityWeights(
        immediateCapture: 1100,
        replyRisk: 680,
        trapRisk: 38,
        expansion: 10,
        heldScore: 1050,
        opponentScore: 1000,
        futureCapture: 120,
        optionCount: 6,
        mobility: 7,
      ),
    };
  }

  final double immediateCapture;
  final double replyRisk;
  final double trapRisk;
  final double expansion;
  final double heldScore;
  final double opponentScore;
  final double futureCapture;
  final double optionCount;
  final double mobility;
}
