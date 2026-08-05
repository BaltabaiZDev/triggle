import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:trigrid/app/controllers/app_controller.dart';
import 'package:trigrid/app/theme/trigrid_theme.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/screens/main_menu/main_menu_screen.dart';
import 'package:trigrid/presentation/screens/splash/splash_screen.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';

class TriGridApp extends StatefulWidget {
  const TriGridApp({this.repository, super.key});

  final TriGridRepository? repository;

  @override
  State<TriGridApp> createState() => _TriGridAppState();
}

class _TriGridAppState extends State<TriGridApp> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Get.isRegistered<AppController>()
        ? Get.find<AppController>()
        : Get.put(
            AppController(
              widget.repository ?? SharedPreferencesTriGridRepository(),
            ),
            permanent: true,
          );
    if (!Get.isRegistered<GameFeedback>()) {
      Get.put<GameFeedback>(GameFeedbackCoordinator(), permanent: true);
    }
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (!_appController.isReady.value) {
      await _appController.initialize();
    }
    await Get.find<GameFeedback>().initialize(
      _appController.preferences.value.gameFeel,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<GameFeedback>()) {
      playFeedback(Get.find<GameFeedback>().dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preferences = _appController.preferences.value;
      final themeMode = switch (preferences.themePreference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: TriGridTheme.lightWith(highContrast: preferences.highContrast),
        darkTheme: TriGridTheme.darkWith(
          highContrast: preferences.highContrast,
        ),
        themeMode: themeMode,
        locale: _appController.selectedLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        localeResolutionCallback: _resolveLocale,
        home: _appController.isReady.value
            ? const MainMenuScreen()
            : const SplashScreen(),
      );
    });
  }

  Locale _resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (deviceLocale != null) {
      for (final locale in supportedLocales) {
        if (locale.languageCode == deviceLocale.languageCode) {
          return locale;
        }
      }
    }
    return const Locale('en');
  }
}
