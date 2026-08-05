import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_physical_acceptance_kit.dart';

void main() {
  const buildId =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  late Directory temporaryDirectory;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'trigrid_acceptance_kit_test_',
    );
  });

  tearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'creates a self-verifying, current-build physical handoff kit',
    () async {
      final apk = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}source.apk',
      )..writeAsBytesSync(<int>[1, 2, 3, 4]);
      final output = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}kit',
      );

      await createPhysicalAcceptanceKit(
        outputDirectory: output,
        androidApk: apk,
        acceptanceBuildId: buildId,
        generatedAtUtc: DateTime.utc(2026, 7, 31, 6),
      );

      expect(
        File(
          '${output.path}${Platform.pathSeparator}trigrid-android-debug.apk',
        ).readAsBytesSync(),
        <int>[1, 2, 3, 4],
      );
      final manifest =
          jsonDecode(
                File(
                  '${output.path}${Platform.pathSeparator}manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(manifest['acceptanceBuildId'], buildId);
      expect(manifest['lanMatrixScenarioKeys'], hasLength(9));
      expect(manifest['files'], hasLength(3));

      final runbook = File(
        '${output.path}${Platform.pathSeparator}RUNBOOK.md',
      ).readAsStringSync();
      expect(runbook, contains(buildId));
      expect(runbook, contains('flutter build ios --debug --no-codesign'));
      expect(runbook, contains('TRIGRID_PROFILE_CASE=all'));
      expect(runbook, contains('verify_lan_device_matrix.dart'));
      expect(
        await verifyPhysicalAcceptanceKit(output, expectedBuildId: buildId),
        isEmpty,
      );
    },
  );

  test('rejects overwrite and detects a tampered bundled artifact', () async {
    final apk = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}source.apk',
    )..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final output = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}kit',
    );
    final generatedAt = DateTime.utc(2026, 7, 31, 6);

    await createPhysicalAcceptanceKit(
      outputDirectory: output,
      androidApk: apk,
      acceptanceBuildId: buildId,
      generatedAtUtc: generatedAt,
    );
    await expectLater(
      createPhysicalAcceptanceKit(
        outputDirectory: output,
        androidApk: apk,
        acceptanceBuildId: buildId,
        generatedAtUtc: generatedAt,
      ),
      throwsStateError,
    );

    File(
      '${output.path}${Platform.pathSeparator}trigrid-android-debug.apk',
    ).writeAsBytesSync(<int>[9], mode: FileMode.append);
    final failures = await verifyPhysicalAcceptanceKit(
      output,
      expectedBuildId: buildId,
    );

    expect(
      failures,
      contains(
        'Bundled file trigrid-android-debug.apk has the wrong byte length.',
      ),
    );
    expect(
      failures,
      contains(
        'Bundled file trigrid-android-debug.apk failed its SHA-256 check.',
      ),
    );
  });
}
