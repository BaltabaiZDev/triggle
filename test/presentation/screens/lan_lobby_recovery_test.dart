import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/theme/trigrid_theme.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/lan/lan_lobby_screen.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('closed lobby has a working exit instead of stale room controls', (
    tester,
  ) async {
    Get.put<GameFeedback>(const NoopGameFeedback());
    final host = (await tester.runAsync(
      () => LanHostServer.start(
        hostName: 'Host',
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
        advertisedAddress: '127.0.0.1',
      ),
    ))!;
    final guest = (await tester.runAsync(
      () => LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        roomCode: host.lobby.roomCode,
        playerName: 'Guest',
      ),
    ))!;
    addTearDown(() async {
      await guest.close();
      await host.close();
    });
    await tester.pumpWidget(
      GetMaterialApp(
        theme: TriGridTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('Lobby parent')),
      ),
    );
    await tester.pumpAndSettle();
    Get.to<void>(() => LanLobbyScreen(client: guest));
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsOneWidget);
    await tester.runAsync(() async {
      final closed = guest.statusChanges.firstWhere(
        (status) => status == LanConnectionStatus.closed,
      );
      await host.close();
      await closed.timeout(const Duration(seconds: 3));
    });
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsNothing);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    final exit = find.byIcon(Icons.home_rounded);
    await tester.runAsync(() async {
      // Double tap must not pop the parent route while shutdown is awaiting IO.
      await tester.tap(exit);
      await tester.tap(exit);
      await guest.statusChanges.drain<void>().timeout(
        const Duration(seconds: 3),
      );
    });
    // Socket cleanup completes on the real event loop, then navigation awaits
    // the frame that installs PopScope's new canPop value.
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<PopScope>(
            find.byWidgetPredicate((widget) => widget is PopScope),
          )
          .map((widget) => widget.canPop),
      everyElement(isTrue),
      reason: 'Socket cleanup must finish and enable route exit.',
    );
    expect(
      find.text('Lobby parent'),
      findsOneWidget,
      reason:
          'route=${Get.currentRoute}; canPop=${Get.key.currentState?.canPop()}; texts=${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).toList()}',
    );
    expect(find.byType(LanLobbyScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
