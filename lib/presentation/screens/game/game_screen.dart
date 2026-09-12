import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/lan_game_session_controller.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/presentation/widgets/game_icon_controls.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.settings,
    this.feedback,
    this.enablePassAndPlayHandoffs = false,
    this.session,
    this.persistMatch = true,
    this.tutorialMode = false,
    super.key,
  });

  final GameSettings settings;
  final GameFeedback? feedback;
  final bool enablePassAndPlayHandoffs;
  final LocalGameSessionController? session;
  final bool persistMatch;
  final bool tutorialMode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final String _controllerTag;
  late final LocalGameSessionController _session;
  late final TriGridFlameGame _game;
  late final Widget _cachedBoard;
  AppController? _appController;
  Timer? _turnTimer;
  int? _turnSecondsRemaining;
  var _exiting = false;
  var _readyToPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controllerTag = widget.settings.matchId;
    _appController = Get.isRegistered<AppController>()
        ? Get.find<AppController>()
        : null;
    final hasSharedFeedback = Get.isRegistered<GameFeedback>();
    final sessionFeedback =
        widget.feedback ??
        (hasSharedFeedback
            ? Get.find<GameFeedback>()
            : GameFeedbackCoordinator());
    _session = Get.put(
      widget.session ??
          LocalGameSessionController(
            widget.settings,
            feedback: sessionFeedback,
            initialFeelSettings: _appController?.preferences.value.gameFeel,
            enablePassAndPlayHandoffs: widget.enablePassAndPlayHandoffs,
            disposeFeedbackOnClose:
                widget.feedback == null && !hasSharedFeedback,
          ),
      tag: _controllerTag,
    );
    _session.onStateChanged = _handleStateChanged;
    _session.onMatchCompleted = _handleMatchCompleted;
    _game = TriGridFlameGame(session: _session, onMoveRequested: _requestMove);
    _cachedBoard = RepaintBoundary(child: GameWidget(game: _game));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStateChanged(_session.currentState);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.systemReducedMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _turnTimer?.cancel();
    _game.pauseEngine();
    Get.delete<LocalGameSessionController>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _session;
    if (session is LanGameSessionController) {
      session.handleLifecycle(state == AppLifecycleState.resumed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _session.currentState;
      final isPaused = _session.isPaused.value;
      final isBotThinking = _session.isBotThinking.value;
      final awaitingHandoff = _session.awaitingHandoff.value;
      final showResult = _session.showResult.value;
      final resultVisible = showResult && state.matchResult != null;
      final blocksGameSurface = awaitingHandoff || resultVisible;
      final feelSettings = _session.feelSettings.value;
      final lanSession = _session is LanGameSessionController ? _session : null;
      final networkErrorCode = lanSession?.networkErrorCode.value;
      final networkStatus = lanSession == null
          ? null
          : _networkStatusText(AppLocalizations.of(context), lanSession);
      final networkPaused = lanSession?.networkPaused.value ?? false;
      return PopScope(
        canPop: _session is! LanGameSessionController || _readyToPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_exit());
        },
        child: GameMotionScope(
          settings: feelSettings,
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    ignoring: blocksGameSurface,
                    child: ExcludeSemantics(
                      excluding: blocksGameSurface,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final showHud =
                              !state.isGameOver &&
                              !isPaused &&
                              !networkPaused &&
                              networkErrorCode != 'host_ended';
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(
                                child: _buildBoardSurface(
                                  isPaused: isPaused,
                                  showResult: resultVisible,
                                  feelSettings: feelSettings,
                                  networkPaused: networkPaused,
                                  networkErrorCode: networkErrorCode,
                                ),
                              ),
                              if (showHud)
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  top: 5,
                                  child: _GameToolbar(
                                    state: state,
                                    isBotThinking: isBotThinking,
                                    networkStatus: networkStatus,
                                    turnSecondsRemaining: _turnSecondsRemaining,
                                    onPause: _pause,
                                  ),
                                ),
                              if (showHud)
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: _CameraMoveButton(
                                    onPan: _game.panByCanvasDelta,
                                  ),
                                ),
                              if (showHud)
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: _GameCornerButton(
                                    tooltip: AppLocalizations.of(
                                      context,
                                    ).resetCamera,
                                    icon: Icons.refresh_rounded,
                                    onPressed: _game.resetCamera,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: GameSwitcher(
                      child: awaitingHandoff
                          ? _HandoffOverlay(
                              playerName: _session
                                  .currentState
                                  .currentPlayer
                                  .displayName,
                              onReady: _session.confirmHandoff,
                            )
                          : resultVisible
                          ? _ResultOverlay(
                              state: state,
                              onReplay: _replay,
                              onRestart: lanSession == null ? _restart : null,
                              onExit: _exit,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _networkStatusText(
    AppLocalizations l10n,
    LanGameSessionController session,
  ) {
    return switch (session.connectionStatus.value) {
      LanConnectionStatus.connected => l10n.connectionLatency(
        session.latencyMilliseconds.value,
      ),
      LanConnectionStatus.connecting ||
      LanConnectionStatus.reconnecting => l10n.connectionReconnecting,
      LanConnectionStatus.disconnected => l10n.connectionDisconnected,
      LanConnectionStatus.incompatible => l10n.connectionIncompatible,
      LanConnectionStatus.closed => l10n.connectionClosed,
    };
  }

  Widget _buildBoardSurface({
    required bool isPaused,
    required bool showResult,
    required GameFeelSettings feelSettings,
    required bool networkPaused,
    required String? networkErrorCode,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            label: AppLocalizations.of(context).boardSizeLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _game.handleTap(details.localPosition),
              onScaleStart: _game.beginScale,
              onScaleUpdate: _game.updateScale,
              onScaleEnd: _game.endScale,
              child: _cachedBoard,
            ),
          ),
        ),
        if (widget.tutorialMode && !showResult)
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: IgnorePointer(
              child: Center(
                child: _StatusChip(
                  icon: Icons.school_rounded,
                  label: _tutorialPrompt(AppLocalizations.of(context)),
                ),
              ),
            ),
          ),
        if (networkErrorCode != null &&
            networkErrorCode != 'host_ended' &&
            _session is LanGameSessionController)
          Positioned(
            left: 12,
            right: 12,
            top: widget.tutorialMode ? 48 : 8,
            child: Center(
              child: _NetworkErrorBanner(
                code: networkErrorCode,
                onDismiss: _session.clearNetworkError,
              ),
            ),
          ),
        Positioned.fill(
          child: GameSwitcher(
            child:
                networkErrorCode == 'host_ended' &&
                    _session is LanGameSessionController
                ? _HostEndedOverlay(
                    state: _session.currentState,
                    onSave:
                        _appController == null ||
                            _session.currentState.isGameOver
                        ? null
                        : _saveLanSnapshot,
                    onExit: _exit,
                  )
                : networkPaused && _session is LanGameSessionController
                ? _NetworkPauseOverlay(session: _session, onExit: _exit)
                : isPaused && !networkPaused
                ? _PauseOverlay(
                    settings: feelSettings,
                    onSettingsChanged: _updateFeelSettings,
                    onResume: _session.currentState.isGameOver ? null : _resume,
                    onRestart: _session is LanGameSessionController
                        ? null
                        : _restart,
                    onExit: _exit,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  void _pause() {
    if (_session.currentState.isGameOver) return;
    _session.buttonPress();
    _turnTimer?.cancel();
    _turnSecondsRemaining = null;
    _session.setPaused(true);
    _game.setPaused(true);
  }

  void _resume() {
    if (_session.currentState.isGameOver) return;
    _session.buttonPress();
    _session.setPaused(false);
    _game.setPaused(false);
    _resetTurnTimer(_session.currentState);
  }

  void _restart() {
    _session.buttonPress();
    _session.restart();
    _game.resetForNewMatch();
  }

  void _replay() {
    _session.buttonPress();
    _game.resetForReplay();
    unawaited(_session.replayAcceptedActions());
  }

  Future<void> _requestMove(GridCoordinate start, GridCoordinate end) async {
    final preferences = _appController?.preferences.value;
    if (preferences?.confirmMoves != true || widget.tutorialMode) {
      _session.submitMove(start, end);
      return;
    }
    final revision = _session.currentState.revision;
    final playerId = _session.currentState.currentPlayer.id;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmMoveTitle),
        content: Text(l10n.confirmMoveDescription),
        actions: [
          GamePress(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
          ),
          GamePress(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.placeBand),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true &&
        mounted &&
        _session.currentState.revision == revision &&
        _session.currentState.currentPlayer.id == playerId) {
      _session.submitMove(start, end);
    }
  }

  void _updateFeelSettings(GameFeelSettings next) {
    _session.updateFeelSettings(next);
    final appController = _appController;
    if (appController != null) {
      unawaited(
        appController.updatePreferences(
          appController.preferences.value.copyWith(gameFeel: next),
        ),
      );
    }
  }

  void _handleStateChanged(GameState state) {
    _resetTurnTimer(state);
    final appController = _appController;
    if (!widget.persistMatch ||
        widget.tutorialMode ||
        _session.isReplaying.value ||
        appController == null ||
        _session is LanGameSessionController ||
        state.isGameOver) {
      return;
    }
    unawaited(
      appController.saveLocalSnapshot(
        state: state,
        actions: _session.acceptedActions,
        passAndPlayHandoffs: widget.enablePassAndPlayHandoffs,
      ),
    );
  }

  void _resetTurnTimer(GameState state) {
    _turnTimer?.cancel();
    final configuredSeconds = state.settings.turnTimeSeconds;
    _turnSecondsRemaining = configuredSeconds == null || state.isGameOver
        ? null
        : configuredSeconds;
    if (_turnSecondsRemaining == null) {
      return;
    }
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _session.isPaused.value) {
        return;
      }
      final remaining = _turnSecondsRemaining;
      if (remaining == null || remaining <= 1) {
        timer.cancel();
        setState(() => _turnSecondsRemaining = 0);
        return;
      }
      setState(() => _turnSecondsRemaining = remaining - 1);
    });
  }

  void _handleMatchCompleted(
    GameState state,
    List<SubmitMoveAction> actions,
    int largestMultiCapture,
  ) {
    final appController = _appController;
    if (!widget.persistMatch || widget.tutorialMode || appController == null) {
      return;
    }
    final lanSession = _session is LanGameSessionController ? _session : null;
    final perspectivePlayerId =
        lanSession?.localPlayerId ??
        state.players
            .firstWhere(
              (player) => player.controllerType == PlayerControllerType.human,
              orElse: () => state.players.first,
            )
            .id;
    unawaited(
      appController.recordCompletedMatch(
        mode: lanSession == null ? MatchMode.local : MatchMode.lan,
        state: state,
        perspectivePlayerId: perspectivePlayerId,
        actions: actions,
        largestMultiCapture: largestMultiCapture,
      ),
    );
  }

  Future<void> _exit() async {
    if (_exiting) {
      return;
    }
    _exiting = true;
    _session.buttonPress();
    final session = _session;
    if (session is LanGameSessionController) {
      await session.shutdown();
      if (!mounted) return;
      setState(() => _readyToPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      });
      return;
    }
    if (!mounted) {
      return;
    }
    Get.back<void>();
  }

  Future<void> _saveLanSnapshot() async {
    final appController = _appController;
    if (appController == null) {
      return;
    }
    final saved = await appController.archiveLanSnapshot(_session.currentState);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? AppLocalizations.of(context).networkSnapshotSaved
              : AppLocalizations.of(context).networkSnapshotSaveFailed,
        ),
      ),
    );
  }

  String _tutorialPrompt(AppLocalizations l10n) {
    final revision = _session.currentState.revision;
    if (revision == 0) {
      return l10n.tutorialGameFirstMove;
    }
    if (revision < 3) {
      return l10n.tutorialGameConnected;
    }
    return l10n.tutorialGameCapture;
  }
}

class _GameToolbar extends StatelessWidget {
  const _GameToolbar({
    required this.state,
    required this.isBotThinking,
    required this.networkStatus,
    required this.turnSecondsRemaining,
    required this.onPause,
  });

  final GameState state;
  final bool isBotThinking;
  final String? networkStatus;
  final int? turnSecondsRemaining;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = state.currentPlayer;
    final visuals = PlayerVisuals.forSeat(player.visualIndex);
    final theme = Theme.of(context);
    const shadow = [
      Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
    ];
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 13,
                      height: 26,
                      decoration: BoxDecoration(
                        color: visuals.color,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GameSwitcher(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              player.displayName,
                              key: ValueKey(player.id),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: shadow,
                              ),
                            ),
                          ),
                          Text(
                            '${player.bandsRemaining} / ${player.markersRemaining}'
                            '${turnSecondsRemaining == null ? '' : ' · ${l10n.turnTimerCompact(turnSecondsRemaining!)}'}',
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 9,
                              shadows: shadow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isBotThinking) ...[
                      const SizedBox(width: 6),
                      SizedBox.square(
                        dimension: 12,
                        child: CircularProgressIndicator(
                          color: visuals.color,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                    if (networkStatus != null) ...[
                      const SizedBox(width: 5),
                      Tooltip(
                        message: networkStatus,
                        child: const Icon(
                          Icons.wifi_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          for (final scorePlayer in state.players) ...[
            _MiniScore(
              player: scorePlayer,
              active: scorePlayer.id == player.id,
            ),
            const SizedBox(width: 5),
          ],
          GamePress(
            child: IconButton(
              tooltip: l10n.pauseGame,
              onPressed: onPause,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 44),
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 29,
                color: Colors.white,
                shadows: shadow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.player, required this.active});

  final PlayerState player;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final visuals = PlayerVisuals.forSeat(player.visualIndex);
    final semanticsLabel =
        '${player.displayName}, '
        '${AppLocalizations.of(context).scoreLabel(player.score)}';
    return Semantics(
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: GamePulse(
          value: '${player.score}:$active',
          color: visuals.color,
          child: AnimatedContainer(
            duration: GameMotionScope.duration(context, 240),
            curve: const GameSpringCurve(),
            width: 29,
            height: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: visuals.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.white : Colors.black,
                width: active ? 3 : 2,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black87, offset: Offset(1, 2)),
              ],
            ),
            child: Text(
              '${player.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraMoveButton extends StatelessWidget {
  const _CameraMoveButton({required this.onPan});

  final ValueChanged<Offset> onPan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.moveBoard,
      child: Semantics(
        button: true,
        label: l10n.moveBoard,
        child: GamePress(
          sound: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onPan(details.delta),
            child: const _CornerControlSurface(icon: Icons.open_with_rounded),
          ),
        ),
      ),
    );
  }
}

class _GameCornerButton extends StatelessWidget {
  const _GameCornerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: GamePress(
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4),
            child: _CornerControlSurface(icon: icon),
          ),
        ),
      ),
    );
  }
}

class _CornerControlSurface extends StatelessWidget {
  const _CornerControlSurface({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: SizedBox.square(
        dimension: 42,
        child: Icon(
          icon,
          size: 25,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HandoffOverlay extends StatelessWidget {
  const _HandoffOverlay({required this.playerName, required this.onReady});

  final String playerName;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      key: const Key('private-handoff-surface'),
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.passDeviceTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.passDeviceDescription(playerName),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                GamePress(
                  child: FilledButton.icon(
                    onPressed: onReady,
                    icon: const Icon(Icons.visibility_rounded),
                    label: Text(l10n.readyForTurn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkPauseOverlay extends StatelessWidget {
  const _NetworkPauseOverlay({required this.session, required this.onExit});
  final LanGameSessionController session;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final missing =
        session.lobby.value?.seats
            .where((seat) => seat.isOccupied && !seat.isBot && !seat.connected)
            .toList() ??
        const <LanSeat>[];
    return ColoredBox(
      color: const Color(0xCE0E1F19),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 34),
                  const SizedBox(height: 16),
                  Text(
                    l10n.networkGamePaused,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    missing.isEmpty
                        ? l10n.networkPlayerReconnected
                        : l10n.networkWaitingFor(
                            missing
                                .map((seat) => seat.displayName)
                                .whereType<String>()
                                .join(', '),
                          ),
                    textAlign: TextAlign.center,
                  ),
                  if (session.isHost && missing.isNotEmpty)
                    for (final seat in missing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(seat.displayName ?? l10n.humanPlayer),
                            ),
                            GameIconAction(
                              label: l10n.replaceWithBot,
                              icon: Icons.smart_toy_rounded,
                              onPressed: () => session.resolveDisconnect(
                                'replace',
                                seat.playerId!,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GameIconAction(
                              label: l10n.removePlayer,
                              icon: Icons.person_remove_rounded,
                              onPressed: () => session.resolveDisconnect(
                                'remove',
                                seat.playerId!,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (session.isHost &&
                          missing.isEmpty &&
                          !session.currentState.isGameOver &&
                          session.client.isConnected) ...[
                        GameIconAction(
                          label: l10n.resumeGame,
                          icon: Icons.play_arrow_rounded,
                          primary: true,
                          size: 64,
                          onPressed: () =>
                              session.resolveDisconnect('resume', ''),
                        ),
                        const SizedBox(width: 16),
                      ],
                      GameIconAction(
                        label: l10n.exitToMenu,
                        icon: Icons.home_rounded,
                        onPressed: onExit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkErrorBanner extends StatelessWidget {
  const _NetworkErrorBanner({required this.code, required this.onDismiss});

  final String code;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (code) {
      'state_hash_mismatch' => l10n.networkIntegrityError,
      'state_resynchronized' => l10n.networkStateResynchronized,
      'reconnect_failed' => l10n.networkReconnectFailed,
      _ => l10n.networkUnexpectedError,
    };
    final isInformational = code == 'state_resynchronized';
    return Material(
      elevation: 5,
      color: isInformational
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isInformational
                  ? Icons.sync_rounded
                  : Icons.warning_amber_rounded,
              size: 19,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            GamePress(
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostEndedOverlay extends StatelessWidget {
  const _HostEndedOverlay({
    required this.state,
    required this.onSave,
    required this.onExit,
  });
  final GameState state;
  final Future<void> Function()? onSave;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xCE0E1F19),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    l10n.networkHostEndedTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onSave != null &&
                          state.revision > 0 &&
                          !state.isGameOver) ...[
                        GameIconAction(
                          label: l10n.saveLastPosition,
                          icon: Icons.save_outlined,
                          onPressed: onSave,
                        ),
                        const SizedBox(width: 16),
                      ],
                      GameIconAction(
                        label: l10n.exitToMenu,
                        icon: Icons.home_rounded,
                        primary: true,
                        size: 64,
                        onPressed: onExit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.settings,
    required this.onSettingsChanged,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });
  final GameFeelSettings settings;
  final ValueChanged<GameFeelSettings> onSettingsChanged;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0xB30E1F19),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.gamePaused,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _SettingsSlider(
                    icon: Icons.music_note_rounded,
                    label: l10n.musicVolume,
                    value: settings.musicVolume,
                    onChanged: (value) => onSettingsChanged(
                      settings.copyWith(musicVolume: value),
                    ),
                  ),
                  _SettingsSlider(
                    icon: Icons.volume_up_rounded,
                    label: l10n.soundEffectsVolume,
                    value: settings.soundEffectsVolume,
                    onChanged: (value) => onSettingsChanged(
                      settings.copyWith(soundEffectsVolume: value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameIconAction(
                        label: l10n.muteAll,
                        icon: settings.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        selected: settings.muted,
                        onPressed: () => onSettingsChanged(
                          settings.copyWith(muted: !settings.muted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GameIconAction(
                        label: l10n.haptics,
                        icon: Icons.vibration_rounded,
                        selected: settings.haptics,
                        onPressed: () => onSettingsChanged(
                          settings.copyWith(haptics: !settings.haptics),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GameIconAction(
                        label: l10n.reducedMotion,
                        icon: Icons.animation_rounded,
                        selected: settings.reducedMotion,
                        onPressed: () => onSettingsChanged(
                          settings.copyWith(
                            reducedMotion: !settings.reducedMotion,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onRestart != null) ...[
                        GameIconAction(
                          label: l10n.restartMatch,
                          icon: Icons.restart_alt_rounded,
                          onPressed: onRestart,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (onResume != null) ...[
                        GameIconAction(
                          label: l10n.resumeGame,
                          icon: Icons.play_arrow_rounded,
                          primary: true,
                          size: 68,
                          onPressed: onResume,
                        ),
                        const SizedBox(width: 16),
                      ],
                      GameIconAction(
                        label: l10n.backToSetup,
                        icon: Icons.home_rounded,
                        onPressed: onExit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Tooltip(message: label, child: Icon(icon, size: 22)),
      Expanded(
        child: GamePress(
          sound: false,
          child: Slider(
            value: value,
            divisions: 10,
            label: label,
            semanticFormatterCallback: (value) =>
                '$label ${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.state,
    required this.onReplay,
    required this.onRestart,
    required this.onExit,
  });

  final GameState state;
  final VoidCallback onReplay;
  final VoidCallback? onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = state.matchResult!;
    final names = state.players
        .where((p) => result.winnerPlayerIds.contains(p.id))
        .map((p) => p.displayName)
        .toList();
    return ColoredBox(
      key: const Key('match-result-surface'),
      color: const Color(0xB30E1F19),
      child: Center(
        child: GameCelebration(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 370),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameReveal(
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 48,
                        color: Color(0xFFF1D57B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.matchResultTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.isTie
                          ? l10n.tiedWinners(names.join(', '))
                          : l10n.winnerName(names.single),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    for (final player in state.players)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: PlayerVisuals.forSeat(
                                player.visualIndex,
                              ).color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${player.score}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color:
                                        result.winnerPlayerIds.contains(
                                          player.id,
                                        )
                                        ? const Color(0xFFF1D57B)
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameIconAction(
                          label: l10n.replayMatch,
                          icon: Icons.movie_rounded,
                          onPressed: onReplay,
                        ),
                        const SizedBox(width: 16),
                        if (onRestart != null) ...[
                          GameIconAction(
                            label: l10n.restartMatch,
                            icon: Icons.restart_alt_rounded,
                            primary: true,
                            size: 64,
                            onPressed: onRestart,
                          ),
                          const SizedBox(width: 16),
                        ],
                        GameIconAction(
                          label: l10n.backToSetup,
                          icon: Icons.home_rounded,
                          onPressed: onExit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
