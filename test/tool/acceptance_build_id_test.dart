import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/acceptance_build_id.dart';

void main() {
  test(
    'acceptance build ID is deterministic and tracks production inputs',
    () async {
      final root = await Directory.systemTemp.createTemp('trigrid-build-id-');
      addTearDown(() => root.delete(recursive: true));
      final libDirectory = Directory(
        '${root.path}${Platform.pathSeparator}lib',
      );
      await libDirectory.create(recursive: true);
      final source = File(
        '${libDirectory.path}${Platform.pathSeparator}game.dart',
      );
      await source.writeAsString('const version = 1;\n');
      await File(
        '${root.path}${Platform.pathSeparator}pubspec.yaml',
      ).writeAsString('name: trigrid_test\n');

      final first = await computeAcceptanceBuildId(projectRoot: root.path);
      final second = await computeAcceptanceBuildId(projectRoot: root.path);
      expect(first, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(second, first);

      await source.writeAsString('const version = 2;\n');
      final changed = await computeAcceptanceBuildId(projectRoot: root.path);
      expect(changed, isNot(first));
    },
  );

  test('acceptance build ID ignores documentation-only changes', () async {
    final root = await Directory.systemTemp.createTemp('trigrid-build-id-');
    addTearDown(() => root.delete(recursive: true));
    final libDirectory = Directory('${root.path}${Platform.pathSeparator}lib');
    await libDirectory.create(recursive: true);
    await File(
      '${libDirectory.path}${Platform.pathSeparator}game.dart',
    ).writeAsString('const version = 1;\n');

    final before = await computeAcceptanceBuildId(projectRoot: root.path);
    final docs = Directory('${root.path}${Platform.pathSeparator}docs');
    await docs.create();
    await File(
      '${docs.path}${Platform.pathSeparator}notes.md',
    ).writeAsString('Documentation only.\n');
    final after = await computeAcceptanceBuildId(projectRoot: root.path);

    expect(after, before);
  });
}
