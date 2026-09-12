import 'dart:convert';

import 'package:trigrid/core/network/protocol/lan_message_type.dart';

class LanEnvelope {
  factory LanEnvelope({
    required LanMessageType type,
    required String messageId,
    required int sequence,
    required Map<String, Object?> payload,
    String? matchId,
    String? playerId,
    int protocolVersion = currentProtocolVersion,
  }) {
    if (messageId.trim().isEmpty) {
      throw ArgumentError.value(messageId, 'messageId');
    }
    if (sequence < 0) {
      throw RangeError.value(sequence, 'sequence');
    }
    return LanEnvelope._(
      protocolVersion: protocolVersion,
      type: type,
      messageId: messageId,
      sequence: sequence,
      matchId: matchId,
      playerId: playerId,
      payload: Map<String, Object?>.unmodifiable(payload),
    );
  }

  const LanEnvelope._({
    required this.protocolVersion,
    required this.type,
    required this.messageId,
    required this.sequence,
    required this.matchId,
    required this.playerId,
    required this.payload,
  });

  factory LanEnvelope.fromJson(Map<String, Object?> json) {
    final version = json['protocolVersion']! as int;
    if (version != currentProtocolVersion) {
      throw LanProtocolVersionException(version);
    }
    return LanEnvelope(
      protocolVersion: version,
      type: LanMessageType.values.byName(json['type']! as String),
      messageId: json['messageId']! as String,
      sequence: json['sequence']! as int,
      matchId: json['matchId'] as String?,
      playerId: json['playerId'] as String?,
      payload: Map<String, Object?>.from(
        json['payload']! as Map<String, Object?>,
      ),
    );
  }

  factory LanEnvelope.decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('LAN envelope must be a JSON object.');
    }
    return LanEnvelope.fromJson(decoded);
  }

  // Rules v2 changes supplies; older clients must not silently replay v1 rules.
  static const currentProtocolVersion = 2;

  final int protocolVersion;
  final LanMessageType type;
  final String messageId;
  final int sequence;
  final String? matchId;
  final String? playerId;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'type': type.name,
    'messageId': messageId,
    'sequence': sequence,
    'matchId': matchId,
    'playerId': playerId,
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());
}

class LanProtocolVersionException implements FormatException {
  const LanProtocolVersionException(this.receivedVersion);

  final int receivedVersion;

  @override
  int? get offset => null;

  @override
  String get message =>
      'Incompatible LAN protocol $receivedVersion; '
      'expected ${LanEnvelope.currentProtocolVersion}.';

  @override
  Object? get source => null;

  @override
  String toString() => message;
}
