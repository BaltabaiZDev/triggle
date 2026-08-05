import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppController _controller;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppController>();
    _nameController = TextEditingController(
      text: _controller.preferences.value.playerName,
    );
  }

  @override
  void dispose() {
    _saveName();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appSettingsTitle)),
      body: SafeArea(
        child: Obx(() {
          final preferences = _controller.preferences.value;
          final feel = preferences.gameFeel;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              _SettingsSection(
                title: l10n.profileAndLanguage,
                children: [
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                    decoration: InputDecoration(
                      labelText: l10n.playerNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(preferences.localeCode),
                    initialValue: preferences.localeCode ?? 'system',
                    decoration: InputDecoration(
                      labelText: l10n.languageLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.languageSystem),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.languageEnglish),
                      ),
                      DropdownMenuItem(
                        value: 'kk',
                        child: Text(l10n.languageKazakh),
                      ),
                      DropdownMenuItem(
                        value: 'ru',
                        child: Text(l10n.languageRussian),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _update(
                        value == 'system'
                            ? preferences.copyWith(clearLocale: true)
                            : preferences.copyWith(localeCode: value),
                      );
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: l10n.appearanceTitle,
                children: [
                  DropdownButtonFormField<AppThemePreference>(
                    key: ValueKey(preferences.themePreference),
                    initialValue: preferences.themePreference,
                    decoration: InputDecoration(
                      labelText: l10n.themeLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppThemePreference.system,
                        child: Text(l10n.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: AppThemePreference.light,
                        child: Text(l10n.themeLight),
                      ),
                      DropdownMenuItem(
                        value: AppThemePreference.dark,
                        child: Text(l10n.themeDark),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _update(preferences.copyWith(themePreference: value));
                      }
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: preferences.highContrast,
                    title: Text(l10n.highContrast),
                    subtitle: Text(l10n.highContrastDescription),
                    onChanged: (value) {
                      _update(preferences.copyWith(highContrast: value));
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: l10n.audioTitle,
                children: [
                  _VolumeSlider(
                    label: l10n.soundEffectsVolume,
                    value: feel.soundEffectsVolume,
                    onChanged: (value) =>
                        _updateFeel(feel.copyWith(soundEffectsVolume: value)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: feel.muted,
                    title: Text(l10n.muteAll),
                    onChanged: (value) =>
                        _updateFeel(feel.copyWith(muted: value)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: feel.haptics,
                    title: Text(l10n.haptics),
                    onChanged: (value) =>
                        _updateFeel(feel.copyWith(haptics: value)),
                  ),
                ],
              ),
              _SettingsSection(
                title: l10n.accessibilityTitle,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: preferences.confirmMoves,
                    title: Text(l10n.confirmMoves),
                    subtitle: Text(l10n.confirmMovesDescription),
                    onChanged: (value) {
                      _update(preferences.copyWith(confirmMoves: value));
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: feel.reducedMotion,
                    title: Text(l10n.reducedMotion),
                    subtitle: Text(l10n.reducedMotionDescription),
                    onChanged: (value) =>
                        _updateFeel(feel.copyWith(reducedMotion: value)),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && name != _controller.preferences.value.playerName) {
      _update(_controller.preferences.value.copyWith(playerName: name));
    }
  }

  void _update(AppPreferences preferences) {
    unawaited(_controller.updatePreferences(preferences));
  }

  void _updateFeel(GameFeelSettings nextFeel) {
    if (Get.isRegistered<GameFeedback>()) {
      playFeedback(Get.find<GameFeedback>().updateSettings(nextFeel));
    }
    _update(_controller.preferences.value.copyWith(gameFeel: nextFeel));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
          const Divider(height: 14),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 112, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            label: '${(value * 100).round()}%',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
