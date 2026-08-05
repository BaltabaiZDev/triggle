import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _inputDirectories = <String>[
  'lib',
  'assets',
  'android/app/src',
  'ios/Runner',
  'ios/Runner.xcodeproj',
];

const _inputFiles = <String>[
  'pubspec.yaml',
  'pubspec.lock',
  'android/app/build.gradle.kts',
  'android/build.gradle.kts',
  'android/gradle.properties',
  'android/settings.gradle.kts',
  'android/gradle/wrapper/gradle-wrapper.properties',
  'ios/Podfile',
  'ios/Flutter/AppFrameworkInfo.plist',
  'ios/Flutter/Debug.xcconfig',
  'ios/Flutter/Release.xcconfig',
  'integration_test/device_acceptance_test.dart',
  'test_driver/integration_test.dart',
  'tool/acceptance_build_id.dart',
  'tool/verify_device_acceptance.dart',
  'tool/verify_lan_device_matrix.dart',
];

Future<String> computeAcceptanceBuildId({String? projectRoot}) async {
  final root = Directory(projectRoot ?? Directory.current.path).absolute;
  final filesByPath = <String, File>{};

  void addFile(File file) {
    if (!file.existsSync()) {
      return;
    }
    final relativePath = _relativePath(root, file);
    filesByPath[relativePath] = file;
  }

  for (final relativeDirectory in _inputDirectories) {
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}'
      '${relativeDirectory.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!directory.existsSync()) {
      continue;
    }
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File) {
        addFile(entity);
      }
    }
  }
  for (final relativeFile in _inputFiles) {
    addFile(
      File(
        '${root.path}${Platform.pathSeparator}'
        '${relativeFile.replaceAll('/', Platform.pathSeparator)}',
      ),
    );
  }

  final paths = filesByPath.keys.toList()..sort();
  if (paths.isEmpty) {
    throw StateError(
      'No TriGrid acceptance inputs were found under ${root.path}.',
    );
  }

  final bytes = BytesBuilder(copy: false);
  for (final path in paths) {
    final content = await filesByPath[path]!.readAsBytes();
    bytes
      ..add(utf8.encode('${path.length}:$path:${content.length}:'))
      ..add(content)
      ..addByte(0);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}

String _relativePath(Directory root, File file) {
  final rootPath = root.path.replaceAll(r'\', '/');
  final filePath = file.absolute.path.replaceAll(r'\', '/');
  final prefix = rootPath.endsWith('/') ? rootPath : '$rootPath/';
  if (!filePath.startsWith(prefix)) {
    throw ArgumentError.value(
      file.path,
      'file',
      'Acceptance input is outside ${root.path}.',
    );
  }
  return filePath.substring(prefix.length);
}

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    stderr.writeln('Usage: dart tool/acceptance_build_id.dart');
    exitCode = 64;
    return;
  }
  stdout.writeln(await computeAcceptanceBuildId());
}
