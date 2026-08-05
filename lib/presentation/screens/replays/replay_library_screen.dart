import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/replay_game_session_controller.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';

class ReplayLibraryScreen extends StatelessWidget {
  const ReplayLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.replayLibraryTitle)),
      body: SafeArea(
        child: Obx(() {
          if (controller.replays.isEmpty && controller.lanSnapshots.isEmpty) {
            return _EmptyReplayState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount:
                controller.replays.length + controller.lanSnapshots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index >= controller.replays.length) {
                final snapshot =
                    controller.lanSnapshots[index - controller.replays.length];
                return _LanSnapshotCard(
                  snapshot: snapshot,
                  onDelete: () =>
                      unawaited(controller.deleteLanSnapshot(snapshot.id)),
                );
              }
              final entry = controller.replays[index];
              return _ReplayCard(
                entry: entry,
                onPlay: () => _play(entry, controller),
                onDelete: () => unawaited(controller.deleteReplay(entry.id)),
              );
            },
          );
        }),
      ),
    );
  }

  void _play(SavedReplayEntry entry, AppController appController) {
    final session = ReplayGameSessionController(
      entry.replay,
      initialFeelSettings: appController.preferences.value.gameFeel,
    );
    Get.to<void>(
      () => GameScreen(
        settings: entry.replay.settings,
        session: session,
        persistMatch: false,
      ),
    );
  }
}

class _LanSnapshotCard extends StatelessWidget {
  const _LanSnapshotCard({required this.snapshot, required this.onDelete});

  final SavedLanSnapshot snapshot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(snapshot.savedAtUtc.toLocal());
    final players = snapshot.state.players
        .map((player) => player.displayName)
        .join(' · ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 5, 4, 5),
        leading: const Icon(Icons.save_outlined, size: 20),
        title: Text(players, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${l10n.savedLanPosition} · $date · '
          '${l10n.networkRevision(snapshot.state.revision)}',
        ),
        trailing: IconButton(
          tooltip: l10n.deleteSavedPosition,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

class _EmptyReplayState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 40),
            const SizedBox(height: 10),
            Text(
              l10n.noReplaysTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayCard extends StatelessWidget {
  const _ReplayCard({
    required this.entry,
    required this.onPlay,
    required this.onDelete,
  });

  final SavedReplayEntry entry;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final replay = entry.replay;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(entry.createdAtUtc.toLocal());
    final players = replay.settings.players
        .map((player) => player.displayName)
        .join(' · ');
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 5, 4, 5),
        leading: const Icon(Icons.replay_rounded, size: 20),
        title: Text(players, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${entry.mode == MatchMode.local ? l10n.localMode : l10n.lanMode}'
          ' · $date · ${l10n.replayMoveCount(replay.actions.length)}',
        ),
        onTap: onPlay,
        trailing: IconButton(
          tooltip: l10n.deleteReplay,
          onPressed: onDelete,
          icon: const Icon(Icons.close_rounded, size: 18),
        ),
      ),
    );
  }
}
