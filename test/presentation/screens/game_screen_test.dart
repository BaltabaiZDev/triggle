import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/theme/trigrid_theme.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/lan_game_session_controller.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('shows terminal results and restarts the same local setup', (
    tester,
  ) async {
    final settings = GameSettings(
      matchId: 'game-screen-result-test',
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
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
      seed: 9,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: TriGridTheme.light,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: GameScreen(
          settings: settings,
          feedback: const NoopGameFeedback(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final session = Get.find<LocalGameSessionController>(tag: settings.matchId);
    while (!session.currentState.isGameOver) {
      final move = session.engine.validator
          .legalMoves(session.currentState)
          .first;
      session.submitMove(move.start, move.end);
    }
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('Match complete'), findsOneWidget);
    expect(find.text('Final scores'), findsNothing);
    expect(find.byTooltip('Restart'), findsOneWidget);
    expect(find.byKey(const Key('match-result-surface')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('match-result-surface'))),
      tester.getSize(find.byType(Scaffold).first),
    );
    expect(find.byTooltip('Pause').hitTestable(), findsNothing);
    expect(find.byTooltip('Reset camera').hitTestable(), findsNothing);
    expect(find.byTooltip('Restart').hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip('Restart'));
    await tester.pump();

    expect(session.currentState.revision, 0);
    expect(find.text('Match complete'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'app lifecycle reconnects an interrupted LAN session from memory',
    (tester) async {
      final host = (await tester.runAsync(
        () => LanHostServer.start(
          hostName: 'Host',
          port: 0,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddress: InternetAddress.loopbackIPv4.address,
          boardSize: BoardSize.fromPreset(BoardSizePreset.small),
          ruleset: Ruleset.custom,
        ),
      ))!;
      LanClientConnection? hostClient;
      LanClientConnection? guestClient;
      addTearDown(() async {
        await hostClient?.close();
        await guestClient?.close();
        await host.close();
      });

      final connectedHostClient = (await tester.runAsync(
        () => LanClientConnection.connect(
          websocketUrl: host.loopbackWebsocketUrl,
          playerName: 'Host',
          roomCode: host.lobby.roomCode,
          sessionToken: host.hostSessionToken,
        ),
      ))!;
      hostClient = connectedHostClient;
      final connectedGuestClient = (await tester.runAsync(
        () => LanClientConnection.connect(
          websocketUrl: host.loopbackWebsocketUrl,
          playerName: 'Guest',
          roomCode: host.lobby.roomCode,
        ),
      ))!;
      guestClient = connectedGuestClient;
      await tester.runAsync(() async {
        final canStart = host.lobbyChanges.firstWhere(
          (lobby) => lobby.canStart,
        );
        connectedGuestClient.setReady(true);
        await canStart.timeout(const Duration(seconds: 3));
        final hostStarted = connectedHostClient.messages.firstWhere(
          (message) => message.type == LanMessageType.matchStarted,
        );
        final guestStarted = connectedGuestClient.messages.firstWhere(
          (message) => message.type == LanMessageType.matchStarted,
        );
        connectedHostClient.startMatch();
        await Future.wait([
          hostStarted.timeout(const Duration(seconds: 3)),
          guestStarted.timeout(const Duration(seconds: 3)),
        ]);
      });

      final originalClient = connectedHostClient;
      final session = LanGameSessionController(
        client: originalClient,
        feedback: const NoopGameFeedback(),
        disposeFeedbackOnClose: false,
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: TriGridTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: GameScreen(
            settings: originalClient.latestGameState!.settings,
            session: session,
            feedback: const NoopGameFeedback(),
            persistMatch: false,
            enablePassAndPlayHandoffs: false,
          ),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      var lifecycleTriggeredReconnect = false;
      final reconnected = await tester.runAsync(() async {
        await originalClient.close();
        // close() deliberately leaves a room. Model a transient transport loss
        // explicitly here so foreground recovery does not inherit that terminal
        // status; host-ended sessions must never reconnect.
        session.networkErrorCode.value = null;
        session.connectionStatus.value = LanConnectionStatus.disconnected;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        lifecycleTriggeredReconnect =
            session.isReconnecting.value &&
            session.connectionStatus.value == LanConnectionStatus.reconnecting;
        return _waitUntilAsync(
          () =>
              session.connectionStatus.value == LanConnectionStatus.connected &&
              !identical(session.client, originalClient),
        );
      });
      expect(lifecycleTriggeredReconnect, isTrue);
      expect(
        reconnected,
        isTrue,
        reason: 'Timed out waiting for foreground token reconnect.',
      );
      await tester.pump();

      expect(session.client.playerId, originalClient.playerId);
      expect(session.client.sessionToken, originalClient.sessionToken);
      expect(
        session.client.latestStateHash,
        GameStateHasher.hash(host.gameState!),
      );
      expect(session.networkErrorCode.value, isNull);

      await tester.runAsync(() async {
        await session.client.close().timeout(const Duration(seconds: 2));
        await originalClient.close().timeout(const Duration(seconds: 2));
        await connectedGuestClient.close().timeout(const Duration(seconds: 2));
        await host.close().timeout(const Duration(seconds: 2));
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}

Future<bool> _waitUntilAsync(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return predicate();
}
