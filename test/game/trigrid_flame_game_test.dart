import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

void main() {
  testWidgets('tap and drag input submit legal moves through the engine', (
    tester,
  ) async {
    final session = LocalGameSessionController(_settings());
    final game = TriGridFlameGame(session: session);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 700, height: 700, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final firstMove = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final firstStart = game.camera.localToGlobal(
      game.projection.toWorld(firstMove.start),
    );
    final firstEnd = game.camera.localToGlobal(
      game.projection.toWorld(firstMove.end),
    );

    game.handleTap(Offset(firstStart.x, firstStart.y));
    expect(game.selectedStart, firstMove.start);
    expect(game.validEnds, contains(firstMove.end));
    game.handleTap(Offset(firstEnd.x, firstEnd.y));
    expect(session.currentState.revision, 1);
    expect(game.selectedStart, isNull);

    final secondMove = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final secondStart = game.camera.localToGlobal(
      game.projection.toWorld(secondMove.start),
    );
    final secondEnd = game.camera.localToGlobal(
      game.projection.toWorld(secondMove.end),
    );
    final startOffset = Offset(secondStart.x, secondStart.y);
    final endOffset = Offset(secondEnd.x, secondEnd.y);

    game.beginScale(
      ScaleStartDetails(
        focalPoint: startOffset,
        localFocalPoint: startOffset,
        pointerCount: 1,
      ),
    );
    game.updateScale(
      ScaleUpdateDetails(
        focalPoint: endOffset,
        localFocalPoint: endOffset,
        pointerCount: 1,
        scale: 1,
        focalPointDelta: endOffset - startOffset,
      ),
    );
    game.endScale(ScaleEndDetails());

    expect(session.currentState.revision, 2);
  });

  testWidgets('camera pans, zooms, clamps, and resets', (tester) async {
    final session = LocalGameSessionController(_settings());
    final game = TriGridFlameGame(session: session);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 640, height: 480, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final initialPosition = game.camera.viewfinder.position.clone();
    final initialZoom = game.camera.viewfinder.zoom;

    game.beginScale(
      ScaleStartDetails(
        focalPoint: Offset(4, 4),
        localFocalPoint: Offset(4, 4),
        pointerCount: 1,
      ),
    );
    game.updateScale(
      ScaleUpdateDetails(
        focalPoint: Offset(90, 40),
        localFocalPoint: Offset(90, 40),
        pointerCount: 1,
        focalPointDelta: Offset(86, 36),
      ),
    );
    game.endScale(ScaleEndDetails());
    expect(game.camera.viewfinder.position, initialPosition);

    game.panByCanvasDelta(const Offset(80, 30));
    expect(game.camera.viewfinder.position, isNot(initialPosition));

    game.zoomAt(const Offset(320, 240), initialZoom * 1.8);
    expect(game.camera.viewfinder.zoom, greaterThan(initialZoom));

    game.resetCamera();
    expect(game.camera.viewfinder.position.x, closeTo(0, 0.0001));
    expect(game.camera.viewfinder.position.y, closeTo(0, 0.0001));
    expect(game.camera.viewfinder.zoom, closeTo(initialZoom, 0.0001));
  });

  testWidgets('idle board sleeps and wakes immediately for input', (
    tester,
  ) async {
    final session = LocalGameSessionController(_settings());
    final game = TriGridFlameGame(session: session);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 640, height: 640, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(game.paused, isTrue);

    final move = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final start = game.camera.localToGlobal(
      game.projection.toWorld(move.start),
    );
    game.handleTap(Offset(start.x, start.y));

    expect(game.paused, isFalse);
    expect(game.selectedStart, move.start);

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    expect(game.paused, isTrue);
  });

  testWidgets('accepted transitions drive band and capture timelines', (
    tester,
  ) async {
    final session = LocalGameSessionController(_settings());
    final game = TriGridFlameGame(session: session);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(width: 640, height: 640, child: GameWidget(game: game)),
      ),
    );
    await tester.pump();

    final firstMove = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final firstTransition = session.submitMove(firstMove.start, firstMove.end)!;
    expect(
      game.bandPlacementProgress(firstTransition.action.actionId),
      closeTo(0, 0.0001),
    );
    game.update(1);
    expect(
      game.bandPlacementProgress(firstTransition.action.actionId),
      closeTo(1, 0.0001),
    );

    GameTransition? captureTransition;
    while (!session.currentState.isGameOver && captureTransition == null) {
      for (final move in session.engine.validator.legalMoves(
        session.currentState,
      )) {
        final transition = session.submitMove(move.start, move.end)!;
        if (transition.validation.newlyCapturedTriangles.isNotEmpty) {
          captureTransition = transition;
          break;
        }
        break;
      }
    }

    expect(captureTransition, isNotNull);
    final triangleId =
        captureTransition!.validation.newlyCapturedTriangles.first.id;
    expect(game.captureProgress(triangleId), 0);
    expect(game.markerDropProgress(triangleId), 0);
    game.update(2);
    expect(game.captureProgress(triangleId), 1);
    expect(game.markerDropProgress(triangleId), 1);
  });

  test('reduced motion makes transition presentation immediate', () {
    final session = LocalGameSessionController(
      _settings(),
      initialFeelSettings: GameFeelSettings(reducedMotion: true),
    );
    final game = TriGridFlameGame(session: session);
    final move = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    final transition = session.submitMove(move.start, move.end)!;

    expect(game.bandPlacementProgress(transition.action.actionId), 1);
    expect(game.hasActiveMoveAnimation, isFalse);
  });
}

GameSettings _settings() {
  return GameSettings(
    matchId: 'flame-game-test',
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
    seed: 7,
  );
}
