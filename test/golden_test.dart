import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/trigrid_app.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'support/load_game_fonts.dart';
import 'support/atomic_golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalComparator = goldenFileComparator;
  if (originalComparator is LocalFileComparator) {
    goldenFileComparator = AtomicGoldenComparator(
      originalComparator.basedir.resolve('golden_test.dart'),
    );
  }
  tearDownAll(() => goldenFileComparator = originalComparator);
  setUpAll(loadGameFonts);
  const goldenRoot = Key('golden-root');

  tearDown(Get.reset);

  testWidgets('minimal setup in Kazakh on standard and small phones', (
    tester,
  ) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenRoot,
        child: TriGridApp(
          ambientMotion: false,
          repository: MemoryTriGridRepository(
            TriGridData.defaults().copyWith(
              preferences: AppPreferences.defaults().copyWith(localeCode: 'kk'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бір телефонда ойнау'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/local_setup_phone_kk.png'),
    );
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/local_setup_small_phone_kk.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('main menu and local game phone layouts', (tester) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenRoot,
        child: TriGridApp(
          ambientMotion: false,
          repository: MemoryTriGridRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/main_menu_phone.png'),
    );

    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Start match'));
    await tester.tap(find.byTooltip('Start match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final gameFinder = find.byWidgetPredicate(
      (widget) => widget is GameWidget<TriGridFlameGame>,
    );
    final rootRect = tester.getRect(find.byKey(goldenRoot));
    final gameRect = tester.getRect(gameFinder);
    expect(rootRect.size, const Size(430, 900));
    expect(gameRect.top, rootRect.top);
    expect(gameRect.bottom, rootRect.bottom);
    expect(gameRect.width, rootRect.width);

    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/game_screen_phone.png'),
    );

    final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(gameFinder);
    final session = gameWidget.game!.session;
    final firstMove = session.engine.validator
        .legalMoves(session.currentState)
        .first;
    session.submitMove(firstMove.start, firstMove.end);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/handoff_phone.png'),
    );
    session.confirmHandoff();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/pause_settings_phone.png'),
    );

    await tester.ensureVisible(find.byTooltip('Resume'));
    await tester.tap(find.byTooltip('Resume'));
    await tester.pump(const Duration(milliseconds: 500));

    while (!session.currentState.isGameOver) {
      final move = session.engine.validator
          .legalMoves(session.currentState)
          .first;
      session.submitMove(move.start, move.end);
      if (session.awaitingHandoff.value) {
        session.confirmHandoff();
      }
    }
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/result_phone.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('minimal supporting phone layouts', (tester) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenRoot,
        child: TriGridApp(
          ambientMotion: false,
          repository: MemoryTriGridRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/local_setup_phone.png'),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    Future<void> captureMenuPage(String label, String goldenName) async {
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(goldenRoot),
        matchesGoldenFile('goldens/$goldenName'),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await captureMenuPage('Settings', 'settings_phone.png');
    await captureMenuPage('Rules', 'rules_phone.png');

    await tester.tap(find.text('Local network'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/lan_menu_phone.png'),
    );
    await tester.tap(find.text('Join a game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/lan_join_phone.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('local game and result tablet layouts', (tester) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenRoot,
        child: TriGridApp(
          ambientMotion: false,
          repository: MemoryTriGridRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Start match'));
    await tester.tap(find.byTooltip('Start match'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final gameFinder = find.byWidgetPredicate(
      (widget) => widget is GameWidget<TriGridFlameGame>,
    );
    final rootRect = tester.getRect(find.byKey(goldenRoot));
    final gameRect = tester.getRect(gameFinder);
    expect(rootRect.size, const Size(1024, 1366));
    expect(gameRect.size, rootRect.size);

    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/game_screen_tablet.png'),
    );

    await tester.binding.setSurfaceSize(const Size(1366, 1024));
    await tester.pump(const Duration(milliseconds: 500));
    final landscapeRootRect = tester.getRect(find.byKey(goldenRoot));
    final landscapeGameRect = tester.getRect(gameFinder);
    expect(landscapeRootRect.size, const Size(1366, 1024));
    expect(landscapeGameRect.size, landscapeRootRect.size);
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/game_screen_tablet_landscape.png'),
    );

    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    await tester.pump(const Duration(milliseconds: 500));
    final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(gameFinder);
    final session = gameWidget.game!.session;
    while (!session.currentState.isGameOver) {
      final move = session.engine.validator
          .legalMoves(session.currentState)
          .first;
      session.submitMove(move.start, move.end);
      if (session.awaitingHandoff.value) {
        session.confirmHandoff();
      }
    }
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getSize(find.byKey(const Key('match-result-surface'))),
      rootRect.size,
    );
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('goldens/result_tablet.png'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
