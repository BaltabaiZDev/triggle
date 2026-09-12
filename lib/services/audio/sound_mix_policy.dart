/// Admission without queuing: an old tap must never be heard later.
class SoundMixPolicy<T> {
  final _voices = <T, ({int priority, int until})>{};
  final _last = <T, int>{};
  Set<T>? admit(
    T sound, {
    required int nowMs,
    required int durationMs,
    required int priority,
  }) {
    _voices.removeWhere((_, voice) => voice.until <= nowMs);
    if (nowMs - (_last[sound] ?? -10000) < 85 || _voices.containsKey(sound)) {
      return null;
    }
    if (_voices.values.any((voice) => voice.priority > priority)) return null;
    final stop = _voices.entries
        .where((entry) => entry.value.priority < priority)
        .map((entry) => entry.key)
        .toSet();
    if (_voices.length - stop.length >= 2) return null;
    for (final key in stop) {
      _voices.remove(key);
    }
    _voices[sound] = (priority: priority, until: nowMs + durationMs);
    _last[sound] = nowMs;
    return stop;
  }

  void release(T sound) => _voices.remove(sound);
  void clear() {
    _voices.clear();
    _last.clear();
  }
}
