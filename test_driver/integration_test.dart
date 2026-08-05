import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final outputDirectory = Directory('build/device-acceptance');
      final outputFile = File('${outputDirectory.path}/device_acceptance.json');
      final existing = <String, dynamic>{};
      if (await outputFile.exists()) {
        try {
          existing.addAll(
            jsonDecode(await outputFile.readAsString())!
                as Map<String, dynamic>,
          );
        } on Object {
          // A partial prior run must not prevent the new evidence from saving.
        }
      }
      final sanitized = <String, dynamic>{...existing, ...?data};
      final acceptanceBuildId = data?['acceptanceBuildId'];
      final screenshots = <Map<String, Object?>>[
        for (final screenshot
            in (existing['screenshots'] as List<dynamic>? ?? const []))
          Map<String, Object?>.from(screenshot! as Map),
      ];
      for (final raw in (data?['screenshots'] as List<dynamic>? ?? const [])) {
        final screenshot = raw! as Map<String, dynamic>;
        final name = screenshot['screenshotName']! as String;
        final bytes = (screenshot['bytes']! as List<dynamic>).cast<int>();
        final file = File('${outputDirectory.path}/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
        screenshots.removeWhere((existing) => existing['name'] == name);
        screenshots.add(<String, Object?>{
          'name': name,
          'path': file.path,
          'bytes': bytes.length,
          'acceptanceBuildId': acceptanceBuildId,
        });
      }
      sanitized['screenshots'] = screenshots;
      await writeResponseData(
        sanitized,
        testOutputFilename: 'device_acceptance',
        destinationDirectory: outputDirectory.path,
      );
    },
  );
}
