import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keep pixel comparisons strict, but replace images atomically when updating.
/// Windows preview/indexer processes can memory-map a PNG and block truncation.
class AtomicGoldenComparator extends LocalFileComparator {
  AtomicGoldenComparator(super.testFile);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final target = File.fromUri(basedir.resolveUri(golden));
    if (await target.exists() &&
        listEquals(await target.readAsBytes(), imageBytes)) {
      return;
    }
    await target.parent.create(recursive: true);
    final temporary = await target.parent.createTemp('.golden-');
    try {
      final staged = File('${temporary.path}/image.png');
      await staged.writeAsBytes(imageBytes, flush: true);
      await staged.rename(target.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
