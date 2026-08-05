import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';

void main() {
  test('versioned app preferences and aggregate data round-trip', () {
    final preferences = AppPreferences.defaults().copyWith(
      playerName: 'Aruzhan',
      localeCode: 'kk',
      themePreference: AppThemePreference.dark,
      highContrast: true,
      confirmMoves: true,
    );
    final data = TriGridData.defaults().copyWith(preferences: preferences);

    final restored = TriGridData.fromJson(data.toJson());

    expect(restored.preferences.playerName, 'Aruzhan');
    expect(restored.preferences.localeCode, 'kk');
    expect(restored.preferences.themePreference, AppThemePreference.dark);
    expect(restored.preferences.highContrast, isTrue);
    expect(restored.preferences.confirmMoves, isTrue);
  });

  test(
    'local snapshot resumes, completion records once, and replay verifies',
    () async {
      final repository = MemoryTriGridRepository();
      final controller = AppController(repository);
      await controller.initialize();
      final settings = _settings();
      final engine = GameEngine(settings);
      var state = engine.createInitialState(settings);
      final actions = <SubmitMoveAction>[];
      var largestCapture = 0;

      final firstMove = engine.validator.legalMoves(state).first;
      final firstAction = SubmitMoveAction(
        actionId: 'persist-0',
        playerId: state.currentPlayer.id,
        expectedRevision: state.revision,
        start: firstMove.start,
        end: firstMove.end,
      );
      final firstTransition = engine.submitMove(state, firstAction);
      expect(firstTransition.wasAccepted, isTrue);
      state = firstTransition.state;
      actions.add(firstAction);
      await controller.saveLocalSnapshot(
        state: state,
        actions: actions,
        passAndPlayHandoffs: true,
      );

      final restoredController = AppController(repository);
      await restoredController.initialize();
      expect(restoredController.localSnapshot.value?.state.revision, 1);
      expect(
        restoredController.localSnapshot.value?.stateHash,
        GameStateHasher.hash(state),
      );

      while (!state.isGameOver) {
        final move = engine.validator.legalMoves(state).first;
        final action = SubmitMoveAction(
          actionId: 'persist-${actions.length}',
          playerId: state.currentPlayer.id,
          expectedRevision: state.revision,
          start: move.start,
          end: move.end,
        );
        final transition = engine.submitMove(state, action);
        expect(transition.wasAccepted, isTrue);
        if (transition.validation.newlyCapturedTriangles.length >
            largestCapture) {
          largestCapture = transition.validation.newlyCapturedTriangles.length;
        }
        state = transition.state;
        actions.add(action);
      }

      await restoredController.recordCompletedMatch(
        mode: MatchMode.local,
        state: state,
        perspectivePlayerId: state.players.first.id,
        actions: actions,
        largestMultiCapture: largestCapture,
      );
      await restoredController.recordCompletedMatch(
        mode: MatchMode.local,
        state: state,
        perspectivePlayerId: state.players.first.id,
        actions: actions,
        largestMultiCapture: largestCapture,
      );

      expect(restoredController.localSnapshot.value, isNull);
      expect(restoredController.statistics.value.local.matchesPlayed, 1);
      expect(restoredController.replays, hasLength(1));
      final replayResult = ReplayRunner.run(
        restoredController.replays.single.replay,
      );
      expect(replayResult.finalHash, GameStateHasher.hash(state));

      final afterRestart = AppController(repository);
      await afterRestart.initialize();
      expect(afterRestart.statistics.value.local.matchesPlayed, 1);
      expect(afterRestart.replays, hasLength(1));
    },
  );

  test('corrupt or mismatched local snapshots are discarded safely', () async {
    final settings = _settings();
    final state = GameEngine(settings).createInitialState(settings);
    final badSnapshot = SavedMatchSnapshot(
      state: state,
      actions: const [],
      stateHash: 'not-the-state-hash',
      savedAtUtc: DateTime.utc(2026, 7, 30),
      passAndPlayHandoffs: true,
    );
    final repository = MemoryTriGridRepository(
      TriGridData.defaults().copyWith(localSnapshot: badSnapshot),
    );

    final controller = AppController(repository);
    await controller.initialize();

    expect(controller.localSnapshot.value, isNull);
    expect(repository.data.localSnapshot, isNull);
  });

  test('last verified LAN position can be archived and restored', () async {
    final repository = MemoryTriGridRepository();
    final controller = AppController(repository);
    await controller.initialize();
    final settings = _settings();
    final state = GameEngine(settings).createInitialState(settings);

    expect(await controller.archiveLanSnapshot(state), isTrue);
    expect(controller.lanSnapshots, hasLength(1));
    expect(
      controller.lanSnapshots.single.stateHash,
      GameStateHasher.hash(state),
    );

    final restored = AppController(repository);
    await restored.initialize();
    expect(restored.lanSnapshots, hasLength(1));
    expect(restored.lanSnapshots.single.state.revision, state.revision);

    await restored.deleteLanSnapshot(settings.matchId);
    expect(restored.lanSnapshots, isEmpty);
  });

  test('statistics remain separate by mode and track bot-level records', () {
    final settings = GameSettings(
      matchId: 'bot-stat-match',
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
      players: [
        PlayerConfiguration(
          id: 'human',
          displayName: 'Human',
          controllerType: PlayerControllerType.human,
        ),
        PlayerConfiguration(
          id: 'expert',
          displayName: 'Expert',
          controllerType: PlayerControllerType.bot,
          botSettings: BotSettings(difficulty: BotDifficulty.expert),
        ),
      ],
      seed: 71,
    );
    final engine = GameEngine(settings);
    var state = engine.createInitialState(settings);
    while (!state.isGameOver) {
      final move = engine.validator.legalMoves(state).first;
      state = engine
          .submitMove(
            state,
            SubmitMoveAction(
              actionId: 'stat-${state.revision}',
              playerId: state.currentPlayer.id,
              expectedRevision: state.revision,
              start: move.start,
              end: move.end,
            ),
          )
          .state;
    }

    final local = ModeStatistics.empty().record(
      state: state,
      perspectivePlayerId: 'human',
      matchLargestMultiCapture: 2,
    );
    final aggregate = MatchStatistics.empty().copyWith(local: local);

    expect(aggregate.local.matchesPlayed, 1);
    expect(aggregate.lan.matchesPlayed, 0);
    expect(aggregate.local.botLevelRecords[BotDifficulty.expert]?.matches, 1);
    expect(aggregate.local.largestMultiCapture, 2);
  });
}

GameSettings _settings() {
  return GameSettings(
    matchId: 'persistence-match',
    boardSize: BoardSize.fromPreset(BoardSizePreset.small),
    ruleset: Ruleset.custom,
    players: [
      PlayerConfiguration(
        id: 'player-1',
        displayName: 'Player 1',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'player-2',
        displayName: 'Player 2',
        controllerType: PlayerControllerType.human,
      ),
    ],
    seed: 41,
  );
}
