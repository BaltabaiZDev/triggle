import 'dart:convert';
import 'dart:io';

import 'acceptance_build_id.dart';
import 'inspect_lan_device_matrix_progress.dart';
import 'verify_lan_device_matrix.dart';

final class LanMatrixMergeException implements Exception {
  const LanMatrixMergeException(this.failures);

  final List<String> failures;

  @override
  String toString() => failures.join('\n');
}

Map<String, dynamic> mergeLanDeviceMatrixEvidence({
  required Map<String, dynamic> targetReport,
  required Map<String, dynamic> sourceReport,
  required String expectedBuildId,
  bool replaceExisting = false,
}) {
  final sourceFailures = verifyLanDeviceMatrixReport(
    sourceReport,
    expectedBuildId: expectedBuildId,
  );
  if (sourceFailures.isNotEmpty) {
    throw LanMatrixMergeException(List<String>.unmodifiable(sourceFailures));
  }

  final collisions = lanMatrixEvidenceKeys
      .where(targetReport.containsKey)
      .toList(growable: false);
  if (collisions.isNotEmpty && !replaceExisting) {
    throw LanMatrixMergeException(
      List<String>.unmodifiable(<String>[
        for (final key in collisions)
          'Target report already contains $key. Pass --replace-existing only '
              'when replacing that evidence is intentional.',
      ]),
    );
  }

  return <String, dynamic>{
    ...targetReport,
    for (final key in lanMatrixEvidenceKeys) key: sourceReport[key],
  };
}

Future<void> main(List<String> arguments) async {
  var sourcePath = 'build/device-acceptance/lan_device_matrix.template.json';
  var targetPath = 'build/device-acceptance/device_acceptance.json';
  var outputPath = 'build/device-acceptance/device_acceptance.with_lan.json';
  var replaceExisting = false;

  for (final argument in arguments) {
    if (argument.startsWith('--source=')) {
      sourcePath = argument.substring('--source='.length);
    } else if (argument.startsWith('--target=')) {
      targetPath = argument.substring('--target='.length);
    } else if (argument.startsWith('--output=')) {
      outputPath = argument.substring('--output='.length);
    } else if (argument == '--replace-existing') {
      replaceExisting = true;
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
  if (<String>[
    sourcePath,
    targetPath,
    outputPath,
  ].any((path) => path.trim().isEmpty)) {
    stderr.writeln('Path arguments must not be empty.');
    exitCode = 64;
    return;
  }

  final sourceFile = File(sourcePath);
  final targetFile = File(targetPath);
  final outputFile = File(outputPath);
  if (_samePath(targetFile, outputFile)) {
    stderr.writeln(
      'The output must differ from the target; this tool never modifies the '
      'original acceptance report.',
    );
    exitCode = 64;
    return;
  }
  for (final entry in <({String label, File file})>[
    (label: 'LAN matrix source', file: sourceFile),
    (label: 'Acceptance target', file: targetFile),
  ]) {
    if (!entry.file.existsSync()) {
      stderr.writeln('${entry.label} not found: ${entry.file.path}');
      exitCode = 66;
      return;
    }
  }
  if (outputFile.existsSync()) {
    stderr.writeln('Refusing to overwrite merged report: ${outputFile.path}');
    stderr.writeln('Choose a new --output path.');
    exitCode = 73;
    return;
  }

  late final Map<String, dynamic> sourceReport;
  late final Map<String, dynamic> targetReport;
  try {
    sourceReport = _readJsonObject(sourceFile);
  } on Object catch (error) {
    stderr.writeln('LAN matrix source is not valid JSON: $error');
    exitCode = 65;
    return;
  }
  try {
    targetReport = _readJsonObject(targetFile);
  } on Object catch (error) {
    stderr.writeln('Acceptance target is not valid JSON: $error');
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

  late final Map<String, dynamic> merged;
  try {
    merged = mergeLanDeviceMatrixEvidence(
      targetReport: targetReport,
      sourceReport: sourceReport,
      expectedBuildId: expectedBuildId,
      replaceExisting: replaceExisting,
    );
  } on LanMatrixMergeException catch (error) {
    stderr.writeln('FAIL LAN_MATRIX_MERGE');
    for (final failure in error.failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
    return;
  }

  outputFile.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync('${encoder.convert(merged)}\n');
  stdout.writeln('PASS LAN_MATRIX_MERGE');
  stdout.writeln('Wrote merged report: ${outputFile.path}');
  stdout.writeln('Preserved original report: ${targetFile.path}');
  stdout.writeln('Acceptance build ID: $expectedBuildId');
}

Map<String, dynamic> _readJsonObject(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw const FormatException('Expected a top-level JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

bool _samePath(File left, File right) {
  String normalized(File file) {
    final path = file.absolute.path.replaceAll(r'\', '/');
    return Platform.isWindows ? path.toLowerCase() : path;
  }

  return normalized(left) == normalized(right);
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart tool/merge_lan_device_matrix.dart '
    '[--source=<completed-lan-report>] '
    '[--target=<acceptance-report>] [--output=<new-report>] '
    '[--replace-existing]',
  );
}
