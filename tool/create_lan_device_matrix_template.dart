import 'dart:convert';
import 'dart:io';

import 'acceptance_build_id.dart';

typedef _LanTemplateScenario = ({
  String hostPlatform,
  String clientPlatform,
  String networkPath,
  List<String> joinMethods,
});

const _lanTemplateScenarios = <String, _LanTemplateScenario>{
  'android_host_android_client_same_wifi': (
    hostPlatform: 'android',
    clientPlatform: 'android',
    networkPath: 'same_wifi',
    joinMethods: <String>['bonjour'],
  ),
  'android_host_ios_client_same_wifi': (
    hostPlatform: 'android',
    clientPlatform: 'ios',
    networkPath: 'same_wifi',
    joinMethods: <String>['bonjour', 'qr'],
  ),
  'ios_host_android_client_same_wifi': (
    hostPlatform: 'ios',
    clientPlatform: 'android',
    networkPath: 'same_wifi',
    joinMethods: <String>['bonjour', 'manual_ip'],
  ),
  'ios_host_ios_client_same_wifi': (
    hostPlatform: 'ios',
    clientPlatform: 'ios',
    networkPath: 'same_wifi',
    joinMethods: <String>['bonjour'],
  ),
  'android_hotspot_android_client': (
    hostPlatform: 'android',
    clientPlatform: 'android',
    networkPath: 'android_hotspot',
    joinMethods: <String>['manual_ip'],
  ),
  'android_hotspot_ios_client': (
    hostPlatform: 'android',
    clientPlatform: 'ios',
    networkPath: 'android_hotspot',
    joinMethods: <String>['manual_ip'],
  ),
  'ios_hotspot_android_client': (
    hostPlatform: 'ios',
    clientPlatform: 'android',
    networkPath: 'ios_hotspot',
    joinMethods: <String>['manual_ip'],
  ),
  'ios_hotspot_ios_client': (
    hostPlatform: 'ios',
    clientPlatform: 'ios',
    networkPath: 'ios_hotspot',
    joinMethods: <String>['manual_ip'],
  ),
};

Map<String, dynamic> createLanDeviceMatrixTemplate(String acceptanceBuildId) {
  Map<String, dynamic> device(String platform) => <String, dynamic>{
    'platform': platform,
    'isPhysicalDevice': false,
    'deviceLabel': '',
    'deviceManufacturer': '',
    'deviceModel': '',
    'platformVersion': '',
  };

  return <String, dynamic>{
    for (final scenario in _lanTemplateScenarios.entries)
      'lan_matrix_${scenario.key}': <String, dynamic>{
        'acceptanceBuildId': acceptanceBuildId,
        'scenarioId': scenario.key,
        'recordedAtUtc': '',
        'networkPath': scenario.value.networkPath,
        'protocolVersion': 1,
        'hostDevice': device(scenario.value.hostPlatform),
        'clientDevice': device(scenario.value.clientPlatform),
        'automaticDiscoveryAttempted': false,
        'automaticDiscoverySucceeded': false,
        'joinMethods': scenario.value.joinMethods,
        'fullMatchCompleted': false,
        'finalRevision': 0,
        'hostFinalStateHash': '',
        'clientFinalStateHash': '',
        'disconnectPauseObserved': false,
        'backgroundForegroundReconnect': false,
        'snapshotResyncVerified': false,
        'offlineNetworkConfirmed': false,
        'connectionQualityObserved': false,
        'screenshotPaths': <String>['', ''],
      },
    'lan_matrix_client_isolation': <String, dynamic>{
      'acceptanceBuildId': acceptanceBuildId,
      'recordedAtUtc': '',
      'networkPath': 'client_isolation',
      'hostDevice': device(''),
      'clientDevice': device(''),
      'automaticDiscoveryBlocked': false,
      'directConnectionBlocked': false,
      'localizedErrorVisible': false,
      'appStable': false,
      'screenshotPaths': <String>['', ''],
    },
  };
}

Future<void> main(List<String> arguments) async {
  var outputPath = 'build/device-acceptance/lan_device_matrix.template.json';
  var force = false;

  for (final argument in arguments) {
    if (argument.startsWith('--output=')) {
      outputPath = argument.substring('--output='.length);
      if (outputPath.trim().isEmpty) {
        stderr.writeln('--output requires a non-empty path.');
        _printUsage();
        exitCode = 64;
        return;
      }
    } else if (argument == '--force') {
      force = true;
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

  final output = File(outputPath);
  if (output.existsSync() && !force) {
    stderr.writeln(
      'Refusing to overwrite existing LAN matrix template: ${output.path}',
    );
    stderr.writeln('Pass --force only if replacing it is intentional.');
    exitCode = 73;
    return;
  }

  late final String acceptanceBuildId;
  try {
    acceptanceBuildId = await computeAcceptanceBuildId();
  } on Object catch (error) {
    stderr.writeln('Could not compute the current acceptance build ID: $error');
    exitCode = 70;
    return;
  }

  output.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  output.writeAsStringSync(
    '${encoder.convert(createLanDeviceMatrixTemplate(acceptanceBuildId))}\n',
  );
  stdout.writeln('Wrote incomplete LAN matrix template: ${output.path}');
  stdout.writeln('Acceptance build ID: $acceptanceBuildId');
  stdout.writeln(
    'Fill it only from physical runs, merge the nine entries into the '
    'acceptance report, then run the strict verifier.',
  );
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart tool/create_lan_device_matrix_template.dart '
    '[--output=<path>] [--force]',
  );
}
