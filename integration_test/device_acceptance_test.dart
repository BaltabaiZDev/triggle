import 'dart:async';
import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:trigrid/app/trigrid_app.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/network/trigrid_network.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';
import 'package:trigrid/game/trigrid_flame_game.dart';
import 'package:trigrid/l10n/generated/app_localizations.dart';
import 'package:trigrid/presentation/controllers/local_game_session_controller.dart';
import 'package:trigrid/presentation/screens/game/game_screen.dart';
import 'package:trigrid/services/game_feel/game_feedback.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

const _deviceTestScope = String.fromEnvironment(
  'TRIGRID_DEVICE_TEST_SCOPE',
  defaultValue: 'all',
);
const _deviceLabel = String.fromEnvironment(
  'TRIGRID_DEVICE_LABEL',
  defaultValue: 'physical_android',
);
const _acceptanceBuildId = String.fromEnvironment(
  'TRIGRID_ACCEPTANCE_BUILD_ID',
);
const _profileCase = String.fromEnvironment(
  'TRIGRID_PROFILE_CASE',
  defaultValue: 'all',
);

class _ProfileScenario {
  const _ProfileScenario({
    required this.id,
    required this.preset,
    required this.effectsEnabled,
    this.customRadius,
  });

  final String id;
  final BoardSizePreset preset;
  final int? customRadius;
  final bool effectsEnabled;

  BoardSize get boardSize =>
      BoardSize.fromPreset(preset, customRadius: customRadius);
}

const _profileScenarios = <_ProfileScenario>[
  _ProfileScenario(
    id: 'large_effects_on',
    preset: BoardSizePreset.large,
    effectsEnabled: true,
  ),
  _ProfileScenario(
    id: 'large_effects_off',
    preset: BoardSizePreset.large,
    effectsEnabled: false,
  ),
  _ProfileScenario(
    id: 'huge_effects_on',
    preset: BoardSizePreset.huge,
    effectsEnabled: true,
  ),
  _ProfileScenario(
    id: 'huge_effects_off',
    preset: BoardSizePreset.huge,
    effectsEnabled: false,
  ),
  _ProfileScenario(
    id: 'radius8_effects_on',
    preset: BoardSizePreset.custom,
    customRadius: 8,
    effectsEnabled: true,
  ),
  _ProfileScenario(
    id: 'radius8_effects_off',
    preset: BoardSizePreset.custom,
    customRadius: 8,
    effectsEnabled: false,
  ),
];

Future<Map<String, Object?>> _deviceMetadata() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return <String, Object?>{
      'platform': 'android',
      'platformVersion':
          'Android ${android.version.release} (SDK ${android.version.sdkInt})',
      'isPhysicalDevice': android.isPhysicalDevice,
      'deviceManufacturer': android.manufacturer,
      'deviceModel': android.model,
    };
  }
  if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return <String, Object?>{
      'platform': 'ios',
      'platformVersion': '${ios.systemName} ${ios.systemVersion}',
      'isPhysicalDevice': ios.isPhysicalDevice,
      'deviceManufacturer': 'Apple',
      'deviceModel': ios.modelName,
      'deviceMachine': ios.utsname.machine,
    };
  }
  return <String, Object?>{
    'platform': Platform.operatingSystem,
    'platformVersion': Platform.operatingSystemVersion,
    'isPhysicalDevice': false,
    'deviceManufacturer': 'unsupported',
    'deviceModel': Platform.localHostname,
  };
}

Future<void> _bestEffortNsdCleanup(Future<void> Function() cleanup) async {
  try {
    await cleanup().timeout(const Duration(seconds: 5));
  } on Object {
    // Preserve the original test result when a platform cleanup call stalls.
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  testWidgets('target identity is recorded for acceptance evidence', (
    tester,
  ) async {
    expect(
      RegExp(r'^[0-9a-f]{64}$').hasMatch(_acceptanceBuildId),
      isTrue,
      reason:
          'Pass the current output of '
          '`dart tool/acceptance_build_id.dart` through '
          'TRIGRID_ACCEPTANCE_BUILD_ID.',
    );
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['acceptanceBuildId'] = _acceptanceBuildId;
    binding.reportData!['target_identity_$_deviceLabel'] = <String, Object?>{
      ...await _deviceMetadata(),
      'deviceLabel': _deviceLabel,
      'acceptanceBuildId': _acceptanceBuildId,
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
  });

  if (_deviceTestScope != 'performance') {
    testWidgets('native DNS-SD registers and rediscovers a TriGrid room', (
      tester,
    ) async {
      final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final room = LanRoomAdvertisement(
        roomId: 'device-$suffix',
        roomCode: 'DVC${suffix.substring(suffix.length - 3).toUpperCase()}',
        roomName: 'Device acceptance room',
        address: '127.0.0.1',
        port: 43119,
        playerCount: 1,
        capacity: 4,
        protocolVersion: LanEnvelope.currentProtocolVersion,
      );
      nsd.Discovery? discovery;
      nsd.Registration? registration;
      final found = Completer<nsd.Service>();
      final deviceMetadata = await _deviceMetadata();

      void listener(nsd.Service service, nsd.ServiceStatus status) {
        if (status == nsd.ServiceStatus.found &&
            service.name == 'TriGrid-${room.roomCode}' &&
            !found.isCompleted) {
          found.complete(service);
        }
      }

      try {
        discovery = await nsd
            .startDiscovery(
              LanDiscoveryService.bonjourServiceType,
              ipLookupType: nsd.IpLookupType.any,
            )
            .timeout(const Duration(seconds: 12));
        discovery.addServiceListener(listener);
        registration = await nsd
            .register(LanBonjourCodec.serviceFor(room))
            .timeout(const Duration(seconds: 12));
        for (final service in discovery.services) {
          listener(service, nsd.ServiceStatus.found);
        }

        final resolved = await found.future.timeout(
          const Duration(seconds: 12),
        );
        final decoded = LanBonjourCodec.decode(resolved);
        expect(decoded, isNotNull);
        expect(decoded!.roomId, room.roomId);
        expect(decoded.roomCode, room.roomCode);
        expect(decoded.port, room.port);
        binding.reportData ??= <String, dynamic>{};
        binding.reportData!['native_discovery_$_deviceLabel'] =
            <String, Object?>{
              ...deviceMetadata,
              'deviceLabel': _deviceLabel,
              'acceptanceBuildId': _acceptanceBuildId,
              'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
              'serviceType': resolved.type,
              'serviceName': resolved.name,
              'host': resolved.host,
              'addresses': resolved.addresses
                  ?.map((address) => address.address)
                  .toList(growable: false),
              'port': resolved.port,
              'roomId': decoded.roomId,
            };
      } finally {
        if (registration != null) {
          await _bestEffortNsdCleanup(() => nsd.unregister(registration!));
        }
        if (discovery != null) {
          discovery.removeServiceListener(listener);
          await _bestEffortNsdCleanup(() => nsd.stopDiscovery(discovery!));
        }
      }
    });

    testWidgets('physical app navigates from menu to a playable match', (
      tester,
    ) async {
      Get.put<GameFeedback>(const NoopGameFeedback(), permanent: true);
      final preferences = AppPreferences.defaults().copyWith(
        localeCode: 'en',
        themePreference: AppThemePreference.light,
      );
      final repository = MemoryTriGridRepository(
        TriGridData.defaults().copyWith(preferences: preferences),
      );
      final deviceMetadata = await _deviceMetadata();

      await tester.pumpWidget(
        TriGridApp(repository: repository, ambientMotion: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('TriGrid'), findsOneWidget);
      expect(find.text('Play on one phone'), findsOneWidget);

      await tester.tap(find.text('Play on one phone'));
      await tester.pumpAndSettle();
      expect(find.text('Local game'), findsOneWidget);
      expect(find.text('Classic board'), findsOneWidget);

      await tester.ensureVisible(find.byTooltip('Start match'));
      await tester.tap(find.byTooltip('Start match'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await tester.pump();

      final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
        find.byWidgetPredicate(
          (widget) => widget is GameWidget<TriGridFlameGame>,
        ),
      );
      final session = gameWidget.game!.session;
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pump();
      }
      await binding.takeScreenshot('${_deviceLabel}_board');

      final move = session.engine.validator
          .legalMoves(session.currentState)
          .first;
      session.submitMove(move.start, move.end);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      await tester.pump();

      expect(session.currentState.revision, 1);
      expect(find.text('Pass the device'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Reset camera'), findsOneWidget);

      await binding.takeScreenshot('${_deviceLabel}_handoff');
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['functional_flow_$_deviceLabel'] = <String, Object?>{
        ...deviceMetadata,
        'deviceLabel': _deviceLabel,
        'acceptanceBuildId': _acceptanceBuildId,
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'boardPreset': session.settings.boardSize.preset.name,
        'boardRadius': session.settings.boardSize.radius,
        'revision': session.currentState.revision,
        'privateHandoffVisible': true,
      };

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }

  if (_deviceTestScope != 'functional') {
    final selectedScenarios = _profileScenarios
        .where(
          (scenario) => _profileCase == 'all' || scenario.id == _profileCase,
        )
        .toList(growable: false);
    if (selectedScenarios.isEmpty) {
      testWidgets('profile case selector resolves to a known scenario', (
        tester,
      ) async {
        fail(
          'Unknown TRIGRID_PROFILE_CASE "$_profileCase". Expected "all" or '
          '${_profileScenarios.map((scenario) => scenario.id).join(', ')}.',
        );
      });
    }

    for (final scenario in selectedScenarios) {
      testWidgets(
        '${scenario.id} gameplay meets the physical 60 FPS profile budget',
        (tester) async {
          expect(
            kProfileMode,
            isTrue,
            reason: 'Device frame evidence must be captured in profile mode.',
          );
          final settings = GameSettings(
            matchId: 'device-profile-${scenario.id}',
            boardSize: scenario.boardSize,
            ruleset: Ruleset.custom,
            players: [
              for (var index = 0; index < 2; index++)
                PlayerConfiguration(
                  id: 'profile-$index',
                  displayName: 'Profile ${index + 1}',
                  controllerType: PlayerControllerType.human,
                ),
            ],
            seed: 731,
          );
          final session = LocalGameSessionController(
            settings,
            feedback: const NoopGameFeedback(),
            initialFeelSettings: GameFeelSettings(
              reducedMotion: false,
              particles: scenario.effectsEnabled,
              screenShake: scenario.effectsEnabled,
            ),
          );
          final deviceMetadata = await _deviceMetadata();

          await tester.pumpWidget(
            GetMaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: GameScreen(
                settings: settings,
                session: session,
                persistMatch: false,
              ),
            ),
          );
          await tester.pump();
          await Future<void>.delayed(const Duration(seconds: 2));

          final gameWidget = tester.widget<GameWidget<TriGridFlameGame>>(
            find.byWidgetPredicate(
              (widget) => widget is GameWidget<TriGridFlameGame>,
            ),
          );
          final game = gameWidget.game!;
          var submittedMoves = 0;
          final frameTimings = <FrameTiming>[];
          void recordTimings(List<FrameTiming> timings) {
            frameTimings.addAll(timings);
          }

          Future<void> renderFrames(int count) async {
            for (var index = 0; index < count; index++) {
              await tester.pump(const Duration(milliseconds: 16));
            }
          }

          await renderFrames(30);
          await Future<void>.delayed(const Duration(seconds: 2));
          binding.addTimingsCallback(recordTimings);
          try {
            for (
              var index = 0;
              index < 20 && !session.currentState.isGameOver;
              index++
            ) {
              final legalMoves = session.engine.validator.legalMoves(
                session.currentState,
              );
              final move = legalMoves.reduce((best, candidate) {
                final bestCaptures = session.engine.validator
                    .capturesForMove(session.currentState, best)
                    .length;
                final candidateCaptures = session.engine.validator
                    .capturesForMove(session.currentState, candidate)
                    .length;
                return candidateCaptures > bestCaptures ? candidate : best;
              });
              session.submitMove(move.start, move.end);
              submittedMoves++;
              if (index == 5) {
                game.zoomAt(
                  Offset(game.size.x * 0.5, game.size.y * 0.5),
                  game.camera.viewfinder.zoom * 1.35,
                );
              } else if (index == 10) {
                game.panByCanvasDelta(const Offset(90, -65));
              } else if (index == 15) {
                game.resetCamera();
              }
              await renderFrames(10);
            }
            await renderFrames(30);
            await Future<void>.delayed(const Duration(seconds: 2));
          } finally {
            binding.removeTimingsCallback(recordTimings);
          }

          expect(frameTimings, isNotEmpty);
          final performance = FrameTimingSummarizer(frameTimings).summary;
          binding.reportData ??= <String, dynamic>{};
          binding.reportData!['profile_${scenario.id}_$_deviceLabel'] =
              performance;
          performance['deviceLabel'] = _deviceLabel;
          performance['acceptanceBuildId'] = _acceptanceBuildId;
          performance['scenarioId'] = scenario.id;
          performance.addAll(deviceMetadata);
          performance['recordedAtUtc'] = DateTime.now()
              .toUtc()
              .toIso8601String();
          performance['profileMode'] = kProfileMode;
          performance['boardPreset'] = settings.boardSize.preset.name;
          performance['boardRadius'] = settings.boardSize.radius;
          performance['effectsEnabled'] = scenario.effectsEnabled;
          performance['particles'] = scenario.effectsEnabled;
          performance['screenShake'] = scenario.effectsEnabled;
          performance['submittedMoves'] = submittedMoves;
          performance['finalRevision'] = session.currentState.revision;
          performance['screenPhysicalSize'] =
              '${tester.view.physicalSize.width.toInt()}x'
              '${tester.view.physicalSize.height.toInt()}';
          performance['devicePixelRatio'] = tester.view.devicePixelRatio;
          final p90Build =
              performance['90th_percentile_frame_build_time_millis']! as double;
          final p90Raster =
              performance['90th_percentile_frame_rasterizer_time_millis']!
                  as double;
          const frameBudgetMillis = 16.67;
          final frameCount = performance['frame_count']! as int;
          final passedFrameBudget =
              submittedMoves >= 16 &&
              frameCount > 120 &&
              p90Build <= frameBudgetMillis &&
              p90Raster <= frameBudgetMillis;
          performance['frameBudgetMillis'] = frameBudgetMillis;
          performance['passedFrameBudget'] = passedFrameBudget;

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          expect(submittedMoves, greaterThanOrEqualTo(16));
          expect(frameCount, greaterThan(120));
          expect(p90Build, lessThanOrEqualTo(frameBudgetMillis));
          expect(p90Raster, lessThanOrEqualTo(frameBudgetMillis));
        },
      );
    }
  }
}
