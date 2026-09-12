import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:trigrid/core/game/trigrid_engine.dart';
import 'package:trigrid/core/persistence/trigrid_persistence.dart';

class AppController extends GetxController {
  AppController(this._repository);

  final TriGridRepository _repository;
  final preferences = AppPreferences.defaults().obs;
  final localSnapshot = Rxn<SavedMatchSnapshot>();
  final replays = <SavedReplayEntry>[].obs;
  final lanSnapshots = <SavedLanSnapshot>[].obs;
  final statistics = MatchStatistics.empty().obs;
  final isReady = false.obs;

  TriGridData _data = TriGridData.defaults();

  Locale? get selectedLocale {
    final code = preferences.value.localeCode;
    return code == null ? null : Locale(code);
  }

  Future<void> initialize() async {
    try {
      _data = await _repository.load();
      final snapshot = _verifiedSnapshot(_data.localSnapshot);
      if (snapshot == null && _data.localSnapshot != null) {
        _data = _data.copyWith(clearLocalSnapshot: true);
        await _persist();
      }
      preferences.value = _data.preferences;
      localSnapshot.value = snapshot;
      replays.assignAll(_data.replays);
      lanSnapshots.assignAll(
        _data.lanSnapshots.where(
          (snapshot) =>
              GameStateHasher.hash(snapshot.state) == snapshot.stateHash,
        ),
      );
      statistics.value = _data.statistics;
    } on Object {
      _data = TriGridData.defaults();
      preferences.value = _data.preferences;
      localSnapshot.value = null;
      replays.clear();
      lanSnapshots.clear();
      statistics.value = _data.statistics;
    } finally {
      isReady.value = true;
    }
  }

  Future<void> updatePreferences(AppPreferences next) async {
    preferences.value = next;
    _data = _data.copyWith(preferences: next);
    await _persist();
  }

  Future<void> saveLocalSnapshot({
    required GameState state,
    required List<SubmitMoveAction> actions,
    required bool passAndPlayHandoffs,
  }) async {
    if (state.isGameOver) {
      await clearLocalSnapshot();
      return;
    }
    final snapshot = SavedMatchSnapshot(
      state: state,
      actions: List<SubmitMoveAction>.unmodifiable(actions),
      stateHash: GameStateHasher.hash(state),
      savedAtUtc: DateTime.now().toUtc(),
      passAndPlayHandoffs: passAndPlayHandoffs,
    );
    if (_verifiedSnapshot(snapshot) == null) {
      return;
    }
    localSnapshot.value = snapshot;
    _data = _data.copyWith(localSnapshot: snapshot);
    await _persist();
  }

  Future<void> clearLocalSnapshot() async {
    if (localSnapshot.value == null && _data.localSnapshot == null) {
      return;
    }
    localSnapshot.value = null;
    _data = _data.copyWith(clearLocalSnapshot: true);
    await _persist();
  }

  Future<void> recordCompletedMatch({
    required MatchMode mode,
    required GameState state,
    required String perspectivePlayerId,
    required List<SubmitMoveAction> actions,
    required int largestMultiCapture,
  }) async {
    if (!state.isGameOver) return;
    if (localSnapshot.value?.state.settings.matchId == state.settings.matchId) {
      await clearLocalSnapshot();
    }
    if (_data.completedMatchIds.contains(state.settings.matchId)) {
      return;
    }
    final completedIds = {..._data.completedMatchIds, state.settings.matchId};
    final currentStatistics = statistics.value;
    final modeStatistics = mode == MatchMode.local
        ? currentStatistics.local
        : currentStatistics.lan;
    final updatedMode = modeStatistics.record(
      state: state,
      perspectivePlayerId: perspectivePlayerId,
      matchLargestMultiCapture: largestMultiCapture,
    );
    final updatedStatistics = mode == MatchMode.local
        ? currentStatistics.copyWith(local: updatedMode)
        : currentStatistics.copyWith(lan: updatedMode);

    final updatedReplays = [...replays];
    final replay = GameReplay(
      settings: state.settings,
      actions: actions,
      expectedFinalHash: GameStateHasher.hash(state),
    );
    try {
      final result = ReplayRunner.run(replay);
      if (result.finalHash == GameStateHasher.hash(state)) {
        updatedReplays.removeWhere(
          (entry) => entry.id == state.settings.matchId,
        );
        updatedReplays.insert(
          0,
          SavedReplayEntry(
            id: state.settings.matchId,
            mode: mode,
            createdAtUtc: DateTime.now().toUtc(),
            replay: replay,
          ),
        );
        if (updatedReplays.length > 40) {
          updatedReplays.removeRange(40, updatedReplays.length);
        }
      }
    } on Object {
      // A resynchronized LAN client may not own the complete action history.
    }

    statistics.value = updatedStatistics;
    replays.assignAll(updatedReplays);
    _data = _data.copyWith(
      statistics: updatedStatistics,
      replays: updatedReplays,
      completedMatchIds: completedIds,
    );
    await _persist();
  }

  Future<void> deleteReplay(String id) async {
    final updated = replays.where((entry) => entry.id != id).toList();
    replays.assignAll(updated);
    _data = _data.copyWith(replays: updated);
    await _persist();
  }

  Future<bool> archiveLanSnapshot(GameState state) async {
    final hash = GameStateHasher.hash(state);
    final snapshot = SavedLanSnapshot(
      id: state.settings.matchId,
      state: state,
      stateHash: hash,
      savedAtUtc: DateTime.now().toUtc(),
    );
    if (GameStateHasher.hash(snapshot.state) != snapshot.stateHash) {
      return false;
    }
    final updated = [...lanSnapshots]
      ..removeWhere((item) => item.id == snapshot.id)
      ..insert(0, snapshot);
    if (updated.length > 20) {
      updated.removeRange(20, updated.length);
    }
    lanSnapshots.assignAll(updated);
    _data = _data.copyWith(lanSnapshots: updated);
    await _persist();
    return true;
  }

  Future<void> deleteLanSnapshot(String id) async {
    final updated = lanSnapshots.where((entry) => entry.id != id).toList();
    lanSnapshots.assignAll(updated);
    _data = _data.copyWith(lanSnapshots: updated);
    await _persist();
  }

  Future<void> clearStatistics() async {
    final empty = MatchStatistics.empty();
    statistics.value = empty;
    _data = _data.copyWith(statistics: empty, completedMatchIds: const {});
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _repository.save(_data);
    } on Object {
      // Storage failure never interrupts a running local or LAN match.
    }
  }

  SavedMatchSnapshot? _verifiedSnapshot(SavedMatchSnapshot? snapshot) {
    if (snapshot == null ||
        snapshot.state.isGameOver ||
        snapshot.state.revision == 0 ||
        _data.completedMatchIds.contains(snapshot.state.settings.matchId) ||
        GameStateHasher.hash(snapshot.state) != snapshot.stateHash) {
      return null;
    }
    try {
      final result = ReplayRunner.run(
        GameReplay(
          settings: snapshot.state.settings,
          actions: snapshot.actions,
          expectedFinalHash: snapshot.stateHash,
        ),
      );
      return result.finalHash == snapshot.stateHash ? snapshot : null;
    } on Object {
      return null;
    }
  }
}
