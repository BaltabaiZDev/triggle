import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/presentation/controllers/lan_game_session_controller.dart';

void main() {
  test('authoritative LAN lifecycle works over loopback WebSockets', () async {
    final host = await LanHostServer.start(
      hostName: 'Host',
      port: 0,
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddress: InternetAddress.loopbackIPv4.address,
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
      botMoveProvider: const _FirstLegalBot(),
    );
    LanClientConnection? hostClient;
    LanClientConnection? guest;
    LanClientConnection? reconnectedGuest;
    LanGameSessionController? gameSession;
    addTearDown(() async {
      gameSession?.onClose();
      await hostClient?.close();
      await guest?.close();
      await reconnectedGuest?.close();
      await host.close();
    });

    hostClient = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Host',
      roomCode: host.lobby.roomCode,
      sessionToken: host.hostSessionToken,
    );
    guest = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Guest',
      roomCode: host.lobby.roomCode,
    );

    expect(hostClient.isHost, isTrue);
    expect(guest.isHost, isFalse);
    expect(host.lobby.occupiedSeatCount, 2);

    await expectLater(
      LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Intruder',
        roomCode: host.lobby.roomCode,
        sessionToken: 'not-a-valid-session-token',
      ),
      throwsA(isA<StateError>()),
    );
    expect(host.lobby.occupiedSeatCount, 2);

    final colorChanged = host.lobbyChanges.firstWhere(
      (lobby) =>
          lobby.seats
              .firstWhere((seat) => seat.playerId == guest!.playerId)
              .colorIndex ==
          2,
    );
    guest.selectColor(2);
    await colorChanged.timeout(const Duration(seconds: 3));

    final botAdded = host.lobbyChanges.firstWhere(
      (lobby) => lobby.seats[2].isBot,
    );
    hostClient.addBot(
      seatIndex: 2,
      displayName: 'Bot',
      settings: BotSettings(difficulty: BotDifficulty.normal),
    );
    await botAdded.timeout(const Duration(seconds: 3));
    final botUpdated = host.lobbyChanges.firstWhere(
      (lobby) => lobby.seats[2].botSettings?.difficulty == BotDifficulty.expert,
    );
    hostClient.updateBot(
      seatIndex: 2,
      settings: BotSettings(difficulty: BotDifficulty.expert),
    );
    await botUpdated.timeout(const Duration(seconds: 3));

    final timerUpdated = host.lobbyChanges.firstWhere(
      (lobby) => lobby.turnTimeSeconds == 30,
    );
    hostClient.updateRoom(
      boardSize: host.lobby.boardSize,
      ruleset: host.lobby.ruleset,
      turnTimeSeconds: 30,
    );
    await timerUpdated.timeout(const Duration(seconds: 3));

    final ready = host.lobbyChanges.firstWhere((lobby) => lobby.canStart);
    guest.setReady(true);
    await ready.timeout(const Duration(seconds: 3));

    final hostStarted = hostClient.messages.firstWhere(
      (message) => message.type == LanMessageType.matchStarted,
    );
    final guestStarted = guest.messages.firstWhere(
      (message) => message.type == LanMessageType.matchStarted,
    );
    hostClient.startMatch();
    await Future.wait([
      hostStarted.timeout(const Duration(seconds: 3)),
      guestStarted.timeout(const Duration(seconds: 3)),
    ]);

    final initial = host.gameState!;
    expect(initial.currentPlayer.id, hostClient.playerId);
    expect(initial.settings.turnTimeSeconds, 30);
    expect(
      initial.players
          .firstWhere((player) => player.id == guest!.playerId)
          .visualIndex,
      2,
    );
    expect(
      initial.players
          .firstWhere(
            (player) => player.controllerType == PlayerControllerType.bot,
          )
          .botSettings
          ?.difficulty,
      BotDifficulty.expert,
    );
    final move = GameEngine(
      initial.settings,
    ).validator.legalMoves(initial).first;
    gameSession = LanGameSessionController(client: hostClient);
    gameSession.onInit();
    final hostAccepted = hostClient.messages.firstWhere(
      (message) => message.type == LanMessageType.actionAccepted,
    );
    final guestAccepted = guest.messages.firstWhere(
      (message) => message.type == LanMessageType.actionAccepted,
    );
    gameSession.submitMove(move.start, move.end);
    final acceptedMessages = await Future.wait([
      hostAccepted.timeout(const Duration(seconds: 3)),
      guestAccepted.timeout(const Duration(seconds: 3)),
    ]);
    final action = SubmitMoveAction.fromJson(
      acceptedMessages.first.payload['action']! as Map<String, Object?>,
    );
    expect(host.gameState?.revision, 1);
    expect(hostClient.latestStateHash, GameStateHasher.hash(host.gameState!));
    expect(gameSession.currentState.revision, 1);
    expect(gameSession.acceptedActions, hasLength(1));

    final duplicateAccepted = hostClient.messages.firstWhere(
      (message) =>
          message.type == LanMessageType.actionAccepted &&
          (message.payload['action']! as Map<String, Object?>)['actionId'] ==
              action.actionId,
    );
    hostClient.submitMove(action);
    await duplicateAccepted.timeout(const Duration(seconds: 3));
    expect(host.gameState?.revision, 1);
    expect(gameSession.acceptedActions, hasLength(1));
    expect(gameSession.networkErrorCode.value, isNull);

    final invalid = SubmitMoveAction(
      actionId: 'integration-invalid-turn',
      playerId: hostClient.playerId!,
      expectedRevision: 1,
      start: move.start,
      end: move.end,
    );
    final rejected = hostClient.messages.firstWhere(
      (message) =>
          message.type == LanMessageType.actionRejected &&
          message.payload['actionId'] == invalid.actionId,
    );
    hostClient.submitMove(invalid);
    final rejection = await rejected.timeout(const Duration(seconds: 3));
    expect(
      rejection.payload['errorCode'],
      MoveValidationErrorCode.notPlayersTurn.name,
    );

    final guestToken = guest.sessionToken!;
    final paused = host.lobbyChanges.firstWhere((lobby) => lobby.gamePaused);
    await guest.close();
    await paused.timeout(const Duration(seconds: 3));
    expect(host.lobby.gamePaused, isTrue);

    reconnectedGuest = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Guest',
      roomCode: host.lobby.roomCode,
      sessionToken: guestToken,
    );
    expect(reconnectedGuest.playerId, guest.playerId);
    expect(reconnectedGuest.latestGameState?.revision, 1);
    expect(
      reconnectedGuest.latestStateHash,
      GameStateHasher.hash(host.gameState!),
    );

    final resumed = host.lobbyChanges.firstWhere((lobby) => !lobby.gamePaused);
    host.resumeGame();
    await resumed.timeout(const Duration(seconds: 3));

    final pausedAgain = host.lobbyChanges.firstWhere(
      (lobby) => lobby.gamePaused,
    );
    await reconnectedGuest.close();
    await pausedAgain.timeout(const Duration(seconds: 3));
    host.replaceDisconnectedWithBot(guest.playerId!);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(host.lobby.gamePaused, isFalse);
    expect(
      host.gameState!.players
          .firstWhere((player) => player.id == guest!.playerId)
          .controllerType,
      PlayerControllerType.bot,
    );
    expect(host.gameState!.revision, greaterThanOrEqualTo(2));
  });

  test(
    'two LAN clients complete a match with revision and hash agreement',
    () async {
      final host = await LanHostServer.start(
        hostName: 'Host',
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
        advertisedAddress: InternetAddress.loopbackIPv4.address,
        boardSize: BoardSize.fromPreset(BoardSizePreset.small),
        ruleset: Ruleset.custom,
      );
      LanClientConnection? hostClient;
      LanClientConnection? guestClient;
      addTearDown(() async {
        await hostClient?.close();
        await guestClient?.close();
        await host.close();
      });

      hostClient = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Host',
        roomCode: host.lobby.roomCode,
        sessionToken: host.hostSessionToken,
      );
      guestClient = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Guest',
        roomCode: host.lobby.roomCode,
      );
      final canStart = host.lobbyChanges.firstWhere((lobby) => lobby.canStart);
      guestClient.setReady(true);
      await canStart.timeout(const Duration(seconds: 3));
      final hostStarted = hostClient.messages.firstWhere(
        (message) => message.type == LanMessageType.matchStarted,
      );
      final guestStarted = guestClient.messages.firstWhere(
        (message) => message.type == LanMessageType.matchStarted,
      );
      hostClient.startMatch();
      await Future.wait([
        hostStarted.timeout(const Duration(seconds: 3)),
        guestStarted.timeout(const Duration(seconds: 3)),
      ]);

      final engine = GameEngine(host.gameState!.settings);
      var submittedMoves = 0;
      while (!host.gameState!.isGameOver) {
        final before = host.gameState!;
        final move = engine.validator.legalMoves(before).first;
        final nextRevision = before.revision + 1;
        final hostAdvanced = host.gameStateChanges.firstWhere(
          (state) => state.revision == nextRevision,
        );
        bool isExpectedAcceptance(LanEnvelope message) {
          if (message.type != LanMessageType.actionAccepted) {
            return false;
          }
          final state = message.payload['state']! as Map<String, Object?>;
          return state['revision'] == nextRevision;
        }

        final hostAccepted = hostClient.messages.firstWhere(
          isExpectedAcceptance,
        );
        final guestAccepted = guestClient.messages.firstWhere(
          isExpectedAcceptance,
        );
        final actor = before.currentPlayer.id == hostClient.playerId
            ? hostClient
            : guestClient;
        actor.submitMove(
          SubmitMoveAction(
            actionId: 'full-lan-match-$nextRevision',
            playerId: before.currentPlayer.id,
            expectedRevision: before.revision,
            start: move.start,
            end: move.end,
          ),
        );

        final next = await hostAdvanced.timeout(const Duration(seconds: 3));
        final accepted = await Future.wait([
          hostAccepted.timeout(const Duration(seconds: 3)),
          guestAccepted.timeout(const Duration(seconds: 3)),
        ]);
        final expectedHash = GameStateHasher.hash(next);
        for (final message in accepted) {
          expect(message.payload['stateHash'], expectedHash);
          final received = GameState.fromJson(
            message.payload['state']! as Map<String, Object?>,
          );
          expect(received.revision, nextRevision);
          expect(GameStateHasher.hash(received), expectedHash);
        }
        submittedMoves++;
        expect(submittedMoves, lessThan(100));
      }

      final finalState = host.gameState!;
      final finalHash = GameStateHasher.hash(finalState);
      expect(submittedMoves, greaterThan(0));
      expect(finalState.matchResult, isNotNull);
      expect(finalState.revision, submittedMoves);
      expect(hostClient.latestGameState?.matchResult, isNotNull);
      expect(guestClient.latestGameState?.matchResult, isNotNull);
      expect(hostClient.latestStateHash, finalHash);
      expect(guestClient.latestStateHash, finalHash);
    },
  );

  test('host authoritatively advances an expired human turn', () async {
    final host = await LanHostServer.start(
      hostName: 'Host',
      port: 0,
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddress: InternetAddress.loopbackIPv4.address,
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
      turnTimeSeconds: 10,
      turnTimeoutOverride: const Duration(milliseconds: 60),
    );
    LanClientConnection? hostClient;
    LanClientConnection? guest;
    addTearDown(() async {
      await hostClient?.close();
      await guest?.close();
      await host.close();
    });

    hostClient = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Host',
      roomCode: host.lobby.roomCode,
      sessionToken: host.hostSessionToken,
    );
    guest = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Guest',
      roomCode: host.lobby.roomCode,
    );
    final ready = host.lobbyChanges.firstWhere((lobby) => lobby.canStart);
    guest.setReady(true);
    await ready.timeout(const Duration(seconds: 3));

    final accepted = guest.messages.firstWhere(
      (message) => message.type == LanMessageType.actionAccepted,
    );
    hostClient.startMatch();
    final envelope = await accepted.timeout(const Duration(seconds: 3));
    final action = SubmitMoveAction.fromJson(
      envelope.payload['action']! as Map<String, Object?>,
    );

    expect(action.actionId, startsWith('lan-timeout:'));
    expect(action.playerId, hostClient.playerId);
    expect(host.gameState?.revision, 1);
    expect(host.gameState?.currentPlayer.id, guest.playerId);
  });

  test(
    'guest leaving before the match immediately releases the seat',
    () async {
      final host = await LanHostServer.start(
        hostName: 'Host',
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
        advertisedAddress: InternetAddress.loopbackIPv4.address,
      );
      LanClientConnection? hostClient;
      LanClientConnection? guest;
      LanClientConnection? replacement;
      addTearDown(() async {
        await hostClient?.close();
        await guest?.close();
        await replacement?.close();
        await host.close();
      });

      hostClient = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Host',
        roomCode: host.lobby.roomCode,
        sessionToken: host.hostSessionToken,
      );
      guest = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Leaving guest',
        roomCode: host.lobby.roomCode,
      );
      final leavingPlayerId = guest.playerId;
      expect(host.lobby.occupiedSeatCount, 2);

      final seatReleased = host.lobbyChanges.firstWhere(
        (lobby) =>
            lobby.occupiedSeatCount == 1 &&
            lobby.seats.every((seat) => seat.playerId != leavingPlayerId),
      );
      await guest.close();
      await seatReleased.timeout(const Duration(seconds: 3));

      expect(host.lobby.occupiedSeatCount, 1);
      expect(host.lobby.seats[1].isOccupied, isFalse);
      replacement = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Replacement',
        roomCode: host.lobby.roomCode,
      );
      expect(host.lobby.occupiedSeatCount, 2);
      expect(host.lobby.seats[1].playerId, replacement.playerId);
    },
  );

  test(
    'host shutdown is final and exposes only the live room generation',
    () async {
      final host = await LanHostServer.start(
        hostName: 'Host',
        port: 0,
        bindAddress: InternetAddress.loopbackIPv4,
        advertisedAddress: InternetAddress.loopbackIPv4.address,
      );
      LanClientConnection? guest;
      addTearDown(() async {
        await guest?.close();
        await host.close();
      });

      final http = HttpClient();
      final request = await http.getUrl(
        Uri.parse('http://127.0.0.1:${host.port}/room'),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      http.close(force: true);
      final advertised = LanRoomAdvertisement.fromJson(
        jsonDecode(body) as Map<String, Object?>,
      );
      expect(advertised.roomId, host.lobby.roomId);
      expect(advertised.roomCode, host.lobby.roomCode);

      guest = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: 'Guest',
        roomCode: host.lobby.roomCode,
      );
      final ended = guest.messages.firstWhere(
        (message) => message.type == LanMessageType.hostEnded,
      );
      final closed = guest.statusChanges.firstWhere(
        (status) => status == LanConnectionStatus.closed,
      );

      await host.close();
      await Future.wait([
        ended.timeout(const Duration(seconds: 3)),
        closed.timeout(const Duration(seconds: 3)),
      ]);
      expect(guest.status, LanConnectionStatus.closed);
    },
  );

  test('host board selection determines the lobby supply policy', () async {
    final host = await LanHostServer.start(
      hostName: 'Host',
      port: 0,
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddress: InternetAddress.loopbackIPv4.address,
    );
    LanClientConnection? hostClient;
    addTearDown(() async {
      await hostClient?.close();
      await host.close();
    });

    hostClient = await LanClientConnection.connect(
      websocketUrl: host.loopbackWebsocketUrl,
      playerName: 'Host',
      roomCode: host.lobby.roomCode,
      sessionToken: host.hostSessionToken,
    );

    final classicRevision = host.lobby.revision;
    final classicNormalized = host.lobbyChanges.firstWhere(
      (lobby) => lobby.revision > classicRevision,
    );
    hostClient.updateRoom(
      boardSize: BoardSize.fromPreset(BoardSizePreset.classic),
      ruleset: Ruleset.custom,
    );
    expect(
      (await classicNormalized.timeout(const Duration(seconds: 3))).ruleset,
      Ruleset.classic,
    );

    final scaledRevision = host.lobby.revision;
    final scaledNormalized = host.lobbyChanges.firstWhere(
      (lobby) => lobby.revision > scaledRevision,
    );
    hostClient.updateRoom(
      boardSize: BoardSize.fromPreset(BoardSizePreset.large),
      ruleset: Ruleset.classic,
    );
    final scaledLobby = await scaledNormalized.timeout(
      const Duration(seconds: 3),
    );
    expect(scaledLobby.ruleset, Ruleset.custom);
    expect(scaledLobby.boardSize.preset, BoardSizePreset.large);
  });
}

class _FirstLegalBot implements BotMoveProvider {
  const _FirstLegalBot();

  @override
  Future<BotDecision> chooseMove(GameState state, BotSettings settings) async {
    final move = GameEngine(state.settings).validator.legalMoves(state).first;
    return BotDecision(
      move: move,
      difficulty: settings.difficulty,
      estimatedValue: 0,
      nodesVisited: 1,
      completedDepth: 1,
      elapsedMilliseconds: 0,
    );
  }
}
