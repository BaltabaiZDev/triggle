import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/core/network/protocol/lan_envelope.dart';

import '../../tool/verify_lan_device_matrix.dart';

void main() {
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const scenarioSettings =
      <String, ({String host, String client, String network})>{
        'android_host_android_client_same_wifi': (
          host: 'android',
          client: 'android',
          network: 'same_wifi',
        ),
        'android_host_ios_client_same_wifi': (
          host: 'android',
          client: 'ios',
          network: 'same_wifi',
        ),
        'ios_host_android_client_same_wifi': (
          host: 'ios',
          client: 'android',
          network: 'same_wifi',
        ),
        'ios_host_ios_client_same_wifi': (
          host: 'ios',
          client: 'ios',
          network: 'same_wifi',
        ),
        'android_hotspot_android_client': (
          host: 'android',
          client: 'android',
          network: 'android_hotspot',
        ),
        'android_hotspot_ios_client': (
          host: 'android',
          client: 'ios',
          network: 'android_hotspot',
        ),
        'ios_hotspot_android_client': (
          host: 'ios',
          client: 'android',
          network: 'ios_hotspot',
        ),
        'ios_hotspot_ios_client': (
          host: 'ios',
          client: 'ios',
          network: 'ios_hotspot',
        ),
      };

  Map<String, dynamic> device(String platform, String label) =>
      <String, dynamic>{
        'platform': platform,
        'isPhysicalDevice': true,
        'deviceLabel': label,
        'deviceManufacturer': platform == 'ios' ? 'Apple' : 'Android maker',
        'deviceModel': platform == 'ios' ? 'iPhone Test' : 'Android Test',
        'platformVersion': platform == 'ios' ? 'iOS 19' : 'Android 15',
      };

  List<String> joinMethods(String scenarioId, String network) {
    if (scenarioId == 'android_host_ios_client_same_wifi') {
      return <String>['bonjour', 'qr'];
    }
    if (scenarioId == 'ios_host_android_client_same_wifi') {
      return <String>['bonjour', 'manual_ip'];
    }
    if (network == 'same_wifi') {
      return <String>['bonjour'];
    }
    return <String>['manual_ip'];
  }

  Map<String, dynamic> completeReport() {
    final hash = List<String>.filled(64, 'a').join();
    return <String, dynamic>{
      for (final scenario in scenarioSettings.entries)
        'lan_matrix_${scenario.key}': <String, dynamic>{
          'scenarioId': scenario.key,
          'acceptanceBuildId': buildId,
          'recordedAtUtc': '2026-07-31T06:00:00.000Z',
          'networkPath': scenario.value.network,
          'protocolVersion': LanEnvelope.currentProtocolVersion,
          'hostDevice': device(scenario.value.host, '${scenario.key}_host'),
          'clientDevice': device(
            scenario.value.client,
            '${scenario.key}_client',
          ),
          'automaticDiscoveryAttempted': true,
          'automaticDiscoverySucceeded': scenario.value.network == 'same_wifi',
          'joinMethods': joinMethods(scenario.key, scenario.value.network),
          'fullMatchCompleted': true,
          'finalRevision': 20,
          'hostFinalStateHash': hash,
          'clientFinalStateHash': hash,
          'disconnectPauseObserved': true,
          'backgroundForegroundReconnect': true,
          'snapshotResyncVerified': true,
          'offlineNetworkConfirmed': true,
          'connectionQualityObserved': true,
          'screenshotPaths': <String>[
            '${scenario.key}_host.png',
            '${scenario.key}_client.png',
          ],
        },
      'lan_matrix_client_isolation': <String, dynamic>{
        'acceptanceBuildId': buildId,
        'recordedAtUtc': '2026-07-31T06:00:00.000Z',
        'networkPath': 'client_isolation',
        'hostDevice': device('android', 'isolation_host'),
        'clientDevice': device('ios', 'isolation_client'),
        'automaticDiscoveryBlocked': true,
        'directConnectionBlocked': true,
        'localizedErrorVisible': true,
        'appStable': true,
        'screenshotPaths': <String>[
          'isolation_host.png',
          'isolation_client.png',
        ],
      },
    };
  }

  test('accepts the complete physical LAN release matrix', () {
    expect(
      verifyLanDeviceMatrixReport(completeReport(), expectedBuildId: buildId),
      isEmpty,
    );
  });

  test('rejects missing, virtual-device, and hash-mismatch evidence', () {
    final report = completeReport();
    report.remove('lan_matrix_ios_hotspot_ios_client');
    final sameWifi =
        report['lan_matrix_android_host_ios_client_same_wifi']!
            as Map<String, dynamic>;
    final host = sameWifi['hostDevice']! as Map<String, dynamic>;
    host['isPhysicalDevice'] = false;
    sameWifi['clientFinalStateHash'] = List<String>.filled(64, 'b').join();

    final failures = verifyLanDeviceMatrixReport(
      report,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'lan_matrix_ios_hotspot_ios_client is missing or is not an object.',
      ),
    );
    expect(
      failures,
      contains(
        'lan_matrix_android_host_ios_client_same_wifi.hostDevice was not '
        'captured on a physical device.',
      ),
    );
    expect(
      failures,
      contains(
        'lan_matrix_android_host_ios_client_same_wifi host and client final '
        'state hashes differ.',
      ),
    );
  });

  test('rejects incomplete client-isolation behavior and screenshots', () {
    final report = completeReport();
    final isolation =
        report['lan_matrix_client_isolation']! as Map<String, dynamic>;
    isolation['localizedErrorVisible'] = false;
    isolation['screenshotPaths'] = <String>['only-one.png'];

    final failures = verifyLanDeviceMatrixReport(
      report,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'lan_matrix_client_isolation did not verify a localized '
        'client-isolation error.',
      ),
    );
    expect(
      failures,
      contains(
        'lan_matrix_client_isolation requires host and client screenshot '
        'paths.',
      ),
    );
  });

  test('rejects LAN evidence captured for another acceptance build', () {
    final report = completeReport();
    final scenario =
        report['lan_matrix_android_host_android_client_same_wifi']!
            as Map<String, dynamic>;
    scenario['acceptanceBuildId'] =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

    final failures = verifyLanDeviceMatrixReport(
      report,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'lan_matrix_android_host_android_client_same_wifi was captured for '
        'a different acceptance build.',
      ),
    );
  });
}
