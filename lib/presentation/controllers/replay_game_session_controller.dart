import 'dart:async';

import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

class ReplayGameSessionController extends LocalGameSessionController {
  ReplayGameSessionController(
    this.replay, {
    GameFeelSettings? initialFeelSettings,
  }) : super(
         replay.settings,
         feedback: const NoopGameFeedback(),
         initialFeelSettings: initialFeelSettings,
       ) {
    ReplayRunner.run(replay);
    prepareReplayActions(replay.actions);
  }

  final GameReplay replay;

  @override
  void onReady() {
    unawaited(replayAcceptedActions());
  }

  @override
  GameTransition? submitMove(GridCoordinate start, GridCoordinate end) => null;

  @override
  Future<void> startAutomatedTurnIfNeeded() async {}

  @override
  void restart({bool newRound = true}) {
    super.restart(newRound: false);
    prepareReplayActions(replay.actions);
    unawaited(replayAcceptedActions());
  }
}
