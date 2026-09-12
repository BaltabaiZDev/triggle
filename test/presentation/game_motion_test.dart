import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

class _Feedback extends NoopGameFeedback {
  int clicks = 0;
  @override
  Future<void> buttonPress() async {
    clicks++;
  }
}

Widget _host(Widget child, {bool reduced = false, bool ambient = false}) =>
    MaterialApp(
      home: GameMotionScope(
        settings: GameFeelSettings(reducedMotion: reduced),
        ambientMotion: ambient,
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  tearDown(Get.reset);
  testWidgets('press scales immediately and never delays the native callback', (
    tester,
  ) async {
    var taps = 0;
    final feedback = _Feedback();
    Get.put<GameFeedback>(feedback);
    await tester.pumpWidget(
      _host(
        GamePress(
          child: FilledButton(
            onPressed: () => taps++,
            child: const Text('Play'),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Play')),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(GamePress),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.storage[0], lessThan(1));
    await gesture.up();
    expect(taps, 1);
    expect(feedback.clicks, 1);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('disabled and cancelled controls do not produce clicks', (
    tester,
  ) async {
    final feedback = _Feedback();
    Get.put<GameFeedback>(feedback);
    await tester.pumpWidget(
      _host(
        const GamePress(
          child: FilledButton(onPressed: null, child: Text('Disabled')),
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    expect(feedback.clicks, 0);
    await tester.pumpWidget(
      _host(
        GamePress(
          child: FilledButton(onPressed: () {}, child: const Text('Cancel')),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Cancel')),
    );
    await gesture.moveBy(const Offset(0, 60));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(feedback.clicks, 0);
  });
  testWidgets('nested buttons produce exactly one sound', (tester) async {
    final feedback = _Feedback();
    Get.put<GameFeedback>(feedback);
    await tester.pumpWidget(
      _host(
        GamePress(
          child: ListTile(
            onTap: () {},
            title: const Text('Replay'),
            trailing: GamePress(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(feedback.clicks, 1);
  });
  testWidgets('reduced motion has no press displacement or idle ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GameFloat(
          child: GamePress(
            child: FilledButton(onPressed: () {}, child: const Text('Quiet')),
          ),
        ),
        reduced: true,
        ambient: true,
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Quiet')),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(GamePress),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(transform.transform.storage[0], 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
  testWidgets('outgoing controls are inert during a crossfade', (tester) async {
    var oldTaps = 0;
    await tester.pumpWidget(
      _host(
        GameSwitcher(
          child: FilledButton(
            key: const ValueKey('old'),
            onPressed: () => oldTaps++,
            child: const Text('Old'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _host(
        const GameSwitcher(
          child: SizedBox(key: ValueKey('new'), width: 100, height: 40),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Old').hitTestable(), findsNothing);
    expect(oldTaps, 0);
    await tester.pumpAndSettle();
    expect(find.text('Old'), findsNothing);
  });
  testWidgets('celebration stops and disposes its ticker', (tester) async {
    await tester.pumpWidget(
      _host(const GameCelebration(child: SizedBox(width: 300, height: 400))),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
