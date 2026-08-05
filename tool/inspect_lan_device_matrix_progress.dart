import 'dart:convert';
import 'dart:io';

import 'acceptance_build_id.dart';
import 'verify_lan_device_matrix.dart';

final lanMatrixEvidenceKeys = List<String>.unmodifiable(<String>[
  ...lanMatrixScenarioIds.map((scenarioId) => 'lan_matrix_$scenarioId'),
  'lan_matrix_client_isolation',
]);

Map<String, List<String>> inspectLanDeviceMatrixProgress(
  Map<String, dynamic> report, {
  required String expectedBuildId,
}) {
  final failures = verifyLanDeviceMatrixReport(
    report,
    expectedBuildId: expectedBuildId,
  );

  return <String, List<String>>{
    for (final key in lanMatrixEvidenceKeys)
      key: failures
          .where(
            (failure) =>
                failure == '$key is missing or is not an object.' ||
                failure.startsWith('$key ') ||
                failure.startsWith('$key.'),
          )
          .toList(growable: false),
  };
}

Future<void> main(List<String> arguments) async {
  var reportPath = 'build/device-acceptance/lan_device_matrix.template.json';
  var jsonOutput = false;
  var verbose = false;

  for (final argument in arguments) {
    if (argument.startsWith('--report=')) {
      reportPath = argument.substring('--report='.length);
      if (reportPath.trim().isEmpty) {
        stderr.writeln('--report requires a non-empty path.');
        _printUsage();
        exitCode = 64;
        return;
      }
    } else if (argument == '--json') {
      jsonOutput = true;
    } else if (argument == '--verbose') {
      verbose = true;
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
    stderr.writeln('LAN matrix report not found: ${file.path}');
    exitCode = 66;
    return;
  }

  late final Map<String, dynamic> report;
  try {
    report = jsonDecode(file.readAsStringSync())! as Map<String, dynamic>;
  } on Object catch (error) {
    stderr.writeln('LAN matrix report is not valid JSON: $error');
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

  final progress = inspectLanDeviceMatrixProgress(
    report,
    expectedBuildId: expectedBuildId,
  );
  final completed = progress.values
      .where((failures) => failures.isEmpty)
      .length;
  final complete = completed == lanMatrixEvidenceKeys.length;

  if (jsonOutput) {
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(
      encoder.convert(<String, dynamic>{
        'acceptanceBuildId': expectedBuildId,
        'completedScenarios': completed,
        'requiredScenarios': lanMatrixEvidenceKeys.length,
        'complete': complete,
        'scenarios': <Map<String, dynamic>>[
          for (final entry in progress.entries)
            <String, dynamic>{
              'key': entry.key,
              'complete': entry.value.isEmpty,
              'outstandingChecks': entry.value.length,
              'failures': entry.value,
            },
        ],
      }),
    );
  } else {
    stdout.writeln('LAN matrix progress for acceptance build:');
    stdout.writeln(expectedBuildId);
    stdout.writeln(
      '$completed/${lanMatrixEvidenceKeys.length} scenarios complete',
    );
    for (final entry in progress.entries) {
      if (entry.value.isEmpty) {
        stdout.writeln('PASS       ${entry.key}');
        continue;
      }
      stdout.writeln(
        'INCOMPLETE ${entry.key} (${entry.value.length} outstanding checks)',
      );
      if (verbose) {
        for (final failure in entry.value) {
          stdout.writeln('  - $failure');
        }
      }
    }
  }

  if (!complete) {
    exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart tool/inspect_lan_device_matrix_progress.dart '
    '[--report=<path>] [--verbose] [--json]',
  );
}
