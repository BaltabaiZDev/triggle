import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/lan/lan_lobby_screen.dart';
import 'package:trigrid/presentation/screens/lan/lan_qr_scanner_screen.dart';

class LanJoinScreen extends StatefulWidget {
  const LanJoinScreen({super.key});

  @override
  State<LanJoinScreen> createState() => _LanJoinScreenState();
}

class _LanJoinScreenState extends State<LanJoinScreen> {
  late final TextEditingController _playerController;
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final LanReconnectStore _reconnectStore =
      SharedPreferencesLanReconnectStore();
  LanRoomBrowser? _browser;
  StreamSubscription<List<LanRoomAdvertisement>>? _roomSubscription;
  List<LanRoomAdvertisement> _rooms = const [];
  LanReconnectCredentials? _savedCredentials;
  var _initialized = false;
  var _busy = false;
  var _failed = false;
  var _discoveryFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final savedName = Get.isRegistered<AppController>()
          ? Get.find<AppController>().preferences.value.playerName.trim()
          : '';
      _playerController = TextEditingController(
        text: savedName.isEmpty
            ? AppLocalizations.of(context).playerDefaultName(1)
            : savedName,
      );
      unawaited(_startDiscovery());
      unawaited(_loadSavedReconnect());
    }
  }

  Future<void> _startDiscovery() async {
    try {
      final browser = await const LanDiscoveryService().browse();
      if (!mounted) {
        await browser.close();
        return;
      }
      _browser = browser;
      _roomSubscription = browser.rooms.listen((rooms) {
        if (mounted) {
          setState(() => _rooms = rooms);
        }
      });
      setState(() => _rooms = browser.currentRooms);
    } on Object {
      if (mounted) {
        setState(() => _discoveryFailed = true);
      }
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    unawaited(_browser?.close());
    _playerController.dispose();
    _hostController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinSetupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _playerController,
                    decoration: InputDecoration(
                      labelText: l10n.playerNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_savedCredentials != null) ...[
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.savedLanMatch,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.roomCodeDisplay(_savedCredentials!.roomCode)} · ${_savedCredentials!.websocketUrl}',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _busy ? null : _forgetSaved,
                                  child: Text(l10n.forgetSavedLan),
                                ),
                                FilledButton.icon(
                                  onPressed: _busy ? null : _reconnectSaved,
                                  icon: const Icon(Icons.sync_rounded),
                                  label: Text(l10n.reconnectSavedLan),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    l10n.discoveredRooms,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_rooms.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (!_discoveryFailed)
                              const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(Icons.info_outline_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _discoveryFailed
                                    ? l10n.discoveryUnavailable
                                    : l10n.scanningNetwork,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final room in _rooms)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.wifi_rounded),
                          title: Text(room.roomName),
                          subtitle: Text(
                            '${room.roomCode} · '
                            '${l10n.playersConnected(room.playerCount)}',
                          ),
                          trailing: const Icon(Icons.login_rounded),
                          onTap: _busy ? null : () => _connectRoom(room),
                        ),
                      ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.manualJoin,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _busy ? null : _scanQr,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(l10n.scanQr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _hostController,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: l10n.hostAddressLabel,
                              hintText: l10n.hostAddressExample,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: l10n.roomCodeLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          if (_failed) ...[
                            const SizedBox(height: 10),
                            Text(
                              l10n.lanConnectionFailed,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _manualConnect,
                              icon: _busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(l10n.connectToRoom),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _connectRoom(LanRoomAdvertisement room) {
    _hostController.text = room.address;
    _codeController.text = room.roomCode;
    unawaited(_connect(room.websocketUrl, room.roomCode));
  }

  Future<void> _loadSavedReconnect() async {
    try {
      final saved = await _reconnectStore.load();
      if (mounted) {
        setState(() => _savedCredentials = saved);
      }
    } on Object {
      // Joining by discovery, IP, or QR remains available without storage.
    }
  }

  void _reconnectSaved() {
    final saved = _savedCredentials;
    if (saved == null) {
      return;
    }
    final uri = Uri.parse(saved.websocketUrl);
    _playerController.text = saved.playerName;
    _hostController.text = uri.host;
    _codeController.text = saved.roomCode;
    unawaited(
      _connect(
        saved.websocketUrl,
        saved.roomCode,
        sessionToken: saved.sessionToken,
      ),
    );
  }

  Future<void> _forgetSaved() async {
    await _reconnectStore.clear();
    if (mounted) {
      setState(() => _savedCredentials = null);
    }
  }

  void _manualConnect() {
    final host = _hostController.text.trim();
    final code = _codeController.text.trim();
    if (host.isEmpty || code.isEmpty) {
      setState(() => _failed = true);
      return;
    }
    unawaited(_connect('ws://$host:${LanHostServer.defaultPort}/ws', code));
  }

  Future<void> _scanQr() async {
    final link = await Get.to<LanJoinLink>(() => const LanQrScannerScreen());
    if (link == null || !mounted) {
      return;
    }
    _hostController.text = link.host;
    _codeController.text = link.roomCode;
    await _connect(link.websocketUrl, link.roomCode);
  }

  Future<void> _connect(String url, String code, {String? sessionToken}) async {
    final playerName = _playerController.text.trim();
    if (playerName.isEmpty || _busy) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    LanClientConnection? client;
    try {
      client = await LanClientConnection.connect(
        websocketUrl: url,
        playerName: playerName,
        roomCode: code,
        sessionToken: sessionToken,
      );
      try {
        await _reconnectStore.save(
          LanReconnectCredentials.fromConnection(client),
        );
      } on Object {
        // Storage failure must not prevent an otherwise valid LAN join.
      }
      if (Get.isRegistered<AppController>()) {
        final appController = Get.find<AppController>();
        await appController.updatePreferences(
          appController.preferences.value.copyWith(playerName: playerName),
        );
      }
      if (!mounted) {
        await client.close();
        return;
      }
      await Get.off<void>(() => LanLobbyScreen(client: client!));
    } on Object {
      await client?.close();
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }
}
