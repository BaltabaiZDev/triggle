import 'dart:collection';
import 'dart:convert';

abstract final class CanonicalJson {
  static String encode(Object? value) => jsonEncode(_normalize(value));

  static Object? _normalize(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map) {
      final normalized = SplayTreeMap<String, Object?>();
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw ArgumentError('Canonical JSON object keys must be strings.');
        }
        normalized[entry.key as String] = _normalize(entry.value);
      }
      return normalized;
    }
    if (value is Iterable) {
      return value.map(_normalize).toList(growable: false);
    }
    throw ArgumentError(
      'Unsupported canonical JSON value ${value.runtimeType}.',
    );
  }
}
