import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/widgets/game_motion.dart';

/// Icon-first game control with a large target and a spoken/long-press label.
class GameIconAction extends StatelessWidget {
  const GameIconAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.selected = false,
    this.size = 54,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        selected: selected,
        child: GamePress(
          enabled: onPressed != null,
          child: Material(
            color: primary
                ? scheme.primary
                : selected
                ? scheme.primary.withValues(alpha: .18)
                : Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox.square(
                dimension: size,
                child: Icon(
                  icon,
                  size: primary ? 34 : 25,
                  color: onPressed == null
                      ? Colors.white24
                      : primary
                      ? const Color(0xFF18311B)
                      : selected
                      ? scheme.primary
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoardSizeSelector extends StatelessWidget {
  const BoardSizeSelector({
    required this.value,
    required this.onChanged,
    this.playerCount = 2,
    this.includeCustom = true,
    super.key,
  });
  final BoardSizePreset value;
  final ValueChanged<BoardSizePreset>? onChanged;
  final int playerCount;
  final bool includeCustom;

  String _label(AppLocalizations l10n, BoardSizePreset preset) =>
      switch (preset) {
        BoardSizePreset.small => l10n.smallBoardLimit,
        BoardSizePreset.classic => l10n.boardSizeClassic,
        BoardSizePreset.large => l10n.boardSizeLarge,
        BoardSizePreset.huge => l10n.boardSizeHuge,
        BoardSizePreset.custom => l10n.boardSizeCustom,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in BoardSizePreset.values)
              if (includeCustom || preset != BoardSizePreset.custom)
                Builder(
                  builder: (context) {
                    final enabled =
                        onChanged != null &&
                        (preset != BoardSizePreset.small || playerCount <= 2);
                    final selected = preset == value;
                    return Tooltip(
                      message: _label(l10n, preset),
                      child: Semantics(
                        label: _label(l10n, preset),
                        selected: selected,
                        button: true,
                        enabled: enabled,
                        child: GamePulse(
                          value: selected,
                          child: GamePress(
                            enabled: enabled,
                            child: InkWell(
                              key: ValueKey('board-${preset.name}'),
                              onTap: enabled ? () => onChanged!(preset) : null,
                              borderRadius: BorderRadius.circular(5),
                              child: AnimatedContainer(
                                duration: GameMotionScope.duration(
                                  context,
                                  220,
                                ),
                                curve: const GameSpringCurve(),
                                width: 48,
                                height: 54,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? scheme.primary.withValues(alpha: .17)
                                      : Colors.white.withValues(alpha: .04),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: selected
                                        ? scheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: preset == BoardSizePreset.custom
                                    ? Icon(
                                        Icons.tune_rounded,
                                        color: enabled
                                            ? scheme.onSurfaceVariant
                                            : Colors.white24,
                                      )
                                    : CustomPaint(
                                        painter: _BoardGlyph(
                                          preset.radius!,
                                          enabled
                                              ? (selected
                                                    ? scheme.primary
                                                    : scheme.onSurfaceVariant)
                                              : Colors.white24,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
        const SizedBox(height: 8),
        GameSwitcher(
          alignment: Alignment.centerLeft,
          child: Text(
            _label(l10n, value),
            key: ValueKey(value),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _BoardGlyph extends CustomPainter {
  const _BoardGlyph(this.radius, this.color);
  final int radius;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.shortestSide / (radius * 2 + 1);
    final paint = Paint()..color = color;
    for (var q = -radius; q <= radius; q++) {
      for (var r = -radius; r <= radius; r++) {
        if ((q + r).abs() > radius) continue;
        canvas.drawCircle(
          Offset(
            size.width / 2 + step * (q + r / 2),
            size.height / 2 + step * math.sqrt(3) * r / 2,
          ),
          math.max(.8, step * .2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BoardGlyph oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.color != color;
}
