import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:flutter/material.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';

class BotDifficultyScreen extends StatelessWidget {
  const BotDifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GamePage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? const GamePress(child: BackButton())
            : null,
        title: Text(l10n.botGuideTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                l10n.botGuideIntro,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Divider(height: 12),
            for (final difficulty in BotDifficulty.values) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                leading: Text(
                  '${difficulty.index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                title: Text(
                  _label(l10n, difficulty),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(_description(l10n, difficulty)),
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.botPersonalitiesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.botPersonalitiesDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n, BotDifficulty difficulty) {
    return switch (difficulty) {
      BotDifficulty.beginner => l10n.botDifficultyBeginner,
      BotDifficulty.easy => l10n.botDifficultyEasy,
      BotDifficulty.normal => l10n.botDifficultyNormal,
      BotDifficulty.hard => l10n.botDifficultyHard,
      BotDifficulty.expert => l10n.botDifficultyExpert,
    };
  }

  String _description(AppLocalizations l10n, BotDifficulty difficulty) {
    return switch (difficulty) {
      BotDifficulty.beginner => l10n.botBeginnerDescription,
      BotDifficulty.easy => l10n.botEasyDescription,
      BotDifficulty.normal => l10n.botNormalDescription,
      BotDifficulty.hard => l10n.botHardDescription,
      BotDifficulty.expert => l10n.botExpertDescription,
    };
  }
}
