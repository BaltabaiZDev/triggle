import 'package:trigrid/core/network/models/lan_room_advertisement.dart';

class LanJoinLink {
  const LanJoinLink({
    required this.host,
    required this.port,
    required this.roomCode,
    required this.protocolVersion,
    this.roomId,
  });

  factory LanJoinLink.parse(String value) {
    final uri = Uri.parse(value.trim());
    if (uri.scheme != 'trigrid' || uri.host != 'join') {
      throw const FormatException('Not a TriGrid join link.');
    }
    final host = uri.queryParameters['host']?.trim();
    final port = int.tryParse(uri.queryParameters['port'] ?? '');
    final code = uri.queryParameters['code']?.trim();
    final version = int.tryParse(uri.queryParameters['v'] ?? '');
    final roomId = uri.queryParameters['id']?.trim();
    if (host == null ||
        host.isEmpty ||
        port == null ||
        port <= 0 ||
        port > 65535 ||
        code == null ||
        code.isEmpty ||
        version == null) {
      throw const FormatException('Incomplete TriGrid join link.');
    }
    return LanJoinLink(
      host: host,
      port: port,
      roomCode: code.toUpperCase(),
      protocolVersion: version,
      roomId: roomId == null || roomId.isEmpty ? null : roomId,
    );
  }

  final String host;
  final int port;
  final String roomCode;
  final int protocolVersion;
  final String? roomId;

  String get websocketUrl =>
      Uri(scheme: 'ws', host: host, port: port, path: '/ws').toString();

  String resolveWebsocketUrl(Iterable<LanRoomAdvertisement> discoveredRooms) {
    for (final room in discoveredRooms) {
      if (room.protocolVersion != protocolVersion) {
        continue;
      }
      final sameRoom = roomId == null
          ? room.roomCode.toUpperCase() == roomCode
          : room.roomId == roomId;
      if (sameRoom) {
        return room.websocketUrl;
      }
    }
    return websocketUrl;
  }
}
