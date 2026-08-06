import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nsd/nsd.dart' as nsd;
import 'package:trigrid/core/network/models/lan_room_advertisement.dart';
import 'package:trigrid/core/network/protocol/lan_envelope.dart';

class LanDiscoveryService {
  static const discoveryPort = 42421;
  static const bonjourServiceType = '_trigrid._tcp';
  static const _advertisementType = 'trigrid_room_v1';
  static const _departureType = 'trigrid_room_closed_v1';
  static const _probeType = 'trigrid_probe_v1';

  const LanDiscoveryService();

  Future<LanRoomAdvertiser> advertise(
    LanRoomAdvertisement Function() advertisement,
  ) async {
    return LanRoomAdvertiser.start(advertisement);
  }

  Future<LanRoomBrowser> browse() => LanRoomBrowser.start();

  static List<int> encodeAdvertisement(LanRoomAdvertisement advertisement) {
    return utf8.encode(
      jsonEncode({'type': _advertisementType, 'room': advertisement.toJson()}),
    );
  }

  static LanRoomAdvertisement? decodeAdvertisement(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?> ||
          decoded['type'] != _advertisementType) {
        return null;
      }
      return LanRoomAdvertisement.fromJson(
        decoded['room']! as Map<String, Object?>,
      );
    } on Object {
      return null;
    }
  }

  static List<int> encodeDeparture(String roomId) {
    return utf8.encode(
      jsonEncode({
        'type': _departureType,
        'roomId': roomId,
        'protocolVersion': LanEnvelope.currentProtocolVersion,
      }),
    );
  }

  static String? decodeDeparture(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, Object?> ||
          decoded['type'] != _departureType ||
          decoded['protocolVersion'] != LanEnvelope.currentProtocolVersion) {
        return null;
      }
      final roomId = decoded['roomId'];
      return roomId is String && roomId.isNotEmpty ? roomId : null;
    } on Object {
      return null;
    }
  }
}

abstract final class LanBonjourCodec {
  static nsd.Service serviceFor(LanRoomAdvertisement room) {
    return nsd.Service(
      name: 'TriGrid-${room.roomCode}',
      type: LanDiscoveryService.bonjourServiceType,
      port: room.port,
      txt: {
        'id': _encode(room.roomId),
        'code': _encode(room.roomCode),
        'room': _encode(room.roomName),
        'players': _encode('${room.playerCount}'),
        'capacity': _encode('${room.capacity}'),
        'proto': _encode('${room.protocolVersion}'),
        'addr': _encode(room.address),
      },
    );
  }

  static LanRoomAdvertisement? decode(nsd.Service service) {
    try {
      final txt = service.txt;
      final roomId = _read(txt, 'id');
      final roomCode = _read(txt, 'code');
      final roomName = _read(txt, 'room');
      final port = service.port;
      final playerCount = int.tryParse(_read(txt, 'players') ?? '');
      final capacity = int.tryParse(_read(txt, 'capacity') ?? '');
      final protocolVersion = int.tryParse(_read(txt, 'proto') ?? '');
      final address = _serviceAddress(service) ?? _read(txt, 'addr');
      if (roomId == null ||
          roomId.isEmpty ||
          roomCode == null ||
          roomCode.isEmpty ||
          roomName == null ||
          roomName.isEmpty ||
          address == null ||
          address.isEmpty ||
          port == null ||
          port < 1 ||
          port > 65535 ||
          playerCount == null ||
          playerCount < 1 ||
          capacity == null ||
          capacity < playerCount ||
          protocolVersion != LanEnvelope.currentProtocolVersion) {
        return null;
      }
      return LanRoomAdvertisement(
        roomId: roomId,
        roomCode: roomCode,
        roomName: roomName,
        address: address,
        port: port,
        playerCount: playerCount,
        capacity: capacity,
        protocolVersion: protocolVersion!,
      );
    } on Object {
      return null;
    }
  }

  static Uint8List _encode(String value) =>
      Uint8List.fromList(utf8.encode(value));

  static String? _read(Map<String, Uint8List?>? txt, String key) {
    final value = txt?[key];
    return value == null ? null : utf8.decode(value, allowMalformed: true);
  }

  static String? _serviceAddress(nsd.Service service) {
    for (final address in service.addresses ?? const <InternetAddress>[]) {
      if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
        return address.address;
      }
    }
    final host = service.host;
    return host == null || host.isEmpty ? null : host;
  }
}

class LanRoomAdvertiser {
  LanRoomAdvertiser._(
    this._socket,
    this._advertisement,
    this._bonjourRegistration,
  );

  static Future<LanRoomAdvertiser> start(
    LanRoomAdvertisement Function() advertisement,
  ) async {
    RawDatagramSocket? socket;
    nsd.Registration? bonjourRegistration;
    try {
      final room = advertisement();
      bonjourRegistration = await nsd.register(
        LanBonjourCodec.serviceFor(room),
      );
    } on Object {
      // UDP remains available when native DNS-SD cannot start.
    }
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        LanDiscoveryService.discoveryPort,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
    } on Object {
      if (bonjourRegistration == null) {
        rethrow;
      }
    }
    final advertiser = LanRoomAdvertiser._(
      socket,
      advertisement,
      bonjourRegistration,
    );
    if (socket != null) {
      advertiser._subscription = socket.listen(advertiser._onSocketEvent);
      advertiser._timer = Timer.periodic(
        const Duration(milliseconds: 1400),
        (_) => advertiser._broadcast(),
      );
      advertiser._broadcast();
    }
    return advertiser;
  }

  final RawDatagramSocket? _socket;
  final LanRoomAdvertisement Function() _advertisement;
  final nsd.Registration? _bonjourRegistration;
  StreamSubscription<RawSocketEvent>? _subscription;
  Timer? _timer;

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    Datagram? datagram;
    while ((datagram = _socket?.receive()) != null) {
      try {
        final decoded = jsonDecode(utf8.decode(datagram!.data));
        if (decoded is Map<String, Object?> &&
            decoded['type'] == LanDiscoveryService._probeType) {
          _sendTo(datagram.address);
        }
      } on Object {
        // Ignore unrelated UDP traffic on the discovery port.
      }
    }
  }

  void _broadcast() {
    final socket = _socket;
    if (socket == null) {
      return;
    }
    final bytes = LanDiscoveryService.encodeAdvertisement(_advertisement());
    socket.send(
      bytes,
      InternetAddress('255.255.255.255'),
      LanDiscoveryService.discoveryPort,
    );
  }

  void _sendTo(InternetAddress address) {
    _socket?.send(
      LanDiscoveryService.encodeAdvertisement(_advertisement()),
      address,
      LanDiscoveryService.discoveryPort,
    );
  }

  Future<void> close() async {
    _timer?.cancel();
    final socket = _socket;
    if (socket != null) {
      try {
        final bytes = LanDiscoveryService.encodeDeparture(
          _advertisement().roomId,
        );
        socket.send(
          bytes,
          InternetAddress('255.255.255.255'),
          LanDiscoveryService.discoveryPort,
        );
      } on Object {
        // The periodic expiry still removes the room if UDP goodbye is lost.
      }
    }
    await _subscription?.cancel();
    socket?.close();
    final registration = _bonjourRegistration;
    if (registration != null) {
      try {
        await nsd.unregister(registration);
      } on Object {
        // Closing gameplay must not be blocked by an NSD teardown failure.
      }
    }
  }
}

class LanRoomBrowser {
  LanRoomBrowser._(this._socket);

  static Future<LanRoomBrowser> start() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        LanDiscoveryService.discoveryPort,
        reuseAddress: true,
      );
      socket.broadcastEnabled = true;
    } on Object {
      socket = null;
    }
    final browser = LanRoomBrowser._(socket);
    if (socket != null) {
      browser._subscription = socket.listen(browser._onSocketEvent);
    }
    try {
      browser._bonjourDiscovery = await nsd.startDiscovery(
        LanDiscoveryService.bonjourServiceType,
        ipLookupType: nsd.IpLookupType.any,
      );
      browser._bonjourDiscovery!.addServiceListener(browser._onBonjourService);
      for (final service in browser._bonjourDiscovery!.services) {
        browser._onBonjourService(service, nsd.ServiceStatus.found);
      }
    } on Object {
      browser._bonjourDiscovery = null;
    }
    if (socket == null && browser._bonjourDiscovery == null) {
      throw StateError('No LAN discovery transport is available.');
    }
    browser._pruneTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => browser._prune(),
    );
    browser.probe();
    return browser;
  }

  final RawDatagramSocket? _socket;
  final Map<String, _SeenRoom> _rooms = {};
  final Map<String, String> _bonjourRoomIds = {};
  final StreamController<List<LanRoomAdvertisement>> _controller =
      StreamController<List<LanRoomAdvertisement>>.broadcast();
  StreamSubscription<RawSocketEvent>? _subscription;
  Timer? _pruneTimer;
  nsd.Discovery? _bonjourDiscovery;
  var _closed = false;

  Stream<List<LanRoomAdvertisement>> get rooms => _controller.stream;

  List<LanRoomAdvertisement> get currentRooms {
    final result =
        _rooms.values.map((seen) => seen.room).toList(growable: false)
          ..sort((first, second) => first.roomName.compareTo(second.roomName));
    return result;
  }

  void probe() {
    final socket = _socket;
    if (socket == null) {
      return;
    }
    final bytes = utf8.encode(
      jsonEncode({
        'type': LanDiscoveryService._probeType,
        'protocolVersion': LanEnvelope.currentProtocolVersion,
      }),
    );
    socket.send(
      bytes,
      InternetAddress('255.255.255.255'),
      LanDiscoveryService.discoveryPort,
    );
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    Datagram? datagram;
    var changed = false;
    while ((datagram = _socket?.receive()) != null) {
      final packet = datagram!;
      final departedRoomId = LanDiscoveryService.decodeDeparture(packet.data);
      if (departedRoomId != null) {
        changed = _rooms.remove(departedRoomId) != null || changed;
        continue;
      }
      final decoded = LanDiscoveryService.decodeAdvertisement(packet.data);
      final room = decoded?.copyWith(address: packet.address.address);
      if (room == null ||
          room.protocolVersion != LanEnvelope.currentProtocolVersion) {
        continue;
      }
      _recordRoom(room, persistent: false, seenViaUdp: true);
      changed = true;
    }
    if (changed) {
      _controller.add(currentRooms);
    }
  }

  void _onBonjourService(nsd.Service service, nsd.ServiceStatus status) {
    final serviceName = service.name;
    if (status == nsd.ServiceStatus.lost) {
      final roomId = serviceName == null
          ? null
          : _bonjourRoomIds.remove(serviceName);
      final seen = roomId == null ? null : _rooms[roomId];
      if (roomId != null && seen != null && seen.persistent) {
        _rooms[roomId] = _SeenRoom(
          seen.room,
          DateTime.now(),
          persistent: false,
          seenViaUdp: seen.seenViaUdp,
        );
        _controller.add(currentRooms);
      }
      return;
    }
    final room = LanBonjourCodec.decode(service);
    if (room == null) {
      return;
    }
    if (serviceName != null) {
      _bonjourRoomIds[serviceName] = room.roomId;
    }
    unawaited(_validateBonjourRoom(room));
  }

  Future<void> _validateBonjourRoom(LanRoomAdvertisement room) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final request = await client.getUrl(
        Uri(scheme: 'http', host: room.address, port: room.port, path: '/room'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 1),
      );
      if (response.statusCode != HttpStatus.ok) {
        return;
      }
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        return;
      }
      final liveRoom = LanRoomAdvertisement.fromJson(decoded);
      if (_closed ||
          liveRoom.roomId != room.roomId ||
          liveRoom.roomCode != room.roomCode ||
          liveRoom.protocolVersion != LanEnvelope.currentProtocolVersion) {
        _removeRoom(room.roomId);
        return;
      }
      _recordRoom(
        liveRoom.copyWith(address: room.address),
        persistent: true,
        seenViaUdp: false,
      );
      _controller.add(currentRooms);
    } on Object {
      _removeRoom(room.roomId);
    } finally {
      client.close(force: true);
    }
  }

  void _removeRoom(String roomId) {
    if (!_closed && _rooms.remove(roomId) != null) {
      _controller.add(currentRooms);
    }
  }

  void _recordRoom(
    LanRoomAdvertisement room, {
    required bool persistent,
    required bool seenViaUdp,
  }) {
    final previous = _rooms[room.roomId];
    _rooms[room.roomId] = _SeenRoom(
      room,
      DateTime.now(),
      persistent: persistent || (previous?.persistent ?? false),
      seenViaUdp: seenViaUdp || (previous?.seenViaUdp ?? false),
    );
  }

  void _prune() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 4));
    final previousLength = _rooms.length;
    _rooms.removeWhere(
      (_, seen) =>
          (!seen.persistent || seen.seenViaUdp) &&
          seen.lastSeen.isBefore(cutoff),
    );
    if (_rooms.length != previousLength) {
      _controller.add(currentRooms);
    }
  }

  Future<void> close() async {
    _closed = true;
    _pruneTimer?.cancel();
    await _subscription?.cancel();
    _socket?.close();
    final discovery = _bonjourDiscovery;
    if (discovery != null) {
      discovery.removeServiceListener(_onBonjourService);
      try {
        await nsd.stopDiscovery(discovery);
      } on Object {
        // UDP shutdown and the room browser remain deterministic.
      }
    }
    await _controller.close();
  }
}

class _SeenRoom {
  const _SeenRoom(
    this.room,
    this.lastSeen, {
    required this.persistent,
    required this.seenViaUdp,
  });

  final LanRoomAdvertisement room;
  final DateTime lastSeen;
  final bool persistent;
  final bool seenViaUdp;
}
