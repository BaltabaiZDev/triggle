import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/presentation/controllers/lan_game_session_controller.dart';

Future<LanHostServer> room({int port = 0, bool small = true}) =>
    LanHostServer.start(
      hostName: 'Host',
      port: port,
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddress: '127.0.0.1',
      boardSize: BoardSize.fromPreset(
        small ? BoardSizePreset.small : BoardSizePreset.classic,
      ),
    );
Future<LanClientConnection> join(
  LanHostServer host, {
  bool owner = false,
  String? code,
}) => LanClientConnection.connect(
  websocketUrl: host.loopbackWebsocketUrl,
  playerName: owner ? 'Host' : 'Guest',
  roomCode: code ?? host.lobby.roomCode,
  sessionToken: owner ? host.hostSessionToken : null,
);
Future<void> until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('LAN state did not converge.');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test(
    'manual join accepts IP, explicit port and copied URLs without duplicating a port',
    () {
      expect(
        LanClientConnection.urlForHost('192.168.1.5'),
        'ws://192.168.1.5:42422/ws',
      );
      expect(
        LanClientConnection.urlForHost('192.168.1.5:42422'),
        'ws://192.168.1.5:42422/ws',
      );
      expect(
        LanClientConnection.urlForHost('http://192.168.1.5:42422/room'),
        'ws://192.168.1.5:42422/ws',
      );
      expect(
        () => LanClientConnection.urlForHost('file:///tmp/test'),
        throwsFormatException,
      );
    },
  );

  test(
    'three close/reopen cycles reuse one port and reject stale room codes',
    () async {
      var port = 0;
      String? oldCode;
      for (var cycle = 0; cycle < 3; cycle++) {
        final host = await room(port: port);
        final owner = await join(host, owner: true);
        LanClientConnection? guest;
        try {
          port = host.port;
          if (oldCode != null) {
            await expectLater(
              join(host, code: oldCode),
              throwsA(
                isA<LanConnectionException>().having(
                  (e) => e.code,
                  'code',
                  'invalid_room_code',
                ),
              ),
            );
          }
          guest = await join(host);
          await guest.close();
          await until(() => host.lobby.occupiedSeatCount == 1);
          guest = await join(host);
          expect(host.lobby.occupiedSeatCount, 2);
          oldCode = host.lobby.roomCode;
          await host.close();
          await until(() => guest!.status == LanConnectionStatus.closed);
        } finally {
          await owner.close();
          await guest?.close();
          await host.close();
        }
      }
    },
  );

  test('small LAN rooms reject a third player and hidden bot seats', () async {
    final host = await room();
    final owner = await join(host, owner: true);
    final guest = await join(host);
    try {
      expect(host.advertisement.capacity, 2);
      await expectLater(
        join(host),
        throwsA(
          isA<LanConnectionException>().having(
            (e) => e.code,
            'code',
            'room_full',
          ),
        ),
      );
      owner.addBot(
        seatIndex: 2,
        displayName: 'Extra',
        settings: BotSettings.standard,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(host.lobby.seats[2].isOccupied, isFalse);
      expect(host.lobby.occupiedSeatCount, 2);
    } finally {
      await owner.close();
      await guest.close();
      await host.close();
    }
  });

  test(
    'shrinking a populated LAN room cannot strand or eject occupied seats',
    () async {
      final host = await room(small: false);
      final owner = await join(host, owner: true);
      final guest = await join(host);
      final third = await join(host);
      try {
        final error = owner.messages.firstWhere(
          (message) => message.type == LanMessageType.error,
        );
        owner.updateRoom(
          boardSize: BoardSize.fromPreset(BoardSizePreset.small),
          ruleset: Ruleset.custom,
        );
        expect(
          (await error.timeout(const Duration(seconds: 3))).payload['code'],
          'board_capacity',
        );
        expect(host.lobby.occupiedSeatCount, 3);
        expect(host.lobby.boardSize.isClassic, isTrue);
      } finally {
        await owner.close();
        await guest.close();
        await third.close();
        await host.close();
      }
    },
  );

  test(
    'final LAN snapshots wait for presentation and never resume a completed game',
    () async {
      final settings = GameSettings(
        matchId: 'snapshot-room',
        boardSize: BoardSize.fromPreset(BoardSizePreset.small),
        ruleset: Ruleset.custom,
        players: [
          for (var i = 0; i < 2; i++)
            PlayerConfiguration(
              id: 'p$i',
              displayName: 'P$i',
              controllerType: PlayerControllerType.human,
            ),
        ],
        seed: 1,
      );
      final engine = GameEngine(settings);
      final initial = engine.createInitialState(settings);
      var terminal = initial;
      while (!terminal.isGameOver) {
        final move = engine.validator.legalMoves(terminal).first;
        terminal = engine
            .submitMove(
              terminal,
              SubmitMoveAction(
                actionId: 'm${terminal.revision}',
                playerId: terminal.currentPlayer.id,
                expectedRevision: terminal.revision,
                start: move.start,
                end: move.end,
              ),
            )
            .state;
      }
      final lobby = LanLobbyState(
        roomId: settings.matchId,
        roomCode: 'ABC123',
        roomName: 'Room',
        hostPlayerId: 'p0',
        boardSize: settings.boardSize,
        ruleset: settings.ruleset,
        revision: 0,
        started: true,
        seats: [
          for (var i = 0; i < 2; i++)
            LanSeat.empty(i).copyWith(
              playerId: 'p$i',
              displayName: 'P$i',
              connected: true,
              ready: true,
            ),
        ],
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final socketReady = Completer<WebSocket>();
      var sequence = 0;
      void send(
        WebSocket socket,
        LanMessageType type,
        Map<String, Object?> payload,
      ) => socket.add(
        LanEnvelope(
          type: type,
          messageId: 'test-${sequence++}',
          sequence: sequence,
          payload: payload,
          matchId: settings.matchId,
        ).encode(),
      );
      final requests = server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((raw) {
          if (LanEnvelope.decode(raw as String).type ==
              LanMessageType.joinRequest) {
            send(socket, LanMessageType.joinAccepted, {
              'playerId': 'p1',
              'sessionToken': 'test-token',
              'isHost': false,
              'lobby': lobby.toJson(),
              'gameState': initial.toJson(),
              'stateHash': GameStateHasher.hash(initial),
            });
            socketReady.complete(socket);
          }
        });
      });
      final client = await LanClientConnection.connect(
        websocketUrl: 'ws://127.0.0.1:${server.port}/ws',
        playerName: 'P1',
        roomCode: 'ABC123',
      );
      final socket = await socketReady.future;
      final session = LanGameSessionController(client: client);
      session.onAcceptedTransition = (_) {};
      session.onInit();
      try {
        final snapshot = {
          'state': terminal.toJson(),
          'stateHash': GameStateHasher.hash(terminal),
        };
        send(socket, LanMessageType.stateSnapshot, snapshot);
        await until(() => session.currentState.isGameOver);
        expect(session.showResult.value, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        send(socket, LanMessageType.stateSnapshot, snapshot);
        send(socket, LanMessageType.gamePaused, {});
        send(socket, LanMessageType.hostEnded, {});
        await until(
          () => session.connectionStatus.value == LanConnectionStatus.closed,
        );
        expect(session.networkPaused.value, isFalse);
        expect(session.isPaused.value, isFalse);
        expect(session.networkErrorCode.value, isNull);
        session.restart();
        session.setPaused(true);
        await session.reconnect();
        expect(session.currentState.isGameOver, isTrue);
        expect(session.isReconnecting.value, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        expect(session.showResult.value, isTrue);
      } finally {
        session.onClose();
        await session.shutdown();
        await socket.close();
        await requests.cancel();
        await server.close(force: true);
      }
    },
  );
}
