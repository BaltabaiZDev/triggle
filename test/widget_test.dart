import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/trigrid_app.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('uses Kazakh when the device language is Kazakh', (tester) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('kk')];

    await tester.pumpWidget(TriGridApp(repository: MemoryTriGridRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Бір телефонда ойнау'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.binding.platformDispatcher.clearLocalesTestValue();
    await tester.pump();
  });

  testWidgets('opens a configurable local match and pause overlay', (
    tester,
  ) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.pumpWidget(TriGridApp(repository: MemoryTriGridRepository()));
    await tester.pumpAndSettle();

    expect(find.text('TriGrid'), findsOneWidget);
    expect(find.text('Play on one phone'), findsOneWidget);

    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();

    expect(find.text('Local game'), findsOneWidget);
    expect(find.text('Players'), findsOneWidget);
    expect(find.text('Game board'), findsOneWidget);
    expect(find.text('Classic rules'), findsOneWidget);

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.ensureVisible(find.text('Start match'));
    await tester.tap(find.text('Start match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Player 1'), findsOneWidget);
    expect(find.byTooltip('Show a legal move'), findsNothing);
    expect(find.byTooltip('Move board'), findsOneWidget);
    expect(find.byTooltip('Reset camera'), findsOneWidget);
    expect(find.byTooltip('Debug diagnostics'), findsNothing);

    final localGameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
      find.byWidgetPredicate(
        (widget) => widget is GameWidget<TriGridFlameGame>,
      ),
    );
    final localSession = localGameWidget.game!.session;
    final firstMove = localSession.engine.validator
        .legalMoves(localSession.currentState)
        .first;
    localSession.submitMove(firstMove.start, firstMove.end);
    await tester.pump();
    expect(find.text('Pass the device'), findsOneWidget);
    expect(find.text('I’m ready'), findsOneWidget);
    final handoffSurface = find.byKey(const Key('private-handoff-surface'));
    expect(handoffSurface, findsOneWidget);
    expect(
      tester.getSize(handoffSurface),
      tester.getSize(find.byType(Scaffold).last),
    );
    expect(find.byTooltip('Pause').hitTestable(), findsNothing);
    expect(find.byTooltip('Reset camera').hitTestable(), findsNothing);
    await tester.tap(find.text('I’m ready'));
    await tester.pump();
    expect(handoffSurface, findsNothing);
    expect(find.byTooltip('Pause').hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Game paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('Game paused'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('configures a mixed human and bot local match', (tester) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.pumpWidget(TriGridApp(repository: MemoryTriGridRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    final secondSeat = find.widgetWithText(SwitchListTile, 'Player 2');
    expect(secondSeat, findsOneWidget);
    await tester.tap(secondSeat);
    await tester.pump();

    expect(find.text('Bot player'), findsOneWidget);
    expect(find.text('Bot difficulty'), findsOneWidget);
    expect(find.text('Bot personality'), findsNothing);
    await tester.ensureVisible(find.text('Start match'));
    await tester.tap(find.text('Start match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
      find.byWidgetPredicate(
        (widget) => widget is GameWidget<TriGridFlameGame>,
      ),
    );
    expect(
      gameWidget.game!.session.settings.players.first.controllerType,
      PlayerControllerType.human,
    );
    expect(
      gameWidget.game!.session.settings.players[1].controllerType,
      PlayerControllerType.bot,
    );
    expect(
      gameWidget.game!.session.settings.players[1].botSettings?.difficulty,
      BotDifficulty.normal,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens LAN create and join flows from the main menu', (
    tester,
  ) async {
    await tester.pumpWidget(TriGridApp(repository: MemoryTriGridRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local network'));
    await tester.pumpAndSettle();
    expect(find.text('LAN multiplayer'), findsOneWidget);
    expect(find.text('Create a game'), findsOneWidget);
    expect(find.text('Join a game'), findsOneWidget);

    await tester.tap(find.text('Create a game'));
    await tester.pumpAndSettle();
    expect(find.text('Create LAN game'), findsOneWidget);
    expect(find.text('Player name'), findsOneWidget);
    expect(find.text('Room name'), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join a game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Host address'), findsOneWidget);
    expect(find.text('Room code'), findsWidgets);
    expect(find.text('Port'), findsNothing);
    expect(find.text('Connect'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens every product surface from the expanded main menu', (
    tester,
  ) async {
    await tester.pumpWidget(TriGridApp(repository: MemoryTriGridRepository()));
    await tester.pumpAndSettle();

    Future<void> openAndReturn(String menuLabel, String expectedText) async {
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      final menuItem = find.text(menuLabel).last;
      await tester.tap(menuItem);
      await tester.pumpAndSettle();
      expect(find.text(expectedText), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Solo vs bots'));
    await tester.pumpAndSettle();
    expect(find.text('Solo game'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openAndReturn('Tutorial', 'Stretch across four pegs');
    await openAndReturn('Rules', 'Keep it connected');
    await openAndReturn('Settings', 'Player & language');
    await openAndReturn('Statistics', 'Local matches');
    await openAndReturn('Replays', 'No saved replays');
    await openAndReturn('Bot strengths', 'Bot strengths');
    await openAndReturn('About', 'Privacy');
  });

  testWidgets('continues a verified local snapshot at the saved revision', (
    tester,
  ) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    final snapshot = _savedSnapshot();
    final repository = MemoryTriGridRepository(
      TriGridData.defaults().copyWith(localSnapshot: snapshot),
    );
    await tester.pumpWidget(TriGridApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
      find.byWidgetPredicate(
        (widget) => widget is GameWidget<TriGridFlameGame>,
      ),
    );
    expect(gameWidget.game!.session.currentState.revision, 1);
    expect(
      GameStateHasher.hash(gameWidget.game!.session.currentState),
      snapshot.stateHash,
    );
    expect(find.text('Pass the device'), findsOneWidget);
  });

  testWidgets('optional move confirmation gates the actual board request', (
    tester,
  ) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    final preferences = AppPreferences.defaults().copyWith(confirmMoves: true);
    final repository = MemoryTriGridRepository(
      TriGridData.defaults().copyWith(preferences: preferences),
    );
    await tester.pumpWidget(TriGridApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start match'));
    await tester.tap(find.text('Start match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
      find.byWidgetPredicate(
        (widget) => widget is GameWidget<TriGridFlameGame>,
      ),
    );
    final game = gameWidget.game!;
    final move = game.session.engine.validator
        .legalMoves(game.session.currentState)
        .first;
    game.onMoveRequested!(move.start, move.end);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Place this band?'), findsOneWidget);
    expect(game.session.currentState.revision, 0);
    await tester.tap(find.text('Place band'));
    await tester.pump();
    expect(game.session.currentState.revision, 1);
  });
}

SavedMatchSnapshot _savedSnapshot() {
  final settings = GameSettings(
    matchId: 'widget-saved-match',
    boardSize: BoardSize.fromPreset(BoardSizePreset.small),
    ruleset: Ruleset.custom,
    players: [
      PlayerConfiguration(
        id: 'saved-1',
        displayName: 'Player 1',
        controllerType: PlayerControllerType.human,
      ),
      PlayerConfiguration(
        id: 'saved-2',
        displayName: 'Player 2',
        controllerType: PlayerControllerType.human,
      ),
    ],
    seed: 17,
  );
  final engine = GameEngine(settings);
  final initial = engine.createInitialState(settings);
  final move = engine.validator.legalMoves(initial).first;
  final action = SubmitMoveAction(
    actionId: 'widget-saved-action',
    playerId: initial.currentPlayer.id,
    expectedRevision: 0,
    start: move.start,
    end: move.end,
  );
  final state = engine.submitMove(initial, action).state;
  return SavedMatchSnapshot(
    state: state,
    actions: [action],
    stateHash: GameStateHasher.hash(state),
    savedAtUtc: DateTime.utc(2026, 7, 30),
    passAndPlayHandoffs: true,
  );
}
