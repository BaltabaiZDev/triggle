import 'package:flutter/material.dart';

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
          colors: [Color(0xFF292C2A), Color(0xFF202321)],
        ),
      ),
      child: CustomPaint(
        painter: _TriGridBackdropPainter(
          lineColor: Colors.white.withValues(alpha: 0.025),
          glowColor: theme.colorScheme.primary.withValues(alpha: 0.035),
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
            blurRadius: 0,
            offset: const Offset(3, 3),
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

class TriGridGameButton extends StatefulWidget {
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
  State<TriGridGameButton> createState() => _TriGridGameButtonState();
}

class _TriGridGameButtonState extends State<TriGridGameButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final foreground = widget.primary
        ? Colors.white
        : theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) {
              if (_pressed != value) {
                setState(() => _pressed = value);
              }
            },
            splashFactory: InkSplash.splashFactory,
            borderRadius: BorderRadius.circular(4),
            child: Ink(
              height: widget.compact ? 40 : 46,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 10 : 13,
              ),
              decoration: BoxDecoration(
                color: widget.primary
                    ? accent
                    : theme.colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.92),
                  width: 2,
                ),
                boxShadow: _pressed
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 0,
                          offset: Offset(2, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: widget.compact ? 17 : 19,
                    color: widget.primary ? Colors.white : accent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: widget.compact ? 12 : 14,
                        fontWeight: FontWeight.w700,
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
    final spacing = dense ? 5.0 : 7.0;
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
