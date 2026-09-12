import 'dart:io';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;
    final directory = Directory('build/game-feel-device');
    await directory.create(recursive: true);
    final report = Map<String, dynamic>.from(data);
    final screenshots = report.remove('screenshots') as List<dynamic>? ?? [];
    for (final screenshot in screenshots.cast<Map<String, dynamic>>()) {
      final name = screenshot['screenshotName'] as String;
      if (!RegExp(r'^[a-z_]+$').hasMatch(name)) continue;
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes((screenshot['bytes'] as List<dynamic>).cast<int>());
    }
    await writeResponseData(
      report,
      testOutputFilename: 'game_feel',
      destinationDirectory: directory.path,
    );
  },
);
