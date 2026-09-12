import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

void main() {
  test('accepts authoritative moves, records them, pauses, and restarts', () {
    final controller = LocalGameSessionController(_settings());
    final move = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;

    final transition = controller.submitMove(move.start, move.end);

    expect(transition?.wasAccepted, isTrue);
    expect(controller.currentState.revision, 1);
    expect(controller.acceptedActions, hasLength(1));
    expect(controller.currentState.currentPlayerIndex, 1);

    controller.setPaused(true);
    final pausedMove = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;
    expect(controller.submitMove(pausedMove.start, pausedMove.end), isNull);
    expect(controller.currentState.revision, 1);

    controller.restart();
    expect(controller.currentState.revision, 0);
    expect(controller.acceptedActions, isEmpty);
    expect(controller.isPaused.value, isFalse);
  });

  test('restores a verified resumable state and accepted action log', () {
    final original = LocalGameSessionController(
      _settings(),
      enablePassAndPlayHandoffs: true,
    );
    final move = original.engine.validator
        .legalMoves(original.currentState)
        .first;
    original.submitMove(move.start, move.end);
    final hash = GameStateHasher.hash(original.currentState);

    final restored = LocalGameSessionController(
      _settings(),
      enablePassAndPlayHandoffs: true,
    );
    restored.restoreVerifiedState(
      restoredState: original.currentState,
      actions: original.acceptedActions,
      expectedHash: hash,
    );

    expect(restored.currentState.revision, 1);
    expect(restored.acceptedActions, hasLength(1));
    expect(GameStateHasher.hash(restored.currentState), hash);
    expect(restored.awaitingHandoff.value, isTrue);
  });

  test('drives a complete local match through the controller', () {
    final controller = LocalGameSessionController(_settings());
    var guard = 0;

    while (!controller.currentState.isGameOver) {
      final move = controller.engine.validator
          .legalMoves(controller.currentState)
          .first;
      final transition = controller.submitMove(move.start, move.end);
      expect(transition?.wasAccepted, isTrue);
      guard++;
      expect(guard, lessThanOrEqualTo(28));
    }

    expect(controller.currentState.matchResult, isNotNull);
    expect(
      controller.acceptedActions,
      hasLength(controller.currentState.revision),
    );
  });

  test('plays victory or defeat from the local player perspective', () {
    final settings = _settings();
    final simulated = _playFirstLegalMatch(settings);
    expect(simulated.matchResult!.isTie, isFalse);
    final winnerId = simulated.matchResult!.winnerPlayerIds.single;
    final loserId = settings.players
        .map((player) => player.id)
        .firstWhere((id) => id != winnerId);

    for (final perspective in [
      (playerId: winnerId, expected: 'victory'),
      (playerId: loserId, expected: 'defeat'),
    ]) {
      final feedback = _RecordingFeedback();
      final controller = LocalGameSessionController(
        settings,
        feedback: feedback,
        feedbackPerspectivePlayerId: perspective.playerId,
      );
      while (!controller.currentState.isGameOver) {
        final move = controller.engine.validator
            .legalMoves(controller.currentState)
            .first;
        controller.submitMove(move.start, move.end);
      }

      expect(
        feedback.events.where(
          (event) => const {'victory', 'defeat', 'draw'}.contains(event),
        ),
        [perspective.expected],
      );
    }
  });

  test('replays accepted actions to the identical final hash', () async {
    final controller = LocalGameSessionController(
      _settings(),
      initialFeelSettings: GameFeelSettings(reducedMotion: true),
    );
    final presentedRevisions = <int>[];
    controller.onAcceptedTransition = (transition) {
      presentedRevisions.add(transition.state.revision);
    };

    while (!controller.currentState.isGameOver) {
      final move = controller.engine.validator
          .legalMoves(controller.currentState)
          .first;
      controller.submitMove(move.start, move.end);
    }
    final finalHash = GameStateHasher.hash(controller.currentState);
    final finalRevision = controller.currentState.revision;
    final actionCount = controller.acceptedActions.length;

    presentedRevisions.clear();
    await controller.replayAcceptedActions();
    expect(controller.showResult.value, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 750));

    expect(GameStateHasher.hash(controller.currentState), finalHash);
    expect(controller.currentState.revision, finalRevision);
    expect(controller.acceptedActions, hasLength(actionCount));
    expect(
      presentedRevisions,
      List.generate(finalRevision, (index) => index + 1),
    );
    expect(controller.showResult.value, isTrue);
    expect(controller.isReplaying.value, isFalse);
  });

  test('emits feedback and applies game-feel settings', () {
    final feedback = _RecordingFeedback();
    final controller = LocalGameSessionController(
      _settings(),
      feedback: feedback,
    );
    final move = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;

    controller.pegTouch();
    controller.elasticStretch();
    controller.submitMove(move.start, move.end);
    controller.showInvalidPlacement();
    controller.updateFeelSettings(
      controller.feelSettings.value.copyWith(muted: true, reducedMotion: true),
    );

    expect(
      feedback.events,
      containsAllInOrder([
        'pegTouch',
        'elasticStretch',
        'elasticSnap',
        'turnChange',
        'invalidMove',
        'settings',
      ]),
    );
    expect(controller.feelSettings.value.muted, isTrue);
    expect(controller.feelSettings.value.reducedMotion, isTrue);
  });

  test('preserves shared feedback when a game session closes', () {
    final feedback = _RecordingFeedback();
    final controller = LocalGameSessionController(
      _settings(),
      feedback: feedback,
      disposeFeedbackOnClose: false,
    );

    controller.onClose();

    expect(feedback.events, isNot(contains('dispose')));
  });

  test('runs a bot turn after an accepted human move', () async {
    final controller = LocalGameSessionController(
      _mixedSettings(),
      botMoveProvider: const _FirstLegalBot(),
      initialFeelSettings: GameFeelSettings(reducedMotion: true),
    );
    final humanMove = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;

    controller.submitMove(humanMove.start, humanMove.end);
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentState.revision, 2);
    expect(
      controller.currentState.currentPlayer.controllerType,
      PlayerControllerType.human,
    );
    expect(controller.isBotThinking.value, isFalse);
    expect(controller.lastBotDecision.value, isNotNull);
    expect(controller.acceptedActions, hasLength(2));
  });

  test('discards a stale bot result after restart', () async {
    final provider = _ControllableBot();
    final controller = LocalGameSessionController(
      _mixedSettings(),
      botMoveProvider: provider,
    );
    final humanMove = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;

    controller.submitMove(humanMove.start, humanMove.end);
    expect(controller.isBotThinking.value, isTrue);
    controller.restart();
    provider.complete();
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentState.revision, 0);
    expect(controller.acceptedActions, isEmpty);
    expect(controller.isBotThinking.value, isTrue);
    provider.complete();
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentState.revision, 1);
    expect(controller.isBotThinking.value, isFalse);
  });

  test('bot-vs-bot debug match completes autonomously', () async {
    final controller = LocalGameSessionController(
      _allBotSettings(),
      botMoveProvider: const _FirstLegalBot(),
      initialFeelSettings: GameFeelSettings(reducedMotion: true),
    );

    controller.startAutomatedTurnIfNeeded();
    var guard = 0;
    while (!controller.currentState.isGameOver && guard < 30) {
      await Future<void>.delayed(Duration.zero);
      guard++;
    }

    expect(controller.currentState.isGameOver, isTrue);
    expect(controller.acceptedActions, isNotEmpty);
    expect(controller.isBotThinking.value, isFalse);
  });

  test('pass-and-play blocks the next human until handoff confirmation', () {
    final controller = LocalGameSessionController(
      _settings(),
      enablePassAndPlayHandoffs: true,
    );
    final first = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;
    controller.submitMove(first.start, first.end);

    expect(controller.awaitingHandoff.value, isTrue);
    final second = controller.engine.validator
        .legalMoves(controller.currentState)
        .first;
    expect(controller.submitMove(second.start, second.end), isNull);

    controller.confirmHandoff();
    expect(controller.awaitingHandoff.value, isFalse);
    expect(
      controller.submitMove(second.start, second.end)?.wasAccepted,
      isTrue,
    );
  });
}

GameSettings _settings() {
  return GameSettings(
    matchId: 'local-controller-test',
    boardSize: BoardSize.fromPreset(BoardSizePreset.classic),
    ruleset: Ruleset.classic,
    players: [
      PlayerConfiguration(
        id: 'p1',
        displayName: 'Player 1',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'p2',
        displayName: 'Player 2',
        controllerType: PlayerControllerType.human,
      ),
    ],
    seed: 42,
  );
}

GameSettings _mixedSettings() {
  return GameSettings(
    matchId: 'mixed-controller-test',
    boardSize: BoardSize.fromPreset(BoardSizePreset.small),
    ruleset: Ruleset.custom,
    players: [
      PlayerConfiguration(
        id: 'human',
        displayName: 'Human',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'bot',
        displayName: 'Bot',
        controllerType: PlayerControllerType.bot,
        botSettings: BotSettings(
          difficulty: BotDifficulty.easy,
          deterministic: true,
        ),
      ),
    ],
    seed: 84,
  );
}

GameSettings _allBotSettings() {
  return GameSettings(
    matchId: 'all-bot-controller-test',
    boardSize: BoardSize.fromPreset(BoardSizePreset.small),
    ruleset: Ruleset.custom,
    players: [
      for (var index = 0; index < 2; index++)
        PlayerConfiguration(
          id: 'bot-$index',
          displayName: 'Bot ${index + 1}',
          controllerType: PlayerControllerType.bot,
          botSettings: BotSettings(
            difficulty: BotDifficulty.beginner,
            deterministic: true,
            seedOffset: index,
          ),
        ),
    ],
    seed: 19,
  );
}

GameState _playFirstLegalMatch(GameSettings settings) {
  final engine = GameEngine(settings);
  var state = engine.createInitialState(settings);
  var actionIndex = 0;
  while (!state.isGameOver) {
    final move = engine.validator.legalMoves(state).first;
    final transition = engine.submitMove(
      state,
      SubmitMoveAction(
        actionId: 'simulation:${actionIndex++}',
        playerId: state.currentPlayer.id,
        expectedRevision: state.revision,
        start: move.start,
        end: move.end,
      ),
    );
    state = transition.state;
  }
  return state;
}

class _RecordingFeedback implements GameFeedback {
  final List<String> events = [];

  @override
  Future<void> initialize(GameFeelSettings settings) async {
    events.add('initialize');
  }

  @override
  Future<void> updateSettings(GameFeelSettings settings) async {
    events.add('settings');
  }

  @override
  Future<void> pegTouch() async {
    events.add('pegTouch');
  }

  @override
  Future<void> elasticStretch() async {
    events.add('elasticStretch');
  }

  @override
  Future<void> elasticSnap() async {
    events.add('elasticSnap');
  }

  @override
  Future<void> invalidMove() async {
    events.add('invalidMove');
  }

  @override
  Future<void> capture(int count) async {
    events.add('capture:$count');
  }

  @override
  Future<void> turnChange() async {
    events.add('turnChange');
  }

  @override
  Future<void> buttonPress() async {
    events.add('buttonPress');
  }

  @override
  Future<void> playerJoin() async {
    events.add('playerJoin');
  }

  @override
  Future<void> countdown() async {
    events.add('countdown');
  }

  @override
  Future<void> victory() async {
    events.add('victory');
  }

  @override
  Future<void> defeat() async {
    events.add('defeat');
  }

  @override
  Future<void> draw() async {
    events.add('draw');
  }

  @override
  Future<void> matchEnd(MatchResult result) async {
    events.add(result.isTie ? 'draw' : 'victory');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

class _FirstLegalBot implements BotMoveProvider {
  const _FirstLegalBot();

  @override
  Future<BotDecision> chooseMove(GameState state, BotSettings settings) async {
    final move = GameEngine(state.settings).validator.legalMoves(state).first;
    return BotDecision(
      move: move,
      difficulty: settings.difficulty,
      estimatedValue: 1,
      nodesVisited: 1,
      completedDepth: 1,
      elapsedMilliseconds: 0,
    );
  }
}

class _ControllableBot implements BotMoveProvider {
  final _pending =
      <
        ({
          Completer<BotDecision> completer,
          GameState state,
          BotSettings settings,
        })
      >[];

  @override
  Future<BotDecision> chooseMove(GameState state, BotSettings settings) {
    final completer = Completer<BotDecision>();
    _pending.add((completer: completer, state: state, settings: settings));
    return completer.future;
  }

  void complete() {
    final request = _pending.removeAt(0);
    final move = GameEngine(
      request.state.settings,
    ).validator.legalMoves(request.state).first;
    request.completer.complete(
      BotDecision(
        move: move,
        difficulty: request.settings.difficulty,
        estimatedValue: 1,
        nodesVisited: 1,
        completedDepth: 1,
        elapsedMilliseconds: 0,
      ),
    );
  }
}
