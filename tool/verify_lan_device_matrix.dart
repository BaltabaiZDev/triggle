import 'dart:convert';
import 'dart:io';

import 'package:trigrid/core/network/protocol/lan_envelope.dart';

import 'acceptance_build_id.dart';

typedef _LanScenarioExpectation = ({
  String hostPlatform,
  String clientPlatform,
  String networkPath,
  Set<String> requiredJoinMethods,
  bool requireAutomaticDiscovery,
  bool requireFallbackJoin,
});

const lanMatrixScenarioIds = <String>[
  'android_host_android_client_same_wifi',
  'android_host_ios_client_same_wifi',
  'ios_host_android_client_same_wifi',
  'ios_host_ios_client_same_wifi',
  'android_hotspot_android_client',
  'android_hotspot_ios_client',
  'ios_hotspot_android_client',
  'ios_hotspot_ios_client',
];

const _scenarioExpectations = <String, _LanScenarioExpectation>{
  'android_host_android_client_same_wifi': (
    hostPlatform: 'android',
    clientPlatform: 'android',
    networkPath: 'same_wifi',
    requiredJoinMethods: <String>{},
    requireAutomaticDiscovery: true,
    requireFallbackJoin: false,
  ),
  'android_host_ios_client_same_wifi': (
    hostPlatform: 'android',
    clientPlatform: 'ios',
    networkPath: 'same_wifi',
    requiredJoinMethods: <String>{'qr'},
    requireAutomaticDiscovery: true,
    requireFallbackJoin: false,
  ),
  'ios_host_android_client_same_wifi': (
    hostPlatform: 'ios',
    clientPlatform: 'android',
    networkPath: 'same_wifi',
    requiredJoinMethods: <String>{'manual_ip'},
    requireAutomaticDiscovery: true,
    requireFallbackJoin: false,
  ),
  'ios_host_ios_client_same_wifi': (
    hostPlatform: 'ios',
    clientPlatform: 'ios',
    networkPath: 'same_wifi',
    requiredJoinMethods: <String>{'bonjour'},
    requireAutomaticDiscovery: true,
    requireFallbackJoin: false,
  ),
  'android_hotspot_android_client': (
    hostPlatform: 'android',
    clientPlatform: 'android',
    networkPath: 'android_hotspot',
    requiredJoinMethods: <String>{},
    requireAutomaticDiscovery: false,
    requireFallbackJoin: true,
  ),
  'android_hotspot_ios_client': (
    hostPlatform: 'android',
    clientPlatform: 'ios',
    networkPath: 'android_hotspot',
    requiredJoinMethods: <String>{},
    requireAutomaticDiscovery: false,
    requireFallbackJoin: true,
  ),
  'ios_hotspot_android_client': (
    hostPlatform: 'ios',
    clientPlatform: 'android',
    networkPath: 'ios_hotspot',
    requiredJoinMethods: <String>{},
    requireAutomaticDiscovery: false,
    requireFallbackJoin: true,
  ),
  'ios_hotspot_ios_client': (
    hostPlatform: 'ios',
    clientPlatform: 'ios',
    networkPath: 'ios_hotspot',
    requiredJoinMethods: <String>{},
    requireAutomaticDiscovery: false,
    requireFallbackJoin: true,
  ),
};

List<String> verifyLanDeviceMatrixReport(
  Map<String, dynamic> report, {
  required String expectedBuildId,
}) {
  final failures = <String>[];
  final hashPattern = RegExp(r'^[0-9a-fA-F]{64}$');

  void require(bool condition, String message) {
    if (!condition) {
      failures.add(message);
    }
  }

  Map<String, dynamic>? mapAt(
    Map<String, dynamic> container,
    String key,
    String path,
  ) {
    final value = container[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    failures.add('$path is missing or is not an object.');
    return null;
  }

  bool hasText(Object? value) => value is String && value.trim().isNotEmpty;

  void verifyRecordedAtUtc(Map<String, dynamic> evidence, String path) {
    final raw = evidence['recordedAtUtc'];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    require(
      parsed != null && parsed.isUtc,
      '$path has no valid UTC recordedAtUtc timestamp.',
    );
  }

  void verifyPhysicalDevice(
    Map<String, dynamic> evidence,
    String path,
    String expectedPlatform,
  ) {
    require(
      evidence['platform'] == expectedPlatform,
      '$path has the wrong platform.',
    );
    require(
      evidence['isPhysicalDevice'] == true,
      '$path was not captured on a physical device.',
    );
    for (final field in const [
      'deviceLabel',
      'deviceManufacturer',
      'deviceModel',
      'platformVersion',
    ]) {
      require(hasText(evidence[field]), '$path has no $field.');
    }
  }

  Set<String> joinMethodsAt(Map<String, dynamic> evidence, String path) {
    final raw = evidence['joinMethods'];
    if (raw is! List || raw.any((value) => !hasText(value))) {
      failures.add('$path has no valid joinMethods list.');
      return const <String>{};
    }
    return raw.cast<String>().toSet();
  }

  void verifyScreenshots(Map<String, dynamic> evidence, String path) {
    final raw = evidence['screenshotPaths'];
    require(
      raw is List && raw.length >= 2 && raw.every((value) => hasText(value)),
      '$path requires host and client screenshot paths.',
    );
  }

  for (final entry in _scenarioExpectations.entries) {
    final scenarioId = entry.key;
    final expectation = entry.value;
    final key = 'lan_matrix_$scenarioId';
    final evidence = mapAt(report, key, key);
    if (evidence == null) {
      continue;
    }
    require(
      evidence['acceptanceBuildId'] == expectedBuildId,
      '$key was captured for a different acceptance build.',
    );
    verifyRecordedAtUtc(evidence, key);
    require(
      evidence['scenarioId'] == scenarioId,
      '$key has the wrong scenarioId.',
    );
    require(
      evidence['networkPath'] == expectation.networkPath,
      '$key has the wrong networkPath.',
    );
    require(
      evidence['protocolVersion'] == LanEnvelope.currentProtocolVersion,
      '$key did not use protocol version ${LanEnvelope.currentProtocolVersion}.',
    );

    final host = mapAt(evidence, 'hostDevice', '$key.hostDevice');
    final client = mapAt(evidence, 'clientDevice', '$key.clientDevice');
    if (host != null) {
      verifyPhysicalDevice(host, '$key.hostDevice', expectation.hostPlatform);
    }
    if (client != null) {
      verifyPhysicalDevice(
        client,
        '$key.clientDevice',
        expectation.clientPlatform,
      );
    }
    if (host != null && client != null) {
      require(
        host['deviceLabel'] != client['deviceLabel'],
        '$key must use two distinct physical devices.',
      );
    }

    final joinMethods = joinMethodsAt(evidence, key);
    require(
      evidence['automaticDiscoveryAttempted'] == true,
      '$key did not attempt automatic discovery.',
    );
    if (expectation.requireAutomaticDiscovery) {
      require(
        evidence['automaticDiscoverySucceeded'] == true &&
            joinMethods.intersection(const {'bonjour', 'udp'}).isNotEmpty,
        '$key did not prove automatic LAN discovery.',
      );
    }
    if (expectation.requireFallbackJoin) {
      require(
        joinMethods.intersection(const {'manual_ip', 'qr'}).isNotEmpty,
        '$key did not prove a hotspot fallback join.',
      );
    }
    for (final method in expectation.requiredJoinMethods) {
      require(
        joinMethods.contains(method),
        '$key did not verify the required $method join path.',
      );
    }

    require(
      evidence['fullMatchCompleted'] == true,
      '$key did not complete a full match.',
    );
    require(
      evidence['finalRevision'] is int &&
          (evidence['finalRevision']! as int) > 0,
      '$key has no terminal state revision.',
    );
    final hostHash = evidence['hostFinalStateHash'];
    final clientHash = evidence['clientFinalStateHash'];
    require(
      hostHash is String && hashPattern.hasMatch(hostHash),
      '$key has no valid host final state hash.',
    );
    require(
      clientHash is String && hashPattern.hasMatch(clientHash),
      '$key has no valid client final state hash.',
    );
    require(
      hostHash is String && clientHash == hostHash,
      '$key host and client final state hashes differ.',
    );
    for (final check in const {
      'disconnectPauseObserved': 'disconnect pause',
      'backgroundForegroundReconnect': 'background/foreground reconnect',
      'snapshotResyncVerified': 'snapshot resynchronization',
      'offlineNetworkConfirmed': 'offline LAN operation',
      'connectionQualityObserved': 'connection quality reporting',
    }.entries) {
      require(
        evidence[check.key] == true,
        '$key did not verify ${check.value}.',
      );
    }
    verifyScreenshots(evidence, key);
  }

  const isolationKey = 'lan_matrix_client_isolation';
  final isolation = mapAt(report, isolationKey, isolationKey);
  if (isolation != null) {
    require(
      isolation['acceptanceBuildId'] == expectedBuildId,
      '$isolationKey was captured for a different acceptance build.',
    );
    verifyRecordedAtUtc(isolation, isolationKey);
    require(
      isolation['networkPath'] == 'client_isolation',
      '$isolationKey has the wrong networkPath.',
    );
    final host = mapAt(isolation, 'hostDevice', '$isolationKey.hostDevice');
    final client = mapAt(
      isolation,
      'clientDevice',
      '$isolationKey.clientDevice',
    );
    if (host != null) {
      final platform = host['platform'];
      verifyPhysicalDevice(
        host,
        '$isolationKey.hostDevice',
        platform is String ? platform : '',
      );
      require(
        platform == 'android' || platform == 'ios',
        '$isolationKey.hostDevice has an unsupported platform.',
      );
    }
    if (client != null) {
      final platform = client['platform'];
      verifyPhysicalDevice(
        client,
        '$isolationKey.clientDevice',
        platform is String ? platform : '',
      );
      require(
        platform == 'android' || platform == 'ios',
        '$isolationKey.clientDevice has an unsupported platform.',
      );
    }
    if (host != null && client != null) {
      require(
        host['deviceLabel'] != client['deviceLabel'],
        '$isolationKey must use two distinct physical devices.',
      );
    }
    for (final check in const {
      'automaticDiscoveryBlocked': 'blocked automatic discovery',
      'directConnectionBlocked': 'blocked direct connection',
      'localizedErrorVisible': 'a localized client-isolation error',
      'appStable': 'stable app behavior',
    }.entries) {
      require(
        isolation[check.key] == true,
        '$isolationKey did not verify ${check.value}.',
      );
    }
    verifyScreenshots(isolation, isolationKey);
  }

  return failures;
}

Future<void> main(List<String> arguments) async {
  var reportPath = 'build/device-acceptance/device_acceptance.json';
  for (final argument in arguments) {
    if (argument.startsWith('--report=')) {
      reportPath = argument.substring('--report='.length);
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

  final failures = verifyLanDeviceMatrixReport(
    report,
    expectedBuildId: expectedBuildId,
  );
  if (failures.isEmpty) {
    stdout.writeln('PASS LAN_DEVICE_MATRIX');
    return;
  }
  stderr.writeln('FAIL LAN_DEVICE_MATRIX');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
  exitCode = 1;
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tool/verify_lan_device_matrix.dart '
    '[--report=<path>]',
  );
}
