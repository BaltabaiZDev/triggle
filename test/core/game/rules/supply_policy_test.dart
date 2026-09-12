import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/game/models/board_size.dart';
import 'package:trigrid/core/game/rules/ruleset.dart';

void main() {
  group('BoardSize', () {
    test('Classic has the canonical geometry counts', () {
      final board = BoardSize.fromPreset(BoardSizePreset.classic);

      expect(board.expectedPegCount, 37);
      expect(board.expectedTriangleCount, 54);
      expect(board.potentialBandMoveCount, 48);
    });

    test('serializes without losing the preset or radius', () {
      final board = BoardSize.fromPreset(
        BoardSizePreset.custom,
        customRadius: 6,
      );

      expect(BoardSize.fromJson(board.toJson()), board);
    });
  });

  group('SupplyPolicy', () {
    final classic = BoardSize.fromPreset(BoardSizePreset.classic);

    test('uses the exact two-player Classic band limit', () {
      final supplies = SupplyPolicy.forMatch(
        boardSize: classic,
        playerCount: 2,
        ruleset: Ruleset.classic,
        rulesVersion: 1,
      );

      expect(supplies, const PlayerSupplies(bands: 10, markers: 21));
    });

    test('uses the exact three/four-player Classic supplies', () {
      for (final players in [3, 4]) {
        final supplies = SupplyPolicy.forMatch(
          boardSize: classic,
          playerCount: players,
          ruleset: Ruleset.classic,
          rulesVersion: 1,
        );

        expect(supplies, const PlayerSupplies(bands: 12, markers: 21));
      }
    });

    test('scales custom supplies and never exceeds the move fair share', () {
      final small = BoardSize.fromPreset(BoardSizePreset.small);
      final supplies = SupplyPolicy.forMatch(
        boardSize: small,
        playerCount: 4,
        ruleset: Ruleset.custom,
        rulesVersion: 1,
      );

      expect(small.potentialBandMoveCount, 12);
      expect(supplies, const PlayerSupplies(bands: 3, markers: 9));
    });

    test('rejects Classic rules on a non-Classic board', () {
      expect(
        () => SupplyPolicy.forMatch(
          boardSize: BoardSize.fromPreset(BoardSizePreset.large),
          playerCount: 2,
          ruleset: Ruleset.classic,
          rulesVersion: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
