import 'dart:convert';
import 'dart:io';

import 'acceptance_build_id.dart';

const _profileExpectations = <String, ({int radius, bool effects})>{
  'large_effects_on': (radius: 4, effects: true),
  'large_effects_off': (radius: 4, effects: false),
  'huge_effects_on': (radius: 5, effects: true),
  'huge_effects_off': (radius: 5, effects: false),
  'radius8_effects_on': (radius: 8, effects: true),
  'radius8_effects_off': (radius: 8, effects: false),
};

List<String> verifyDeviceAcceptanceReport(
  Map<String, dynamic> report,
  String deviceLabel, {
  bool checkFunctional = true,
  bool checkPerformance = true,
  required String expectedBuildId,
}) {
  final failures = <String>[];

  Map<String, dynamic>? mapAt(String key) {
    final value = report[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    failures.add('$key is missing or is not an object.');
    return null;
  }

  void require(bool condition, String message) {
    if (!condition) {
      failures.add(message);
    }
  }

  void verifyPhysicalTarget(Map<String, dynamic> evidence, String key) {
    require(
      evidence['acceptanceBuildId'] == expectedBuildId,
      '$key was captured for a different acceptance build.',
    );
    require(
      evidence['platform'] == 'android' || evidence['platform'] == 'ios',
      '$key was not captured on Android or iOS.',
    );
    require(
      evidence['isPhysicalDevice'] == true,
      '$key was not captured on a physical device.',
    );
    require(
      evidence['deviceModel'] is String &&
          (evidence['deviceModel']! as String).trim().isNotEmpty,
      '$key has no device model.',
    );
    require(
      evidence['platformVersion'] is String &&
          (evidence['platformVersion']! as String).trim().isNotEmpty,
      '$key has no platform version.',
    );
  }

  final identityKey = 'target_identity_$deviceLabel';
  final identity = mapAt(identityKey);
  if (identity != null) {
    verifyPhysicalTarget(identity, identityKey);
    require(
      identity['deviceLabel'] == deviceLabel,
      '$identityKey has the wrong deviceLabel.',
    );
  }

  if (checkFunctional) {
    final discoveryKey = 'native_discovery_$deviceLabel';
    final discovery = mapAt(discoveryKey);
    if (discovery != null) {
      verifyPhysicalTarget(discovery, discoveryKey);
      require(
        discovery['deviceLabel'] == deviceLabel,
        '$discoveryKey has the wrong deviceLabel.',
      );
      require(
        discovery['serviceType'] == '_trigrid._tcp',
        '$discoveryKey did not verify the TriGrid DNS-SD service.',
      );
      require(
        discovery['port'] is int && (discovery['port']! as int) > 0,
        '$discoveryKey has no usable service port.',
      );
    }

    final flowKey = 'functional_flow_$deviceLabel';
    final flow = mapAt(flowKey);
    if (flow != null) {
      verifyPhysicalTarget(flow, flowKey);
      require(
        flow['deviceLabel'] == deviceLabel,
        '$flowKey has the wrong deviceLabel.',
      );
      require(
        flow['revision'] is int && (flow['revision']! as int) >= 1,
        '$flowKey did not submit a confirmed move.',
      );
      require(
        flow['privateHandoffVisible'] == true,
        '$flowKey did not verify the private handoff.',
      );
    }

    final screenshots = <Map<String, dynamic>>[
      for (final raw
          in (report['screenshots'] as List<dynamic>? ?? const <dynamic>[]))
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];
    for (final suffix in const ['board', 'handoff']) {
      final expectedName = '${deviceLabel}_$suffix';
      Map<String, dynamic>? matching;
      for (final screenshot in screenshots) {
        if (screenshot['name'] == expectedName) {
          matching = screenshot;
          break;
        }
      }
      require(matching != null, 'Screenshot $expectedName is missing.');
      if (matching != null) {
        require(
          matching['acceptanceBuildId'] == expectedBuildId,
          'Screenshot $expectedName was captured for a different acceptance '
          'build.',
        );
      }
    }
  }

  if (checkPerformance) {
    for (final scenario in _profileExpectations.entries) {
      final key = 'profile_${scenario.key}_$deviceLabel';
      final profile = mapAt(key);
      if (profile == null) {
        continue;
      }
      verifyPhysicalTarget(profile, key);
      final buildP90 =
          profile['90th_percentile_frame_build_time_millis'] as num?;
      final rasterP90 =
          profile['90th_percentile_frame_rasterizer_time_millis'] as num?;
      final frameBudget = profile['frameBudgetMillis'] as num?;
      require(
        profile['deviceLabel'] == deviceLabel,
        '$key has the wrong deviceLabel.',
      );
      require(
        profile['scenarioId'] == scenario.key,
        '$key has the wrong scenarioId.',
      );
      require(
        profile['boardRadius'] == scenario.value.radius,
        '$key has the wrong board radius.',
      );
      require(
        profile['effectsEnabled'] == scenario.value.effects,
        '$key has the wrong effects mode.',
      );
      require(
        profile['profileMode'] == true,
        '$key was not captured in Flutter profile mode.',
      );
      require(
        profile['submittedMoves'] is int &&
            (profile['submittedMoves']! as int) >= 16,
        '$key did not submit enough moves.',
      );
      require(
        profile['frame_count'] is int && (profile['frame_count']! as int) > 120,
        '$key did not capture enough frames.',
      );
      require(
        frameBudget != null && frameBudget.toDouble() == 16.67,
        '$key does not use the 16.67 ms budget.',
      );
      require(
        buildP90 != null && buildP90.toDouble() <= 16.67,
        '$key exceeds the build p90 budget.',
      );
      require(
        rasterP90 != null && rasterP90.toDouble() <= 16.67,
        '$key exceeds the raster p90 budget.',
      );
      require(
        profile['passedFrameBudget'] == true,
        '$key is not marked as a passing frame-budget result.',
      );
    }
  }

  return failures;
}

Future<void> main(List<String> arguments) async {
  var reportPath = 'build/device-acceptance/device_acceptance.json';
  var checkFunctional = true;
  var checkPerformance = true;
  final deviceLabels = <String>[];

  for (final argument in arguments) {
    if (argument.startsWith('--device=')) {
      final label = argument.substring('--device='.length);
      if (label.isNotEmpty) {
        deviceLabels.add(label);
      }
    } else if (argument.startsWith('--report=')) {
      reportPath = argument.substring('--report='.length);
    } else if (argument == '--functional-only') {
      checkPerformance = false;
    } else if (argument == '--performance-only') {
      checkFunctional = false;
    } else if (argument == '--help' || argument == '-h') {
      _printUsage();
      return;
    } else {
      stderr.writeln('Unknown argument: $argument');
      _printUsage();
      exitCode = 64;
      return;
    }
  }

  if (deviceLabels.isEmpty || (!checkFunctional && !checkPerformance)) {
    stderr.writeln('At least one --device label and one check are required.');
    _printUsage();
    exitCode = 64;
    return;
  }

  final file = File(reportPath);
  if (!file.existsSync()) {
    stderr.writeln('Acceptance report not found: ${file.path}');
    exitCode = 66;
    return;
  }

  late final Map<String, dynamic> report;
  try {
    report = jsonDecode(file.readAsStringSync())! as Map<String, dynamic>;
  } on Object catch (error) {
    stderr.writeln('Acceptance report is not valid JSON: $error');
    exitCode = 65;
    return;
  }

  late final String expectedBuildId;
  try {
    expectedBuildId = await computeAcceptanceBuildId();
  } on Object catch (error) {
    stderr.writeln('Could not compute the current acceptance build ID: $error');
    exitCode = 70;
    return;
  }

  var failed = false;
  for (final deviceLabel in deviceLabels) {
    final failures = verifyDeviceAcceptanceReport(
      report,
      deviceLabel,
      checkFunctional: checkFunctional,
      checkPerformance: checkPerformance,
      expectedBuildId: expectedBuildId,
    );
    if (failures.isEmpty) {
      stdout.writeln('PASS $deviceLabel');
      continue;
    }
    failed = true;
    stderr.writeln('FAIL $deviceLabel');
    for (final failure in failures) {
      stderr.writeln('  - $failure');
    }
  }
  if (failed) {
    exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tool/verify_device_acceptance.dart '
    '--device=<label> [--device=<label> ...] '
    '[--report=<path>] [--functional-only|--performance-only]',
  );
}
