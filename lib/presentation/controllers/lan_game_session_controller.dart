import 'dart:async';

import 'package:get/get.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';
import 'package:uuid/uuid.dart';

class LanGameSessionController extends LocalGameSessionController {
  LanGameSessionController({
    required LanClientConnection client,
    this.ownedHost,
    this.ownedAdvertiser,
    GameFeedback feedback = const NoopGameFeedback(),
    GameFeelSettings? initialFeelSettings,
    bool disposeFeedbackOnClose = true,
  }) : _client = client,
       super(
         client.latestGameState!.settings,
         feedback: feedback,
         initialFeelSettings: initialFeelSettings,
         feedbackPerspectivePlayerId: client.playerId,
         disposeFeedbackOnClose: disposeFeedbackOnClose,
       ) {
    state.value = client.latestGameState!;
    lobby.value = client.latestLobby;
    networkPaused.value = client.latestLobby?.gamePaused ?? false;
    isPaused.value = networkPaused.value;
  }

  LanClientConnection _client;
  final LanHostServer? ownedHost;
  final LanRoomAdvertiser? ownedAdvertiser;
  StreamSubscription<LanEnvelope>? _messageSubscription;
  StreamSubscription<LanConnectionStatus>? _statusSubscription;
  StreamSubscription<int>? _latencySubscription;
  final connectionStatus = LanConnectionStatus.connected.obs;
  final latencyMilliseconds = 0.obs;
  final isReconnecting = false.obs;
  final networkErrorCode = RxnString();
  final Rxn<LanLobbyState> lobby = Rxn<LanLobbyState>();
  final networkPaused = false.obs;
  var _networkAttempt = 0;
  var _reconnectGeneration = 0;
  Future<void>? _shutdownFuture;

  LanClientConnection get client => _client;

  String get localPlayerId => _client.playerId!;

  bool get isHost => _client.isHost;

  @override
  bool get canCurrentPlayerInteract =>
      super.canCurrentPlayerInteract &&
      currentState.currentPlayer.id == localPlayerId &&
      connectionStatus.value == LanConnectionStatus.connected;

  @override
  void onInit() {
    super.onInit();
    _attachClient(_client);
  }

  @override
  void onReady() {
    // The authoritative host, never a LAN client, runs automated seats.
    presentResultWhenReady();
  }

  @override
  GameTransition? submitMove(GridCoordinate start, GridCoordinate end) {
    if (isPaused.value ||
        isReplaying.value ||
        currentState.isGameOver ||
        !canCurrentPlayerInteract) {
      return null;
    }
    final action = SubmitMoveAction(
      actionId: 'lan:${const Uuid().v4()}:${_networkAttempt++}',
      playerId: localPlayerId,
      expectedRevision: currentState.revision,
      start: start,
      end: end,
    );
    _client.submitMove(action);
    return null;
  }

  @override
  void setPaused(bool value) {
    if (currentState.isGameOver ||
        connectionStatus.value == LanConnectionStatus.closed) {
      return;
    }
    isPaused.value = value || networkPaused.value;
  }

  @override
  void restart({bool newRound = true}) {
    // A LAN client cannot restart its local engine independently of the host.
  }

  void _attachClient(LanClientConnection next) {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _latencySubscription?.cancel();
    _client = next;
    connectionStatus.value = next.status;
    if (next.status == LanConnectionStatus.closed && !currentState.isGameOver) {
      networkErrorCode.value = 'host_ended';
    }
    latencyMilliseconds.value = next.latencyMilliseconds;
    lobby.value = next.latestLobby;
    networkPaused.value =
        !currentState.isGameOver && (next.latestLobby?.gamePaused ?? false);
    isPaused.value = networkPaused.value;
    _messageSubscription = next.messages.listen(_handleMessage);
    _statusSubscription = next.statusChanges.listen((status) {
      connectionStatus.value = status;
      if (status == LanConnectionStatus.closed && !currentState.isGameOver) {
        networkPaused.value = false;
        isPaused.value = false;
        networkErrorCode.value = 'host_ended';
      }
      if (status == LanConnectionStatus.disconnected &&
          !currentState.isGameOver) {
        unawaited(reconnect());
      }
    });
    _latencySubscription = next.latencyChanges.listen(
      (latency) => latencyMilliseconds.value = latency,
    );
  }

  void _handleMessage(LanEnvelope envelope) {
    switch (envelope.type) {
      case LanMessageType.actionAccepted:
        _applyAccepted(envelope);
      case LanMessageType.actionRejected:
        final code = MoveValidationErrorCode.values.byName(
          envelope.payload['errorCode']! as String,
        );
        showValidationError(code);
      case LanMessageType.stateSnapshot:
        _applySnapshot(envelope);
      case LanMessageType.gamePaused:
        if (!currentState.isGameOver) {
          networkPaused.value = true;
          isPaused.value = true;
        }
      case LanMessageType.gameResumed:
        networkPaused.value = false;
        isPaused.value = false;
        onStateChanged?.call(currentState);
      case LanMessageType.lobbySnapshot:
        lobby.value = LanLobbyState.fromJson(
          envelope.payload['lobby']! as Map<String, Object?>,
        );
      case LanMessageType.error:
        networkErrorCode.value = envelope.payload['code']! as String;
      case LanMessageType.hostEnded:
        _reconnectGeneration++;
        isReconnecting.value = false;
        connectionStatus.value = LanConnectionStatus.closed;
        networkPaused.value = false;
        isPaused.value = false;
        networkErrorCode.value = currentState.isGameOver ? null : 'host_ended';
      case LanMessageType.matchStarted ||
          LanMessageType.joinRequest ||
          LanMessageType.joinAccepted ||
          LanMessageType.setReady ||
          LanMessageType.selectColor ||
          LanMessageType.updateRoom ||
          LanMessageType.updateSeat ||
          LanMessageType.startMatch ||
          LanMessageType.submitMove ||
          LanMessageType.ping ||
          LanMessageType.pong ||
          LanMessageType.disconnectDecision:
        break;
    }
  }

  void _applyAccepted(LanEnvelope envelope) {
    if (isReplaying.value) return;
    final action = SubmitMoveAction.fromJson(
      envelope.payload['action']! as Map<String, Object?>,
    );
    final authoritativeState = GameState.fromJson(
      envelope.payload['state']! as Map<String, Object?>,
    );
    final expectedHash = envelope.payload['stateHash']! as String;
    final localTransition = engine.submitMove(currentState, action);
    if (GameStateHasher.hash(authoritativeState) != expectedHash) {
      networkErrorCode.value = 'state_hash_mismatch';
      return;
    }
    if (authoritativeState.revision < currentState.revision) return;
    if (acceptedActions.any((item) => item.actionId == action.actionId)) {
      if (authoritativeState.revision >= currentState.revision) {
        state.value = authoritativeState;
      }
      return;
    }
    if (localTransition.wasAccepted &&
        GameStateHasher.hash(localTransition.state) == expectedHash) {
      final transition = GameTransition(
        state: authoritativeState,
        validation: localTransition.validation,
        action: action,
      );
      applyConfirmedTransition(transition, allowHandoff: false);
    } else {
      state.value = authoritativeState;
      presentResultWhenReady();
      onStateChanged?.call(authoritativeState);
      if (authoritativeState.isGameOver) {
        onMatchCompleted?.call(
          authoritativeState,
          acceptedActions,
          largestMultiCapture,
        );
      }
      // Successful resync is recovery, not an error that needs a banner.
      networkErrorCode.value = null;
    }
    if (authoritativeState.isGameOver) {
      networkPaused.value = false;
      isPaused.value = false;
    }
  }

  void _applySnapshot(LanEnvelope envelope) {
    if (isReplaying.value) return;
    final authoritativeState = GameState.fromJson(
      envelope.payload['state']! as Map<String, Object?>,
    );
    final expectedHash = envelope.payload['stateHash']! as String;
    if (GameStateHasher.hash(authoritativeState) != expectedHash) {
      networkErrorCode.value = 'state_hash_mismatch';
      return;
    }
    if (authoritativeState.revision < currentState.revision) return;
    state.value = authoritativeState;
    presentResultWhenReady();
    if (authoritativeState.isGameOver) {
      networkPaused.value = false;
      isPaused.value = false;
    }
    onStateChanged?.call(authoritativeState);
    if (authoritativeState.isGameOver) {
      onMatchCompleted?.call(
        authoritativeState,
        acceptedActions,
        largestMultiCapture,
      );
    }
  }

  Future<void> reconnect() async {
    if (isReconnecting.value ||
        _shutdownFuture != null ||
        currentState.isGameOver ||
        connectionStatus.value == LanConnectionStatus.closed) {
      return;
    }
    final generation = ++_reconnectGeneration;
    isReconnecting.value = true;
    connectionStatus.value = LanConnectionStatus.reconnecting;
    for (var attempt = 0; attempt < 5; attempt++) {
      if (generation != _reconnectGeneration) {
        break;
      }
      try {
        final replacement = await _client.reconnect(
          timeout: const Duration(seconds: 4),
        );
        if (generation != _reconnectGeneration) {
          await replacement.close();
          break;
        }
        final previous = _client;
        _attachClient(replacement);
        unawaited(previous.close());
        final snapshot = replacement.latestGameState;
        if (snapshot != null) {
          state.value = snapshot;
          presentResultWhenReady();
          onStateChanged?.call(snapshot);
          if (snapshot.isGameOver) {
            networkPaused.value = false;
            isPaused.value = false;
            onMatchCompleted?.call(
              snapshot,
              acceptedActions,
              largestMultiCapture,
            );
          }
        }
        isReconnecting.value = false;
        networkErrorCode.value = null;
        return;
      } on LanConnectionException {
        if (generation != _reconnectGeneration) return;
        isReconnecting.value = false;
        connectionStatus.value = LanConnectionStatus.closed;
        networkPaused.value = false;
        isPaused.value = false;
        networkErrorCode.value = 'host_ended';
        return;
      } on Object {
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }
    if (generation != _reconnectGeneration) {
      return;
    }
    isReconnecting.value = false;
    connectionStatus.value = LanConnectionStatus.disconnected;
    networkErrorCode.value = 'reconnect_failed';
  }

  void handleLifecycle(bool resumed) {
    if (resumed &&
        !currentState.isGameOver &&
        connectionStatus.value == LanConnectionStatus.disconnected &&
        networkErrorCode.value != 'host_ended') {
      unawaited(reconnect());
    }
  }

  void resolveDisconnect(String decision, String playerId) {
    _client.decideDisconnect(decision: decision, playerId: playerId);
  }

  void clearNetworkError() {
    if (networkErrorCode.value != 'host_ended') networkErrorCode.value = null;
  }

  Future<void> shutdown() {
    return _shutdownFuture ??= _shutdown();
  }

  Future<void> _shutdown() async {
    _reconnectGeneration++;
    isReconnecting.value = false;
    await Future.wait([
      if (_messageSubscription != null) _messageSubscription!.cancel(),
      if (_statusSubscription != null) _statusSubscription!.cancel(),
      if (_latencySubscription != null) _latencySubscription!.cancel(),
    ]);
    // Stop announcing first, then tell guests that the host ended the room.
    // Awaiting this sequence prevents a newly created room from overlapping
    // the previous room on the fixed LAN port.
    await ownedAdvertiser?.close();
    await ownedHost?.close();
    await _client.close();
  }

  @override
  void onClose() {
    unawaited(shutdown());
    super.onClose();
  }
}
