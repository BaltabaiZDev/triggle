import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';

GameSettings settings({
  String id = 'polish',
  int players = 2,
  int version = 2,
  BoardSizePreset preset = BoardSizePreset.small,
}) => GameSettings(
  matchId: id,
  boardSize: BoardSize.fromPreset(preset),
  ruleset: preset == BoardSizePreset.classic ? Ruleset.classic : Ruleset.custom,
  players: [
    for (var i = 0; i < players; i++)
      PlayerConfiguration(
        id: 'p$i',
        displayName: 'Player $i',
        controllerType: PlayerControllerType.human,
      ),
  ],
  seed: 1,
  rulesVersion: version,
);

void move(LocalGameSessionController session) {
  final next = session.engine.validator.legalMoves(session.currentState).first;
  expect(session.submitMove(next.start, next.end)?.wasAccepted, isTrue);
}

void finish(LocalGameSessionController session) {
  var guard = 0;
  while (!session.currentState.isGameOver) {
    move(session);
    expect(++guard, lessThan(100));
  }
}

void main() {
  test('v2 increases supplies and limits small boards to two seats', () {
    expect(GameState.initial(settings()).players.first.bandsRemaining, 6);
    expect(() => settings(players: 3), throwsArgumentError);
    expect(() => settings(players: 4), throwsArgumentError);
    expect(() => settings(version: 3), throwsFormatException);
    for (final count in [2, 3, 4]) {
      final state = GameState.initial(
        settings(players: count, preset: BoardSizePreset.classic),
      );
      expect(state.players.first.bandsRemaining, count == 2 ? 14 : 16);
    }
  });

  test('legacy v1 supplies, settings JSON and replay hashes are preserved', () {
    final legacy = settings(players: 4, version: 1);
    final json = legacy.toJson();
    expect(json, isNot(contains('startingPlayerIndex')));
    expect(GameSettings.fromJson(json).toJson(), json);
    expect(
      () => GameSettings.fromJson({...json, 'startingPlayerIndex': 1}),
      throwsArgumentError,
    );
    expect(GameState.initial(legacy).players.first.bandsRemaining, 3);
    final session = LocalGameSessionController(legacy);
    addTearDown(session.onClose);
    finish(session);
    final replay = GameReplay(
      settings: legacy,
      actions: session.acceptedActions,
      expectedFinalHash: GameStateHasher.hash(session.currentState),
    );
    expect(
      ReplayRunner.run(GameReplay.fromJson(replay.toJson())).finalHash,
      GameStateHasher.hash(session.currentState),
    );
  });

  test(
    'new rounds have independent identities and alternate the first seat',
    () {
      final session = LocalGameSessionController(settings());
      addTearDown(session.onClose);
      final firstId = session.settings.matchId;
      session.restart();
      expect(session.settings.matchId, isNot(firstId));
      expect(session.currentState.currentPlayerIndex, 1);
      move(session);
      expect(
        ReplayRunner.run(
          GameReplay(
            settings: session.settings,
            actions: session.acceptedActions,
          ),
        ).finalHash,
        GameStateHasher.hash(session.currentState),
      );
      session.restart();
      expect(session.currentState.currentPlayerIndex, 0);
    },
  );

  test(
    'completed games never become resumable; older callbacks preserve a new round',
    () async {
      final repository = MemoryTriGridRepository();
      final app = AppController(repository);
      await app.initialize();
      final session = LocalGameSessionController(settings());
      addTearDown(session.onClose);
      await app.saveLocalSnapshot(
        state: session.currentState,
        actions: [],
        passAndPlayHandoffs: false,
      );
      expect(
        app.localSnapshot.value,
        isNull,
        reason: 'An untouched setup is not a match to continue.',
      );
      move(session);
      await app.saveLocalSnapshot(
        state: session.currentState,
        actions: session.acceptedActions,
        passAndPlayHandoffs: false,
      );
      expect(app.localSnapshot.value, isNotNull);
      finish(session);
      final completed = session.currentState;
      final completedActions = session.acceptedActions;
      await app.recordCompletedMatch(
        mode: MatchMode.local,
        state: completed,
        perspectivePlayerId: 'p0',
        actions: completedActions,
        largestMultiCapture: 1,
      );
      expect(app.localSnapshot.value, isNull);
      session.restart();
      move(session);
      await app.saveLocalSnapshot(
        state: session.currentState,
        actions: session.acceptedActions,
        passAndPlayHandoffs: false,
      );
      await app.recordCompletedMatch(
        mode: MatchMode.local,
        state: completed,
        perspectivePlayerId: 'p0',
        actions: completedActions,
        largestMultiCapture: 1,
      );
      expect(
        app.localSnapshot.value!.state.settings.matchId,
        session.settings.matchId,
      );
      finish(session);
      await app.recordCompletedMatch(
        mode: MatchMode.local,
        state: session.currentState,
        perspectivePlayerId: 'p0',
        actions: session.acceptedActions,
        largestMultiCapture: 1,
      );
      final reloaded = AppController(repository);
      await reloaded.initialize();
      expect(reloaded.localSnapshot.value, isNull);
      expect(reloaded.statistics.value.local.matchesPlayed, 2);
    },
  );

  testWidgets(
    'final move stays visible; repeated snapshots do not skip or reset the delay',
    (tester) async {
      final session = LocalGameSessionController(settings());
      session.onAcceptedTransition = (_) {};
      finish(session);
      expect(session.showResult.value, isFalse);
      await tester.pump(const Duration(milliseconds: 1000));
      session.presentResultWhenReady();
      expect(session.showResult.value, isFalse);
      await tester.pump(const Duration(milliseconds: 950));
      expect(session.showResult.value, isTrue);
      session.restart();
      await tester.pump(const Duration(seconds: 3));
      expect(session.showResult.value, isFalse);
      session.onClose();
    },
  );

  testWidgets('zoomed-out endpoints keep a 48px touch target and 36px ring', (
    tester,
  ) async {
    final session = LocalGameSessionController(
      settings(preset: BoardSizePreset.huge),
    );
    final game = TriGridFlameGame(session: session);
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    game.zoomAt(const Offset(400, 300), .01);
    expect(
      game.inputTargetRadius * game.camera.viewfinder.zoom,
      closeTo(24, .001),
    );
    expect(
      game.endpointRingRadius * game.camera.viewfinder.zoom,
      closeTo(18, .001),
    );
    final first = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final start = game.camera.localToGlobal(
      game.projection.toWorld(first.start),
    );
    game.handleTap(Offset(start.x, start.y));
    final endpoints =
        game.validEnds
            .map(
              (end) => game.camera.localToGlobal(game.projection.toWorld(end)),
            )
            .toList()
          ..sort((a, b) => b.y.compareTo(a.y));
    final bottom = endpoints.first;
    game.handleTap(Offset(bottom.x, bottom.y + 20));
    expect(session.currentState.revision, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    session.onClose();
  });
}
