import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'package:flutter/material.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';

class PlayerBadge extends StatelessWidget {
  const PlayerBadge({
    required this.player,
    required this.isActive,
    this.compact = false,
    super.key,
  });

  final PlayerState player;
  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visuals = PlayerVisuals.forSeat(player.visualIndex);
    return GamePulse(
      value: '${player.score}:$isActive',
      color: visuals.color,
      child: AnimatedContainer(
        duration: GameMotionScope.duration(context, 240),
        curve: const GameSpringCurve(),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 7,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? visuals.color.withValues(alpha: 0.72)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, offset: Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: GameMotionScope.duration(context, 240),
              curve: Curves.easeOutBack,
              scale: isActive ? 1.12 : 1,
              child: Icon(
                _markerIcon(visuals.markerShape),
                color: visuals.color,
                size: compact ? 15 : 18,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: compact
                  ? TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: player.score),
                      duration: GameMotionScope.duration(context, 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, score, _) => Text(
                        '${player.displayName} · $score',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: player.score),
                          duration: GameMotionScope.duration(context, 260),
                          curve: Curves.easeOutCubic,
                          builder: (context, score, _) => Text(
                            l10n.scoreLabel(score),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _markerIcon(PlayerMarkerShape shape) {
    return switch (shape) {
      PlayerMarkerShape.circle => Icons.circle,
      PlayerMarkerShape.diamond => Icons.diamond,
      PlayerMarkerShape.triangle => Icons.change_history_rounded,
      PlayerMarkerShape.square => Icons.square_rounded,
    };
  }
}
