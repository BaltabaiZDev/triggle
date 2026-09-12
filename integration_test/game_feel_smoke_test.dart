import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trigrid/app/trigrid_app.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/presentation/screens/main_menu/main_menu_screen.dart';

/// Physical smoke/measurement with real audio enabled; not a thermal soak test.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('game-feel phone smoke with real audio and finite rewards', (
    tester,
  ) async {
    expect(kProfileMode, isTrue);
    final repository = MemoryTriGridRepository(
      TriGridData.defaults().copyWith(
        preferences: AppPreferences.defaults().copyWith(localeCode: 'en'),
      ),
    );
    await tester.pumpWidget(TriGridApp(repository: repository));
    for (
      var i = 0;
      i < 20 && find.text('Play on one phone').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Play on one phone'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Start match'));
    await tester.tap(find.byTooltip('Start match'));
    await tester.pump(const Duration(milliseconds: 700));
    final game = tester
        .widget<GameWidget<TriGridFlameGame>>(
          find.byWidgetPredicate((w) => w is GameWidget<TriGridFlameGame>),
        )
        .game!;
    final session = game.session;
    final timings = <FrameTiming>[];
    void record(List<FrameTiming> frames) => timings.addAll(frames);
    await tester.pump(const Duration(seconds: 1));
    binding.addTimingsCallback(record);
    var moves = 0;
    try {
      while (!session.currentState.isGameOver && moves < 50) {
        final move = session.engine.validator
            .legalMoves(session.currentState)
            .first;
        session.submitMove(move.start, move.end);
        if (session.awaitingHandoff.value) session.confirmHandoff();
        moves++;
        for (var frame = 0; frame < 24; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
      for (var frame = 0; frame < 220; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    } finally {
      binding.removeTimingsCallback(record);
    }
    expect(session.currentState.isGameOver, isTrue);
    expect(find.text('Match complete'), findsOneWidget);
    expect(timings, isNotEmpty);
    double percentile(Iterable<int> values, double p) {
      final sorted = values.toList()..sort();
      return sorted[((sorted.length - 1) * p).round()] / 1000;
    }

    binding.reportData = {
      'acceptanceBuildId': 'game-feel-2026-09-08',
      'gameFeelSmoke': {
        'profileMode': kProfileMode,
        'realAudio': true,
        'moves': moves,
        'frames': timings.length,
        'buildP90Ms': percentile(
          timings.map((f) => f.buildDuration.inMicroseconds),
          .9,
        ),
        'rasterP90Ms': percentile(
          timings.map((f) => f.rasterDuration.inMicroseconds),
          .9,
        ),
        'rasterP99Ms': percentile(
          timings.map((f) => f.rasterDuration.inMicroseconds),
          .99,
        ),
        'over16msRaster': timings
            .where((f) => f.rasterDuration.inMicroseconds > 16667)
            .length,
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'scope':
            'One short classic-board match; not a 120 Hz or thermal certification.',
      },
    };
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await binding.takeScreenshot('game_feel_result_phone');
    Get.offAll<void>(() => const MainMenuScreen());
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Play on one phone'), findsOneWidget);
    await binding.takeScreenshot('game_feel_menu_phone');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    Get.reset();
  });
}
