import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trigrid/core/network/session/lan_client_connection.dart';

class LanReconnectCredentials {
  const LanReconnectCredentials({
    required this.websocketUrl,
    required this.playerName,
    required this.roomCode,
    required this.playerId,
    required this.sessionToken,
    required this.matchId,
    required this.lastRevision,
    required this.lastStateHash,
    required this.savedAtUtc,
  });

  factory LanReconnectCredentials.fromConnection(
    LanClientConnection connection, {
    DateTime? savedAt,
  }) {
    final playerId = connection.playerId;
    final sessionToken = connection.sessionToken;
    if (playerId == null || sessionToken == null) {
      throw StateError('The LAN connection has not completed its handshake.');
    }
    return LanReconnectCredentials(
      websocketUrl: connection.websocketUrl,
      playerName: connection.playerName,
      roomCode: connection.roomCode,
      playerId: playerId,
      sessionToken: sessionToken,
      matchId: connection.latestLobby?.roomId,
      lastRevision: connection.latestGameState?.revision,
      lastStateHash: connection.latestStateHash,
      savedAtUtc: (savedAt ?? DateTime.now()).toUtc(),
    );
  }

  factory LanReconnectCredentials.fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion']! as int;
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported LAN reconnect schema $schemaVersion.');
    }
    return LanReconnectCredentials(
      websocketUrl: json['websocketUrl']! as String,
      playerName: json['playerName']! as String,
      roomCode: json['roomCode']! as String,
      playerId: json['playerId']! as String,
      sessionToken: json['sessionToken']! as String,
      matchId: json['matchId'] as String?,
      lastRevision: json['lastRevision'] as int?,
      lastStateHash: json['lastStateHash'] as String?,
      savedAtUtc: DateTime.parse(json['savedAtUtc']! as String).toUtc(),
    );
  }

  static const currentSchemaVersion = 1;

  final String websocketUrl;
  final String playerName;
  final String roomCode;
  final String playerId;
  final String sessionToken;
  final String? matchId;
  final int? lastRevision;
  final String? lastStateHash;
  final DateTime savedAtUtc;

  Map<String, Object?> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'websocketUrl': websocketUrl,
    'playerName': playerName,
    'roomCode': roomCode,
    'playerId': playerId,
    'sessionToken': sessionToken,
    'matchId': matchId,
    'lastRevision': lastRevision,
    'lastStateHash': lastStateHash,
    'savedAtUtc': savedAtUtc.toIso8601String(),
  };
}

abstract interface class LanReconnectStore {
  Future<void> save(LanReconnectCredentials credentials);

  Future<LanReconnectCredentials?> load();

  Future<void> clear();
}

class SharedPreferencesLanReconnectStore implements LanReconnectStore {
  SharedPreferencesLanReconnectStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const storageKey = 'trigrid.lan.reconnect.v1';

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<void> save(LanReconnectCredentials credentials) {
    return _store.setString(storageKey, jsonEncode(credentials.toJson()));
  }

  @override
  Future<LanReconnectCredentials?> load() async {
    final encoded = await _store.getString(storageKey);
    if (encoded == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Reconnect data must be an object.');
      }
      return LanReconnectCredentials.fromJson(decoded);
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() => _store.remove(storageKey);
}
