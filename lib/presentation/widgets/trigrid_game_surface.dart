import 'package:flutter/material.dart';
import 'package:trigrid/presentation/widgets/game_motion.dart';

/// Shared shell for support screens; never wraps/rebuilds the Flame playfield.
class GamePage extends StatelessWidget {
  const GamePage({
    required this.body,
    this.appBar,
    this.extendBodyBehindAppBar = false,
    super.key,
  });
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
    body: TriGridBackdrop(dense: true, child: GameReveal(child: body)),
  );
}

class TriGridBackdrop extends StatelessWidget {
  const TriGridBackdrop({required this.child, this.dense = false, super.key});

  final Widget child;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF303C35), Color(0xFF191F1C)],
        ),
      ),
      child: CustomPaint(
        painter: _TriGridBackdropPainter(
          lineColor: Colors.white.withValues(alpha: 0.018),
          glowColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          dense: dense,
        ),
        child: child,
      ),
    );
  }
}

class TriGridPanel extends StatelessWidget {
  const TriGridPanel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 5,
    this.highlighted = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final border = highlighted
        ? theme.colorScheme.primary.withValues(alpha: 0.58)
        : theme.colorScheme.onSurface.withValues(alpha: 0.11);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted ? border : Colors.black.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class TriGridSectionTitle extends StatelessWidget {
  const TriGridSectionTitle({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
      ],
    );
  }
}

class TriGridGameButton extends StatelessWidget {
  const TriGridGameButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accentColor,
    this.primary = false,
    this.compact = false,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? accentColor;
  final bool primary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    final face = primary ? accent : theme.colorScheme.surface;
    final foreground = primary
        ? const Color(0xFF13251B)
        : theme.colorScheme.onSurface;
    return GamePress(
      child: Semantics(
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(5),
            child: Ink(
              height: compact ? 46 : 52,
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(face, Colors.white, 0.10)!, face],
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF101A14), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color.lerp(face, Colors.black, 0.45)!,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: compact ? 18 : 22,
                    color: primary ? foreground : accent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: compact ? 12 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriGridBackdropPainter extends CustomPainter {
  const _TriGridBackdropPainter({
    required this.lineColor,
    required this.glowColor,
    required this.dense,
  });

  final Color lineColor;
  final Color glowColor;
  final bool dense;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = dense ? 44.0 : 54.0;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [glowColor, glowColor.withValues(alpha: 0)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.82, size.height * 0.14),
              radius: size.shortestSide * 0.72,
            ),
          );
    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _TriGridBackdropPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.dense != dense;
}
