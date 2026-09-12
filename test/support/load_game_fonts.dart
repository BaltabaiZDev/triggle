import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Use the SDK's real game fonts, not the rectangular Ahem test font.
Future<void> loadGameFonts() async {
  final config = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(await config.readAsString())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  final flutter = packages.cast<Map<String, dynamic>>().firstWhere(
    (entry) => entry['name'] == 'flutter',
  );
  final rootPath = flutter['rootUri'] as String;
  final root = config.uri.resolve(
    rootPath.endsWith('/') ? rootPath : '$rootPath/',
  );
  final fonts = root.resolve('../../bin/cache/artifacts/material_fonts/');
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        File.fromUri(
          fonts.resolve(file),
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
  }

  const textFonts = [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ];
  await load('Roboto', textFonts);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}
