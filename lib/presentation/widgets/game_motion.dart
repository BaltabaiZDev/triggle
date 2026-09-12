import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:get/get.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

/// Presentation-only policy. OS accessibility always wins over game settings.
class GameMotionScope extends InheritedWidget {
  const GameMotionScope({
    required this.settings,
    required super.child,
    this.ambientMotion = true,
    super.key,
  });

  final GameFeelSettings settings;
  final bool ambientMotion;
  static bool ambientOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GameMotionScope>()
          ?.ambientMotion ??
      true;

  static GameFeelSettings of(BuildContext context) {
    final settings =
        context
            .dependOnInheritedWidgetOfExactType<GameMotionScope>()
            ?.settings ??
        GameFeelSettings();
    return MediaQuery.disableAnimationsOf(context)
        ? settings.copyWith(reducedMotion: true)
        : settings;
  }

  static Duration duration(BuildContext context, int milliseconds) {
    final settings = of(context);
    // A short crossfade remains; spatial motion is removed for accessibility.
    return Duration(
      milliseconds: settings.reducedMotion
          ? 90
          : (milliseconds * settings.motionScale).round(),
    );
  }

  @override
  bool updateShouldNotify(GameMotionScope oldWidget) =>
      oldWidget.settings.reducedMotion != settings.reducedMotion ||
      oldWidget.settings.animationSpeed != settings.animationSpeed ||
      oldWidget.settings.particles != settings.particles ||
      oldWidget.ambientMotion != ambientMotion;
}

/// Only the small cached menu hero floats. Hidden routes/background apps sleep.
class GameFloat extends StatefulWidget {
  const GameFloat({required this.child, super.key});
  final Widget child;
  @override
  State<GameFloat> createState() => _GameFloatState();
}

class _GameFloatState extends State<GameFloat>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_foreground &&
        TickerMode.valuesOf(context).enabled &&
        GameMotionScope.ambientOf(context) &&
        !GameMotionScope.of(context).reducedMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: RepaintBoundary(child: widget.child),
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        GameMotionScope.of(context).reducedMotion
            ? 0
            : math.sin(_controller.value * math.pi * 2) * 4,
      ),
      child: child,
    ),
  );
}

/// A damped spring, normalized to a finite animation (no perpetual ticker).
class GameSpringCurve extends Curve {
  const GameSpringCurve();
  static final _spring = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 210, damping: 23),
    0,
    1,
    0,
  );

  @override
  double transformInternal(double t) => _spring.x(t * 0.7);
}

void gameUiSound({bool select = false}) {
  if (Get.isRegistered<GameFeedback>()) {
    final feedback = Get.find<GameFeedback>();
    playFeedback(select ? feedback.elasticStretch() : feedback.buttonPress());
  }
}

/// Keeps the native control, focus, semantics and gesture recognizer intact.
/// Raw pointer observation adds feedback without delaying or claiming a tap.
class GamePress extends StatefulWidget {
  const GamePress({
    required this.child,
    this.enabled = true,
    this.sound = true,
    super.key,
  });
  final Widget child;
  final bool enabled;
  final bool sound;

  @override
  State<GamePress> createState() => _GamePressState();
}

class _GamePressState extends State<GamePress>
    with SingleTickerProviderStateMixin {
  static final _claimedPointers = <int>{};
  late final _spring = AnimationController.unbounded(vsync: this, value: 1);
  Offset? _down;
  int? _pointer;

  bool get _enabled {
    if (!widget.enabled) return false;
    final child = widget.child;
    return switch (child) {
      ButtonStyleButton() => child.enabled,
      IconButton() => child.onPressed != null,
      InkWell() => child.onTap != null || child.onLongPress != null,
      ListTile() =>
        child.enabled && (child.onTap != null || child.onLongPress != null),
      SwitchListTile() => child.onChanged != null,
      Slider() => child.onChanged != null,
      ChoiceChip() => child.onSelected != null,
      // Inspect only; do not cast a generic callback to a dynamic callback.
      DropdownButtonFormField() => (child as dynamic).onChanged != null,
      SegmentedButton() => (child as dynamic).onSelectionChanged != null,
      PopupMenuButton() => child.enabled,
      _ => true,
    };
  }

  void _animate(double target) {
    if (GameMotionScope.of(context).reducedMotion ||
        !TickerMode.valuesOf(context).enabled) {
      _spring.value = 1;
      return;
    }
    if (target < 1 && _spring.value >= 1) _spring.value = 0.995;
    _spring.animateWith(
      SpringSimulation(
        SpringDescription(
          mass: 1,
          stiffness: 650 / math.pow(GameMotionScope.of(context).motionScale, 2),
          damping: 36 / GameMotionScope.of(context).motionScale,
        ),
        _spring.value,
        target,
        _spring.velocity,
      ),
    );
  }

  void _release() {
    _claimedPointers.remove(_pointer);
    _pointer = null;
    _down = null;
    _animate(1);
  }

  @override
  void didUpdateWidget(GamePress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _claimedPointers.remove(_pointer);
      _down = null;
      _pointer = null;
      _spring.value = 1;
    }
  }

  @override
  void dispose() {
    _claimedPointers.remove(_pointer);
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      if (_enabled && widget.sound) gameUiSound(select: true);
    },
    child: Listener(
      onPointerDown: (event) {
        if (!_enabled ||
            _pointer != null ||
            !_claimedPointers.add(event.pointer)) {
          return;
        }
        _pointer = event.pointer;
        _down = event.position;
        _animate(0.955);
      },
      onPointerMove: (event) {
        if (event.pointer == _pointer &&
            _down != null &&
            (event.position - _down!).distance > 12) {
          _release();
        }
      },
      onPointerUp: (event) {
        if (event.pointer != _pointer) return;
        if (_enabled && _down != null && widget.sound) gameUiSound();
        _release();
      },
      onPointerCancel: (event) {
        if (event.pointer == _pointer) _release();
      },
      child: AnimatedBuilder(
        animation: _spring,
        child: widget.child,
        builder: (context, child) =>
            Transform.scale(scale: _spring.value, child: child),
      ),
    ),
  );
}

class GameReveal extends StatelessWidget {
  const GameReveal({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = GameMotionScope.of(context).reducedMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameMotionScope.duration(context, 520),
      curve: const GameSpringCurve(),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, reduced ? 0 : (1 - value) * 14),
          child: Transform.scale(
            scale: reduced ? 1 : 0.965 + value * 0.035,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Outgoing widgets cannot receive input or duplicate accessibility actions.
class GameSwitcher extends StatelessWidget {
  const GameSwitcher({
    required this.child,
    this.alignment = Alignment.center,
    super.key,
  });
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: GameMotionScope.duration(context, 330),
    reverseDuration: GameMotionScope.duration(context, 180),
    switchInCurve: const GameSpringCurve(),
    switchOutCurve: Curves.easeOutCubic,
    layoutBuilder: (current, previous) => Stack(
      alignment: alignment,
      children: [
        for (final outgoing in previous)
          IgnorePointer(child: ExcludeSemantics(child: outgoing)),
        ?current,
      ],
    ),
    transitionBuilder: (child, animation) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0, 1),
        child: Transform.scale(
          scale: GameMotionScope.of(context).reducedMotion
              ? 1
              : 0.96 + animation.value * 0.04,
          child: child,
        ),
      ),
    ),
    child: child,
  );
}

/// A bounded score/selection accent; unrelated rebuilds do not replay it.
class GamePulse extends StatefulWidget {
  const GamePulse({
    required this.value,
    required this.child,
    this.color = const Color(0xFF91D998),
    super.key,
  });
  final Object value;
  final Widget child;
  final Color color;

  @override
  State<GamePulse> createState() => _GamePulseState();
}

class _GamePulseState extends State<GamePulse>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(GamePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.duration = GameMotionScope.duration(context, 480);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final t = _controller.value;
      final envelope = math.sin(t * math.pi);
      return Transform.scale(
        scale: GameMotionScope.of(context).reducedMotion
            ? 1
            : 1 + math.sin(t * math.pi * 2) * (1 - t) * 0.075,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              if (t < 1)
                BoxShadow(
                  color: widget.color.withValues(alpha: envelope * 0.25),
                  blurRadius: 10 * envelope,
                  spreadRadius: envelope * 2,
                ),
            ],
          ),
          child: child,
        ),
      );
    },
  );
}

class GameRouteTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = const GameSpringCurve().transform(animation.value);
        final reduced = GameMotionScope.of(context).reducedMotion;
        return Opacity(
          opacity: (animation.value * 2).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : (1 - t) * 24),
            child: child,
          ),
        );
      },
    );
  }
}

/// Finite, isolated effects. Never drives layout or the Flame render loop.
class GameCelebration extends StatefulWidget {
  const GameCelebration({required this.child, super.key});
  final Widget child;

  @override
  State<GameCelebration> createState() => _GameCelebrationState();
}

class _GameCelebrationState extends State<GameCelebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = GameMotionScope.of(context);
    if (settings.reducedMotion || !settings.particles) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ConfettiPainter(_controller)),
          ),
        ),
      ),
    ],
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.time) : super(repaint: time);
  final Animation<double> time;
  static const colors = [
    Color(0xFF91D998),
    Color(0xFFF1D57B),
    Color(0xFFE785A2),
    Color(0xFF83BEDE),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (t == 0 || t >= 1) return;
    final paint = Paint();
    for (var i = 0; i < 36; i++) {
      final phase = i * 2.39996;
      final travel = (0.35 + i % 7 / 12) * size.shortestSide;
      final x = size.width / 2 + math.cos(phase) * travel * t;
      final y =
          size.height * 0.27 -
          math.sin(phase).abs() * travel * t +
          size.height * 0.58 * t * t;
      paint.color = colors[i % 4].withValues(alpha: ((1 - t) * 2).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase + t * 5);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 4,
          height: 7 * math.cos(t * 8 + i).abs() + 2,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.time != time;
}
