import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/presentation/screens/about/about_screen.dart';
import 'package:trigrid/presentation/screens/bots/bot_difficulty_screen.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/presentation/screens/lan/lan_menu_screen.dart';
import 'package:trigrid/presentation/screens/local_game/local_game_setup_screen.dart';
import 'package:trigrid/presentation/screens/replays/replay_library_screen.dart';
import 'package:trigrid/presentation/screens/rules/rules_screen.dart';
import 'package:trigrid/presentation/screens/settings/settings_screen.dart';
import 'package:trigrid/presentation/screens/statistics/statistics_screen.dart';
import 'package:trigrid/presentation/screens/tutorial/tutorial_screen.dart';
import 'package:trigrid/presentation/widgets/trigrid_board_mark.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final appController = Get.find<AppController>();
    return Scaffold(
      body: TriGridBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TriGridBoardMark(
                          size: 64,
                          semanticsLabel: l10n.boardPreviewLabel,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.appTitle,
                            style: theme.textTheme.displaySmall,
                          ),
                        ),
                        PopupMenuButton<_MenuDestination>(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).moreButtonTooltip,
                          icon: const Icon(Icons.more_horiz_rounded),
                          onSelected: _openSecondary,
                          itemBuilder: (context) => [
                            _menuItem(
                              _MenuDestination.tutorial,
                              Icons.school_outlined,
                              l10n.tutorialTitle,
                            ),
                            _menuItem(
                              _MenuDestination.rules,
                              Icons.menu_book_outlined,
                              l10n.rulesTitle,
                            ),
                            _menuItem(
                              _MenuDestination.settings,
                              Icons.settings_outlined,
                              l10n.appSettingsTitle,
                            ),
                            _menuItem(
                              _MenuDestination.statistics,
                              Icons.bar_chart_rounded,
                              l10n.statisticsTitle,
                            ),
                            _menuItem(
                              _MenuDestination.replays,
                              Icons.movie_filter_outlined,
                              l10n.replayLibraryTitle,
                            ),
                            _menuItem(
                              _MenuDestination.bots,
                              Icons.psychology_outlined,
                              l10n.botGuideTitle,
                            ),
                            _menuItem(
                              _MenuDestination.about,
                              Icons.info_outline_rounded,
                              l10n.aboutTitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Divider(
                      height: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    Obx(() {
                      final snapshot = appController.localSnapshot.value;
                      return Column(
                        children: [
                          if (snapshot != null) ...[
                            TriGridGameButton(
                              icon: Icons.play_arrow_rounded,
                              label: l10n.continueMatch,
                              primary: true,
                              onPressed: _withFeedback(
                                () => _continueMatch(snapshot, appController),
                              ),
                            ),
                            const SizedBox(height: 7),
                          ],
                          TriGridGameButton(
                            icon: Icons.smart_toy_rounded,
                            label: l10n.soloPlay,
                            primary: snapshot == null,
                            onPressed: _withFeedback(
                              () => Get.to<void>(
                                () => const LocalGameSetupScreen(
                                  mode: LocalGameSetupMode.solo,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: TriGridGameButton(
                                  icon: Icons.people_alt_rounded,
                                  label: l10n.playOnOnePhone,
                                  accentColor: const Color(0xFFE96F51),
                                  compact: true,
                                  onPressed: _withFeedback(
                                    () => Get.to<void>(
                                      () => const LocalGameSetupScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: TriGridGameButton(
                                  icon: Icons.wifi_tethering_rounded,
                                  label: l10n.lanPlay,
                                  accentColor: const Color(0xFF477CA8),
                                  compact: true,
                                  onPressed: _withFeedback(
                                    () => Get.to<void>(
                                      () => const LanMenuScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback _withFeedback(VoidCallback action) {
    return () {
      if (Get.isRegistered<GameFeedback>()) {
        playFeedback(Get.find<GameFeedback>().buttonPress());
      }
      action();
    };
  }

  PopupMenuItem<_MenuDestination> _menuItem(
    _MenuDestination destination,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: destination,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  void _openSecondary(_MenuDestination destination) {
    if (Get.isRegistered<GameFeedback>()) {
      playFeedback(Get.find<GameFeedback>().buttonPress());
    }
    Get.to<void>(
      () => switch (destination) {
        _MenuDestination.tutorial => const TutorialScreen(),
        _MenuDestination.rules => const RulesScreen(),
        _MenuDestination.settings => const SettingsScreen(),
        _MenuDestination.statistics => const StatisticsScreen(),
        _MenuDestination.replays => const ReplayLibraryScreen(),
        _MenuDestination.bots => const BotDifficultyScreen(),
        _MenuDestination.about => const AboutScreen(),
      },
    );
  }

  void _continueMatch(
    SavedMatchSnapshot snapshot,
    AppController appController,
  ) {
    final feedback = Get.find<GameFeedback>();
    final session = LocalGameSessionController(
      snapshot.state.settings,
      feedback: feedback,
      initialFeelSettings: appController.preferences.value.gameFeel,
      enablePassAndPlayHandoffs: snapshot.passAndPlayHandoffs,
      disposeFeedbackOnClose: false,
    );
    try {
      session.restoreVerifiedState(
        restoredState: snapshot.state,
        actions: snapshot.actions,
        expectedHash: snapshot.stateHash,
      );
    } on Object {
      appController.clearLocalSnapshot();
      return;
    }
    Get.to<void>(
      () => GameScreen(
        settings: snapshot.state.settings,
        session: session,
        enablePassAndPlayHandoffs: snapshot.passAndPlayHandoffs,
      ),
    );
  }
}

enum _MenuDestination {
  tutorial,
  rules,
  settings,
  statistics,
  replays,
  bots,
  about,
}
