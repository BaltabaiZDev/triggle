import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:trigrid/core/ai/trigrid_ai.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/models/lan_lobby_state.dart';
import 'package:trigrid/core/network/models/lan_room_advertisement.dart';
import 'package:trigrid/core/network/protocol/lan_envelope.dart';
import 'package:trigrid/core/network/protocol/lan_message_type.dart';
import 'package:uuid/uuid.dart';

class LanHostServer {
  static const defaultPort = 42422;

  LanHostServer._({
    required HttpServer server,
    required this.hostSessionToken,
    required this.advertisedAddress,
    required this.lobby,
    required this.startingPlayerIndex,
    required Duration? turnTimeoutOverride,
    BotMoveProvider botMoveProvider = const BotWorker(),
  }) : _server = server,
       _turnTimeoutOverride = turnTimeoutOverride,
       _botMoveProvider = botMoveProvider;

  static Future<LanHostServer> start({
    required String hostName,
    String roomName = 'TriGrid LAN',
    InternetAddress? bindAddress,
    String? advertisedAddress,
    int port = defaultPort,
    BoardSize? boardSize,
    Ruleset ruleset = Ruleset.classic,
    int? turnTimeSeconds,
    int startingPlayerIndex = 0,
    Duration? turnTimeoutOverride,
    BotMoveProvider botMoveProvider = const BotWorker(),
  }) async {
    final server = await _bindServer(
      bindAddress ?? InternetAddress.anyIPv4,
      port,
    );
    final uuid = const Uuid();
    final roomId = uuid.v4();
    final hostPlayerId = uuid.v4();
    final hostToken = uuid.v4();
    final selectedBoard =
        boardSize ?? BoardSize.fromPreset(BoardSizePreset.classic);
    final host = LanHostServer._(
      server: server,
      hostSessionToken: hostToken,
      startingPlayerIndex: startingPlayerIndex,
      advertisedAddress: advertisedAddress ?? await _bestLocalIpv4Address(),
      lobby: LanLobbyState(
        roomId: roomId,
        roomCode: _roomCode(roomId),
        roomName: roomName,
        hostPlayerId: hostPlayerId,
        boardSize: selectedBoard,
        ruleset: selectedBoard.isClassic ? ruleset : Ruleset.custom,
        seats: [
          LanSeat.empty(0).copyWith(
            playerId: hostPlayerId,
            displayName: hostName,
            ready: true,
            connected: false,
          ),
          for (var index = 1; index < 4; index++) LanSeat.empty(index),
        ],
        revision: 0,
        turnTimeSeconds: turnTimeSeconds,
      ),
      turnTimeoutOverride: turnTimeoutOverride,
      botMoveProvider: botMoveProvider,
    );
    host._sessionTokens[hostPlayerId] = hostToken;
    host._listen();
    return host;
  }

  final HttpServer _server;
  final BotMoveProvider _botMoveProvider;
  final Duration? _turnTimeoutOverride;
  final String hostSessionToken;
  final String advertisedAddress;
  final int startingPlayerIndex;
  final Map<WebSocket, _ClientContext> _clients = {};
  final Map<String, String> _sessionTokens = {};
  final Map<String, Map<String, Object?>> _acceptedActionPayloads = {};
  final StreamController<LanLobbyState> _lobbyController =
      StreamController<LanLobbyState>.broadcast();
  final StreamController<GameState> _gameController =
      StreamController<GameState>.broadcast();

  late LanLobbyState lobby;
  GameEngine? _engine;
  GameState? _state;
  Timer? _heartbeatTimer;
  Timer? _turnTimer;
  var _outgoingSequence = 0;
  var _messageCounter = 0;
  var _acceptedSinceSnapshot = 0;
  var _botGeneration = 0;
  var _botThinking = false;
  var _closing = false;

  int get port => _server.port;

  GameState? get gameState => _state;

  Stream<LanLobbyState> get lobbyChanges => _lobbyController.stream;

  Stream<GameState> get gameStateChanges => _gameController.stream;

  LanRoomAdvertisement get advertisement => LanRoomAdvertisement(
    roomId: lobby.roomId,
    roomCode: lobby.roomCode,
    roomName: lobby.roomName,
    address: advertisedAddress,
    port: port,
    playerCount: lobby.occupiedSeatCount,
    capacity: lobby.capacity,
    protocolVersion: LanEnvelope.currentProtocolVersion,
  );

  String get loopbackWebsocketUrl => 'ws://127.0.0.1:$port/ws';

  void _listen() {
    unawaited(_serveRequests());
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _heartbeat(),
    );
  }

  Future<void> _serveRequests() async {
    await for (final request in _server) {
      if (request.method == 'GET' && request.uri.path == '/room') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(advertisement.toJson()));
        await request.response.close();
        continue;
      }
      if (request.uri.path != '/ws' ||
          !WebSocketTransformer.isUpgradeRequest(request)) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('TriGrid LAN WebSocket endpoint is /ws.');
        await request.response.close();
        continue;
      }
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _attachSocket(socket);
      } on Object {
        await request.response.close();
      }
    }
  }

  void _attachSocket(WebSocket socket) {
    final context = _ClientContext(socket);
    _clients[socket] = context;
    socket.listen(
      (data) => _handleRawMessage(context, data),
      onDone: () => _handleDisconnect(context),
      onError: (_) => _handleDisconnect(context),
      cancelOnError: true,
    );
  }

  void _handleRawMessage(_ClientContext context, Object? raw) {
    context.lastSeen = DateTime.now();
    if (raw is! String) {
      _sendError(context, 'binary_not_supported');
      return;
    }
    LanEnvelope envelope;
    try {
      envelope = LanEnvelope.decode(raw);
    } on LanProtocolVersionException catch (error) {
      _sendError(
        context,
        'incompatible_protocol',
        details: {'receivedVersion': error.receivedVersion},
      );
      return;
    } on Object {
      _sendError(context, 'invalid_envelope');
      return;
    }
    if (envelope.sequence <= context.lastIncomingSequence) {
      _sendError(context, 'out_of_order_message');
      return;
    }
    context.lastIncomingSequence = envelope.sequence;
    try {
      if (context.playerId == null) {
        if (envelope.type != LanMessageType.joinRequest) {
          _sendError(context, 'join_required');
          return;
        }
        _handleJoin(context, envelope);
        return;
      }

      switch (envelope.type) {
        case LanMessageType.setReady:
          _setReady(context.playerId!, envelope.payload['ready']! as bool);
        case LanMessageType.selectColor:
          _setColor(context.playerId!, envelope.payload['colorIndex']! as int);
        case LanMessageType.updateRoom:
          if (_isHost(context)) {
            _updateRoom(envelope.payload);
          } else {
            _sendError(context, 'host_only');
          }
        case LanMessageType.updateSeat:
          if (_isHost(context)) {
            _updateSeat(envelope.payload);
          } else {
            _sendError(context, 'host_only');
          }
        case LanMessageType.startMatch:
          if (_isHost(context)) {
            startMatch();
          } else {
            _sendError(context, 'host_only');
          }
        case LanMessageType.submitMove:
          _handleSubmitMove(context, envelope);
        case LanMessageType.pong:
          context.lastPong = DateTime.now();
        case LanMessageType.ping:
          _send(
            context,
            _envelope(LanMessageType.pong, {
              'echo': envelope.payload['sentAt'],
            }, playerId: context.playerId),
          );
        case LanMessageType.disconnectDecision:
          if (_isHost(context)) {
            _handleDisconnectDecision(envelope.payload);
          } else {
            _sendError(context, 'host_only');
          }
        case LanMessageType.joinRequest ||
            LanMessageType.joinAccepted ||
            LanMessageType.error ||
            LanMessageType.lobbySnapshot ||
            LanMessageType.matchStarted ||
            LanMessageType.actionAccepted ||
            LanMessageType.actionRejected ||
            LanMessageType.stateSnapshot ||
            LanMessageType.gamePaused ||
            LanMessageType.gameResumed ||
            LanMessageType.hostEnded:
          _sendError(context, 'unsupported_client_message');
      }
    } on Object {
      _sendError(context, 'invalid_payload');
    }
  }

  void _handleJoin(_ClientContext context, LanEnvelope envelope) {
    final playerName = (envelope.payload['playerName']! as String).trim();
    final roomCode = (envelope.payload['roomCode']! as String)
        .trim()
        .toUpperCase();
    final requestedToken = envelope.payload['sessionToken'] as String?;
    if (roomCode != lobby.roomCode) {
      _sendError(context, 'invalid_room_code');
      return;
    }
    if (playerName.isEmpty) {
      _sendError(context, 'invalid_room_or_name');
      return;
    }

    String playerId;
    String sessionToken;
    var reconnecting = false;
    if (requestedToken != null &&
        _sessionTokens.containsValue(requestedToken)) {
      playerId = _sessionTokens.entries
          .firstWhere((entry) => entry.value == requestedToken)
          .key;
      sessionToken = requestedToken;
      reconnecting = true;
    } else {
      if (requestedToken != null) {
        _sendError(context, 'invalid_session_token');
        return;
      }
      if (lobby.started) {
        _sendError(context, 'match_already_started');
        return;
      }
      final emptySeat = lobby.seats
          .take(lobby.capacity)
          .where((seat) => !seat.isOccupied)
          .firstOrNull;
      if (emptySeat == null) {
        _sendError(context, 'room_full');
        return;
      }
      playerId = const Uuid().v4();
      sessionToken = const Uuid().v4();
      _sessionTokens[playerId] = sessionToken;
      _replaceSeat(
        emptySeat.seatIndex,
        emptySeat.copyWith(
          playerId: playerId,
          displayName: playerName,
          controllerType: PlayerControllerType.human,
          ready: false,
          connected: true,
          colorIndex: _firstAvailableColorIndex(),
          clearBotSettings: true,
        ),
      );
    }

    final seatIndex = lobby.seats.indexWhere(
      (seat) => seat.playerId == playerId,
    );
    if (seatIndex < 0) {
      _sendError(context, 'reconnect_seat_missing');
      return;
    }
    context.playerId = playerId;
    context.sessionToken = sessionToken;
    for (final existing in _clients.values) {
      if (existing != context && existing.playerId == playerId) {
        unawaited(existing.socket.close(WebSocketStatus.goingAway));
      }
    }
    _replaceSeat(
      seatIndex,
      lobby.seats[seatIndex].copyWith(
        displayName: playerName,
        connected: true,
        ready: playerId == lobby.hostPlayerId
            ? true
            : lobby.seats[seatIndex].ready,
      ),
    );
    _send(
      context,
      _envelope(LanMessageType.joinAccepted, {
        'playerId': playerId,
        'sessionToken': sessionToken,
        'isHost': playerId == lobby.hostPlayerId,
        'reconnected': reconnecting,
        'lobby': lobby.toJson(),
        'gameState': _state?.toJson(),
        'stateHash': _state == null ? null : GameStateHasher.hash(_state!),
      }, playerId: playerId),
    );
    _broadcastLobby();
    if (_state != null) {
      _sendSnapshot(context);
    }
  }

  void _setReady(String playerId, bool ready) {
    if (lobby.started) {
      return;
    }
    final index = lobby.seats.indexWhere(
      (seat) => seat.playerId == playerId && !seat.isBot,
    );
    if (index < 0) {
      return;
    }
    _replaceSeat(
      index,
      lobby.seats[index].copyWith(
        ready: playerId == lobby.hostPlayerId ? true : ready,
      ),
    );
    _broadcastLobby();
  }

  void _setColor(String playerId, int colorIndex) {
    if (lobby.started || colorIndex < 0 || colorIndex > 3) {
      return;
    }
    final index = lobby.seats.indexWhere(
      (seat) => seat.playerId == playerId && !seat.isBot,
    );
    if (index < 0 ||
        lobby.seats.any(
          (seat) =>
              seat.isOccupied &&
              seat.playerId != playerId &&
              seat.colorIndex == colorIndex,
        )) {
      return;
    }
    _replaceSeat(index, lobby.seats[index].copyWith(colorIndex: colorIndex));
    _broadcastLobby();
  }

  void _updateRoom(Map<String, Object?> payload) {
    if (lobby.started) {
      return;
    }
    final boardSize = BoardSize.fromJson(
      payload['boardSize']! as Map<String, Object?>,
    );
    if (lobby.occupiedSeatCount > boardSize.maximumPlayers ||
        lobby.seats
            .skip(boardSize.maximumPlayers)
            .any((seat) => seat.isOccupied)) {
      _broadcast(_envelope(LanMessageType.error, {'code': 'board_capacity'}));
      return;
    }
    final turnTimeSeconds = payload['turnTimeSeconds'] as int?;
    if (turnTimeSeconds != null &&
        (turnTimeSeconds < 10 || turnTimeSeconds > 300)) {
      return;
    }
    lobby = lobby.copyWith(
      boardSize: boardSize,
      ruleset: boardSize.isClassic ? Ruleset.classic : Ruleset.custom,
      turnTimeSeconds: turnTimeSeconds,
      clearTurnTime: turnTimeSeconds == null,
      revision: lobby.revision + 1,
    );
    _broadcastLobby();
  }

  void _updateSeat(Map<String, Object?> payload) {
    if (lobby.started) {
      return;
    }
    final index = payload['seatIndex']! as int;
    if (index <= 0 || index >= lobby.seats.length) {
      return;
    }
    final operation = payload['operation']! as String;
    final current = lobby.seats[index];
    if (operation == 'remove') {
      if (current.isBot || !current.connected) {
        if (current.playerId != null) {
          _sessionTokens.remove(current.playerId);
        }
        _replaceSeat(index, LanSeat.empty(index));
        _broadcastLobby();
      }
      return;
    }
    if (operation == 'addBot' &&
        !current.isOccupied &&
        index < lobby.capacity) {
      final botSettings = BotSettings.fromJson(
        payload['botSettings']! as Map<String, Object?>,
      );
      _replaceSeat(
        index,
        current.copyWith(
          playerId: 'bot:${lobby.roomId}:$index',
          displayName: payload['displayName']! as String,
          controllerType: PlayerControllerType.bot,
          botSettings: botSettings,
          ready: true,
          connected: true,
          colorIndex: _firstAvailableColorIndex(),
        ),
      );
      _broadcastLobby();
      return;
    }
    if (operation == 'updateBot' && current.isBot) {
      final botSettings = BotSettings.fromJson(
        payload['botSettings']! as Map<String, Object?>,
      );
      _replaceSeat(index, current.copyWith(botSettings: botSettings));
      _broadcastLobby();
    }
  }

  int _firstAvailableColorIndex() {
    final used = lobby.seats
        .where((seat) => seat.isOccupied)
        .map((seat) => seat.colorIndex)
        .toSet();
    return Iterable<int>.generate(
      4,
    ).firstWhere((color) => !used.contains(color), orElse: () => 0);
  }

  void startMatch() {
    if (lobby.started || !lobby.canStart) {
      return;
    }
    final occupied = lobby.seats.where((seat) => seat.isOccupied).toList();
    final settings = GameSettings(
      matchId: lobby.roomId,
      boardSize: lobby.boardSize,
      ruleset: lobby.ruleset,
      players: [
        for (final seat in occupied)
          PlayerConfiguration(
            id: seat.playerId!,
            displayName: seat.displayName!,
            controllerType: seat.controllerType,
            botSettings: seat.botSettings,
            visualIndex: seat.colorIndex,
          ),
      ],
      seed: lobby.roomId.codeUnits.fold<int>(
        17,
        (seed, unit) => (seed * 31 + unit) & 0x7FFFFFFF,
      ),
      turnTimeSeconds: lobby.turnTimeSeconds,
      startingPlayerIndex: startingPlayerIndex % occupied.length,
    );
    _engine = GameEngine(settings);
    _state = _engine!.createInitialState(settings);
    lobby = lobby.copyWith(started: true, revision: lobby.revision + 1);
    _broadcast(
      _envelope(LanMessageType.matchStarted, {
        'settings': settings.toJson(),
        'state': _state!.toJson(),
        'stateHash': GameStateHasher.hash(_state!),
      }),
    );
    _lobbyController.add(lobby);
    _gameController.add(_state!);
    _scheduleNextTurn();
  }

  void _handleSubmitMove(_ClientContext context, LanEnvelope envelope) {
    final state = _state;
    final engine = _engine;
    if (state == null || engine == null) {
      _sendError(context, 'match_not_started');
      return;
    }
    if (lobby.gamePaused) {
      _sendError(context, 'match_paused');
      return;
    }
    final action = SubmitMoveAction.fromJson(
      envelope.payload['action']! as Map<String, Object?>,
    );
    if (action.playerId != context.playerId) {
      _sendError(context, 'player_identity_mismatch');
      return;
    }
    final cached = _acceptedActionPayloads[action.actionId];
    if (cached != null) {
      _send(
        context,
        _envelope(
          LanMessageType.actionAccepted,
          cached,
          playerId: context.playerId,
        ),
      );
      return;
    }
    final transition = engine.submitMove(state, action);
    if (!transition.wasAccepted) {
      _send(
        context,
        _envelope(LanMessageType.actionRejected, {
          'actionId': action.actionId,
          'errorCode': transition.validation.errorCode!.name,
          'authoritativeRevision': state.revision,
          'stateHash': GameStateHasher.hash(state),
        }, playerId: context.playerId),
      );
      return;
    }
    _acceptTransition(transition);
  }

  void _acceptTransition(GameTransition transition) {
    _state = transition.state;
    final payload = <String, Object?>{
      'action': transition.action.toJson(),
      'state': transition.state.toJson(),
      'stateHash': GameStateHasher.hash(transition.state),
      'capturedTriangleIds': transition.validation.newlyCapturedTriangles
          .map((triangle) => triangle.id)
          .toList(),
    };
    _acceptedActionPayloads[transition.action.actionId] = payload;
    _broadcast(_envelope(LanMessageType.actionAccepted, payload));
    _gameController.add(transition.state);
    _acceptedSinceSnapshot++;
    if (_acceptedSinceSnapshot >= 5) {
      _acceptedSinceSnapshot = 0;
      _broadcastSnapshot();
    }
    _scheduleNextTurn();
  }

  void _scheduleNextTurn() {
    _turnTimer?.cancel();
    final state = _state;
    if (state == null || state.isGameOver || lobby.gamePaused) {
      return;
    }
    if (state.currentPlayer.controllerType == PlayerControllerType.bot) {
      _scheduleBotIfNeeded();
      return;
    }
    final configuredSeconds = lobby.turnTimeSeconds;
    if (configuredSeconds == null) {
      return;
    }
    final revision = state.revision;
    final duration =
        _turnTimeoutOverride ?? Duration(seconds: configuredSeconds);
    _turnTimer = Timer(duration, () {
      final current = _state;
      if (current == null ||
          current.isGameOver ||
          lobby.gamePaused ||
          current.revision != revision ||
          current.currentPlayer.controllerType != PlayerControllerType.human) {
        return;
      }
      final legalMoves = _engine!.validator.legalMoves(current);
      if (legalMoves.isEmpty) {
        return;
      }
      final move = legalMoves.first;
      final transition = _engine!.submitMove(
        current,
        SubmitMoveAction(
          actionId: 'lan-timeout:${lobby.roomId}:${current.revision}',
          playerId: current.currentPlayer.id,
          expectedRevision: current.revision,
          start: move.start,
          end: move.end,
        ),
      );
      if (transition.wasAccepted) {
        _acceptTransition(transition);
      }
    });
  }

  void _scheduleBotIfNeeded() {
    final state = _state;
    if (state == null ||
        state.isGameOver ||
        lobby.gamePaused ||
        _botThinking ||
        state.currentPlayer.controllerType != PlayerControllerType.bot) {
      return;
    }
    final generation = _botGeneration;
    _botThinking = true;
    unawaited(() async {
      BotDecision decision;
      try {
        decision = await _botMoveProvider.chooseMove(
          state,
          state.currentPlayer.botSettings ?? BotSettings.standard,
        );
      } on Object {
        final fallback = _engine!.validator.legalMoves(state).first;
        decision = BotDecision(
          move: fallback,
          difficulty: BotDifficulty.beginner,
          estimatedValue: 0,
          nodesVisited: 0,
          completedDepth: 0,
          elapsedMilliseconds: 0,
        );
      }
      _botThinking = false;
      if (generation != _botGeneration ||
          _state?.revision != state.revision ||
          lobby.gamePaused) {
        return;
      }
      final transition = _engine!.submitMove(
        state,
        SubmitMoveAction(
          actionId: 'lan-bot:${lobby.roomId}:${state.revision}',
          playerId: state.currentPlayer.id,
          expectedRevision: state.revision,
          start: decision.move.start,
          end: decision.move.end,
        ),
      );
      if (transition.wasAccepted) {
        _acceptTransition(transition);
      }
    }());
  }

  void _handleDisconnect(_ClientContext context) {
    if (_clients.remove(context.socket) == null || _closing) {
      return;
    }
    final playerId = context.playerId;
    if (playerId == null) {
      return;
    }
    if (_clients.values.any((client) => client.playerId == playerId)) {
      return;
    }
    final index = lobby.seats.indexWhere((seat) => seat.playerId == playerId);
    if (index < 0) {
      return;
    }
    if (!lobby.started && playerId != lobby.hostPlayerId) {
      _sessionTokens.remove(playerId);
      _replaceSeat(index, LanSeat.empty(index));
      _broadcastLobby();
      return;
    }
    _replaceSeat(index, lobby.seats[index].copyWith(connected: false));
    if (lobby.started &&
        _state?.isGameOver != true &&
        !lobby.seats[index].isBot) {
      _botGeneration++;
      _turnTimer?.cancel();
      lobby = lobby.copyWith(gamePaused: true, revision: lobby.revision + 1);
      _broadcast(
        _envelope(LanMessageType.gamePaused, {
          'disconnectedPlayerId': playerId,
        }),
      );
    }
    _broadcastLobby();
  }

  void _handleDisconnectDecision(Map<String, Object?> payload) {
    final decision = payload['decision']! as String;
    final playerId = payload['playerId'] as String?;
    switch (decision) {
      case 'wait':
        return;
      case 'resume':
        resumeGame();
      case 'replace':
        if (playerId != null) {
          replaceDisconnectedWithBot(playerId);
        }
      case 'remove':
        if (playerId != null) {
          removeDisconnectedPlayer(playerId);
        }
    }
  }

  void resumeGame() {
    if (!lobby.started ||
        _state?.isGameOver == true ||
        lobby.seats.any(
          (seat) => seat.isOccupied && !seat.isBot && !seat.connected,
        )) {
      return;
    }
    lobby = lobby.copyWith(gamePaused: false, revision: lobby.revision + 1);
    _broadcast(
      _envelope(LanMessageType.gameResumed, {'revision': _state?.revision}),
    );
    _broadcastLobby();
    _scheduleNextTurn();
  }

  void replaceDisconnectedWithBot(String playerId) {
    final seatIndex = lobby.seats.indexWhere(
      (seat) => seat.playerId == playerId && !seat.connected && !seat.isBot,
    );
    final state = _state;
    if (seatIndex < 0 || state == null || state.isGameOver) {
      return;
    }
    final statePlayerIndex = state.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (statePlayerIndex < 0) {
      return;
    }
    final botSettings = BotSettings(
      difficulty: BotDifficulty.normal,
      personality: BotPersonality.balanced,
      thinkingTimeMs: 350,
    );
    final players = [...state.players];
    players[statePlayerIndex] = players[statePlayerIndex].copyWith(
      controllerType: PlayerControllerType.bot,
      botSettings: botSettings,
    );
    _state = state.copyWith(players: players, revision: state.revision + 1);
    _replaceSeat(
      seatIndex,
      lobby.seats[seatIndex].copyWith(
        controllerType: PlayerControllerType.bot,
        botSettings: botSettings,
        ready: true,
        connected: true,
      ),
    );
    _sessionTokens.remove(playerId);
    _resumeAfterHostDecision();
  }

  void removeDisconnectedPlayer(String playerId) {
    final seatIndex = lobby.seats.indexWhere(
      (seat) => seat.playerId == playerId && !seat.connected && !seat.isBot,
    );
    final state = _state;
    if (seatIndex < 0 || state == null || state.isGameOver) {
      return;
    }
    final playerIndex = state.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (playerIndex < 0) {
      return;
    }
    final players = [...state.players];
    players[playerIndex] = players[playerIndex].copyWith(
      bandsRemaining: 0,
      controllerType: PlayerControllerType.human,
      clearBotSettings: true,
    );
    var currentIndex = state.currentPlayerIndex;
    if (currentIndex == playerIndex) {
      for (var offset = 1; offset < players.length; offset++) {
        final candidate = (playerIndex + offset) % players.length;
        if (players[candidate].bandsRemaining > 0) {
          currentIndex = candidate;
          break;
        }
      }
    }
    _state = state.copyWith(
      players: players,
      currentPlayerIndex: currentIndex,
      revision: state.revision + 1,
    );
    _sessionTokens.remove(playerId);
    _replaceSeat(seatIndex, LanSeat.empty(seatIndex));
    _resumeAfterHostDecision();
  }

  void _resumeAfterHostDecision() {
    _botGeneration++;
    lobby = lobby.copyWith(gamePaused: false, revision: lobby.revision + 1);
    _broadcastLobby();
    _broadcastSnapshot();
    _broadcast(
      _envelope(LanMessageType.gameResumed, {'revision': _state!.revision}),
    );
    _gameController.add(_state!);
    _scheduleNextTurn();
  }

  void _replaceSeat(int index, LanSeat seat) {
    final seats = [...lobby.seats];
    seats[index] = seat;
    lobby = lobby.copyWith(seats: seats, revision: lobby.revision + 1);
  }

  void _broadcastLobby() {
    _lobbyController.add(lobby);
    _broadcast(
      _envelope(LanMessageType.lobbySnapshot, {'lobby': lobby.toJson()}),
    );
  }

  void _broadcastSnapshot() {
    for (final context in _clients.values) {
      if (context.playerId != null) {
        _sendSnapshot(context);
      }
    }
  }

  void _sendSnapshot(_ClientContext context) {
    final state = _state;
    if (state == null) {
      return;
    }
    _send(
      context,
      _envelope(LanMessageType.stateSnapshot, {
        'state': state.toJson(),
        'stateHash': GameStateHasher.hash(state),
      }, playerId: context.playerId),
    );
  }

  void _heartbeat() {
    if (_closing) {
      return;
    }
    final now = DateTime.now();
    for (final context in _clients.values.toList()) {
      if (now.difference(context.lastSeen) > const Duration(seconds: 8)) {
        unawaited(
          context.socket.close(WebSocketStatus.goingAway, 'heartbeat_timeout'),
        );
        continue;
      }
      _send(
        context,
        _envelope(LanMessageType.ping, {
          'sentAt': now.millisecondsSinceEpoch,
        }, playerId: context.playerId),
      );
    }
  }

  bool _isHost(_ClientContext context) =>
      context.playerId == lobby.hostPlayerId;

  LanEnvelope _envelope(
    LanMessageType type,
    Map<String, Object?> payload, {
    String? playerId,
  }) {
    return LanEnvelope(
      type: type,
      messageId: 'host:${_messageCounter++}',
      sequence: _outgoingSequence++,
      matchId: lobby.roomId,
      playerId: playerId,
      payload: payload,
    );
  }

  void _sendError(
    _ClientContext context,
    String code, {
    Map<String, Object?> details = const {},
  }) {
    _send(
      context,
      _envelope(LanMessageType.error, {
        'code': code,
        ...details,
      }, playerId: context.playerId),
    );
  }

  void _send(_ClientContext context, LanEnvelope envelope) {
    if (context.socket.readyState == WebSocket.open) {
      context.socket.add(envelope.encode());
    }
  }

  void _broadcast(LanEnvelope envelope) {
    for (final context in _clients.values) {
      if (context.playerId != null) {
        _send(context, envelope);
      }
    }
  }

  Future<void> close() async {
    if (_closing) {
      return;
    }
    _closing = true;
    _botGeneration++;
    _heartbeatTimer?.cancel();
    _turnTimer?.cancel();
    _broadcast(_envelope(LanMessageType.hostEnded, {'reason': 'host_closed'}));
    await Future.wait([
      for (final context in _clients.values)
        context.socket.close(WebSocketStatus.normalClosure),
    ]);
    _clients.clear();
    await _server.close(force: true);
    await _lobbyController.close();
    await _gameController.close();
  }

  static Future<HttpServer> _bindServer(
    InternetAddress address,
    int port,
  ) async {
    const attempts = 5;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        // A shared gameplay port can route a new connection to a server that
        // is still shutting down. Exclusive binding keeps room generations
        // isolated when a host immediately creates another room.
        return await HttpServer.bind(address, port, shared: false);
      } on SocketException {
        if (port == 0 || attempt == attempts - 1) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 120 * (attempt + 1)));
      }
    }
    throw StateError('Unable to bind LAN host port.');
  }

  static Future<String> _bestLocalIpv4Address() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final candidates = <({String address, int score})>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final value = address.address;
          if (address.isLoopback || _isLinkLocalIpv4(value)) {
            continue;
          }
          candidates.add((
            address: value,
            score: _interfaceScore(interface.name, value),
          ));
        }
      }
      candidates.sort((first, second) => second.score.compareTo(first.score));
      if (candidates.isNotEmpty) {
        return candidates.first.address;
      }
    } on Object {
      // Manual IP entry remains available when interface enumeration fails.
    }
    return InternetAddress.loopbackIPv4.address;
  }

  static int _interfaceScore(String interfaceName, String address) {
    final name = interfaceName.toLowerCase();
    var score = _isPrivateIpv4(address) ? 100 : 0;
    if (name.contains('wlan') ||
        name.contains('wifi') ||
        name.contains('softap') ||
        name.contains('hotspot') ||
        name == 'ap0') {
      score += 200;
    } else if (name.startsWith('en') || name.startsWith('eth')) {
      score += 160;
    }
    if (name.contains('rmnet') ||
        name.contains('ccmni') ||
        name.contains('pdp') ||
        name.contains('tun') ||
        name.contains('tap') ||
        name.contains('vpn') ||
        name.contains('virtual') ||
        name.contains('vbox') ||
        name.contains('docker')) {
      score -= 300;
    }
    return score;
  }

  static bool _isPrivateIpv4(String address) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) {
      return false;
    }
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  static bool _isLinkLocalIpv4(String address) =>
      address.startsWith('169.254.');

  static String _roomCode(String roomId) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var seed = roomId.codeUnits.fold<int>(
      23,
      (value, unit) => (value * 37 + unit) & 0x7FFFFFFF,
    );
    return List<String>.generate(6, (_) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      return alphabet[seed % alphabet.length];
    }).join();
  }
}

class _ClientContext {
  _ClientContext(this.socket);

  final WebSocket socket;
  String? playerId;
  String? sessionToken;
  var lastIncomingSequence = -1;
  var lastSeen = DateTime.now();
  var lastPong = DateTime.now();
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
