import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:uuid/uuid.dart';

enum LocalGameSetupMode { solo, passAndPlay }

class LocalGameSetupScreen extends StatefulWidget {
  const LocalGameSetupScreen({
    this.mode = LocalGameSetupMode.passAndPlay,
    super.key,
  });

  final LocalGameSetupMode mode;

  @override
  State<LocalGameSetupScreen> createState() => _LocalGameSetupScreenState();
}

class _LocalGameSetupScreenState extends State<LocalGameSetupScreen> {
  var _playerCount = 2;
  var _boardPreset = BoardSizePreset.classic;
  var _customRadius = 6;
  var _useClassicRules = true;
  final List<bool> _isBot = List<bool>.filled(4, false);
  final List<BotDifficulty> _botDifficulties = List<BotDifficulty>.filled(
    4,
    BotDifficulty.normal,
  );
  final List<BotPersonality> _botPersonalities = List<BotPersonality>.filled(
    4,
    BotPersonality.balanced,
  );
  final List<int> _botThinkingTimes = List<int>.filled(4, 350);

  @override
  void initState() {
    super.initState();
    final appController = Get.isRegistered<AppController>()
        ? Get.find<AppController>()
        : null;
    final saved = widget.mode == LocalGameSetupMode.solo
        ? appController?.preferences.value.soloSetup
        : appController?.preferences.value.passAndPlaySetup;
    if (saved != null) {
      _playerCount = saved.playerCount;
      _boardPreset = saved.boardPreset;
      _customRadius = saved.customRadius;
      _useClassicRules = saved.useClassicRules;
    }
    if (widget.mode == LocalGameSetupMode.solo) {
      for (var index = 1; index < _isBot.length; index++) {
        _isBot[index] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          widget.mode == LocalGameSetupMode.solo
              ? l10n.soloSetupTitle
              : l10n.localGameSetupTitle,
        ),
      ),
      body: TriGridBackdrop(
        dense: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: TriGridPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TriGridSectionTitle(
                        icon: Icons.groups_rounded,
                        label: l10n.playerCountLabel,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<int>(
                        segments: [
                          for (final count in [2, 3, 4])
                            ButtonSegment(
                              value: count,
                              label: Text('$count'),
                              icon: const Icon(Icons.person_rounded),
                            ),
                        ],
                        selected: {_playerCount},
                        onSelectionChanged: (selection) {
                          setState(() => _playerCount = selection.single);
                        },
                      ),
                      const SizedBox(height: 16),
                      TriGridSectionTitle(
                        icon: Icons.stadium_rounded,
                        label: l10n.seatSetupTitle,
                      ),
                      const SizedBox(height: 8),
                      for (var index = 0; index < _playerCount; index++) ...[
                        _SeatConfigurationCard(
                          playerName: _playerName(l10n, index),
                          isBot: _isBot[index],
                          controllerCanChange:
                              widget.mode != LocalGameSetupMode.solo ||
                              index > 0,
                          difficulty: _botDifficulties[index],
                          difficultyLabel: _difficultyLabel,
                          onBotChanged: (value) {
                            if (widget.mode == LocalGameSetupMode.solo &&
                                !value &&
                                _isBot
                                        .take(_playerCount)
                                        .where((isBot) => isBot)
                                        .length <=
                                    1) {
                              return;
                            }
                            setState(() => _isBot[index] = value);
                          },
                          onDifficultyChanged: (value) {
                            setState(() => _botDifficulties[index] = value);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      const Divider(height: 22),
                      TriGridSectionTitle(
                        icon: Icons.hexagon_outlined,
                        label: l10n.boardSizeLabel,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BoardSizePreset>(
                        initialValue: _boardPreset,
                        decoration: const InputDecoration(),
                        items: [
                          for (final preset in BoardSizePreset.values)
                            DropdownMenuItem(
                              value: preset,
                              child: Text(_boardLabel(l10n, preset)),
                            ),
                        ],
                        onChanged: (preset) {
                          if (preset == null) {
                            return;
                          }
                          setState(() {
                            _boardPreset = preset;
                            _useClassicRules =
                                preset == BoardSizePreset.classic;
                          });
                        },
                      ),
                      if (_boardPreset == BoardSizePreset.custom) ...[
                        const SizedBox(height: 20),
                        Text(l10n.customRadiusLabel(_customRadius)),
                        Slider(
                          value: _customRadius.toDouble(),
                          min: BoardSize.minimumRadius.toDouble(),
                          max: BoardSize.maximumRadius.toDouble(),
                          divisions:
                              BoardSize.maximumRadius - BoardSize.minimumRadius,
                          label: '$_customRadius',
                          onChanged: (value) {
                            setState(() => _customRadius = value.round());
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.classicRules),
                        value: _useClassicRules,
                        onChanged: _boardPreset == BoardSizePreset.classic
                            ? (value) {
                                setState(() => _useClassicRules = value);
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _startMatch(l10n),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(l10n.startMatch),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startMatch(AppLocalizations l10n) {
    final boardSize = BoardSize.fromPreset(
      _boardPreset,
      customRadius: _boardPreset == BoardSizePreset.custom
          ? _customRadius
          : null,
    );
    final settings = GameSettings(
      matchId: const Uuid().v4(),
      boardSize: boardSize,
      ruleset: _useClassicRules ? Ruleset.classic : Ruleset.custom,
      players: [
        for (var index = 0; index < _playerCount; index++)
          PlayerConfiguration(
            id: 'local-player-$index',
            displayName: _playerName(l10n, index),
            controllerType: _isBot[index]
                ? PlayerControllerType.bot
                : PlayerControllerType.human,
            botSettings: _isBot[index]
                ? BotSettings(
                    difficulty: _botDifficulties[index],
                    personality: _botPersonalities[index],
                    thinkingTimeMs: _botThinkingTimes[index],
                    seedOffset: index,
                  )
                : null,
          ),
      ],
      seed: DateTime.now().microsecondsSinceEpoch,
    );
    final appController = Get.isRegistered<AppController>()
        ? Get.find<AppController>()
        : null;
    if (appController != null) {
      final setup = LocalSetupPreferences(
        playerCount: _playerCount,
        boardPreset: _boardPreset,
        customRadius: _customRadius,
        useClassicRules: _useClassicRules,
      );
      final preferences = appController.preferences.value;
      unawaited(
        appController.updatePreferences(
          widget.mode == LocalGameSetupMode.solo
              ? preferences.copyWith(soloSetup: setup)
              : preferences.copyWith(passAndPlaySetup: setup),
        ),
      );
    }
    Get.to<void>(
      () => GameScreen(
        settings: settings,
        enablePassAndPlayHandoffs:
            widget.mode == LocalGameSetupMode.passAndPlay,
      ),
    );
  }

  String _playerName(AppLocalizations l10n, int index) {
    if (index == 0 &&
        Get.isRegistered<AppController>() &&
        Get.find<AppController>().preferences.value.playerName
            .trim()
            .isNotEmpty) {
      return Get.find<AppController>().preferences.value.playerName.trim();
    }
    return _isBot[index]
        ? l10n.botDefaultName(index + 1)
        : l10n.playerDefaultName(index + 1);
  }

  String _boardLabel(AppLocalizations l10n, BoardSizePreset preset) {
    return switch (preset) {
      BoardSizePreset.small => l10n.boardSizeSmall,
      BoardSizePreset.classic => l10n.boardSizeClassic,
      BoardSizePreset.large => l10n.boardSizeLarge,
      BoardSizePreset.huge => l10n.boardSizeHuge,
      BoardSizePreset.custom => l10n.boardSizeCustom,
    };
  }

  String _difficultyLabel(BotDifficulty difficulty) {
    final l10n = AppLocalizations.of(context);
    return switch (difficulty) {
      BotDifficulty.beginner => l10n.botDifficultyBeginner,
      BotDifficulty.easy => l10n.botDifficultyEasy,
      BotDifficulty.normal => l10n.botDifficultyNormal,
      BotDifficulty.hard => l10n.botDifficultyHard,
      BotDifficulty.expert => l10n.botDifficultyExpert,
    };
  }
}

class _SeatConfigurationCard extends StatelessWidget {
  const _SeatConfigurationCard({
    required this.playerName,
    required this.isBot,
    required this.controllerCanChange,
    required this.difficulty,
    required this.difficultyLabel,
    required this.onBotChanged,
    required this.onDifficultyChanged,
  });

  final String playerName;
  final bool isBot;
  final bool controllerCanChange;
  final BotDifficulty difficulty;
  final String Function(BotDifficulty) difficultyLabel;
  final ValueChanged<bool> onBotChanged;
  final ValueChanged<BotDifficulty> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(playerName),
              subtitle: Text(isBot ? l10n.botPlayer : l10n.humanPlayer),
              secondary: Icon(
                isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
              ),
              value: isBot,
              onChanged: controllerCanChange ? onBotChanged : null,
            ),
            if (isBot) ...[
              DropdownButtonFormField<BotDifficulty>(
                initialValue: difficulty,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.botDifficultyLabel),
                items: [
                  for (final value in BotDifficulty.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(difficultyLabel(value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onDifficultyChanged(value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
