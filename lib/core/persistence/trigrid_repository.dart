import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:trigrid/core/persistence/trigrid_data.dart';

abstract interface class TriGridRepository {
  Future<TriGridData> load();

  Future<void> save(TriGridData data);
}

class SharedPreferencesTriGridRepository implements TriGridRepository {
  SharedPreferencesTriGridRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const storageKey = 'trigrid.app_data.v1';

  SharedPreferencesAsync? _preferences;
  final Lock _lock = Lock();

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<TriGridData> load() {
    return _lock.synchronized(() async {
      final encoded = await _store.getString(storageKey);
      if (encoded == null) {
        return TriGridData.defaults();
      }
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is! Map<String, Object?>) {
          throw const FormatException('App data must be a JSON object.');
        }
        return TriGridData.fromJson(decoded);
      } on Object {
        await _store.remove(storageKey);
        return TriGridData.defaults();
      }
    });
  }

  @override
  Future<void> save(TriGridData data) {
    return _lock.synchronized(
      () => _store.setString(storageKey, jsonEncode(data.toJson())),
    );
  }
}

class MemoryTriGridRepository implements TriGridRepository {
  MemoryTriGridRepository([TriGridData? initial])
    : _data = initial ?? TriGridData.defaults();

  TriGridData _data;

  @override
  Future<TriGridData> load() async => _data;

  @override
  Future<void> save(TriGridData data) async {
    _data = data;
  }

  TriGridData get data => _data;
}
