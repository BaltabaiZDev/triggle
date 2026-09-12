import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

void main() {
  group('BotEngine', () {
    for (var radius = 2; radius <= 8; radius++) {
      for (final difficulty in BotDifficulty.values) {
        test('${difficulty.name} returns a legal move on radius $radius', () {
          final settings = _settings(
            BoardSize.fromPreset(BoardSizePreset.custom, customRadius: radius),
            players: 2,
          );
          final state = GameState.initial(settings);
          final engine = GameEngine(settings);
          final decision = BotEngine(settings).chooseMove(
            state,
            BotSettings(
              difficulty: difficulty,
              deterministic: difficulty == BotDifficulty.beginner,
              thinkingTimeMs: 30,
            ),
          );

          expect(
            engine.validator.legalMoves(state).map((move) => move.id),
            contains(decision.move.id),
          );
          expect(decision.nodesVisited, greaterThan(0));
        });
      }
    }

    test('supports deterministic seeded decisions', () {
      final settings = _settings(
        BoardSize.fromPreset(BoardSizePreset.classic),
        players: 2,
      );
      final state = GameState.initial(settings);
      final botSettings = BotSettings(
        difficulty: BotDifficulty.normal,
        personality: BotPersonality.defensive,
        deterministic: true,
        seedOffset: 71,
      );

      final first = BotEngine(settings).chooseMove(state, botSettings);
      final second = BotEngine(settings).chooseMove(state, botSettings);

      expect(second.move, first.move);
      expect(second.completedDepth, first.completedDepth);
      expect(second.nodesVisited, first.nodesVisited);
    });

    test('easy always takes the largest immediate capture', () {
      final settings = _settings(
        BoardSize.fromPreset(BoardSizePreset.classic),
        players: 2,
      );
      final engine = GameEngine(settings);
      final state = _stateWithCaptureAvailable(engine, settings);
      final legalMoves = engine.validator.legalMoves(state);
      final maximumCapture = legalMoves
          .map((move) => engine.validator.capturesForMove(state, move).length)
          .reduce((first, second) => first > second ? first : second);

      final decision = BotEngine(settings).chooseMove(
        state,
        BotSettings(difficulty: BotDifficulty.easy, deterministic: true),
      );

      expect(maximumCapture, greaterThan(0));
      expect(
        engine.validator.capturesForMove(state, decision.move),
        hasLength(maximumCapture),
      );
    });

    test('difficulty changes tactical behavior, not only thinking delay', () {
      final settings = _settings(
        BoardSize.fromPreset(BoardSizePreset.classic),
        players: 2,
      );
      final engine = GameEngine(settings);
      final state = _stateWithCaptureAvailable(engine, settings);
      final maximumCapture = engine.validator
          .legalMoves(state)
          .map((move) => engine.validator.capturesForMove(state, move).length)
          .reduce((first, second) => first > second ? first : second);
      BotDecision? beginnerMistake;
      for (var seedOffset = 0; seedOffset < 256; seedOffset++) {
        final decision = BotEngine(settings).chooseMove(
          state,
          BotSettings(
            difficulty: BotDifficulty.beginner,
            deterministic: true,
            seedOffset: seedOffset,
            thinkingTimeMs: 120,
          ),
        );
        final captures = engine.validator
            .capturesForMove(state, decision.move)
            .length;
        if (captures < maximumCapture) {
          beginnerMistake = decision;
          break;
        }
      }
      final easy = BotEngine(settings).chooseMove(
        state,
        BotSettings(
          difficulty: BotDifficulty.easy,
          deterministic: true,
          thinkingTimeMs: 120,
        ),
      );

      expect(maximumCapture, greaterThan(0));
      expect(beginnerMistake, isNotNull);
      expect(beginnerMistake!.completedDepth, 0);
      expect(
        engine.validator.capturesForMove(state, beginnerMistake.move).length,
        lessThan(maximumCapture),
      );
      expect(easy.completedDepth, 1);
      expect(
        engine.validator.capturesForMove(state, easy.move),
        hasLength(maximumCapture),
      );

      final searchSettings = _settings(
        BoardSize.fromPreset(BoardSizePreset.small),
        players: 2,
      );
      final searchState = GameState.initial(searchSettings);
      final searched = <BotDifficulty, BotDecision>{
        for (final difficulty in const [
          BotDifficulty.normal,
          BotDifficulty.hard,
          BotDifficulty.expert,
        ])
          difficulty: BotEngine(searchSettings).chooseMove(
            searchState,
            BotSettings(
              difficulty: difficulty,
              deterministic: true,
              thinkingTimeMs: 120,
            ),
          ),
      };
      expect(searched[BotDifficulty.normal]!.completedDepth, 2);
      expect(searched[BotDifficulty.hard]!.completedDepth, 4);
      expect(searched[BotDifficulty.expert]!.completedDepth, 5);
    });

    test('supports MaxN search for four players', () {
      final settings = _settings(
        BoardSize.fromPreset(BoardSizePreset.classic),
        players: 4,
      );
      final state = GameState.initial(settings);
      final engine = GameEngine(settings);
      final decision = BotEngine(settings).chooseMove(
        state,
        BotSettings(difficulty: BotDifficulty.hard, thinkingTimeMs: 60),
      );

      expect(engine.validator.legalMoves(state), contains(decision.move));
      expect(decision.completedDepth, greaterThanOrEqualTo(1));
    });

    test('worker returns a legal move from a background isolate', () async {
      final settings = _settings(
        BoardSize.fromPreset(BoardSizePreset.classic),
        players: 3,
      );
      final state = GameState.initial(settings);
      final engine = GameEngine(settings);

      final decision = await const BotWorker().chooseMove(
        state,
        BotSettings(difficulty: BotDifficulty.normal, thinkingTimeMs: 40),
      );

      expect(engine.validator.legalMoves(state), contains(decision.move));
      expect(decision.difficulty, BotDifficulty.normal);
    });
  });

  test('bot settings survive player and state serialization', () {
    final settings = _settings(
      BoardSize.fromPreset(BoardSizePreset.small),
      players: 2,
      botDifficulty: BotDifficulty.expert,
    );
    final restoredSettings = GameSettings.fromJson(settings.toJson());
    final restoredState = GameState.fromJson(
      GameState.initial(settings).toJson(),
    );

    expect(
      restoredSettings.players.last.botSettings?.difficulty,
      BotDifficulty.expert,
    );
    expect(
      restoredState.players.last.botSettings?.difficulty,
      BotDifficulty.expert,
    );
  });
}

GameState _stateWithCaptureAvailable(GameEngine engine, GameSettings settings) {
  var state = engine.createInitialState(settings);
  var guard = 0;
  while (!state.isGameOver) {
    final legalMoves = engine.validator.legalMoves(state);
    if (legalMoves.any(
      (move) => engine.validator.capturesForMove(state, move).isNotEmpty,
    )) {
      return state;
    }
    final move = legalMoves.first;
    state = engine
        .submitMove(
          state,
          SubmitMoveAction(
            actionId: 'capture-state:$guard',
            playerId: state.currentPlayer.id,
            expectedRevision: state.revision,
            start: move.start,
            end: move.end,
          ),
        )
        .state;
    guard++;
    if (guard > 30) {
      break;
    }
  }
  throw StateError('Could not construct a state with an immediate capture.');
}

GameSettings _settings(
  BoardSize boardSize, {
  required int players,
  BotDifficulty botDifficulty = BotDifficulty.normal,
}) {
  return GameSettings(
    matchId: 'bot-${boardSize.radius}-$players',
    boardSize: boardSize,
    ruleset: boardSize.isClassic ? Ruleset.classic : Ruleset.custom,
    players: [
      for (var index = 0; index < players; index++)
        PlayerConfiguration(
          id: 'p$index',
          displayName: 'Player ${index + 1}',
          controllerType: index == 0
              ? PlayerControllerType.human
              : PlayerControllerType.bot,
          botSettings: index == 0
              ? null
              : BotSettings(difficulty: botDifficulty, deterministic: true),
        ),
    ],
    seed: 731,
  );
}
