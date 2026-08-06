import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:trigrid/core/network/trigrid_network.dart';

void main() {
  test('LAN gameplay binds one fixed production port', () async {
    final host = await LanHostServer.start(
      hostName: 'Port check',
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddress: InternetAddress.loopbackIPv4.address,
    );
    addTearDown(host.close);

    expect(LanHostServer.defaultPort, 42422);
    expect(host.port, LanHostServer.defaultPort);
  });

  test('LAN envelope round-trips and rejects incompatible versions', () {
    final envelope = LanEnvelope(
      type: LanMessageType.submitMove,
      messageId: 'message-1',
      sequence: 9,
      matchId: 'match-1',
      playerId: 'player-1',
      payload: const {'expectedRevision': 4},
    );

    final restored = LanEnvelope.decode(envelope.encode());
    expect(restored.type, LanMessageType.submitMove);
    expect(restored.sequence, 9);
    expect(restored.payload['expectedRevision'], 4);

    final incompatible = envelope.toJson()
      ..['protocolVersion'] = LanEnvelope.currentProtocolVersion + 1;
    expect(
      () => LanEnvelope.decode(jsonEncode(incompatible)),
      throwsA(isA<LanProtocolVersionException>()),
    );
  });

  test('discovery advertisement and QR link round-trip', () {
    const room = LanRoomAdvertisement(
      roomId: 'room-1',
      roomCode: 'ABC234',
      roomName: 'Kitchen table',
      address: '192.168.4.1',
      port: 4040,
      playerCount: 2,
      capacity: 4,
      protocolVersion: LanEnvelope.currentProtocolVersion,
    );

    final decoded = LanDiscoveryService.decodeAdvertisement(
      LanDiscoveryService.encodeAdvertisement(room),
    );
    final link = LanJoinLink.parse('  ${room.qrPayload}\n');

    expect(decoded?.roomId, room.roomId);
    expect(decoded?.websocketUrl, 'ws://192.168.4.1:4040/ws');
    expect(link.host, room.address);
    expect(link.port, room.port);
    expect(link.roomCode, room.roomCode);
    expect(link.roomId, room.roomId);
    expect(link.protocolVersion, LanEnvelope.currentProtocolVersion);

    final resolvedRoom = room.copyWith(address: '192.168.4.22');
    expect(
      link.resolveWebsocketUrl([resolvedRoom]),
      'ws://192.168.4.22:4040/ws',
    );
    expect(link.resolveWebsocketUrl(const []), link.websocketUrl);
  });

  test('invalid discovery traffic and join links are ignored', () {
    expect(
      LanDiscoveryService.decodeAdvertisement(utf8.encode('not json')),
      isNull,
    );
    expect(
      () => LanJoinLink.parse('https://example.com/room'),
      throwsFormatException,
    );
  });

  test('room departure packets expire the exact room generation', () {
    final packet = LanDiscoveryService.encodeDeparture('closed-room-id');

    expect(LanDiscoveryService.decodeDeparture(packet), 'closed-room-id');
    expect(LanDiscoveryService.decodeAdvertisement(packet), isNull);
    expect(
      LanDiscoveryService.decodeDeparture(utf8.encode('not json')),
      isNull,
    );
  });

  test('Bonjour metadata round-trips and prefers a resolved IPv4 address', () {
    const room = LanRoomAdvertisement(
      roomId: 'bonjour-room',
      roomCode: 'NSD234',
      roomName: 'Garden table',
      address: '192.168.4.1',
      port: 4040,
      playerCount: 3,
      capacity: 4,
      protocolVersion: LanEnvelope.currentProtocolVersion,
    );

    final encoded = LanBonjourCodec.serviceFor(room);
    final resolved = nsd.Service(
      name: encoded.name,
      type: encoded.type,
      host: 'trigrid-host.local',
      port: encoded.port,
      txt: encoded.txt,
      addresses: [InternetAddress('192.168.4.22')],
    );
    final decoded = LanBonjourCodec.decode(resolved);

    expect(encoded.type, LanDiscoveryService.bonjourServiceType);
    expect(decoded?.roomId, room.roomId);
    expect(decoded?.roomName, room.roomName);
    expect(decoded?.address, '192.168.4.22');
    expect(decoded?.playerCount, 3);
    expect(decoded?.capacity, 4);
  });

  test('Bonjour metadata rejects malformed and incompatible rooms', () {
    final invalid = nsd.Service(
      name: 'TriGrid-BAD',
      type: LanDiscoveryService.bonjourServiceType,
      port: 4040,
      host: 'trigrid-host.local',
      txt: const {},
    );
    final incompatibleRoom = LanBonjourCodec.serviceFor(
      const LanRoomAdvertisement(
        roomId: 'old-room',
        roomCode: 'OLD234',
        roomName: 'Old room',
        address: '192.168.1.3',
        port: 4040,
        playerCount: 1,
        capacity: 4,
        protocolVersion: LanEnvelope.currentProtocolVersion + 1,
      ),
    );

    expect(LanBonjourCodec.decode(invalid), isNull);
    expect(LanBonjourCodec.decode(incompatibleRoom), isNull);
  });

  test(
    'UDP fallback advertises and discovers a room without internet',
    () async {
      const room = LanRoomAdvertisement(
        roomId: 'udp-room',
        roomCode: 'UDP234',
        roomName: 'Offline table',
        address: '127.0.0.1',
        port: 4040,
        playerCount: 1,
        capacity: 4,
        protocolVersion: LanEnvelope.currentProtocolVersion,
      );
      final browser = await const LanDiscoveryService().browse();
      LanRoomAdvertiser? advertiser;
      addTearDown(() async {
        await advertiser?.close();
        await browser.close();
      });
      final discovered = browser.rooms
          .expand((rooms) => rooms)
          .firstWhere((candidate) => candidate.roomId == room.roomId)
          .timeout(const Duration(seconds: 4));

      advertiser = await const LanDiscoveryService().advertise(() => room);
      browser.probe();

      expect((await discovered).roomCode, room.roomCode);
    },
  );

  test(
    'persistent reconnect credentials round-trip with revision metadata',
    () {
      final savedAt = DateTime.utc(2026, 7, 30, 12, 34, 56);
      final credentials = LanReconnectCredentials(
        websocketUrl: 'ws://192.168.4.1:4040/ws',
        playerName: 'Aruzhan',
        roomCode: 'ABC234',
        playerId: 'player-2',
        sessionToken: 'private-token',
        matchId: 'match-9',
        lastRevision: 12,
        lastStateHash: 'abc123',
        savedAtUtc: savedAt,
      );

      final restored = LanReconnectCredentials.fromJson(credentials.toJson());

      expect(restored.websocketUrl, credentials.websocketUrl);
      expect(restored.playerName, credentials.playerName);
      expect(restored.sessionToken, credentials.sessionToken);
      expect(restored.lastRevision, 12);
      expect(restored.lastStateHash, 'abc123');
      expect(restored.savedAtUtc, savedAt);
    },
  );
}
