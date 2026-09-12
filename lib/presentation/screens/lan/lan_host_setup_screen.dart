import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'dart:async';
import 'package:trigrid/presentation/widgets/game_icon_controls.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/lan/lan_lobby_screen.dart';

class LanHostSetupScreen extends StatefulWidget {
  const LanHostSetupScreen({super.key});

  @override
  State<LanHostSetupScreen> createState() => _LanHostSetupScreenState();
}

class _LanHostSetupScreenState extends State<LanHostSetupScreen> {
  late final TextEditingController _playerNameController;
  late final TextEditingController _roomNameController;
  var _boardPreset = BoardSizePreset.classic;
  var _initialized = false;
  var _busy = false;
  var _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    if (!_initialized) {
      _initialized = true;
      final appController = Get.isRegistered<AppController>()
          ? Get.find<AppController>()
          : null;
      final savedName = appController?.preferences.value.playerName.trim();
      final playerName = savedName == null || savedName.isEmpty
          ? l10n.playerDefaultName(1)
          : savedName;
      final savedLan = appController?.preferences.value.lanSetup;
      if (savedLan != null) {
        _boardPreset = savedLan.boardPreset;
      }
      _playerNameController = TextEditingController(text: playerName);
      _roomNameController = TextEditingController(
        text: savedLan == null || savedLan.roomName.trim().isEmpty
            ? l10n.roomDefaultName(playerName)
            : savedLan.roomName,
      );
    }
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamePage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? const GamePress(child: BackButton())
            : null,
        title: Text(l10n.hostSetupTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _playerNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.playerNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _roomNameController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.roomNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.boardSizeLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    BoardSizeSelector(
                      value: _boardPreset,
                      includeCustom: false,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _boardPreset = value),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.lanConnectionFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    GamePress(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _createRoom,
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.wifi_tethering_rounded),
                        label: Text(l10n.createRoom),
                      ),
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

  Future<void> _createRoom() async {
    final l10n = AppLocalizations.of(context);
    final playerName = _playerNameController.text.trim();
    final roomName = _roomNameController.text.trim();
    if (playerName.isEmpty || roomName.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    LanHostServer? host;
    LanRoomAdvertiser? advertiser;
    LanClientConnection? client;
    try {
      final boardSize = BoardSize.fromPreset(_boardPreset);
      final appController = Get.isRegistered<AppController>()
          ? Get.find<AppController>()
          : null;
      if (appController != null) {
        final preferences = appController.preferences.value;
        await appController.updatePreferences(
          preferences.copyWith(
            playerName: playerName,
            lanSetup: LanSetupPreferences(
              roomName: roomName,
              boardPreset: _boardPreset,
              ruleset: boardSize.isClassic ? Ruleset.classic : Ruleset.custom,
              botSeats: preferences.lanSetup.botSeats,
              turnTimeSeconds: preferences.lanSetup.turnTimeSeconds,
            ),
          ),
        );
      }
      host = await LanHostServer.start(
        hostName: playerName,
        startingPlayerIndex:
            appController?.statistics.value.lan.matchesPlayed ?? 0,
        roomName: roomName,
        boardSize: boardSize,
        ruleset: boardSize.isClassic ? Ruleset.classic : Ruleset.custom,
        turnTimeSeconds:
            appController?.preferences.value.lanSetup.turnTimeSeconds,
      );
      try {
        advertiser = await const LanDiscoveryService().advertise(
          () => host!.advertisement,
        );
      } on Object {
        advertiser = null;
      }
      client = await LanClientConnection.connect(
        websocketUrl: host.loopbackWebsocketUrl,
        playerName: playerName,
        roomCode: host.lobby.roomCode,
        sessionToken: host.hostSessionToken,
      );
      if (!mounted) {
        await client.close();
        await advertiser?.close();
        await host.close();
        return;
      }
      final savedBots =
          appController?.preferences.value.lanSetup.botSeats ?? const {};
      for (final entry in savedBots.entries) {
        if (entry.key > 0 && entry.key < boardSize.maximumPlayers) {
          client.addBot(
            seatIndex: entry.key,
            displayName: l10n.botDefaultName(entry.key + 1),
            settings: entry.value,
          );
        }
      }
      await Get.off<void>(
        () =>
            LanLobbyScreen(client: client!, host: host, advertiser: advertiser),
      );
    } on Object {
      await client?.close();
      await advertiser?.close();
      await host?.close();
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }
}
