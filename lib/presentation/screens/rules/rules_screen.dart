import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:flutter/material.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = [
      (Icons.linear_scale_rounded, l10n.rulesGoalTitle, l10n.rulesGoalBody),
      (
        Icons.timeline_rounded,
        l10n.rulesPlacementTitle,
        l10n.rulesPlacementBody,
      ),
      (Icons.hub_rounded, l10n.rulesConnectionTitle, l10n.rulesConnectionBody),
      (
        Icons.change_history_rounded,
        l10n.rulesCaptureTitle,
        l10n.rulesCaptureBody,
      ),
      (Icons.emoji_events_rounded, l10n.rulesEndingTitle, l10n.rulesEndingBody),
      (Icons.grid_4x4_rounded, l10n.rulesBoardsTitle, l10n.rulesBoardsBody),
    ];
    return GamePage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? const GamePress(child: BackButton())
            : null,
        title: Text(l10n.rulesTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                l10n.rulesIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Divider(height: 12),
            for (final section in sections) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                leading: Icon(section.$1, size: 20),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    section.$2,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                subtitle: Text(section.$3),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
