class LanRoomAdvertisement {
  const LanRoomAdvertisement({
    required this.roomId,
    required this.roomCode,
    required this.roomName,
    required this.address,
    required this.port,
    required this.playerCount,
    required this.capacity,
    required this.protocolVersion,
  });

  factory LanRoomAdvertisement.fromJson(Map<String, Object?> json) {
    return LanRoomAdvertisement(
      roomId: json['roomId']! as String,
      roomCode: json['roomCode']! as String,
      roomName: json['roomName']! as String,
      address: json['address']! as String,
      port: json['port']! as int,
      playerCount: json['playerCount']! as int,
      capacity: json['capacity']! as int,
      protocolVersion: json['protocolVersion']! as int,
    );
  }

  final String roomId;
  final String roomCode;
  final String roomName;
  final String address;
  final int port;
  final int playerCount;
  final int capacity;
  final int protocolVersion;

  String get websocketUrl => 'ws://$address:$port/ws';

  String get qrPayload =>
      'trigrid://join?host=$address&port=$port&code=$roomCode'
      '&v=$protocolVersion';

  Map<String, Object> toJson() => {
    'roomId': roomId,
    'roomCode': roomCode,
    'roomName': roomName,
    'address': address,
    'port': port,
    'playerCount': playerCount,
    'capacity': capacity,
    'protocolVersion': protocolVersion,
  };
}
