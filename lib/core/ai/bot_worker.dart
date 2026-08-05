import 'dart:isolate';

import 'package:trigrid/core/ai/bot_decision.dart';
import 'package:trigrid/core/ai/bot_engine.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';

abstract interface class BotMoveProvider {
  Future<BotDecision> chooseMove(GameState state, BotSettings settings);
}

class BotWorker implements BotMoveProvider {
  const BotWorker();

  @override
  Future<BotDecision> chooseMove(GameState state, BotSettings settings) async {
    final request = <String, Object?>{
      'state': state.toJson(),
      'botSettings': settings.toJson(),
    };
    final response = await Isolate.run(
      () => _runBotSearch(request),
      debugName: 'trigrid-bot-${settings.difficulty.name}',
    );
    return BotDecision.fromJson(response);
  }
}

Map<String, Object?> _runBotSearch(Map<String, Object?> request) {
  final state = GameState.fromJson(request['state']! as Map<String, Object?>);
  final settings = BotSettings.fromJson(
    request['botSettings']! as Map<String, Object?>,
  );
  return BotEngine(state.settings).chooseMove(state, settings).toJson();
}
