import 'dart:async';
import 'dart:io';

import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/models/lan_lobby_state.dart';
import 'package:trigrid/core/network/protocol/lan_envelope.dart';
import 'package:trigrid/core/network/protocol/lan_message_type.dart';
import 'package:uuid/uuid.dart';

enum LanConnectionStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,
  incompatible,
  closed,
}

class LanConnectionException implements Exception {
  const LanConnectionException(this.code);
  final String code;
  @override
  String toString() => 'LAN connection: $code';
}

class LanClientConnection {
  static String urlForHost(String address) {
    final trimmed = address.trim();
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'ws://$trimmed',
    );
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !const {'ws', 'wss', 'http', 'https'}.contains(uri.scheme)) {
      throw const FormatException('Enter a LAN host address.');
    }
    return Uri(
      scheme: const {'wss', 'https'}.contains(uri.scheme) ? 'wss' : 'ws',
      host: uri.host,
      port: uri.hasPort ? uri.port : 42422,
      path: '/ws',
    ).toString();
  }

  LanClientConnection._({
    required WebSocket socket,
    required this.websocketUrl,
    required this.playerName,
    required this.roomCode,
    required String? requestedSessionToken,
  }) : _socket = socket,
       _requestedSessionToken = requestedSessionToken;

  static Future<LanClientConnection> connect({
    required String websocketUrl,
    required String playerName,
    required String roomCode,
    String? sessionToken,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final pendingSocket = WebSocket.connect(websocketUrl);
    final socket = await pendingSocket.timeout(
      timeout,
      onTimeout: () {
        // Future.timeout does not cancel the underlying handshake.
        unawaited(
          pendingSocket.then<void>((lateSocket) async {
            await lateSocket.close(WebSocketStatus.goingAway);
          }, onError: (Object _) {}),
        );
        throw TimeoutException('LAN handshake timed out.', timeout);
      },
    );
    final client = LanClientConnection._(
      socket: socket,
      websocketUrl: websocketUrl,
      playerName: playerName,
      roomCode: roomCode,
      requestedSessionToken: sessionToken,
    );
    client._listen();
    client._send(LanMessageType.joinRequest, {
      'playerName': playerName,
      'roomCode': roomCode.toUpperCase(),
      'sessionToken': sessionToken,
    });
    try {
      await client._joinCompleter.future.timeout(timeout);
      return client;
    } on Object {
      await client.close();
      rethrow;
    }
  }

  final WebSocket _socket;
  final String websocketUrl;
  final String playerName;
  final String roomCode;
  final String? _requestedSessionToken;
  final StreamController<LanEnvelope> _messageController =
      StreamController<LanEnvelope>.broadcast();
  final StreamController<LanConnectionStatus> _statusController =
      StreamController<LanConnectionStatus>.broadcast();
  final StreamController<int> _latencyController =
      StreamController<int>.broadcast();
  final Completer<void> _joinCompleter = Completer<void>();

  StreamSubscription<Object?>? _socketSubscription;
  LanConnectionStatus _status = LanConnectionStatus.connecting;
  String? playerId;
  String? sessionToken;
  bool isHost = false;
  LanLobbyState? latestLobby;
  GameState? latestGameState;
  String? latestStateHash;
  String? lastErrorCode;
  int latencyMilliseconds = 0;
  var _outgoingSequence = 0;
  var _messageCounter = 0;
  var _lastHostSequence = -1;
  var _closed = false;
  var _hostEnded = false;

  Stream<LanEnvelope> get messages => _messageController.stream;

  Stream<LanConnectionStatus> get statusChanges => _statusController.stream;

  Stream<int> get latencyChanges => _latencyController.stream;

  LanConnectionStatus get status => _status;

  bool get isConnected => _status == LanConnectionStatus.connected;

  void _listen() {
    _socketSubscription = _socket.listen(
      _handleRawMessage,
      onDone: _handleDone,
      onError: (_) => _handleDone(),
      cancelOnError: true,
    );
  }

  void _handleRawMessage(Object? raw) {
    if (raw is! String) {
      return;
    }
    LanEnvelope envelope;
    try {
      envelope = LanEnvelope.decode(raw);
    } on LanProtocolVersionException {
      _setStatus(LanConnectionStatus.incompatible);
      if (!_joinCompleter.isCompleted) {
        _joinCompleter.completeError(
          const LanConnectionException('incompatible_protocol'),
        );
      }
      return;
    } on Object {
      return;
    }
    if (envelope.sequence <= _lastHostSequence) {
      return;
    }
    _lastHostSequence = envelope.sequence;

    try {
      switch (envelope.type) {
        case LanMessageType.joinAccepted:
          playerId = envelope.payload['playerId']! as String;
          sessionToken = envelope.payload['sessionToken']! as String;
          isHost = envelope.payload['isHost']! as bool;
          latestLobby = LanLobbyState.fromJson(
            envelope.payload['lobby']! as Map<String, Object?>,
          );
          final gameJson = envelope.payload['gameState'];
          if (gameJson != null) {
            latestGameState = GameState.fromJson(
              gameJson as Map<String, Object?>,
            );
            latestStateHash = envelope.payload['stateHash'] as String?;
          }
          _setStatus(LanConnectionStatus.connected);
          if (!_joinCompleter.isCompleted) {
            _joinCompleter.complete();
          }
        case LanMessageType.lobbySnapshot:
          latestLobby = LanLobbyState.fromJson(
            envelope.payload['lobby']! as Map<String, Object?>,
          );
        case LanMessageType.matchStarted:
          latestGameState = GameState.fromJson(
            envelope.payload['state']! as Map<String, Object?>,
          );
          latestStateHash = envelope.payload['stateHash']! as String;
        case LanMessageType.actionAccepted || LanMessageType.stateSnapshot:
          latestGameState = GameState.fromJson(
            envelope.payload['state']! as Map<String, Object?>,
          );
          latestStateHash = envelope.payload['stateHash']! as String;
        case LanMessageType.actionRejected:
          lastErrorCode = envelope.payload['errorCode']! as String;
        case LanMessageType.error:
          lastErrorCode = envelope.payload['code']! as String;
          if (!_joinCompleter.isCompleted) {
            _joinCompleter.completeError(
              LanConnectionException(lastErrorCode!),
            );
          }
        case LanMessageType.ping:
          final sentAt = envelope.payload['sentAt']! as int;
          latencyMilliseconds = DateTime.now().millisecondsSinceEpoch - sentAt;
          _latencyController.add(latencyMilliseconds);
          _send(LanMessageType.pong, {'sentAt': sentAt});
        case LanMessageType.hostEnded:
          _hostEnded = true;
          lastErrorCode = 'host_ended';
          if (!_joinCompleter.isCompleted) {
            _joinCompleter.completeError(
              const LanConnectionException('host_ended'),
            );
          }
          _setStatus(LanConnectionStatus.closed);
        case LanMessageType.gamePaused ||
            LanMessageType.gameResumed ||
            LanMessageType.pong ||
            LanMessageType.joinRequest ||
            LanMessageType.setReady ||
            LanMessageType.selectColor ||
            LanMessageType.updateRoom ||
            LanMessageType.updateSeat ||
            LanMessageType.startMatch ||
            LanMessageType.submitMove ||
            LanMessageType.disconnectDecision:
          break;
      }
    } on Object {
      lastErrorCode = 'invalid_host_payload';
      if (!_joinCompleter.isCompleted) {
        _joinCompleter.completeError(StateError(lastErrorCode!));
      }
      return;
    }
    _messageController.add(envelope);
  }

  void setReady(bool ready) {
    _send(LanMessageType.setReady, {'ready': ready});
  }

  void selectColor(int colorIndex) {
    _send(LanMessageType.selectColor, {'colorIndex': colorIndex});
  }

  void updateRoom({
    required BoardSize boardSize,
    required Ruleset ruleset,
    int? turnTimeSeconds,
  }) {
    _send(LanMessageType.updateRoom, {
      'boardSize': boardSize.toJson(),
      'ruleset': ruleset.name,
      'turnTimeSeconds': turnTimeSeconds,
    });
  }

  void addBot({
    required int seatIndex,
    required String displayName,
    required BotSettings settings,
  }) {
    _send(LanMessageType.updateSeat, {
      'seatIndex': seatIndex,
      'operation': 'addBot',
      'displayName': displayName,
      'botSettings': settings.toJson(),
    });
  }

  void removeSeat(int seatIndex) {
    _send(LanMessageType.updateSeat, {
      'seatIndex': seatIndex,
      'operation': 'remove',
    });
  }

  void updateBot({required int seatIndex, required BotSettings settings}) {
    _send(LanMessageType.updateSeat, {
      'seatIndex': seatIndex,
      'operation': 'updateBot',
      'botSettings': settings.toJson(),
    });
  }

  void startMatch() {
    _send(LanMessageType.startMatch, const {});
  }

  void submitMove(SubmitMoveAction action) {
    _send(LanMessageType.submitMove, {'action': action.toJson()});
  }

  void decideDisconnect({required String decision, required String playerId}) {
    _send(LanMessageType.disconnectDecision, {
      'decision': decision,
      'playerId': playerId,
    });
  }

  void _send(LanMessageType type, Map<String, Object?> payload) {
    if (_closed || _socket.readyState != WebSocket.open) {
      return;
    }
    final envelope = LanEnvelope(
      type: type,
      messageId: 'client:${const Uuid().v4()}:${_messageCounter++}',
      sequence: _outgoingSequence++,
      matchId: latestLobby?.roomId,
      playerId: playerId,
      payload: payload,
    );
    _socket.add(envelope.encode());
  }

  void _handleDone() {
    if (_closed) {
      return;
    }
    if (_hostEnded) {
      _setStatus(LanConnectionStatus.closed);
      return;
    }
    _setStatus(LanConnectionStatus.disconnected);
    if (!_joinCompleter.isCompleted) {
      _joinCompleter.completeError(
        StateError('LAN connection closed before joining.'),
      );
    }
  }

  void _setStatus(LanConnectionStatus next) {
    if (_status == next) {
      return;
    }
    _status = next;
    _statusController.add(next);
  }

  Future<LanClientConnection> reconnect({
    Duration timeout = const Duration(seconds: 8),
  }) {
    return LanClientConnection.connect(
      websocketUrl: websocketUrl,
      playerName: playerName,
      roomCode: roomCode,
      sessionToken: sessionToken ?? _requestedSessionToken,
      timeout: timeout,
    );
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _setStatus(LanConnectionStatus.closed);
    await _socketSubscription?.cancel();
    await _socket.close(WebSocketStatus.normalClosure);
    await _messageController.close();
    await _statusController.close();
    await _latencyController.close();
  }
}
