class LanJoinLink {
  const LanJoinLink({
    required this.host,
    required this.port,
    required this.roomCode,
    required this.protocolVersion,
  });

  factory LanJoinLink.parse(String value) {
    final uri = Uri.parse(value);
    if (uri.scheme != 'trigrid' || uri.host != 'join') {
      throw const FormatException('Not a TriGrid join link.');
    }
    final host = uri.queryParameters['host'];
    final port = int.tryParse(uri.queryParameters['port'] ?? '');
    final code = uri.queryParameters['code'];
    final version = int.tryParse(uri.queryParameters['v'] ?? '');
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
    );
  }

  final String host;
  final int port;
  final String roomCode;
  final int protocolVersion;

  String get websocketUrl => 'ws://$host:$port/ws';
}
