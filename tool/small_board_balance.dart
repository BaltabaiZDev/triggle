import 'dart:convert';
import 'dart:io';
import 'package:trigrid/core/game/trigrid_engine.dart';

/// Exact, offline two-seat small-board minimax; never runs on a user's phone.
/// Compares supply limits without changing the legal-move or scoring rules.
void main() {
  final settings = GameSettings(
    matchId: 'small-board-balance',
    boardSize: BoardSize.fromPreset(BoardSizePreset.small),
    ruleset: Ruleset.custom,
    players: [
      for (var i = 0; i < 2; i++)
        PlayerConfiguration(
          id: 'p$i',
          displayName: 'Player ${i + 1}',
          controllerType: PlayerControllerType.human,
        ),
    ],
    seed: 1,
  );
  final results = <Map<String, Object>>[];
  for (final bands in [3, 4, 5, 6]) {
    final engine = GameEngine(settings);
    final indices = {
      for (var i = 0; i < engine.board.bandMoves.length; i++)
        engine.board.bandMoves[i].id: i,
    };
    final memo = <String, int>{};
    var nodes = 0;
    int solve(GameState state) {
      if (state.isGameOver) {
        return state.players[0].score - state.players[1].score;
      }
      var mask = 0;
      for (final id in state.placedBandIds) {
        mask |= 1 << indices[id]!;
      }
      final key =
          '$mask:${state.currentPlayerIndex}:'
          '${state.players.map((p) => '${p.score}/${p.bandsRemaining}').join(',')}';
      if (memo.containsKey(key)) return memo[key]!;
      if (++nodes > 1000000) throw StateError('Probe safety budget exceeded.');
      final maximizing = state.currentPlayerIndex == 0;
      var best = maximizing ? -1000 : 1000;
      for (final move in engine.validator.legalMoves(state)) {
        final next = engine.submitMove(
          state,
          SubmitMoveAction(
            actionId: 'probe-${state.revision}',
            playerId: state.currentPlayer.id,
            expectedRevision: state.revision,
            start: move.start,
            end: move.end,
          ),
        );
        final value = solve(next.state);
        if (maximizing ? value > best : value < best) best = value;
      }
      return memo[key] = best;
    }

    final initial = engine.createInitialState(settings);
    final difference = solve(
      initial.copyWith(
        players: [
          for (final player in initial.players)
            player.copyWith(bandsRemaining: bands),
        ],
      ),
    );
    results.add({
      'bandsPerSeat': bands,
      'optimalFirstMinusSecond': difference,
      'states': nodes,
    });
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(results));
}
