import 'package:trigrid/presentation/widgets/game_motion.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/game/rendering/player_visuals.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/presentation/widgets/trigrid_game_surface.dart';
import 'package:uuid/uuid.dart';
import 'package:trigrid/presentation/widgets/game_icon_controls.dart';

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
    }
    _normalizeBoardForPlayers();
    if (widget.mode == LocalGameSetupMode.solo) {
      for (var index = 1; index < _isBot.length; index++) {
        _isBot[index] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).height < 650;
    return GamePage(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? const GamePress(child: BackButton())
            : null,
        title: Text(
          widget.mode == LocalGameSetupMode.solo
              ? l10n.soloSetupTitle
              : l10n.localGameSetupTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, compact ? 10 : 18, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.playerCountLabel,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            for (final count in [2, 3, 4]) ...[
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 46,
                                child: _SetupChoice(
                                  label: '$count',
                                  selected: _playerCount == count,
                                  onTap: () => _setPlayerCount(count),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 20),
                        AnimatedSize(
                          duration: GameMotionScope.duration(context, 320),
                          curve: const GameSpringCurve(),
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              for (var index = 0; index < _playerCount; index++)
                                _SeatConfigurationRow(
                                  key: ValueKey(index),
                                  index: index,
                                  compact: compact,
                                  playerName: _playerName(l10n, index),
                                  isBot: _isBot[index],
                                  controllerCanChange:
                                      widget.mode != LocalGameSetupMode.solo ||
                                      index > 0,
                                  canBecomeHuman:
                                      !(widget.mode ==
                                              LocalGameSetupMode.solo &&
                                          _isBot[index] &&
                                          _isBot
                                                  .take(_playerCount)
                                                  .where((isBot) => isBot)
                                                  .length <=
                                              1),
                                  difficulty: _botDifficulties[index],
                                  difficultyLabel: _difficultyLabel,
                                  onBotChanged: (value) =>
                                      setState(() => _isBot[index] = value),
                                  onDifficultyChanged: (value) => setState(
                                    () => _botDifficulties[index] = value,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 28),
                        Text(
                          l10n.boardSizeLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        BoardSizeSelector(
                          value: _boardPreset,
                          playerCount: _playerCount,
                          onChanged: (preset) => setState(() {
                            _boardPreset = preset;
                            _normalizeBoardForPlayers();
                          }),
                        ),
                        const SizedBox(height: 12),
                        GameSwitcher(
                          child: _boardPreset == BoardSizePreset.custom
                              ? Column(
                                  key: const ValueKey('custom-radius'),
                                  children: [
                                    Text(
                                      l10n.customRadiusLabel(_customRadius),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    GamePress(
                                      sound: false,
                                      child: Slider(
                                        value: _customRadius.toDouble(),
                                        min:
                                            (_playerCount > 2
                                                    ? 3
                                                    : BoardSize.minimumRadius)
                                                .toDouble(),
                                        max: BoardSize.maximumRadius.toDouble(),
                                        divisions:
                                            BoardSize.maximumRadius -
                                            (_playerCount > 2
                                                ? 3
                                                : BoardSize.minimumRadius),
                                        label: '$_customRadius',
                                        onChanged: (value) => setState(
                                          () => _customRadius = value.round(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('preset-radius'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Center(
                    child: GameIconAction(
                      icon: Icons.play_arrow_rounded,
                      label: l10n.startMatch,
                      primary: true,
                      size: 68,
                      onPressed: () => _startMatch(l10n),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPlayerCount(int count) {
    setState(() {
      _playerCount = count;
      _normalizeBoardForPlayers();
      // Removing the last bot's seat must not turn solo into a human-only game.
      if (widget.mode == LocalGameSetupMode.solo &&
          !_isBot.take(count).any((isBot) => isBot)) {
        _isBot[count - 1] = true;
      }
    });
  }

  void _normalizeBoardForPlayers() {
    if (_playerCount <= 2) return;
    if (_boardPreset == BoardSizePreset.small) {
      _boardPreset = BoardSizePreset.classic;
    }
    if (_customRadius < 3) _customRadius = 3;
  }

  void _startMatch(AppLocalizations l10n) {
    final appController = Get.isRegistered<AppController>()
        ? Get.find<AppController>()
        : null;
    final boardSize = BoardSize.fromPreset(
      _boardPreset,
      customRadius: _boardPreset == BoardSizePreset.custom
          ? _customRadius
          : null,
    );
    final settings = GameSettings(
      matchId: const Uuid().v4(),
      boardSize: boardSize,
      ruleset: boardSize.isClassic ? Ruleset.classic : Ruleset.custom,
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
      startingPlayerIndex:
          (appController?.statistics.value.local.matchesPlayed ?? 0) %
          _playerCount,
    );
    if (appController != null) {
      final setup = LocalSetupPreferences(
        playerCount: _playerCount,
        boardPreset: _boardPreset,
        customRadius: _customRadius,
        useClassicRules: boardSize.isClassic,
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

/// Compact, readable player row: no nested cards, switches or form borders.
class _SeatConfigurationRow extends StatelessWidget {
  const _SeatConfigurationRow({
    required this.index,
    required this.compact,
    required this.playerName,
    required this.isBot,
    required this.controllerCanChange,
    required this.canBecomeHuman,
    required this.difficulty,
    required this.difficultyLabel,
    required this.onBotChanged,
    required this.onDifficultyChanged,
    super.key,
  });
  final int index;
  final bool compact;
  final String playerName;
  final bool isBot;
  final bool controllerCanChange;
  final bool canBecomeHuman;
  final BotDifficulty difficulty;
  final String Function(BotDifficulty) difficultyLabel;
  final ValueChanged<bool> onBotChanged;
  final ValueChanged<BotDifficulty> onDifficultyChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = PlayerVisuals.forSeat(index).color;
    return GamePulse(
      value: '$isBot:$difficulty',
      color: color,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GameSwitcher(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      playerName,
                      key: ValueKey(playerName),
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _RoleChoice(
                  key: ValueKey('seat-$index-human'),
                  label: l10n.humanPlayer,
                  icon: Icons.person_rounded,
                  selected: !isBot,
                  onTap: controllerCanChange && canBecomeHuman
                      ? () => onBotChanged(false)
                      : null,
                ),
                const SizedBox(width: 4),
                _RoleChoice(
                  key: ValueKey('seat-$index-bot'),
                  label: l10n.botPlayer,
                  icon: Icons.smart_toy_rounded,
                  selected: isBot,
                  onTap: controllerCanChange ? () => onBotChanged(true) : null,
                ),
              ],
            ),
            AnimatedSize(
              duration: GameMotionScope.duration(context, 280),
              curve: const GameSpringCurve(),
              alignment: Alignment.topCenter,
              child: GameSwitcher(
                child: isBot
                    ? Padding(
                        key: const ValueKey('difficulty'),
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.botDifficultyLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            GamePress(
                              child: PopupMenuButton<BotDifficulty>(
                                tooltip: l10n.botDifficultyLabel,
                                initialValue: difficulty,
                                onSelected: (value) {
                                  gameUiSound(select: true);
                                  onDifficultyChanged(value);
                                },
                                itemBuilder: (context) => [
                                  for (final value in BotDifficulty.values)
                                    PopupMenuItem(
                                      value: value,
                                      child: Text(difficultyLabel(value)),
                                    ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        difficultyLabel(difficulty),
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.expand_more_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-difficulty')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: GamePress(
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: GameMotionScope.duration(context, 220),
            curve: const GameSpringCurve(),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 21,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white38,
            ),
          ),
        ),
      ),
    ),
  );
}

class _SetupChoice extends StatelessWidget {
  const _SetupChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GamePulse(
        value: selected,
        child: GamePress(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: GameMotionScope.duration(context, 220),
              curve: const GameSpringCurve(),
              constraints: const BoxConstraints(minHeight: 46),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.65)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
