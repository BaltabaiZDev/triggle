import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'acceptance_build_id.dart';
import 'create_lan_device_matrix_template.dart';
import 'inspect_lan_device_matrix_progress.dart';

const _kitSchemaVersion = 1;
const _apkKitPath = 'trigrid-android-debug.apk';
const _lanTemplateKitPath = 'lan_device_matrix.template.json';
const _runbookKitPath = 'RUNBOOK.md';
const _manifestKitPath = 'manifest.json';

Future<Directory> createPhysicalAcceptanceKit({
  required Directory outputDirectory,
  required File androidApk,
  required String acceptanceBuildId,
  required DateTime generatedAtUtc,
}) async {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(acceptanceBuildId)) {
    throw ArgumentError.value(
      acceptanceBuildId,
      'acceptanceBuildId',
      'Expected a lowercase SHA-256 hash.',
    );
  }
  if (!generatedAtUtc.isUtc) {
    throw ArgumentError.value(
      generatedAtUtc,
      'generatedAtUtc',
      'Expected a UTC timestamp.',
    );
  }
  if (!androidApk.existsSync()) {
    throw FileSystemException('Android APK does not exist', androidApk.path);
  }
  if (outputDirectory.existsSync()) {
    throw StateError(
      'Refusing to overwrite existing acceptance kit: '
      '${outputDirectory.path}',
    );
  }

  outputDirectory.createSync(recursive: true);
  final copiedApk = await androidApk.copy(
    _inside(outputDirectory, _apkKitPath).path,
  );
  final lanTemplate = _inside(outputDirectory, _lanTemplateKitPath);
  const encoder = JsonEncoder.withIndent('  ');
  lanTemplate.writeAsStringSync(
    '${encoder.convert(createLanDeviceMatrixTemplate(acceptanceBuildId))}\n',
  );
  final runbook = _inside(outputDirectory, _runbookKitPath);
  runbook.writeAsStringSync(
    _createRunbook(
      acceptanceBuildId: acceptanceBuildId,
      generatedAtUtc: generatedAtUtc,
    ),
  );

  final bundledFiles = <File>[copiedApk, lanTemplate, runbook];
  final fileRecords = <Map<String, dynamic>>[];
  for (final file in bundledFiles) {
    fileRecords.add(<String, dynamic>{
      'path': _relativeTo(outputDirectory, file),
      'sizeBytes': file.lengthSync(),
      'sha256': await _sha256File(file),
    });
  }

  final manifest = <String, dynamic>{
    'schemaVersion': _kitSchemaVersion,
    'product': 'TriGrid',
    'acceptanceBuildId': acceptanceBuildId,
    'generatedAtUtc': generatedAtUtc.toIso8601String(),
    'sourceProjectRequiredForHarness': true,
    'files': fileRecords,
    'lanMatrixScenarioKeys': lanMatrixEvidenceKeys,
    'requiredExternalGates': <String, dynamic>{
      'iosDebugBuildOnMacOsWithXcode': true,
      'physicalFunctionalPlatforms': <String>['android', 'ios'],
      'physicalPerformancePlatforms': <String>['android', 'ios'],
      'performanceCasesPerDevice': 6,
      'lanScenarios': lanMatrixEvidenceKeys.length,
      'requiresSameWifi': true,
      'requiresAndroidHotspot': true,
      'requiresIosHotspot': true,
      'requiresClientIsolationNetwork': true,
    },
    'verificationCommands': <String>[
      'dart tool/acceptance_build_id.dart',
      'dart tool/create_physical_acceptance_kit.dart '
          '--verify=<kit-directory>',
      'dart run tool/verify_device_acceptance.dart '
          '--device=<device-label>',
      'dart tool/inspect_lan_device_matrix_progress.dart '
          '--report=<lan-report-path> --verbose',
      'dart run tool/verify_lan_device_matrix.dart '
          '--report=<lan-report-path>',
    ],
  };
  _inside(
    outputDirectory,
    _manifestKitPath,
  ).writeAsStringSync('${encoder.convert(manifest)}\n');
  return outputDirectory;
}

Future<List<String>> verifyPhysicalAcceptanceKit(
  Directory kitDirectory, {
  required String expectedBuildId,
}) async {
  final failures = <String>[];
  final manifestFile = _inside(kitDirectory, _manifestKitPath);
  if (!manifestFile.existsSync()) {
    return <String>['Missing $_manifestKitPath.'];
  }

  late final Map<String, dynamic> manifest;
  try {
    manifest =
        jsonDecode(manifestFile.readAsStringSync())! as Map<String, dynamic>;
  } on Object catch (error) {
    return <String>['Invalid $_manifestKitPath: $error'];
  }

  if (manifest['schemaVersion'] != _kitSchemaVersion) {
    failures.add('Unsupported acceptance kit schema version.');
  }
  final manifestBuildId = manifest['acceptanceBuildId'];
  if (manifestBuildId != expectedBuildId) {
    failures.add(
      'Kit acceptance build ID differs from the current source state.',
    );
  }
  final scenarioKeys = manifest['lanMatrixScenarioKeys'];
  if (scenarioKeys is! List ||
      !const ListEquality<String>().equals(
        scenarioKeys.whereType<String>().toList(),
        lanMatrixEvidenceKeys,
      )) {
    failures.add('Kit LAN matrix scenario list is incomplete or reordered.');
  }

  final rawFiles = manifest['files'];
  if (rawFiles is! List || rawFiles.length != 3) {
    failures.add('Kit manifest must describe exactly three bundled files.');
    return failures;
  }
  final seenPaths = <String>{};
  for (final rawRecord in rawFiles) {
    if (rawRecord is! Map) {
      failures.add('Kit manifest contains an invalid file record.');
      continue;
    }
    final record = Map<String, dynamic>.from(rawRecord);
    final path = record['path'];
    if (path is! String || !_isSafeRelativePath(path)) {
      failures.add('Kit manifest contains an unsafe file path.');
      continue;
    }
    if (!seenPaths.add(path)) {
      failures.add('Kit manifest contains duplicate file path $path.');
      continue;
    }
    final file = _inside(kitDirectory, path);
    if (!file.existsSync()) {
      failures.add('Missing bundled file $path.');
      continue;
    }
    if (record['sizeBytes'] != file.lengthSync()) {
      failures.add('Bundled file $path has the wrong byte length.');
    }
    if (record['sha256'] != await _sha256File(file)) {
      failures.add('Bundled file $path failed its SHA-256 check.');
    }
  }

  for (final requiredPath in const {
    _apkKitPath,
    _lanTemplateKitPath,
    _runbookKitPath,
  }) {
    if (!seenPaths.contains(requiredPath)) {
      failures.add('Kit manifest does not include $requiredPath.');
    }
  }

  return failures;
}

Future<void> main(List<String> arguments) async {
  String? outputPath;
  String? verifyPath;
  var apkPath = 'build/app/outputs/flutter-apk/app-debug.apk';

  for (final argument in arguments) {
    if (argument.startsWith('--output=')) {
      outputPath = argument.substring('--output='.length);
    } else if (argument.startsWith('--apk=')) {
      apkPath = argument.substring('--apk='.length);
    } else if (argument.startsWith('--verify=')) {
      verifyPath = argument.substring('--verify='.length);
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
  if (<String?>[
    outputPath,
    apkPath,
    verifyPath,
  ].where((value) => value != null && value.trim().isEmpty).isNotEmpty) {
    stderr.writeln('Path arguments must not be empty.');
    exitCode = 64;
    return;
  }
  if (verifyPath != null && outputPath != null) {
    stderr.writeln('--verify and --output cannot be used together.');
    exitCode = 64;
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

  if (verifyPath != null) {
    final failures = await verifyPhysicalAcceptanceKit(
      Directory(verifyPath),
      expectedBuildId: acceptanceBuildId,
    );
    if (failures.isEmpty) {
      stdout.writeln('PASS PHYSICAL_ACCEPTANCE_KIT');
      stdout.writeln('Acceptance build ID: $acceptanceBuildId');
      return;
    }
    stderr.writeln('FAIL PHYSICAL_ACCEPTANCE_KIT');
    for (final failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }

  final apk = File(apkPath);
  if (!apk.existsSync()) {
    stderr.writeln('Android debug APK not found: ${apk.path}');
    stderr.writeln('Run flutter build apk --debug first.');
    exitCode = 66;
    return;
  }
  final output = Directory(
    outputPath ?? 'build/physical-acceptance-kit/$acceptanceBuildId',
  );
  if (output.existsSync()) {
    stderr.writeln(
      'Refusing to overwrite existing acceptance kit: ${output.path}',
    );
    stderr.writeln('Choose a new --output path if regeneration is intended.');
    exitCode = 73;
    return;
  }

  try {
    await createPhysicalAcceptanceKit(
      outputDirectory: output,
      androidApk: apk,
      acceptanceBuildId: acceptanceBuildId,
      generatedAtUtc: DateTime.now().toUtc(),
    );
  } on Object catch (error) {
    stderr.writeln('Could not create physical acceptance kit: $error');
    exitCode = 74;
    return;
  }
  stdout.writeln('Wrote physical acceptance kit: ${output.path}');
  stdout.writeln('Acceptance build ID: $acceptanceBuildId');
  stdout.writeln(
    'Verify before handoff with: dart '
    'tool/create_physical_acceptance_kit.dart --verify=${output.path}',
  );
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart tool/create_physical_acceptance_kit.dart '
    '[--apk=<path>] [--output=<directory>]',
  );
  stdout.writeln(
    '   or: dart tool/create_physical_acceptance_kit.dart '
    '--verify=<kit-directory>',
  );
}

File _inside(Directory directory, String relativePath) => File(
  '${directory.path}${Platform.pathSeparator}'
  '${relativePath.replaceAll('/', Platform.pathSeparator)}',
);

String _relativeTo(Directory directory, File file) {
  final prefix = '${directory.absolute.path.replaceAll(r'\', '/')}/';
  final path = file.absolute.path.replaceAll(r'\', '/');
  if (!path.startsWith(prefix)) {
    throw ArgumentError.value(file.path, 'file', 'File is outside the kit.');
  }
  return path.substring(prefix.length);
}

bool _isSafeRelativePath(String path) {
  final normalized = path.replaceAll(r'\', '/');
  return normalized.isNotEmpty &&
      !normalized.startsWith('/') &&
      !RegExp(r'^[A-Za-z]:').hasMatch(normalized) &&
      !normalized.split('/').contains('..');
}

Future<String> _sha256File(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

String _createRunbook({
  required String acceptanceBuildId,
  required DateTime generatedAtUtc,
}) =>
    '''
# TriGrid physical acceptance runbook

Acceptance build ID: `$acceptanceBuildId`  
Kit generated: `${generatedAtUtc.toIso8601String()}`

This kit is a handoff aid, not passing evidence. The included Android debug APK
supports install/smoke testing. Physical frame evidence must come from the
profile-mode Flutter harness in the matching source tree. iOS must be compiled
from that same source tree on macOS.

## 1. Verify source and kit

From the TriGrid project root:

```sh
dart tool/acceptance_build_id.dart
dart tool/create_physical_acceptance_kit.dart --verify=<kit-directory>
```

The first command must print `$acceptanceBuildId`. Stop if it differs.

## 2. Android install smoke test

```sh
adb -s <android-device-id> install -r trigrid-android-debug.apk
```

Confirm cold launch, permissions, menu navigation, local play, pass-and-play
handoff, and the full-surface result modal. This install does not replace the
profile harness below.

## 3. iOS build on macOS

```sh
cd ios
pod install
cd ..
flutter build ios --debug --no-codesign
```

For physical deployment, configure the final bundle identifier, development
team, and signing profile, then build/run on the named iOS device in Xcode.

## 4. Functional and performance evidence

Set a filesystem-safe, unique label for each physical device. Run both commands
from the matching source tree for every accepted Android and iOS device:

```sh
flutter drive --driver=test_driver/integration_test.dart \\
  --target=integration_test/device_acceptance_test.dart \\
  -d <device-id> --profile --no-dds \\
  --dart-define=TRIGRID_DEVICE_TEST_SCOPE=functional \\
  --dart-define=TRIGRID_DEVICE_LABEL=<device-label> \\
  --dart-define=TRIGRID_ACCEPTANCE_BUILD_ID=$acceptanceBuildId

flutter drive --driver=test_driver/integration_test.dart \\
  --target=integration_test/device_acceptance_test.dart \\
  -d <device-id> --profile --no-dds \\
  --dart-define=TRIGRID_DEVICE_TEST_SCOPE=performance \\
  --dart-define=TRIGRID_PROFILE_CASE=all \\
  --dart-define=TRIGRID_DEVICE_LABEL=<device-label> \\
  --dart-define=TRIGRID_ACCEPTANCE_BUILD_ID=$acceptanceBuildId

dart run tool/verify_device_acceptance.dart --device=<device-label>
```

PowerShell equivalent:

```powershell
\$acceptanceBuildId = '$acceptanceBuildId'

flutter drive --driver=test_driver/integration_test.dart `
  --target=integration_test/device_acceptance_test.dart `
  -d <device-id> --profile --no-dds `
  --dart-define=TRIGRID_DEVICE_TEST_SCOPE=functional `
  --dart-define=TRIGRID_DEVICE_LABEL=<device-label> `
  --dart-define=TRIGRID_ACCEPTANCE_BUILD_ID=\$acceptanceBuildId

flutter drive --driver=test_driver/integration_test.dart `
  --target=integration_test/device_acceptance_test.dart `
  -d <device-id> --profile --no-dds `
  --dart-define=TRIGRID_DEVICE_TEST_SCOPE=performance `
  --dart-define=TRIGRID_PROFILE_CASE=all `
  --dart-define=TRIGRID_DEVICE_LABEL=<device-label> `
  --dart-define=TRIGRID_ACCEPTANCE_BUILD_ID=\$acceptanceBuildId

dart run tool/verify_device_acceptance.dart --device=<device-label>
```

The verifier must pass without virtual-target, stale-build, missing scenario,
sampling, profile-mode, or frame-budget failures.

## 5. Physical LAN matrix

Copy `lan_device_matrix.template.json` to a working report. Record only observed
physical runs. Cover all eight Android/iOS host/client combinations across
same Wi-Fi and Android/iOS hotspots, plus the client-isolation failure case.
Each full match must prove discovery/fallback routes, terminal hash agreement,
disconnect pause, background/foreground reconnect, snapshot resynchronization,
offline operation, connection quality, and host/client screenshots.

```sh
dart tool/inspect_lan_device_matrix_progress.dart \\
  --report=<lan-report-path> --verbose
dart run tool/verify_lan_device_matrix.dart --report=<lan-report-path>
```

After the working matrix passes, merge it into a new report without modifying
the original shared evidence:

```sh
dart tool/merge_lan_device_matrix.dart \\
  --source=<lan-report-path> \\
  --target=build/device-acceptance/device_acceptance.json \\
  --output=build/device-acceptance/device_acceptance.with_lan.json

dart run tool/verify_lan_device_matrix.dart \\
  --report=build/device-acceptance/device_acceptance.with_lan.json
```

Do not set physical/pass booleans by assumption, reuse evidence after the
acceptance build ID changes, or treat emulator/simulator results as release
evidence.
''';

class ListEquality<T> {
  const ListEquality();

  bool equals(List<T> left, List<T> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
