import 'package:flutter_test/flutter_test.dart';

import '../../tool/verify_device_acceptance.dart';

void main() {
  const deviceLabel = 'android_test_phone';
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const scenarios = <String, ({int radius, bool effects})>{
    'large_effects_on': (radius: 4, effects: true),
    'large_effects_off': (radius: 4, effects: false),
    'huge_effects_on': (radius: 5, effects: true),
    'huge_effects_off': (radius: 5, effects: false),
    'radius8_effects_on': (radius: 8, effects: true),
    'radius8_effects_off': (radius: 8, effects: false),
  };

  Map<String, dynamic> completeReport() => <String, dynamic>{
    'target_identity_$deviceLabel': <String, dynamic>{
      'platform': 'android',
      'platformVersion': 'Android 15 (SDK 35)',
      'isPhysicalDevice': true,
      'deviceModel': 'Test Phone',
      'deviceLabel': deviceLabel,
      'acceptanceBuildId': buildId,
    },
    'native_discovery_$deviceLabel': <String, dynamic>{
      'platform': 'android',
      'platformVersion': 'Android 15 (SDK 35)',
      'isPhysicalDevice': true,
      'deviceModel': 'Test Phone',
      'deviceLabel': deviceLabel,
      'acceptanceBuildId': buildId,
      'serviceType': '_trigrid._tcp',
      'port': 43119,
    },
    'functional_flow_$deviceLabel': <String, dynamic>{
      'platform': 'android',
      'platformVersion': 'Android 15 (SDK 35)',
      'isPhysicalDevice': true,
      'deviceModel': 'Test Phone',
      'deviceLabel': deviceLabel,
      'acceptanceBuildId': buildId,
      'revision': 1,
      'privateHandoffVisible': true,
    },
    'screenshots': <Map<String, dynamic>>[
      <String, dynamic>{
        'name': '${deviceLabel}_board',
        'acceptanceBuildId': buildId,
      },
      <String, dynamic>{
        'name': '${deviceLabel}_handoff',
        'acceptanceBuildId': buildId,
      },
    ],
    for (final scenario in scenarios.entries)
      'profile_${scenario.key}_$deviceLabel': <String, dynamic>{
        'platform': 'android',
        'platformVersion': 'Android 15 (SDK 35)',
        'isPhysicalDevice': true,
        'deviceModel': 'Test Phone',
        'deviceLabel': deviceLabel,
        'acceptanceBuildId': buildId,
        'scenarioId': scenario.key,
        'boardRadius': scenario.value.radius,
        'effectsEnabled': scenario.value.effects,
        'profileMode': true,
        'submittedMoves': 20,
        'frame_count': 230,
        'frameBudgetMillis': 16.67,
        '90th_percentile_frame_build_time_millis': 8.2,
        '90th_percentile_frame_rasterizer_time_millis': 9.4,
        'passedFrameBudget': true,
      },
  };

  test('accepts complete functional and six-case performance evidence', () {
    expect(
      verifyDeviceAcceptanceReport(
        completeReport(),
        deviceLabel,
        expectedBuildId: buildId,
      ),
      isEmpty,
    );
  });

  test('rejects missing scenarios and contradictory pass metadata', () {
    final report = completeReport();
    report.remove('profile_huge_effects_on_$deviceLabel');
    final failed =
        report['profile_radius8_effects_on_$deviceLabel']!
            as Map<String, dynamic>;
    failed['90th_percentile_frame_rasterizer_time_millis'] = 20.0;
    failed['passedFrameBudget'] = false;

    final failures = verifyDeviceAcceptanceReport(
      report,
      deviceLabel,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'profile_huge_effects_on_$deviceLabel is missing or is not an object.',
      ),
    );
    expect(
      failures,
      contains(
        'profile_radius8_effects_on_$deviceLabel exceeds the raster p90 budget.',
      ),
    );
    expect(
      failures,
      contains(
        'profile_radius8_effects_on_$deviceLabel is not marked as a passing '
        'frame-budget result.',
      ),
    );
  });

  test('rejects virtual-device evidence despite passing timings', () {
    final report = completeReport();
    final identity =
        report['target_identity_$deviceLabel']! as Map<String, dynamic>;
    final discovery =
        report['native_discovery_$deviceLabel']! as Map<String, dynamic>;
    final flow =
        report['functional_flow_$deviceLabel']! as Map<String, dynamic>;
    identity['isPhysicalDevice'] = false;
    discovery['isPhysicalDevice'] = false;
    flow['isPhysicalDevice'] = false;
    for (final scenario in scenarios.keys) {
      final profile =
          report['profile_${scenario}_$deviceLabel']! as Map<String, dynamic>;
      profile['isPhysicalDevice'] = false;
    }

    final failures = verifyDeviceAcceptanceReport(
      report,
      deviceLabel,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'target_identity_$deviceLabel was not captured on a physical device.',
      ),
    );
    expect(
      failures,
      contains(
        'native_discovery_$deviceLabel was not captured on a physical device.',
      ),
    );
    expect(
      failures,
      contains(
        'functional_flow_$deviceLabel was not captured on a physical device.',
      ),
    );
    expect(
      failures,
      contains(
        'profile_large_effects_on_$deviceLabel was not captured on a physical '
        'device.',
      ),
    );
  });

  test('rejects stale evidence and screenshots from another build', () {
    final report = completeReport();
    final flow =
        report['functional_flow_$deviceLabel']! as Map<String, dynamic>;
    flow['acceptanceBuildId'] =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final screenshots = report['screenshots']! as List<Map<String, dynamic>>;
    screenshots.first['acceptanceBuildId'] =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    final failures = verifyDeviceAcceptanceReport(
      report,
      deviceLabel,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'functional_flow_$deviceLabel was captured for a different '
        'acceptance build.',
      ),
    );
    expect(
      failures,
      contains(
        'Screenshot ${deviceLabel}_board was captured for a different '
        'acceptance build.',
      ),
    );
  });
}
