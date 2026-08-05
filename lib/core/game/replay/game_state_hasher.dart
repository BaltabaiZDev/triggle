import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:trigrid/core/game/game_state/game_state.dart';
import 'package:trigrid/core/game/replay/canonical_json.dart';

abstract final class GameStateHasher {
  static String hash(GameState state) {
    final canonicalState = CanonicalJson.encode(state.toJson());
    return sha256.convert(utf8.encode(canonicalState)).toString();
  }
}
