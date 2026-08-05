# TriGrid LAN Protocol

This document defines TriGrid LAN protocol version 1. The implementation uses
an authoritative Flutter host device, WebSocket gameplay transport, native
DNS-SD/Bonjour discovery, and a UDP broadcast fallback. It requires no internet
service or remote backend.

## 1. Authority and transport

The host owns the only authoritative `GameEngine`, lobby, turn order, bot
workers, accepted-action cache, and state revision. A client sends requests and
does not apply a move until the host broadcasts `actionAccepted`. Every move,
including a host-owned bot move, passes through the same core `MoveValidator`.

- WebSocket endpoint: `ws://<host-ip>:42422/ws`
- Payload encoding: UTF-8 JSON text frames
- Discovery: native DNS-SD/Bonjour service `_trigrid._tcp`
- Discovery fallback: IPv4 UDP broadcast on port `42421`
- Fixed gameplay port: TCP `42422` (not user-configurable)
- Protocol version: `1`
- Supported room size: two to four occupied seats

Binary WebSocket frames are rejected. The host remains usable when it receives
malformed JSON, an invalid payload, or an unsupported client message.

## 2. Envelope

Every WebSocket message has this shape:

```json
{
  "protocolVersion": 1,
  "type": "submitMove",
  "messageId": "client:2fa7...:4",
  "sequence": 4,
  "matchId": "7942...",
  "playerId": "e572...",
  "payload": {}
}
```

| Field | Type | Meaning |
| --- | --- | --- |
| `protocolVersion` | integer | Must equal `1`; other versions are refused. |
| `type` | string | A `LanMessageType` name listed below. |
| `messageId` | non-empty string | Diagnostic identity for the packet. |
| `sequence` | non-negative integer | Monotonically increases for its sender/socket. |
| `matchId` | string or null | Room/match UUID when known. |
| `playerId` | string or null | Authenticated player UUID when known. |
| `payload` | object | Message-specific data. |

The client rejects host packets whose sequence is not greater than the last
host sequence it accepted. The host tracks the last client sequence per socket
and returns `out_of_order_message` for duplicates or older packets.

## 3. Handshake and identity

The first packet on a new socket must be `joinRequest`:

```json
{
  "playerName": "Aruzhan",
  "roomCode": "ABC234",
  "sessionToken": null
}
```

The host assigns an empty seat and returns `joinAccepted`:

```json
{
  "playerId": "e572...",
  "sessionToken": "31f8...",
  "isHost": false,
  "reconnected": false,
  "lobby": {},
  "gameState": null,
  "stateHash": null
}
```

`sessionToken` is a random, room-scoped bearer secret. It is never present in
UDP advertisements or QR codes. The client persists the WebSocket URL, player
name, room code, player ID, token, match ID, last state revision, last hash, and
save time. A reconnect repeats `joinRequest` with the saved token. Unknown
tokens are rejected with `invalid_session_token`; they never create a new seat.

On a valid reconnect, the host closes an older socket using the same player
identity, marks the seat connected, and returns the current lobby, full game
state, and hash. It also follows with a `stateSnapshot`.

## 4. Lobby messages

| Direction | Type | Payload |
| --- | --- | --- |
| Client → host | `setReady` | `{"ready": true}` |
| Client → host | `selectColor` | `{"colorIndex": 0..3}` |
| Host client → host | `updateRoom` | `{"boardSize": {...}, "ruleset": "classic", "turnTimeSeconds": 30}` |
| Host client → host | `updateSeat` | Add/remove/update a bot as described below. |
| Host client → host | `startMatch` | `{}` |
| Host → all | `lobbySnapshot` | `{"lobby": {...}}` |
| Host → all | `matchStarted` | `{"settings": {...}, "state": {...}, "stateHash": "..."}` |

Only the authenticated host player may update the room, manage seats, start the
match, or resolve a disconnect. Each human may set their own ready state and
choose an unused color/shape. Host readiness is always true. Non-Classic board
sizes force the `custom` ruleset.

`updateSeat` operations are:

```json
{"seatIndex": 2, "operation": "remove"}
```

```json
{
  "seatIndex": 2,
  "operation": "addBot",
  "displayName": "Bot 3",
  "botSettings": {
    "difficulty": "normal",
    "personality": "balanced",
    "thinkingTimeMs": 350,
    "deterministic": false,
    "seedOffset": 0
  }
}
```

```json
{
  "seatIndex": 2,
  "operation": "updateBot",
  "botSettings": {
    "difficulty": "expert",
    "personality": "balanced",
    "thinkingTimeMs": 350,
    "deterministic": false,
    "seedOffset": 0
  }
}
```

## 5. Gameplay messages

A client requests a move with `submitMove`:

```json
{
  "action": {
    "schemaVersion": 1,
    "type": "submitMove",
    "actionId": "lan:2fa7...",
    "playerId": "e572...",
    "expectedRevision": 12,
    "start": {"q": 0, "r": -1},
    "end": {"q": 0, "r": 2}
  }
}
```

The host verifies socket identity, match state, pause state, action ID,
revision, turn, supplies, geometry, connectivity, overlap, and captures. An
accepted action is broadcast as `actionAccepted`:

```json
{
  "action": {},
  "state": {},
  "stateHash": "sha256-hex",
  "capturedTriangleIds": ["triangle-id"]
}
```

The client first hashes the received state. When its local reduction of the
confirmed action produces the same hash, it uses the normal game-feel and
replay presentation path. Otherwise it adopts the verified authoritative state
and reports a resynchronization.

An invalid move produces `actionRejected`:

```json
{
  "actionId": "lan:2fa7...",
  "errorCode": "notPlayersTurn",
  "authoritativeRevision": 12,
  "stateHash": "sha256-hex"
}
```

Accepted payloads are cached by `actionId`. Repeating an accepted action returns
the original accepted payload to that client without reducing it again or
incrementing the revision. Periodic `stateSnapshot` packets are sent after
every five accepted actions and immediately after reconnect or a host
disconnect decision.

## 6. Heartbeat, loss, and backgrounding

The host sends `ping` every two seconds with `sentAt` epoch milliseconds. The
client measures latency and replies with `pong`. A socket with no incoming
traffic for eight seconds is closed.

When a human disconnects during a match, the host broadcasts `gamePaused` and
stops bot scheduling. The authenticated host may send `disconnectDecision`:

```json
{"decision": "wait", "playerId": "e572..."}
```

Valid decisions are:

- `wait`: keep the verified state paused;
- `resume`: resume only when all human seats are connected;
- `replace`: convert the disconnected player to a Normal/Balanced host bot;
- `remove`: exhaust that player's bands, skip them when necessary, and resume.

The app saves reconnect metadata when backgrounded and attempts token
reconnection when foregrounded after a lost socket. Five attempts use bounded
timeouts and increasing delays. Hash-verified full state replaces any stale
client state.

Host migration is not part of version 1. A deliberate host shutdown broadcasts
`hostEnded`; clients show a terminal network error and discard the now-invalid
token. The terminal surface lets the player archive the last hash-verified
position separately from the session credential.

An optional 10–300 second turn timer is configured by the host and serialized
in both lobby and match settings. Only the authoritative host owns expiry. On a
human timeout it submits the first deterministic legal move with a
`lan-timeout` action ID, then broadcasts the accepted transition and hash.
Clients display a countdown but never decide expiry locally.

## 7. Discovery and QR

The primary automatic-discovery path registers `_trigrid._tcp` through the
platform DNS-SD/Bonjour API. Its TXT metadata carries `id`, `code`, `room`,
`players`, `capacity`, `proto`, and `addr`; the service port is the WebSocket
port. Browsers reject malformed records and incompatible protocol versions.
Resolved non-loopback IPv4 addresses take precedence over the advertised
address.

As a best-effort fallback, the host broadcasts this UDP packet approximately
every 1.4 seconds and also answers an explicit probe:

```json
{
  "type": "trigrid_room_v1",
  "room": {
    "roomId": "7942...",
    "roomCode": "ABC234",
    "roomName": "Kitchen table",
    "address": "192.168.4.1",
    "port": 42422,
    "playerCount": 2,
    "capacity": 4,
    "protocolVersion": 1
  }
}
```

Browsers discard advertisements with another protocol version. Bonjour rooms
remain until the native service-lost event; UDP-only rooms are pruned after
five seconds without an advertisement. If routers block discovery or local
network permission is denied, manual IP and QR joining remain available once
the OS grants the connection itself.

Version-1 QR payload:

```text
trigrid://join?host=192.168.4.1&port=42422&code=ABC234&v=1
```

The scanner accepts only the `trigrid://join` scheme, valid host/port/code
fields, and the current protocol version. The encoded port is fixed at `42422`
for version-1 rooms and is never requested from the player. No player token is
encoded.

## 8. Errors

General `error` payloads use `{"code": "<machine_code>"}` and may add details.
Version 1 currently emits:

- `binary_not_supported`
- `incompatible_protocol`
- `invalid_envelope`
- `invalid_payload`
- `out_of_order_message`
- `join_required`
- `invalid_room_or_name`
- `invalid_session_token`
- `match_already_started`
- `room_full`
- `reconnect_seat_missing`
- `host_only`
- `unsupported_client_message`
- `match_not_started`
- `match_paused`
- `player_identity_mismatch`

UI text is localized from these machine-readable conditions; protocol strings
are never shown directly as player-facing copy.

## 9. Platform configuration and validation

Android declares Internet, network/Wi-Fi state, multicast, nearby Wi-Fi, and
camera permissions. The LAN entry flow requests nearby-Wi-Fi access when
needed. The current target is API 36; before raising the target to API 37 or
later, add the newer `ACCESS_LOCAL_NETWORK` declaration and runtime request.
iOS declares local-network and camera usage text plus the active
`_trigrid._tcp` Bonjour service. Native Bonjour avoids relying on the restricted
iOS multicast entitlement; UDP remains only a fallback where allowed.

Automated loopback integration covers room creation, join, lobby updates,
ready/start, color selection, bot configuration, host-authoritative timeout,
accepted/rejected/idempotent actions, incompatible credentials, disconnect
pause, persistent-token reconnect, snapshot/hash restore, resume, and bot
replacement. A separate two-client test plays through a terminal match and
requires both clients to agree with the host on every revision and final state
hash. The game-screen lifecycle test also proves pause-time credential
persistence and foreground token reconnection over real loopback WebSockets.

Before store release, run the following physical matrix because a Windows
loopback test cannot reproduce mobile multicast policy, router isolation, or
OS background suspension:

| Host | Client | Network | Required checks |
| --- | --- | --- | --- |
| Android | Android | Same Wi-Fi | Discovery, play, background/reconnect |
| Android | iOS | Same Wi-Fi | Discovery, QR, cross-platform state hashes |
| iOS | Android | Same Wi-Fi | Discovery, manual IP, host bots |
| iOS | iOS | Same Wi-Fi | Local-network prompt, play, reconnect |
| Android | Android/iOS | Android hotspot | Discovery or fallback, full match |
| iOS | Android/iOS | iOS hotspot | Discovery or fallback, full match |

Also verify an access point with client isolation enabled: discovery/direct
connection may fail, but the app must explain the failure and remain stable.

### Physical matrix evidence gate

Store physical-run evidence in
`build/device-acceptance/device_acceptance.json`. The strict release verifier
requires eight two-device match entries plus one client-isolation entry:

- `lan_matrix_android_host_android_client_same_wifi`
- `lan_matrix_android_host_ios_client_same_wifi`
- `lan_matrix_ios_host_android_client_same_wifi`
- `lan_matrix_ios_host_ios_client_same_wifi`
- `lan_matrix_android_hotspot_android_client`
- `lan_matrix_android_hotspot_ios_client`
- `lan_matrix_ios_hotspot_android_client`
- `lan_matrix_ios_hotspot_ios_client`
- `lan_matrix_client_isolation`

Each match entry records machine-reported physical host/client identities,
network path, discovery and fallback join methods, protocol version, terminal
revision, matching 64-character state hashes, offline operation, disconnect
pause, background/foreground reconnect, snapshot resynchronization, connection
quality, and host/client screenshots. Hotspot entries must prove QR or manual-IP
fallback. The same-Wi-Fi cross-platform entries additionally prove the QR and
manual-IP routes specified in the table. The isolation entry proves blocked
discovery/direct connection, a localized error, stable app behavior, and
screenshots. Every entry must set `acceptanceBuildId` to the output of
`dart tool/acceptance_build_id.dart`; the verifier independently computes
the current ID and rejects results captured from another source/build state.

Generate the current-build scaffold before starting the physical runs:

```sh
dart tool/create_lan_device_matrix_template.dart
```

It writes
`build/device-acceptance/lan_device_matrix.template.json`, prepopulates all
nine scenarios and their required routes, and refuses to replace an existing
file unless `--force` is supplied. Keep the template as a working copy, record
only observations from the named physical runs, and merge the completed
entries into `device_acceptance.json`. Its false/blank placeholders are
deliberate and cannot pass the release gate.

Inspect progress after each physical run:

```sh
dart tool/inspect_lan_device_matrix_progress.dart --verbose
```

The inspector checks every entry against the current acceptance build and
reports independent scenario progress without modifying the report. Use
`--json` for automation or `--report=<path>` after merging entries into the
shared acceptance report. It exits nonzero until all nine scenarios pass.

Once the working matrix is complete, merge it into a new report while
preserving the original:

```sh
dart tool/merge_lan_device_matrix.dart \
  --source=<completed-lan-report> \
  --target=build/device-acceptance/device_acceptance.json \
  --output=build/device-acceptance/device_acceptance.with_lan.json
```

The merge itself runs the strict current-build validator, refuses an existing
output, and rejects collisions unless `--replace-existing` is explicitly
provided. Then run the release gate against the merged output:

```sh
dart run tool/verify_lan_device_matrix.dart \
  --report=build/device-acceptance/device_acceptance.with_lan.json
```

The schema is intentionally stricter than a handwritten “tested” note. A green
verifier is still valid only when the report was produced from the stated
physical runs; the verifier does not manufacture or replace device evidence.
