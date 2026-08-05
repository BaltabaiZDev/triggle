import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/presentation/controllers/replay_game_session_controller.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

void main() {
  test('replay viewer controller reproduces the verified final hash', () async {
    final settings = GameSettings(
      matchId: 'viewer-replay',
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
      players: [
        PlayerConfiguration(
          id: 'one',
          displayName: 'One',
          controllerType: PlayerControllerType.human,
        ),
        PlayerConfiguration(
          id: 'two',
          displayName: 'Two',
          controllerType: PlayerControllerType.human,
        ),
      ],
      seed: 29,
    );
    final engine = GameEngine(settings);
    var state = engine.createInitialState(settings);
    final actions = <SubmitMoveAction>[];
    while (!state.isGameOver) {
      final move = engine.validator.legalMoves(state).first;
      final action = SubmitMoveAction(
        actionId: 'viewer-${state.revision}',
        playerId: state.currentPlayer.id,
        expectedRevision: state.revision,
        start: move.start,
        end: move.end,
      );
      state = engine.submitMove(state, action).state;
      actions.add(action);
    }
    final hash = GameStateHasher.hash(state);
    final controller = ReplayGameSessionController(
      GameReplay(settings: settings, actions: actions, expectedFinalHash: hash),
      initialFeelSettings: GameFeelSettings(reducedMotion: true),
    );

    await controller.replayAcceptedActions();

    expect(GameStateHasher.hash(controller.currentState), hash);
    expect(controller.currentState.isGameOver, isTrue);
    expect(controller.acceptedActions, hasLength(actions.length));
    expect(controller.isReplaying.value, isFalse);
  });
}
