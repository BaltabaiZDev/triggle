import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:trigrid/services/audio/sound_mix_policy.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

enum GameSound {
  pegTouch('peg_touch.wav', 80, 0),
  elasticStretch('elastic_stretch.wav', 140, 0),
  elasticSnap('elastic_snap.wav', 200, 1),
  invalidMove('invalid_move.wav', 300, 2),
  triangleCapture('triangle_capture.wav', 380, 2),
  captureCombo('capture_combo.wav', 620, 2),
  turnChange('turn_change.wav', 200, 0),
  buttonPress('button_press.wav', 90, 0),
  playerJoin('player_join.wav', 400, 1),
  countdown('countdown.wav', 240, 1),
  victory('victory.wav', 1250, 3),
  defeat('defeat.wav', 900, 3),
  draw('draw.wav', 800, 3);

  const GameSound(this.assetName, this.durationMs, this.priority);
  final String assetName;
  final int durationMs;
  final int priority;
}

/// Preloaded native samples; at most two effects, no per-frame position polling.
class TriGridAudioService with WidgetsBindingObserver {
  TriGridAudioService({AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? AudioPlayer.new;
  final AudioPlayer Function() _createPlayer;
  static const musicAsset = 'music_loop.wav';
  static const ambientAsset = 'ambient_loop.wav';
  final _players = <GameSound, AudioPlayer>{};
  final _tokens = <GameSound, Object>{};
  final _stops = <GameSound, Timer>{};
  final _mix = SoundMixPolicy<GameSound>();
  final _clock = Stopwatch()..start();
  AudioPlayer? _music;
  var _settings = GameFeelSettings();
  Future<void>? _initialization;
  var _disposed = false;
  var _registered = false;
  var _foreground = true;
  var _musicSyncing = false;
  var _musicDirty = false;
  var _musicVolume = 0.0;
  var _duckUntil = 0;
  Timer? _unduck;
  Timer? _fadeTimer;
  Completer<void>? _fadeWait;
  Future<void>? _musicWork;

  Future<void> initialize(GameFeelSettings settings) async {
    if (_disposed) return;
    _settings = settings;
    if (!_registered) {
      _registered = true;
      _foreground =
          WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      WidgetsBinding.instance.addObserver(this);
    }
    await (_initialization ??= _prepare());
    _requestMusicSync();
  }

  Future<void> _prepare() async {
    final context = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();
    for (final sound in GameSound.values) {
      if (_disposed) return;
      final player = _createPlayer()..audioCache = FlameAudio.audioCache;
      player.positionUpdater = null;
      try {
        await player.setAudioContext(context);
        try {
          await player.setPlayerMode(PlayerMode.lowLatency);
        } on Object {
          await player.setPlayerMode(PlayerMode.mediaPlayer);
        }
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(sound.assetName));
        _players[sound] = player;
      } on Object {
        _players.remove(sound);
        await _safe(player.dispose);
      }
    }
    if (_disposed) return;
    final music = _createPlayer()..audioCache = FlameAudio.audioCache;
    music.positionUpdater = null;
    try {
      await music.setAudioContext(context);
      await music.setReleaseMode(ReleaseMode.loop);
      await music.setVolume(0);
      await music.setSource(AssetSource(musicAsset));
      _music = music;
    } on Object {
      _music = null;
      await _safe(music.dispose);
    }
  }

  Future<void> updateSettings(GameFeelSettings settings) async {
    _settings = settings;
    if (settings.muted || settings.soundEffectsVolume == 0) {
      await _stopEffects();
    }
    _requestMusicSync();
  }

  Future<void> play(GameSound sound) async {
    if (_disposed ||
        !_foreground ||
        _settings.muted ||
        _settings.soundEffectsVolume <= 0) {
      return;
    }
    final player = _players[sound];
    if (player == null) {
      return; // Drop taps during initialization, never queue them.
    }
    final now = _clock.elapsedMilliseconds;
    final stop = _mix.admit(
      sound,
      nowMs: now,
      durationMs: sound.durationMs + 35,
      priority: sound.priority,
    );
    if (stop == null) return;
    final token = Object();
    _tokens[sound] = token;
    for (final other in stop) {
      await _stopVoice(other);
    }
    try {
      await player.stop();
      await player.setVolume(
        _settings.soundEffectsVolume * (sound.priority == 0 ? 0.65 : 1),
      );
      if (_disposed ||
          !_foreground ||
          _settings.muted ||
          _tokens[sound] != token ||
          _clock.elapsedMilliseconds - now > 100) {
        if (_tokens[sound] == token) await _stopVoice(sound);
        return;
      }
      await player.resume();
      if (_disposed || _tokens[sound] != token) return;
      _stops[sound]?.cancel();
      _stops[sound] = Timer(Duration(milliseconds: sound.durationMs + 30), () {
        if (_tokens[sound] == token) unawaited(_stopVoice(sound));
      });
      if (sound.priority >= 2) {
        _duckUntil = _clock.elapsedMilliseconds + sound.durationMs;
        _unduck?.cancel();
        _unduck = Timer(
          Duration(milliseconds: sound.durationMs),
          _requestMusicSync,
        );
        _requestMusicSync();
      }
    } on Object {
      if (_tokens[sound] == token) await _stopVoice(sound);
    }
  }

  Future<void> _stopVoice(GameSound sound) async {
    _tokens.remove(sound);
    _stops.remove(sound)?.cancel();
    _mix.release(sound);
    final player = _players[sound];
    if (player != null) await _safe(player.stop);
  }

  Future<void> _stopEffects() async {
    await Future.wait(_tokens.keys.toList().map(_stopVoice));
    _mix.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(_stopEffects());
    _requestMusicSync();
  }

  double get _targetMusicVolume => !_foreground || _settings.muted
      ? 0
      : _settings.musicVolume *
            (_clock.elapsedMilliseconds < _duckUntil ? 0.4 : 1);

  void _requestMusicSync() {
    if (_disposed || _music == null) return;
    _musicDirty = true;
    if (!_musicSyncing) _musicWork = _syncMusic();
  }

  Future<void> _syncMusic() async {
    _musicSyncing = true;
    try {
      do {
        _musicDirty = false;
        final music = _music;
        if (_disposed || music == null) break;
        if (!_foreground || _settings.muted) {
          _musicVolume = 0;
          await music.setVolume(0);
          await music.pause();
          continue;
        }
        if (_targetMusicVolume > 0 && music.state != PlayerState.playing) {
          await music.resume();
        }
        // Only while fading, never a frame-driven platform call.
        while (!_disposed &&
            _foreground &&
            !_settings.muted &&
            (_targetMusicVolume - _musicVolume).abs() > 0.005) {
          _musicVolume += (_targetMusicVolume - _musicVolume) * 0.32;
          await music.setVolume(_musicVolume);
          if (_disposed) break;
          final wait = Completer<void>();
          _fadeWait = wait;
          _fadeTimer = Timer(const Duration(milliseconds: 40), wait.complete);
          await wait.future;
          _fadeWait = null;
        }
        if (!_disposed) {
          _musicVolume = _targetMusicVolume;
          await music.setVolume(_musicVolume);
          if (_musicVolume == 0) await music.pause();
        }
      } while (_musicDirty && !_disposed);
    } on Object {
      /* Optional audio must not interrupt gameplay. */
    } finally {
      _musicSyncing = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_registered) WidgetsBinding.instance.removeObserver(this);
    _unduck?.cancel();
    _fadeTimer?.cancel();
    final fade = _fadeWait;
    if (fade != null && !fade.isCompleted) fade.complete();
    for (final timer in _stops.values) {
      timer.cancel();
    }
    _stops.clear();
    _tokens.clear();
    _mix.clear();
    await _initialization;
    await _musicWork;
    await Future.wait(_players.values.map((player) => _safe(player.dispose)));
    _players.clear();
    final music = _music;
    _music = null;
    if (music != null) await _safe(music.dispose);
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      /* Feedback cannot break gameplay. */
    }
  }
}
