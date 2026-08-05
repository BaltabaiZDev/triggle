import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/components/trigrid_board_component.dart';
import 'package:trigrid/game/rendering/board_projection.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';

enum _BoardGestureMode { none, placement, camera }

class TriGridFlameGame extends FlameGame {
  TriGridFlameGame({
    required this.session,
    this.onMoveRequested,
    BoardProjection? projection,
  }) : projection = projection ?? const BoardProjection() {
    session.onAcceptedTransition = animateTransition;
  }

  final LocalGameSessionController session;
  final void Function(GridCoordinate start, GridCoordinate end)?
  onMoveRequested;
  final BoardProjection projection;

  GridCoordinate? selectedStart;
  GridCoordinate? snappedEnd;
  Vector2? previewWorld;
  Set<GridCoordinate> validEnds = const {};

  _BoardGestureMode _gestureMode = _BoardGestureMode.none;
  late double _scaleStartZoom;
  var _hasFramedBoard = false;
  var _fitZoom = 1.0;
  var _minimumZoom = 0.4;
  var _maximumZoom = 2.5;
  var _idleSeconds = 0.0;
  var _diagnosticsKeepAlive = false;
  var _diagnosticFrameSeconds = 0.0;
  var _diagnosticFrameCount = 0;
  var _diagnosticFps = 0.0;
  var _diagnosticFrameTimeMs = 0.0;
  var _inertiaVelocity = Vector2.zero();
  _MoveAnimation? _moveAnimation;
  GridCoordinate? _returnStart;
  Vector2? _returnFrom;
  var _returnElapsed = 1.0;
  var _celebrationElapsed = 0.0;
  Vector2? _celebrationStartPosition;
  var _celebrationStartZoom = 1.0;

  GameState get state => session.currentState;

  BoardDefinition get board => session.engine.board;

  double get diagnosticFps => _diagnosticFps;

  double get diagnosticFrameTimeMs => _diagnosticFrameTimeMs;

  @override
  Color backgroundColor() => const Color(0xFF262927);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    await world.add(TriGridBoardComponent(this));
    resetCamera();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _diagnosticFrameSeconds += dt;
    _diagnosticFrameCount++;
    if (_diagnosticFrameSeconds >= 0.5) {
      _diagnosticFps = _diagnosticFrameCount / _diagnosticFrameSeconds;
      _diagnosticFrameTimeMs =
          _diagnosticFrameSeconds * 1000 / _diagnosticFrameCount;
      _diagnosticFrameSeconds = 0;
      _diagnosticFrameCount = 0;
    }
    _moveAnimation?.elapsed += dt;
    _returnElapsed += dt;
    _updateCameraInertia(dt);
    _updateCelebrationCamera(dt);
    if (_needsContinuousFrames || _diagnosticsKeepAlive) {
      _idleSeconds = 0;
    } else {
      _idleSeconds += dt;
      if (_idleSeconds >= 0.35 && !paused) {
        pauseEngine();
      }
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _updateZoomLimits();
    if (!_hasFramedBoard) {
      resetCamera();
    } else {
      camera.viewfinder.zoom = camera.viewfinder.zoom.clamp(
        _minimumZoom,
        _maximumZoom,
      );
      _clampCamera();
    }
  }

  void handleTap(Offset canvasPosition) {
    if (!_canInteract) {
      return;
    }
    _wake();
    final worldPoint = canvasToWorld(canvasPosition);
    final peg = projection.nearestPeg(worldPoint, board);
    if (peg == null) {
      clearSelection();
      session.showInvalidPlacement();
      return;
    }

    if (selectedStart == null) {
      _selectStart(peg);
      return;
    }
    if (validEnds.contains(peg)) {
      _submitSelectedMove(peg);
      return;
    }
    if (peg == selectedStart) {
      clearSelection();
      session.showChooseStart();
      return;
    }
    if (!_selectStart(peg)) {
      session.showInvalidPlacement();
    }
  }

  void beginScale(ScaleStartDetails details) {
    if (!_canInteract) {
      return;
    }
    _wake();
    _scaleStartZoom = camera.viewfinder.zoom;
    _inertiaVelocity = Vector2.zero();
    if (details.pointerCount > 1) {
      _gestureMode = _BoardGestureMode.camera;
      clearSelection();
      return;
    }

    final worldPoint = canvasToWorld(details.localFocalPoint);
    final peg = projection.nearestPeg(worldPoint, board);
    if (peg != null && _selectStart(peg)) {
      _gestureMode = _BoardGestureMode.placement;
      previewWorld = worldPoint;
      snappedEnd = null;
      session.elasticStretch();
    } else {
      _gestureMode = _BoardGestureMode.none;
    }
  }

  void updateScale(ScaleUpdateDetails details) {
    if (!_canInteract || _gestureMode == _BoardGestureMode.none) {
      return;
    }
    _wake();
    if (details.pointerCount > 1) {
      if (_gestureMode == _BoardGestureMode.placement) {
        clearSelection();
      }
      _gestureMode = _BoardGestureMode.camera;
      zoomAt(details.localFocalPoint, _scaleStartZoom * details.scale);
      panByCanvasDelta(details.focalPointDelta);
      return;
    }

    if (_gestureMode == _BoardGestureMode.placement) {
      previewWorld = canvasToWorld(details.localFocalPoint);
      snappedEnd = projection.nearestPeg(
        previewWorld!,
        board,
        maximumDistance: projection.spacing * 0.42,
      );
      if (!validEnds.contains(snappedEnd)) {
        snappedEnd = null;
      }
    } else {
      panByCanvasDelta(details.focalPointDelta);
    }
  }

  void endScale(ScaleEndDetails details) {
    _wake();
    if (_gestureMode == _BoardGestureMode.placement) {
      final target = snappedEnd;
      if (target != null) {
        _submitSelectedMove(target);
      } else {
        _beginInvalidReturn();
        session.showInvalidPlacement();
      }
    } else if (_gestureMode == _BoardGestureMode.camera) {
      final pixelsPerSecond = details.velocity.pixelsPerSecond;
      _inertiaVelocity =
          Vector2(-pixelsPerSecond.dx, -pixelsPerSecond.dy) /
          camera.viewfinder.zoom;
    }
    _gestureMode = _BoardGestureMode.none;
  }

  void showHint() {
    if (!_canInteract) {
      return;
    }
    _wake();
    final moves = session.engine.validator.legalMoves(state);
    if (moves.isEmpty) {
      return;
    }
    selectedStart = moves.first.start;
    validEnds = {moves.first.end};
    snappedEnd = moves.first.end;
    previewWorld = projection.toWorld(moves.first.end);
    session.showHint();
  }

  void clearSelection() {
    selectedStart = null;
    snappedEnd = null;
    previewWorld = null;
    validEnds = const {};
  }

  void resetForNewMatch() {
    clearSelection();
    _gestureMode = _BoardGestureMode.none;
    _moveAnimation = null;
    _returnElapsed = 1;
    _celebrationElapsed = 0;
    _celebrationStartPosition = null;
    _inertiaVelocity = Vector2.zero();
    _wake();
    resetCamera();
  }

  void resetForReplay() {
    resetForNewMatch();
  }

  void setPaused(bool value) {
    if (value) {
      pauseEngine();
    } else {
      _wake();
    }
  }

  void setDiagnosticsActive(bool value) {
    _diagnosticsKeepAlive = value;
    if (value) {
      _wake();
    }
  }

  Vector2 canvasToWorld(Offset canvasPosition) {
    return camera.globalToLocal(Vector2(canvasPosition.dx, canvasPosition.dy));
  }

  void panByCanvasDelta(Offset delta) {
    if (camera.viewfinder.zoom == 0) {
      return;
    }
    _wake();
    camera.viewfinder.position -=
        Vector2(delta.dx, delta.dy) / camera.viewfinder.zoom;
    _clampCamera();
  }

  void zoomAt(Offset canvasPosition, double requestedZoom) {
    _wake();
    final before = canvasToWorld(canvasPosition);
    camera.viewfinder.zoom = requestedZoom.clamp(_minimumZoom, _maximumZoom);
    final after = canvasToWorld(canvasPosition);
    camera.viewfinder.position += before - after;
    _clampCamera();
  }

  void resetCamera() {
    if (size.x <= 0 || size.y <= 0) {
      return;
    }
    _wake();
    _updateZoomLimits();
    camera.viewfinder.position = Vector2.zero();
    camera.viewfinder.zoom = _fitZoom.clamp(_minimumZoom, _maximumZoom);
    _inertiaVelocity = Vector2.zero();
    _hasFramedBoard = true;
  }

  void animateTransition(GameTransition transition) {
    _wake();
    final settings = session.feelSettings.value;
    final actingPlayer = transition.state.players.firstWhere(
      (player) => player.id == transition.action.playerId,
    );
    final nextPlayer = transition.state.currentPlayer;
    final captures = transition.validation.newlyCapturedTriangles
        .map((triangle) => triangle.id)
        .toList(growable: false);
    _moveAnimation = settings.reducedMotion
        ? null
        : _MoveAnimation(
            actionId: transition.action.actionId,
            captureIds: captures,
            fromSeat: actingPlayer.visualIndex,
            toSeat: nextPlayer.visualIndex,
            durationScale: settings.motionScale,
          );
    if (transition.state.matchResult != null) {
      _celebrationElapsed = 0;
      _celebrationStartPosition = camera.viewfinder.position.clone();
      _celebrationStartZoom = camera.viewfinder.zoom;
      _inertiaVelocity = Vector2.zero();
    }
  }

  double bandPlacementProgress(String actionId) {
    final animation = _moveAnimation;
    if (animation == null || animation.actionId != actionId) {
      return 1;
    }
    final progress = (animation.elapsed / animation.bandDuration)
        .clamp(0, 1)
        .toDouble();
    return _elasticOut(progress);
  }

  double captureProgress(String triangleId) {
    final animation = _moveAnimation;
    if (animation == null) {
      return 1;
    }
    final index = animation.captureIds.indexOf(triangleId);
    if (index < 0) {
      return 1;
    }
    final start = animation.bandDuration * 0.46 + index * animation.captureGap;
    return _smoothStep(
      ((animation.elapsed - start) / animation.captureDuration).clamp(0, 1),
    );
  }

  double markerDropProgress(String triangleId) {
    final animation = _moveAnimation;
    if (animation == null) {
      return 1;
    }
    final index = animation.captureIds.indexOf(triangleId);
    if (index < 0) {
      return 1;
    }
    final start = animation.bandDuration * 0.72 + index * animation.captureGap;
    final progress = ((animation.elapsed - start) / animation.markerDuration)
        .clamp(0, 1)
        .toDouble();
    return _bounceOut(progress);
  }

  bool get hasActiveMoveAnimation {
    final animation = _moveAnimation;
    return animation != null && animation.elapsed < animation.totalDuration;
  }

  Color get boardRimColor {
    final animation = _moveAnimation;
    if (animation == null) {
      return PlayerVisuals.forSeat(state.currentPlayer.visualIndex).color;
    }
    final progress = _smoothStep(
      (animation.elapsed / animation.turnDuration).clamp(0, 1),
    );
    return Color.lerp(
          PlayerVisuals.forSeat(animation.fromSeat).color,
          PlayerVisuals.forSeat(animation.toSeat).color,
          progress,
        ) ??
        PlayerVisuals.forSeat(animation.toSeat).color;
  }

  double pegScale(GridCoordinate coordinate) {
    if (coordinate != selectedStart) {
      return 1;
    }
    return 0.94;
  }

  Vector2? get invalidReturnPoint {
    final from = _returnFrom;
    final start = _returnStart;
    if (from == null || start == null) {
      return null;
    }
    final duration = 0.2 * session.feelSettings.value.motionScale;
    if (duration <= 0 || _returnElapsed >= duration) {
      return null;
    }
    final progress = _smoothStep((_returnElapsed / duration).clamp(0, 1));
    return from + (projection.toWorld(start) - from) * progress;
  }

  GridCoordinate? get invalidReturnStart =>
      invalidReturnPoint == null ? null : _returnStart;

  Offset get boardShakeOffset {
    final animation = _moveAnimation;
    final settings = session.feelSettings.value;
    if (animation == null ||
        animation.captureIds.isEmpty ||
        !settings.screenShake ||
        settings.reducedMotion) {
      return Offset.zero;
    }
    final start = animation.bandDuration * 0.48;
    final elapsed = animation.elapsed - start;
    if (elapsed < 0 || elapsed > 0.28) {
      return Offset.zero;
    }
    final strength = (1 - elapsed / 0.28) * 4.2;
    return Offset(
      math.sin(elapsed * 92) * strength,
      math.cos(elapsed * 77) * strength * 0.7,
    );
  }

  double get celebrationTime => _celebrationElapsed;

  bool get isCelebrating => state.matchResult != null;

  double winnerPulse(String playerId) {
    final result = state.matchResult;
    if (result == null || !result.winnerPlayerIds.contains(playerId)) {
      return 1;
    }
    if (session.feelSettings.value.reducedMotion) {
      return 1.06;
    }
    return 1.05 + math.sin(_celebrationElapsed * 6) * 0.045;
  }

  bool _selectStart(GridCoordinate coordinate) {
    final endpoints = <GridCoordinate>{};
    for (final move in session.engine.validator.legalMoves(state)) {
      if (move.start == coordinate) {
        endpoints.add(move.end);
      } else if (move.end == coordinate) {
        endpoints.add(move.start);
      }
    }
    if (endpoints.isEmpty) {
      return false;
    }
    selectedStart = coordinate;
    validEnds = Set<GridCoordinate>.unmodifiable(endpoints);
    previewWorld = null;
    snappedEnd = null;
    session.pegTouch();
    session.showChooseEnd();
    return true;
  }

  void _submitSelectedMove(GridCoordinate target) {
    final start = selectedStart;
    if (start == null) {
      return;
    }
    final request = onMoveRequested;
    if (request == null) {
      session.submitMove(start, target);
    } else {
      request(start, target);
    }
    clearSelection();
  }

  void _beginInvalidReturn() {
    final start = selectedStart;
    final from = previewWorld;
    if (start != null && from != null) {
      _returnStart = start;
      _returnFrom = from.clone();
      _returnElapsed = 0;
      _wake();
    }
    clearSelection();
  }

  void _updateCameraInertia(double dt) {
    if (_inertiaVelocity.length2 < 1 ||
        _celebrationStartPosition != null ||
        session.feelSettings.value.reducedMotion) {
      _inertiaVelocity = Vector2.zero();
      return;
    }
    camera.viewfinder.position += _inertiaVelocity * dt;
    _clampCamera();
    _inertiaVelocity *= math.exp(-5.6 * dt);
  }

  void _updateCelebrationCamera(double dt) {
    final startPosition = _celebrationStartPosition;
    if (startPosition == null) {
      return;
    }
    _celebrationElapsed += dt;
    final duration = 0.82 * session.feelSettings.value.motionScale;
    final progress = duration <= 0
        ? 1.0
        : _smoothStep((_celebrationElapsed / duration).clamp(0, 1));
    camera.viewfinder.position = startPosition * (1 - progress);
    camera.viewfinder.zoom =
        _celebrationStartZoom +
        (_fitZoom.clamp(_minimumZoom, _maximumZoom) - _celebrationStartZoom) *
            progress;
    if (progress >= 1) {
      _celebrationStartPosition = null;
    }
  }

  void _updateZoomLimits() {
    final bounds = projection.boardBounds(board);
    _fitZoom = math.min(size.x / bounds.width, size.y / bounds.height);
    _minimumZoom = math.max(0.18, _fitZoom * 0.72);
    _maximumZoom = math.max(_minimumZoom, _fitZoom * 3.2);
  }

  void _clampCamera() {
    final bounds = projection.boardBounds(
      board,
      padding: projection.spacing * 0.85,
    );
    camera.viewfinder.position = Vector2(
      camera.viewfinder.position.x.clamp(bounds.left, bounds.right),
      camera.viewfinder.position.y.clamp(bounds.top, bounds.bottom),
    );
  }

  bool get _canInteract =>
      !session.isPaused.value &&
      !session.isReplaying.value &&
      !session.awaitingHandoff.value &&
      session.canCurrentPlayerInteract &&
      !session.currentState.isGameOver;

  bool get _needsContinuousFrames =>
      hasActiveMoveAnimation ||
      invalidReturnPoint != null ||
      _inertiaVelocity.length2 >= 1 ||
      _celebrationStartPosition != null;

  void _wake() {
    _idleSeconds = 0;
    if (paused && !session.isPaused.value) {
      resumeEngine();
    }
  }
}

double _smoothStep(double value) => value * value * (3 - 2 * value);

double _elasticOut(double value) {
  if (value == 0 || value == 1) {
    return value;
  }
  return math.pow(2, -9 * value) *
          math.sin((value * 9.5 - 0.7) * math.pi) *
          0.17 +
      1;
}

double _bounceOut(double value) {
  const first = 7.5625;
  const divisor = 2.75;
  if (value < 1 / divisor) {
    return first * value * value;
  }
  if (value < 2 / divisor) {
    final shifted = value - 1.5 / divisor;
    return first * shifted * shifted + 0.75;
  }
  if (value < 2.5 / divisor) {
    final shifted = value - 2.25 / divisor;
    return first * shifted * shifted + 0.9375;
  }
  final shifted = value - 2.625 / divisor;
  return first * shifted * shifted + 0.984375;
}

class _MoveAnimation {
  _MoveAnimation({
    required this.actionId,
    required this.captureIds,
    required this.fromSeat,
    required this.toSeat,
    required this.durationScale,
  });

  final String actionId;
  final List<String> captureIds;
  final int fromSeat;
  final int toSeat;
  final double durationScale;
  var elapsed = 0.0;

  double get bandDuration => 0.46 * durationScale;

  double get captureDuration => 0.42 * durationScale;

  double get captureGap => 0.1 * durationScale;

  double get markerDuration => 0.38 * durationScale;

  double get turnDuration => 0.36 * durationScale;

  double get totalDuration =>
      bandDuration +
      captureDuration +
      markerDuration +
      captureIds.length * captureGap;
}
