import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: SafeArea(
        child: Obx(() {
          final statistics = controller.statistics.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              _ModeStatisticsCard(
                title: l10n.localStatistics,
                statistics: statistics.local,
              ),
              const SizedBox(height: 14),
              _ModeStatisticsCard(
                title: l10n.lanStatistics,
                statistics: statistics.lan,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ModeStatisticsCard extends StatelessWidget {
  const _ModeStatisticsCard({required this.title, required this.statistics});

  final String title;
  final ModeStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (statistics.winRate * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _StatTile(
                  label: l10n.matchesPlayed,
                  value: '${statistics.matchesPlayed}',
                ),
                _StatTile(label: l10n.wins, value: '${statistics.wins}'),
                _StatTile(label: l10n.winRate, value: '$percent%'),
                _StatTile(
                  label: l10n.capturedTrianglesStat,
                  value: '${statistics.capturedTriangles}',
                ),
                _StatTile(
                  label: l10n.largestMultiCapture,
                  value: '${statistics.largestMultiCapture}',
                ),
                _StatTile(
                  label: l10n.averageScore,
                  value: statistics.averageScore.toStringAsFixed(1),
                ),
              ],
            ),
            if (statistics.botLevelRecords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.winRateByBotLevel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final difficulty in BotDifficulty.values)
                if (statistics.botLevelRecords[difficulty] case final record?)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_difficultyLabel(l10n, difficulty)),
                    trailing: Text(
                      '${(record.winRate * 100).round()}% '
                      '(${record.wins}/${record.matches})',
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String _difficultyLabel(AppLocalizations l10n, BotDifficulty difficulty) {
    return switch (difficulty) {
      BotDifficulty.beginner => l10n.botDifficultyBeginner,
      BotDifficulty.easy => l10n.botDifficultyEasy,
      BotDifficulty.normal => l10n.botDifficultyNormal,
      BotDifficulty.hard => l10n.botDifficultyHard,
      BotDifficulty.expert => l10n.botDifficultyExpert,
    };
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
