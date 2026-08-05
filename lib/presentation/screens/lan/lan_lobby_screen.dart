import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/lan_game_session_controller.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

class LanLobbyScreen extends StatefulWidget {
  const LanLobbyScreen({
    required this.client,
    this.host,
    this.advertiser,
    super.key,
  });

  final LanClientConnection client;
  final LanHostServer? host;
  final LanRoomAdvertiser? advertiser;

  @override
  State<LanLobbyScreen> createState() => _LanLobbyScreenState();
}

class _LanLobbyScreenState extends State<LanLobbyScreen> {
  StreamSubscription<LanEnvelope>? _messageSubscription;
  StreamSubscription<int>? _latencySubscription;
  late LanLobbyState _lobby;
  var _latency = 0;
  var _handedOff = false;

  @override
  void initState() {
    super.initState();
    _lobby = widget.client.latestLobby!;
    _latency = widget.client.latencyMilliseconds;
    _messageSubscription = widget.client.messages.listen(_handleMessage);
    _latencySubscription = widget.client.latencyChanges.listen((latency) {
      if (mounted) {
        setState(() => _latency = latency);
      }
    });
    if (_lobby.started && widget.client.latestGameState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGame());
    }
  }

  void _handleMessage(LanEnvelope envelope) {
    if (!mounted) {
      return;
    }
    if (envelope.type == LanMessageType.lobbySnapshot) {
      final previousPlayerCount = _lobby.occupiedSeatCount;
      final nextLobby = LanLobbyState.fromJson(
        envelope.payload['lobby']! as Map<String, Object?>,
      );
      setState(() {
        _lobby = nextLobby;
      });
      if (nextLobby.occupiedSeatCount > previousPlayerCount &&
          Get.isRegistered<GameFeedback>()) {
        playFeedback(Get.find<GameFeedback>().playerJoin());
      }
      _saveHostLobbyPreferences();
    } else if (envelope.type == LanMessageType.matchStarted) {
      _lobby = _lobby.copyWith(started: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _openGame());
    }
  }

  void _saveHostLobbyPreferences() {
    if (!widget.client.isHost || !Get.isRegistered<AppController>()) {
      return;
    }
    final controller = Get.find<AppController>();
    final preferences = controller.preferences.value;
    unawaited(
      controller.updatePreferences(
        preferences.copyWith(
          lanSetup: preferences.lanSetup.copyWith(
            roomName: _lobby.roomName,
            boardPreset: _lobby.boardSize.preset,
            ruleset: _lobby.ruleset,
            botSeats: {
              for (final seat in _lobby.seats)
                if (seat.isBot) seat.seatIndex: seat.botSettings!,
            },
            turnTimeSeconds: _lobby.turnTimeSeconds,
            clearTurnTime: _lobby.turnTimeSeconds == null,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _latencySubscription?.cancel();
    if (!_handedOff) {
      unawaited(widget.client.close());
      final advertiser = widget.advertiser;
      if (advertiser != null) {
        unawaited(advertiser.close());
      }
      final host = widget.host;
      if (host != null) {
        unawaited(host.close());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localSeat = _lobby.seats.firstWhere(
      (seat) => seat.playerId == widget.client.playerId,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.lobbyTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(child: Text(l10n.connectionLatency(_latency))),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 14,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _lobby.roomName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                l10n.roomCodeDisplay(_lobby.roomCode),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (widget.host != null)
                                Text(
                                  l10n.hostAddressDisplay(
                                    widget.host!.advertisedAddress,
                                    widget.host!.port,
                                  ),
                                ),
                              Text(
                                l10n.playersConnected(_lobby.occupiedSeatCount),
                              ),
                            ],
                          ),
                          if (widget.host != null)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: QrImageView(
                                  data: widget.host!.advertisement.qrPayload,
                                  size: 116,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.client.isHost) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<BoardSizePreset>(
                      initialValue: _lobby.boardSize.preset,
                      decoration: InputDecoration(
                        labelText: l10n.boardSizeLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final preset in [
                          BoardSizePreset.small,
                          BoardSizePreset.classic,
                          BoardSizePreset.large,
                          BoardSizePreset.huge,
                        ])
                          DropdownMenuItem(
                            value: preset,
                            child: Text(_boardLabel(l10n, preset)),
                          ),
                      ],
                      onChanged: _lobby.started
                          ? null
                          : (preset) {
                              if (preset == null) {
                                return;
                              }
                              final board = BoardSize.fromPreset(preset);
                              widget.client.updateRoom(
                                boardSize: board,
                                ruleset: board.isClassic
                                    ? _lobby.ruleset
                                    : Ruleset.custom,
                                turnTimeSeconds: _lobby.turnTimeSeconds,
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Ruleset>(
                      initialValue: _lobby.ruleset,
                      decoration: InputDecoration(
                        labelText: l10n.rulesetLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: Ruleset.classic,
                          child: Text(l10n.classicRules),
                        ),
                        DropdownMenuItem(
                          value: Ruleset.custom,
                          child: Text(l10n.customRules),
                        ),
                      ],
                      onChanged: _lobby.started || !_lobby.boardSize.isClassic
                          ? null
                          : (ruleset) {
                              if (ruleset != null) {
                                widget.client.updateRoom(
                                  boardSize: _lobby.boardSize,
                                  ruleset: ruleset,
                                  turnTimeSeconds: _lobby.turnTimeSeconds,
                                );
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_lobby.turnTimeSeconds),
                      initialValue: _lobby.turnTimeSeconds ?? 0,
                      decoration: InputDecoration(
                        labelText: l10n.turnTimerLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(l10n.turnTimerOff),
                        ),
                        for (final seconds in [30, 60, 90])
                          DropdownMenuItem(
                            value: seconds,
                            child: Text(l10n.turnTimerSeconds(seconds)),
                          ),
                      ],
                      onChanged: _lobby.started
                          ? null
                          : (seconds) {
                              if (seconds != null) {
                                widget.client.updateRoom(
                                  boardSize: _lobby.boardSize,
                                  ruleset: _lobby.ruleset,
                                  turnTimeSeconds: seconds == 0
                                      ? null
                                      : seconds,
                                );
                              }
                            },
                    ),
                  ],
                  const SizedBox(height: 14),
                  for (final seat in _lobby.seats) ...[
                    _SeatCard(
                      seat: seat,
                      isHostSeat: seat.playerId == _lobby.hostPlayerId,
                      isLocalSeat: seat.playerId == widget.client.playerId,
                      unavailableColors: {
                        for (final other in _lobby.seats)
                          if (other.isOccupied &&
                              other.playerId != widget.client.playerId)
                            other.colorIndex,
                      },
                      canManage:
                          widget.client.isHost &&
                          seat.seatIndex > 0 &&
                          !_lobby.started,
                      onAddBot: () => widget.client.addBot(
                        seatIndex: seat.seatIndex,
                        displayName: l10n.botDefaultName(seat.seatIndex + 1),
                        settings: BotSettings(difficulty: BotDifficulty.normal),
                      ),
                      onRemove: () => widget.client.removeSeat(seat.seatIndex),
                      onSelectColor: widget.client.selectColor,
                      onBotDifficulty: (difficulty) {
                        widget.client.updateBot(
                          seatIndex: seat.seatIndex,
                          settings: seat.botSettings!.copyWith(
                            difficulty: difficulty,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (!widget.client.isHost)
                    SwitchListTile.adaptive(
                      value: localSeat.ready,
                      title: Text(
                        localSeat.ready
                            ? l10n.readyStatus
                            : l10n.notReadyStatus,
                      ),
                      secondary: const Icon(Icons.how_to_reg_rounded),
                      onChanged: _lobby.started ? null : widget.client.setReady,
                    ),
                  const SizedBox(height: 10),
                  if (widget.client.isHost) ...[
                    if (!_lobby.canStart)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          l10n.waitingForPlayers,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _lobby.canStart && !_lobby.started
                          ? widget.client.startMatch
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(l10n.startLanMatch),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openGame() {
    if (_handedOff || !mounted) {
      return;
    }
    final state = widget.client.latestGameState;
    if (state == null) {
      return;
    }
    _handedOff = true;
    final feedback = Get.isRegistered<GameFeedback>()
        ? Get.find<GameFeedback>()
        : GameFeedbackCoordinator();
    final ownsFeedback = !Get.isRegistered<GameFeedback>();
    final session = LanGameSessionController(
      client: widget.client,
      ownedHost: widget.host,
      ownedAdvertiser: widget.advertiser,
      feedback: feedback,
      initialFeelSettings: Get.isRegistered<AppController>()
          ? Get.find<AppController>().preferences.value.gameFeel
          : null,
      disposeFeedbackOnClose: ownsFeedback,
    );
    Get.off<void>(() => GameScreen(settings: state.settings, session: session));
  }

  String _boardLabel(AppLocalizations l10n, BoardSizePreset preset) {
    return switch (preset) {
      BoardSizePreset.small => l10n.boardSizeSmall,
      BoardSizePreset.classic => l10n.boardSizeClassic,
      BoardSizePreset.large => l10n.boardSizeLarge,
      BoardSizePreset.huge => l10n.boardSizeHuge,
      BoardSizePreset.custom => l10n.boardSizeCustom,
    };
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard({
    required this.seat,
    required this.isHostSeat,
    required this.isLocalSeat,
    required this.unavailableColors,
    required this.canManage,
    required this.onAddBot,
    required this.onRemove,
    required this.onSelectColor,
    required this.onBotDifficulty,
  });

  final LanSeat seat;
  final bool isHostSeat;
  final bool isLocalSeat;
  final Set<int> unavailableColors;
  final bool canManage;
  final VoidCallback onAddBot;
  final VoidCallback onRemove;
  final ValueChanged<int> onSelectColor;
  final ValueChanged<BotDifficulty> onBotDifficulty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!seat.isOccupied) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.event_seat_outlined),
          title: Text(l10n.openSeat),
          trailing: canManage
              ? TextButton.icon(
                  onPressed: onAddBot,
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: Text(l10n.addBot),
                )
              : null,
        ),
      );
    }
    final visuals = PlayerVisuals.forSeat(seat.colorIndex);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: visuals.color,
              foregroundColor: Colors.white,
              child: Icon(
                seat.isBot
                    ? Icons.smart_toy_rounded
                    : _markerIcon(visuals.markerShape),
              ),
            ),
            title: Row(
              children: [
                Flexible(child: Text(seat.displayName!)),
                if (isHostSeat) ...[
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(l10n.hostBadge),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              [
                if (seat.isBot)
                  '${l10n.botDifficultyLabel}: '
                      '${_difficultyLabel(l10n, seat.botSettings!.difficulty)}',
                seat.connected ? l10n.connectedStatus : l10n.disconnectedStatus,
                seat.ready ? l10n.readyStatus : l10n.notReadyStatus,
              ].join(' · '),
            ),
            trailing: canManage && (seat.isBot || !seat.connected)
                ? IconButton(
                    tooltip: l10n.removeSeat,
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  )
                : Icon(
                    seat.ready
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_empty_rounded,
                    color: seat.ready
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
          ),
          if (isLocalSeat && !seat.isBot)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    l10n.playerColorLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (var index = 0; index < 4; index++)
                          Tooltip(
                            message: _colorLabel(l10n, index),
                            child: ChoiceChip(
                              selected: seat.colorIndex == index,
                              onSelected: unavailableColors.contains(index)
                                  ? null
                                  : (_) => onSelectColor(index),
                              showCheckmark: false,
                              label: Icon(
                                _markerIcon(
                                  PlayerVisuals.forSeat(index).markerShape,
                                ),
                                size: 18,
                                color: PlayerVisuals.forSeat(index).color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (canManage && seat.isBot)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DropdownButtonFormField<BotDifficulty>(
                initialValue: seat.botSettings!.difficulty,
                decoration: InputDecoration(
                  labelText: l10n.botDifficultyLabel,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final difficulty in BotDifficulty.values)
                    DropdownMenuItem(
                      value: difficulty,
                      child: Text(_difficultyLabel(l10n, difficulty)),
                    ),
                ],
                onChanged: (difficulty) {
                  if (difficulty != null) {
                    onBotDifficulty(difficulty);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _markerIcon(PlayerMarkerShape shape) {
    return switch (shape) {
      PlayerMarkerShape.circle => Icons.circle,
      PlayerMarkerShape.diamond => Icons.diamond,
      PlayerMarkerShape.triangle => Icons.change_history,
      PlayerMarkerShape.square => Icons.square,
    };
  }

  String _colorLabel(AppLocalizations l10n, int index) {
    return switch (index) {
      0 => l10n.playerColorMoss,
      1 => l10n.playerColorCoral,
      2 => l10n.playerColorBlue,
      _ => l10n.playerColorGold,
    };
  }

  String _difficultyLabel(AppLocalizations l10n, BotDifficulty difficulty) {
    return switch (difficulty) {
      BotDifficulty.beginner => l10n.botDifficultyBeginner,
      BotDifficulty.easy => l10n.botDifficultyEasy,
      BotDifficulty.normal => l10n.botDifficultyNormal,
      BotDifficulty.hard => l10n.botDifficultyHard,
      BotDifficulty.expert => l10n.botDifficultyExpert,
    };
  }
}
