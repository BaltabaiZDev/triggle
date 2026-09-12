import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:uuid/uuid.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (
        Icons.touch_app_rounded,
        l10n.tutorialPlaceTitle,
        l10n.tutorialPlaceBody,
      ),
      (
        Icons.share_rounded,
        l10n.tutorialConnectTitle,
        l10n.tutorialConnectBody,
      ),
      (
        Icons.change_history_rounded,
        l10n.tutorialCaptureTitle,
        l10n.tutorialCaptureBody,
      ),
      (Icons.emoji_events_rounded, l10n.tutorialWinTitle, l10n.tutorialWinBody),
    ];
    return GamePage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? const GamePress(child: BackButton())
            : null,
        title: Text(l10n.tutorialTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(step.$1, size: 44),
                              const SizedBox(height: 14),
                              Text(
                                step.$2,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step.$3,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Row(
                children: [
                  GamePress(
                    child: TextButton(
                      onPressed: _page == 0
                          ? null
                          : () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 240),
                              curve: const GameSpringCurve(),
                            ),
                      child: Text(l10n.previousStep),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < steps.length; index++)
                          Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              index == _page
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              size: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_page < steps.length - 1)
                    GamePress(
                      child: FilledButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: const GameSpringCurve(),
                        ),
                        child: Text(l10n.nextStep),
                      ),
                    )
                  else
                    GamePress(
                      child: FilledButton.icon(
                        onPressed: () => _startPractice(l10n),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.startPractice),
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

  void _startPractice(AppLocalizations l10n) {
    final savedName = Get.isRegistered<AppController>()
        ? Get.find<AppController>().preferences.value.playerName.trim()
        : '';
    final settings = GameSettings(
      matchId: 'tutorial-${const Uuid().v4()}',
      boardSize: BoardSize.fromPreset(BoardSizePreset.small),
      ruleset: Ruleset.custom,
      players: [
        PlayerConfiguration(
          id: 'tutorial-player',
          displayName: savedName.isEmpty
              ? l10n.playerDefaultName(1)
              : savedName,
          controllerType: PlayerControllerType.human,
        ),
        PlayerConfiguration(
          id: 'tutorial-bot',
          displayName: l10n.tutorialBotName,
          controllerType: PlayerControllerType.bot,
          botSettings: BotSettings(
            difficulty: BotDifficulty.beginner,
            personality: BotPersonality.balanced,
            thinkingTimeMs: 220,
            deterministic: true,
          ),
        ),
      ],
      seed: 173,
    );
    Get.to<void>(
      () => GameScreen(
        settings: settings,
        tutorialMode: true,
        persistMatch: false,
      ),
    );
  }
}
