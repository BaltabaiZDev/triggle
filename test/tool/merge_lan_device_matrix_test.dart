import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_lan_device_matrix_template.dart';
import '../../tool/merge_lan_device_matrix.dart';
import '../../tool/verify_lan_device_matrix.dart';

void main() {
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('merges a complete matrix while preserving the original report', () {
    final target = <String, dynamic>{
      'existing_functional_evidence': <String, dynamic>{'preserve': true},
    };

    final merged = mergeLanDeviceMatrixEvidence(
      targetReport: target,
      sourceReport: _completeSource(buildId),
      expectedBuildId: buildId,
    );

    expect(target, hasLength(1));
    expect(merged['existing_functional_evidence'], <String, dynamic>{
      'preserve': true,
    });
    expect(merged, hasLength(10));
    expect(
      verifyLanDeviceMatrixReport(merged, expectedBuildId: buildId),
      isEmpty,
    );
  });

  test('rejects an incomplete or stale source matrix', () {
    expect(
      () => mergeLanDeviceMatrixEvidence(
        targetReport: <String, dynamic>{},
        sourceReport: createLanDeviceMatrixTemplate(buildId),
        expectedBuildId: buildId,
      ),
      throwsA(
        isA<LanMatrixMergeException>().having(
          (error) => error.failures,
          'failures',
          isNotEmpty,
        ),
      ),
    );

    final stale = _completeSource(buildId);
    final first = stale.values.first! as Map<String, dynamic>;
    first['acceptanceBuildId'] =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    expect(
      () => mergeLanDeviceMatrixEvidence(
        targetReport: <String, dynamic>{},
        sourceReport: stale,
        expectedBuildId: buildId,
      ),
      throwsA(
        isA<LanMatrixMergeException>().having(
          (error) => error.failures,
          'failures',
          contains(
            'lan_matrix_android_host_android_client_same_wifi was captured '
            'for a different acceptance build.',
          ),
        ),
      ),
    );
  });

  test('requires explicit authority to replace existing LAN entries', () {
    final source = _completeSource(buildId);
    final target = <String, dynamic>{
      'lan_matrix_android_host_android_client_same_wifi': <String, dynamic>{
        'old': true,
      },
    };

    expect(
      () => mergeLanDeviceMatrixEvidence(
        targetReport: target,
        sourceReport: source,
        expectedBuildId: buildId,
      ),
      throwsA(
        isA<LanMatrixMergeException>().having(
          (error) => error.failures.single,
          'collision',
          contains('Pass --replace-existing'),
        ),
      ),
    );

    final merged = mergeLanDeviceMatrixEvidence(
      targetReport: target,
      sourceReport: source,
      expectedBuildId: buildId,
      replaceExisting: true,
    );
    expect(
      merged['lan_matrix_android_host_android_client_same_wifi'],
      same(source['lan_matrix_android_host_android_client_same_wifi']),
    );
    expect(target.values.single, <String, dynamic>{'old': true});
  });
}

Map<String, dynamic> _completeSource(String buildId) {
  final report = createLanDeviceMatrixTemplate(buildId);
  final hash = List<String>.filled(64, 'a').join();

  for (final scenarioId in lanMatrixScenarioIds) {
    final key = 'lan_matrix_$scenarioId';
    final evidence = report[key]! as Map<String, dynamic>;
    final host = evidence['hostDevice']! as Map<String, dynamic>;
    final client = evidence['clientDevice']! as Map<String, dynamic>;
    _completeDevice(host, '${scenarioId}_host');
    _completeDevice(client, '${scenarioId}_client');
    evidence
      ..['recordedAtUtc'] = '2026-07-31T06:00:00.000Z'
      ..['automaticDiscoveryAttempted'] = true
      ..['automaticDiscoverySucceeded'] = evidence['networkPath'] == 'same_wifi'
      ..['fullMatchCompleted'] = true
      ..['finalRevision'] = 20
      ..['hostFinalStateHash'] = hash
      ..['clientFinalStateHash'] = hash
      ..['disconnectPauseObserved'] = true
      ..['backgroundForegroundReconnect'] = true
      ..['snapshotResyncVerified'] = true
      ..['offlineNetworkConfirmed'] = true
      ..['connectionQualityObserved'] = true
      ..['screenshotPaths'] = <String>[
        '${scenarioId}_host.png',
        '${scenarioId}_client.png',
      ];
  }

  final isolation =
      report['lan_matrix_client_isolation']! as Map<String, dynamic>;
  isolation
    ..['recordedAtUtc'] = '2026-07-31T06:00:00.000Z'
    ..['hostDevice'] = _physicalDevice('android', 'isolation_host')
    ..['clientDevice'] = _physicalDevice('ios', 'isolation_client')
    ..['automaticDiscoveryBlocked'] = true
    ..['directConnectionBlocked'] = true
    ..['localizedErrorVisible'] = true
    ..['appStable'] = true
    ..['screenshotPaths'] = <String>[
      'isolation_host.png',
      'isolation_client.png',
    ];
  return report;
}

void _completeDevice(Map<String, dynamic> device, String label) {
  device
    ..['isPhysicalDevice'] = true
    ..['deviceLabel'] = label
    ..['deviceManufacturer'] = 'Test manufacturer'
    ..['deviceModel'] = 'Test model'
    ..['platformVersion'] = 'Test OS';
}

Map<String, dynamic> _physicalDevice(String platform, String label) =>
    <String, dynamic>{
      'platform': platform,
      'isPhysicalDevice': true,
      'deviceLabel': label,
      'deviceManufacturer': 'Test manufacturer',
      'deviceModel': 'Test model',
      'platformVersion': 'Test OS',
    };
