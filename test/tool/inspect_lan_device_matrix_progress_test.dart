import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_lan_device_matrix_template.dart';
import '../../tool/inspect_lan_device_matrix_progress.dart';

void main() {
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('reports every untouched template scenario as incomplete', () {
    final progress = inspectLanDeviceMatrixProgress(
      createLanDeviceMatrixTemplate(buildId),
      expectedBuildId: buildId,
    );

    expect(progress.keys, orderedEquals(lanMatrixEvidenceKeys));
    expect(progress, hasLength(9));
    expect(progress.values.every((failures) => failures.isNotEmpty), isTrue);
  });

  test('recognizes an independently completed physical scenario', () {
    final report = createLanDeviceMatrixTemplate(buildId);
    final key = lanMatrixEvidenceKeys.first;
    final evidence = report[key]! as Map<String, dynamic>;
    evidence
      ..['recordedAtUtc'] = '2026-07-31T06:00:00.000Z'
      ..['hostDevice'] = _device('android', 'physical_android_host')
      ..['clientDevice'] = _device('android', 'physical_android_client')
      ..['automaticDiscoveryAttempted'] = true
      ..['automaticDiscoverySucceeded'] = true
      ..['fullMatchCompleted'] = true
      ..['finalRevision'] = 20
      ..['hostFinalStateHash'] = List<String>.filled(64, 'a').join()
      ..['clientFinalStateHash'] = List<String>.filled(64, 'a').join()
      ..['disconnectPauseObserved'] = true
      ..['backgroundForegroundReconnect'] = true
      ..['snapshotResyncVerified'] = true
      ..['offlineNetworkConfirmed'] = true
      ..['connectionQualityObserved'] = true
      ..['screenshotPaths'] = <String>['host.png', 'client.png'];

    final progress = inspectLanDeviceMatrixProgress(
      report,
      expectedBuildId: buildId,
    );

    expect(progress[key], isEmpty);
    expect(
      progress.entries
          .where((entry) => entry.key != key)
          .every((entry) => entry.value.isNotEmpty),
      isTrue,
    );
  });
}

Map<String, dynamic> _device(String platform, String label) =>
    <String, dynamic>{
      'platform': platform,
      'isPhysicalDevice': true,
      'deviceLabel': label,
      'deviceManufacturer': 'Test manufacturer',
      'deviceModel': 'Test model',
      'platformVersion': 'Test OS',
    };
