import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';

class TriGridBoardComponent extends Component {
  TriGridBoardComponent(this.game);

  final TriGridFlameGame game;
  late final Path _cachedBoardPath;
  late final Map<GridCoordinate, Vector2> _pegPositions;
  late final Map<String, Path> _trianglePaths;
  late final Map<String, Vector2> _triangleCenters;
  late final Image _fixedBoardImage;
  late final Rect _fixedBoardImageBounds;

  @override
  void onMount() {
    super.onMount();
    _prepareFixedGeometry();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final state = game.state;
    final activeVisuals = PlayerVisuals.forSeat(
      state.currentPlayer.visualIndex,
    );
    final shake = game.boardShakeOffset;

    canvas.save();
    canvas.translate(shake.dx, shake.dy);
    canvas.drawImageRect(
      _fixedBoardImage,
      Rect.fromLTWH(
        0,
        0,
        _fixedBoardImage.width.toDouble(),
        _fixedBoardImage.height.toDouble(),
      ),
      _fixedBoardImageBounds,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.drawPath(
      _cachedBoardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = game.boardRimColor.withValues(alpha: 0.88),
    );

    _renderCapturedTriangles(canvas, state);
    _renderBands(canvas, state);
    _renderPlacementPreview(canvas, activeVisuals);
    _renderPegHighlights(canvas);
    _renderCaptureMarkers(canvas, state);
    _renderCelebration(canvas);
    canvas.restore();
  }

  void _prepareFixedGeometry() {
    _cachedBoardPath = _createBoardPath();
    _pegPositions = {
      for (final peg in game.board.pegs)
        peg.coordinate: game.projection.toWorld(peg.coordinate),
    };
    _trianglePaths = {
      for (final triangle in game.board.triangles)
        triangle.id: _createTrianglePath(triangle),
    };
    _triangleCenters = {
      for (final triangle in game.board.triangles)
        triangle.id: game.projection.triangleCenter(triangle),
    };

    const rasterScale = 1.25;
    final boardBounds = game.projection.boardBounds(
      game.board,
      padding: game.projection.spacing * 0.75,
    );
    _fixedBoardImageBounds = boardBounds;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(rasterScale)
      ..translate(-boardBounds.left, -boardBounds.top);
    canvas.drawShadow(_cachedBoardPath, const Color(0xDD000000), 5, false);
    canvas.drawPath(_cachedBoardPath, Paint()..color = const Color(0xFF555A57));
    _drawBoardTexture(canvas);
    canvas.drawPath(
      _cachedBoardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFF111311),
    );
    for (final point in _pegPositions.values) {
      canvas.drawCircle(
        Offset(point.x + 2, point.y + 5),
        14,
        Paint()..color = const Color(0xCC111311),
      );
      canvas.drawCircle(
        Offset(point.x, point.y),
        12,
        Paint()..color = const Color(0xFFE9E7DD),
      );
      canvas.drawCircle(
        Offset(point.x, point.y),
        12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFF151715),
      );
    }
    final picture = recorder.endRecording();
    _fixedBoardImage = picture.toImageSync(
      (boardBounds.width * rasterScale).ceil(),
      (boardBounds.height * rasterScale).ceil(),
    );
    picture.dispose();
  }

  @override
  void onRemove() {
    _fixedBoardImage.dispose();
    super.onRemove();
  }

  void _drawBoardTexture(Canvas canvas) {
    final bounds = game.projection.boardBounds(game.board);
    canvas.save();
    canvas.clipPath(_cachedBoardPath);
    final grainPaint = Paint()..color = const Color(0x22111311);
    final highlightPaint = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1.2;
    for (var index = 0; index < 48; index++) {
      final x = bounds.left + ((index * 0.61803398875) % 1) * bounds.width;
      final y =
          bounds.top + ((index * 0.38196601125 + 0.17) % 1) * bounds.height;
      canvas.drawCircle(Offset(x, y), 0.8 + (index % 3) * 0.45, grainPaint);
    }
    for (var index = 0; index < 13; index++) {
      final y = bounds.top + (index + 0.65) * bounds.height / 13;
      final shift = (index % 2) * game.projection.spacing * 0.22;
      canvas.drawLine(
        Offset(bounds.left + shift, y),
        Offset(bounds.right - game.projection.spacing * 0.18, y + 3),
        highlightPaint,
      );
    }
    canvas.restore();
  }

  Path _createBoardPath() {
    final radius = game.board.size.radius;
    final corners = [
      GridCoordinate(radius, 0),
      GridCoordinate(radius, -radius),
      GridCoordinate(0, -radius),
      GridCoordinate(-radius, 0),
      GridCoordinate(-radius, radius),
      GridCoordinate(0, radius),
    ];
    final expansion = (radius + 0.68) / radius;
    final path = Path();
    for (var index = 0; index < corners.length; index++) {
      final point = game.projection.toWorld(corners[index]) * expansion;
      if (index == 0) {
        path.moveTo(point.x, point.y);
      } else {
        path.lineTo(point.x, point.y);
      }
    }
    return path..close();
  }

  void _renderCapturedTriangles(Canvas canvas, GameState state) {
    for (final capture in state.capturedTriangles.values) {
      final triangle = game.board.triangleById[capture.triangleId];
      if (triangle == null) {
        continue;
      }
      final visuals = _visualsForPlayer(state, capture.playerId);
      final path = _trianglePaths[triangle.id]!;
      final progress = game.captureProgress(capture.triangleId);
      if (progress <= 0) {
        continue;
      }

      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = game.projection.spacing * progress
          ..color = visuals.color.withValues(alpha: 0.72),
      );
      if (progress > 0.84) {
        canvas.drawPath(
          path,
          Paint()
            ..color = visuals.color.withValues(
              alpha: 0.7 * ((progress - 0.84) / 0.16),
            ),
        );
      }
      canvas.restore();
      if (progress < 1) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8 * (1 - progress)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              game.board.size.radius >= 5 ? 6 : 9,
            )
            ..color = visuals.color.withValues(alpha: 0.72),
        );
        _renderCaptureParticles(canvas, triangle, visuals, progress);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xCC111311),
      );
    }
  }

  void _renderBands(Canvas canvas, GameState state) {
    for (final band in state.placedBands) {
      final start = _pegPositions[band.move.start]!;
      final finalEnd = _pegPositions[band.move.end]!;
      final progress = game.bandPlacementProgress(band.actionId);
      final end = start + (finalEnd - start) * progress;
      final visuals = _visualsForPlayer(state, band.playerId);
      canvas.drawLine(
        Offset(start.x + 2, start.y + 5),
        Offset(end.x + 2, end.y + 5),
        Paint()
          ..color = const Color(0xFF111311)
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(start.x, start.y),
        Offset(end.x, end.y),
        Paint()
          ..color = visuals.color
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(start.x, start.y - 2),
        Offset(end.x, end.y - 2),
        Paint()
          ..color = const Color(0x44FFFFFF)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderPlacementPreview(Canvas canvas, PlayerVisuals activeVisuals) {
    final selected = game.selectedStart;
    if (selected == null) {
      return;
    }
    final selectedPoint = _pegPositions[selected]!;
    for (final endpoint in game.validEnds) {
      final point = _pegPositions[endpoint]!;
      canvas.drawCircle(
        Offset(point.x, point.y),
        18,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = activeVisuals.color.withValues(alpha: 0.72),
      );
    }

    final target = game.snappedEnd == null
        ? game.previewWorld
        : _pegPositions[game.snappedEnd!];
    if (target != null) {
      final delta = target - selectedPoint;
      final length = delta.length;
      final normal = length <= 0
          ? Vector2.zero()
          : Vector2(-delta.y, delta.x) / length;
      final bend =
          math.min(game.projection.spacing * 0.12, length * 0.07) *
          math.sin(
            math.min(1, length / (game.projection.spacing * 2.8)) * math.pi,
          );
      final middle = (selectedPoint + target) / 2 + normal * bend;
      final path = Path()
        ..moveTo(selectedPoint.x, selectedPoint.y)
        ..quadraticBezierTo(middle.x, middle.y, target.x, target.y);
      canvas.drawPath(
        path,
        Paint()
          ..color = activeVisuals.color.withValues(alpha: 0.64)
          ..strokeWidth = 11
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    final returnStart = game.invalidReturnStart;
    final returnPoint = game.invalidReturnPoint;
    if (returnStart != null && returnPoint != null) {
      final start = _pegPositions[returnStart]!;
      canvas.drawLine(
        Offset(start.x, start.y),
        Offset(returnPoint.x, returnPoint.y),
        Paint()
          ..color = const Color(0xCCB83D31)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderPegHighlights(Canvas canvas) {
    final activeVisuals = PlayerVisuals.forSeat(
      game.state.currentPlayer.visualIndex,
    );
    for (final peg in game.board.pegs) {
      final isSelected = peg.coordinate == game.selectedStart;
      final isTarget = game.validEnds.contains(peg.coordinate);
      if (!isSelected && !isTarget) {
        continue;
      }
      final point = _pegPositions[peg.coordinate]!;
      final scale = game.pegScale(peg.coordinate);
      canvas.drawCircle(
        Offset(point.x + 2, point.y + 5),
        (isSelected ? 19 : 16) * scale,
        Paint()..color = const Color(0x5524342E),
      );
      canvas.drawCircle(
        Offset(point.x, point.y),
        (isSelected ? 17 : 14) * scale,
        Paint()..color = const Color(0xFFFFF9EE),
      );
      canvas.drawCircle(
        Offset(point.x, point.y),
        (isSelected ? 17 : 14) * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = activeVisuals.color,
      );
    }
  }

  void _renderCaptureMarkers(Canvas canvas, GameState state) {
    for (final capture in state.capturedTriangles.values) {
      final triangle = game.board.triangleById[capture.triangleId];
      if (triangle == null) {
        continue;
      }
      final center = _triangleCenters[triangle.id]!;
      final visuals = _visualsForPlayer(state, capture.playerId);
      final progress = game.markerDropProgress(capture.triangleId);
      if (progress <= 0) {
        continue;
      }
      final winnerPulse = game.winnerPulse(capture.playerId);
      _drawMarker(
        canvas,
        Offset(center.x, center.y - (1 - progress) * 34),
        visuals,
        game.projection.spacing * 0.105 * progress * winnerPulse,
      );
    }
  }

  void _renderCaptureParticles(
    Canvas canvas,
    TriangleCell triangle,
    PlayerVisuals visuals,
    double progress,
  ) {
    if (!game.session.feelSettings.value.particles ||
        game.session.feelSettings.value.reducedMotion) {
      return;
    }
    final center = _triangleCenters[triangle.id]!;
    final seed = triangle.id.codeUnits.fold<int>(
      0,
      (value, codeUnit) => value + codeUnit,
    );
    final particleCount = game.board.size.radius >= 5 ? 6 : 9;
    for (var index = 0; index < particleCount; index++) {
      final angle = (seed % 19) * 0.17 + index * math.pi * 2 / particleCount;
      final distance = game.projection.spacing * 0.42 * progress;
      final particle = Offset(
        center.x + math.cos(angle) * distance,
        center.y + math.sin(angle) * distance,
      );
      canvas.drawCircle(
        particle,
        3.8 * (1 - progress),
        Paint()..color = visuals.color.withValues(alpha: 1 - progress),
      );
    }
  }

  void _renderCelebration(Canvas canvas) {
    if (!game.isCelebrating ||
        !game.session.feelSettings.value.particles ||
        game.session.feelSettings.value.reducedMotion) {
      return;
    }
    final time = game.celebrationTime;
    if (time > 3.2) {
      return;
    }
    final bounds = game.projection.boardBounds(
      game.board,
      padding: game.projection.spacing * 0.5,
    );
    const colors = [
      Color(0xFFE85D4A),
      Color(0xFF3B82C4),
      Color(0xFFF0B429),
      Color(0xFF4D9B71),
    ];
    for (var index = 0; index < 42; index++) {
      final phase = (index * 0.61803398875) % 1;
      final x =
          bounds.left +
          ((index * 0.371 + math.sin(time + index) * 0.025) % 1) * bounds.width;
      final travel = (time * (0.22 + (index % 7) * 0.018) + phase) % 1;
      final y = bounds.top + travel * bounds.height;
      final opacity = math.min(1.0, (3.2 - time) * 1.4);
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(time * (2 + index % 4) + index);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -7, 8, 14),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  Path _createTrianglePath(TriangleCell triangle) {
    final path = Path();
    for (var index = 0; index < triangle.vertices.length; index++) {
      final point =
          _pegPositions[triangle.vertices[index]] ??
          game.projection.toWorld(triangle.vertices[index]);
      if (index == 0) {
        path.moveTo(point.x, point.y);
      } else {
        path.lineTo(point.x, point.y);
      }
    }
    return path..close();
  }

  PlayerVisuals _visualsForPlayer(GameState state, String playerId) {
    final player = state.players.firstWhere(
      (candidate) => candidate.id == playerId,
    );
    return PlayerVisuals.forSeat(player.visualIndex);
  }

  void _drawMarker(
    Canvas canvas,
    Offset center,
    PlayerVisuals visuals,
    double radius,
  ) {
    final fill = Paint()..color = visuals.color;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF111311);

    switch (visuals.markerShape) {
      case PlayerMarkerShape.circle:
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, outline);
      case PlayerMarkerShape.square:
        final rect = Rect.fromCenter(
          center: center,
          width: radius * 1.8,
          height: radius * 1.8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.22)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius * 0.22)),
          outline,
        );
      case PlayerMarkerShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
      case PlayerMarkerShape.triangle:
        final height = radius * math.sqrt(3);
        final path = Path()
          ..moveTo(center.dx, center.dy - height * 0.58)
          ..lineTo(center.dx + radius, center.dy + height * 0.42)
          ..lineTo(center.dx - radius, center.dy + height * 0.42)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, outline);
    }
  }
}
