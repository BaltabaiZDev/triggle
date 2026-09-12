import 'package:trigrid/core/game/trigrid_engine.dart';

class LanSeat {
  const LanSeat({
    required this.seatIndex,
    required this.playerId,
    required this.displayName,
    required this.controllerType,
    required this.ready,
    required this.connected,
    required this.colorIndex,
    required this.botSettings,
  });

  factory LanSeat.empty(int seatIndex) {
    return LanSeat(
      seatIndex: seatIndex,
      playerId: null,
      displayName: null,
      controllerType: PlayerControllerType.human,
      ready: false,
      connected: false,
      colorIndex: seatIndex,
      botSettings: null,
    );
  }

  factory LanSeat.fromJson(Map<String, Object?> json) {
    return LanSeat(
      seatIndex: json['seatIndex']! as int,
      playerId: json['playerId'] as String?,
      displayName: json['displayName'] as String?,
      controllerType: PlayerControllerType.values.byName(
        json['controllerType']! as String,
      ),
      ready: json['ready']! as bool,
      connected: json['connected']! as bool,
      colorIndex: json['colorIndex']! as int,
      botSettings: json['botSettings'] == null
          ? null
          : BotSettings.fromJson(json['botSettings']! as Map<String, Object?>),
    );
  }

  final int seatIndex;
  final String? playerId;
  final String? displayName;
  final PlayerControllerType controllerType;
  final bool ready;
  final bool connected;
  final int colorIndex;
  final BotSettings? botSettings;

  bool get isOccupied => playerId != null;

  bool get isBot => controllerType == PlayerControllerType.bot;

  LanSeat copyWith({
    String? playerId,
    bool clearPlayer = false,
    String? displayName,
    PlayerControllerType? controllerType,
    bool? ready,
    bool? connected,
    int? colorIndex,
    BotSettings? botSettings,
    bool clearBotSettings = false,
  }) {
    return LanSeat(
      seatIndex: seatIndex,
      playerId: clearPlayer ? null : (playerId ?? this.playerId),
      displayName: clearPlayer ? null : (displayName ?? this.displayName),
      controllerType: controllerType ?? this.controllerType,
      ready: clearPlayer ? false : (ready ?? this.ready),
      connected: clearPlayer ? false : (connected ?? this.connected),
      colorIndex: colorIndex ?? this.colorIndex,
      botSettings: clearBotSettings ? null : (botSettings ?? this.botSettings),
    );
  }

  Map<String, Object?> toJson() => {
    'seatIndex': seatIndex,
    'playerId': playerId,
    'displayName': displayName,
    'controllerType': controllerType.name,
    'ready': ready,
    'connected': connected,
    'colorIndex': colorIndex,
    'botSettings': botSettings?.toJson(),
  };
}

class LanLobbyState {
  factory LanLobbyState({
    required String roomId,
    required String roomCode,
    required String roomName,
    required String hostPlayerId,
    required BoardSize boardSize,
    required Ruleset ruleset,
    required List<LanSeat> seats,
    required int revision,
    int? turnTimeSeconds,
    bool started = false,
    bool gamePaused = false,
  }) {
    return LanLobbyState._(
      roomId: roomId,
      roomCode: roomCode,
      roomName: roomName,
      hostPlayerId: hostPlayerId,
      boardSize: boardSize,
      ruleset: ruleset,
      seats: List<LanSeat>.unmodifiable(seats),
      revision: revision,
      turnTimeSeconds: turnTimeSeconds,
      started: started,
      gamePaused: gamePaused,
    );
  }

  const LanLobbyState._({
    required this.roomId,
    required this.roomCode,
    required this.roomName,
    required this.hostPlayerId,
    required this.boardSize,
    required this.ruleset,
    required this.seats,
    required this.revision,
    required this.turnTimeSeconds,
    required this.started,
    required this.gamePaused,
  });

  factory LanLobbyState.fromJson(Map<String, Object?> json) {
    return LanLobbyState(
      roomId: json['roomId']! as String,
      roomCode: json['roomCode']! as String,
      roomName: json['roomName']! as String,
      hostPlayerId: json['hostPlayerId']! as String,
      boardSize: BoardSize.fromJson(json['boardSize']! as Map<String, Object?>),
      ruleset: Ruleset.values.byName(json['ruleset']! as String),
      seats: (json['seats']! as List<Object?>)
          .map((item) => LanSeat.fromJson(item! as Map<String, Object?>))
          .toList(),
      revision: json['revision']! as int,
      turnTimeSeconds: json['turnTimeSeconds'] as int?,
      started: json['started']! as bool,
      gamePaused: json['gamePaused']! as bool,
    );
  }

  final String roomId;
  final String roomCode;
  final String roomName;
  final String hostPlayerId;
  final BoardSize boardSize;
  final Ruleset ruleset;
  final List<LanSeat> seats;
  final int revision;
  final int? turnTimeSeconds;
  final bool started;
  final bool gamePaused;

  int get occupiedSeatCount => seats.where((seat) => seat.isOccupied).length;
  int get capacity => boardSize.maximumPlayers;

  bool get canStart =>
      !started &&
      occupiedSeatCount >= 2 &&
      occupiedSeatCount <= capacity &&
      seats
          .where((seat) => seat.isOccupied && !seat.isBot)
          .every((seat) => seat.ready && seat.connected);

  LanLobbyState copyWith({
    BoardSize? boardSize,
    Ruleset? ruleset,
    List<LanSeat>? seats,
    int? revision,
    int? turnTimeSeconds,
    bool clearTurnTime = false,
    bool? started,
    bool? gamePaused,
  }) {
    return LanLobbyState(
      roomId: roomId,
      roomCode: roomCode,
      roomName: roomName,
      hostPlayerId: hostPlayerId,
      boardSize: boardSize ?? this.boardSize,
      ruleset: ruleset ?? this.ruleset,
      seats: seats ?? this.seats,
      revision: revision ?? this.revision,
      turnTimeSeconds: clearTurnTime
          ? null
          : (turnTimeSeconds ?? this.turnTimeSeconds),
      started: started ?? this.started,
      gamePaused: gamePaused ?? this.gamePaused,
    );
  }

  Map<String, Object?> toJson() => {
    'roomId': roomId,
    'roomCode': roomCode,
    'roomName': roomName,
    'hostPlayerId': hostPlayerId,
    'boardSize': boardSize.toJson(),
    'ruleset': ruleset.name,
    'seats': seats.map((seat) => seat.toJson()).toList(),
    'revision': revision,
    'turnTimeSeconds': turnTimeSeconds,
    'started': started,
    'gamePaused': gamePaused,
  };
}
