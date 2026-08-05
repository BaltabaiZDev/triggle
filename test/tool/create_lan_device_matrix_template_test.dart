import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_lan_device_matrix_template.dart';
import '../../tool/verify_lan_device_matrix.dart';

void main() {
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const expectedScenarios =
      <
        String,
        ({String host, String client, String network, List<String> joins})
      >{
        'android_host_android_client_same_wifi': (
          host: 'android',
          client: 'android',
          network: 'same_wifi',
          joins: <String>['bonjour'],
        ),
        'android_host_ios_client_same_wifi': (
          host: 'android',
          client: 'ios',
          network: 'same_wifi',
          joins: <String>['bonjour', 'qr'],
        ),
        'ios_host_android_client_same_wifi': (
          host: 'ios',
          client: 'android',
          network: 'same_wifi',
          joins: <String>['bonjour', 'manual_ip'],
        ),
        'ios_host_ios_client_same_wifi': (
          host: 'ios',
          client: 'ios',
          network: 'same_wifi',
          joins: <String>['bonjour'],
        ),
        'android_hotspot_android_client': (
          host: 'android',
          client: 'android',
          network: 'android_hotspot',
          joins: <String>['manual_ip'],
        ),
        'android_hotspot_ios_client': (
          host: 'android',
          client: 'ios',
          network: 'android_hotspot',
          joins: <String>['manual_ip'],
        ),
        'ios_hotspot_android_client': (
          host: 'ios',
          client: 'android',
          network: 'ios_hotspot',
          joins: <String>['manual_ip'],
        ),
        'ios_hotspot_ios_client': (
          host: 'ios',
          client: 'ios',
          network: 'ios_hotspot',
          joins: <String>['manual_ip'],
        ),
      };

  test('creates every current-build LAN matrix entry with expected routes', () {
    final report = createLanDeviceMatrixTemplate(buildId);

    expect(report, hasLength(9));
    for (final scenario in expectedScenarios.entries) {
      final key = 'lan_matrix_${scenario.key}';
      final evidence = report[key]! as Map<String, dynamic>;
      final host = evidence['hostDevice']! as Map<String, dynamic>;
      final client = evidence['clientDevice']! as Map<String, dynamic>;

      expect(evidence['acceptanceBuildId'], buildId);
      expect(evidence['scenarioId'], scenario.key);
      expect(evidence['networkPath'], scenario.value.network);
      expect(evidence['joinMethods'], scenario.value.joins);
      expect(host['platform'], scenario.value.host);
      expect(client['platform'], scenario.value.client);
      expect(host['isPhysicalDevice'], isFalse);
      expect(client['isPhysicalDevice'], isFalse);
    }

    final isolation =
        report['lan_matrix_client_isolation']! as Map<String, dynamic>;
    expect(isolation['acceptanceBuildId'], buildId);
    expect(isolation['networkPath'], 'client_isolation');
  });

  test('generated placeholders cannot pass the strict physical gate', () {
    final failures = verifyLanDeviceMatrixReport(
      createLanDeviceMatrixTemplate(buildId),
      expectedBuildId: buildId,
    );

    expect(failures, isNotEmpty);
    expect(
      failures,
      contains(
        'lan_matrix_android_host_android_client_same_wifi.hostDevice was not '
        'captured on a physical device.',
      ),
    );
    expect(
      failures,
      contains(
        'lan_matrix_client_isolation did not verify stable app behavior.',
      ),
    );
  });
}
