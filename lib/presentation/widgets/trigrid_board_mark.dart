import 'dart:math' as math;

import 'package:flutter/material.dart';

class TriGridBoardMark extends StatelessWidget {
  const TriGridBoardMark({
    required this.semanticsLabel,
    this.size = 160,
    super.key,
  });

  final String semanticsLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: const _BoardMarkPainter()),
        ),
      ),
    );
  }
}

class _BoardMarkPainter extends CustomPainter {
  const _BoardMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.44;
    final boardPath = Path();

    for (var index = 0; index < 6; index++) {
      final angle = -math.pi / 2 + index * math.pi / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        boardPath.moveTo(point.dx, point.dy);
      } else {
        boardPath.lineTo(point.dx, point.dy);
      }
    }
    boardPath.close();

    canvas.drawShadow(boardPath, Colors.black, size.width * 0.025, false);
    canvas.drawPath(boardPath, Paint()..color = const Color(0xFF555A57));
    canvas.drawPath(
      boardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..color = const Color(0xFF111311),
    );

    final pegPaint = Paint()..color = const Color(0xFFE9E7DD);
    final pegShadow = Paint()..color = const Color(0xCC111311);
    final bandPaint = Paint()
      ..color = const Color(0xFFD86486)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.045;

    final step = radius * 0.34;
    final rows = <List<Offset>>[
      [Offset(0, -step * 2)],
      [Offset(-step, -step), Offset(step, -step)],
      [Offset(-step * 2, 0), Offset.zero, Offset(step * 2, 0)],
      [Offset(-step, step), Offset(step, step)],
      [Offset(0, step * 2)],
    ];
    final pegs = rows.expand((row) => row).map((p) => center + p).toList();

    canvas.drawLine(pegs[0], pegs[7], bandPaint);
    bandPaint.color = const Color(0xFF71C56B);
    canvas.drawLine(pegs[3], pegs[5], bandPaint);
    bandPaint.color = const Color(0xFF7968C6);
    canvas.drawLine(pegs[1], pegs[6], bandPaint);

    for (final peg in pegs) {
      canvas.drawCircle(
        peg + Offset(0, size.width * 0.012),
        size.width * 0.041,
        pegShadow,
      );
      canvas.drawCircle(peg, size.width * 0.035, pegPaint);
      canvas.drawCircle(
        peg,
        size.width * 0.035,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.018
          ..color = const Color(0xFF111311),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardMarkPainter oldDelegate) => false;
}
