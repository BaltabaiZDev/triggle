import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

enum GameSound {
  pegTouch('peg_touch.wav'),
  elasticStretch('elastic_stretch.wav'),
  elasticSnap('elastic_snap.wav'),
  invalidMove('invalid_move.wav'),
  triangleCapture('triangle_capture.wav'),
  captureCombo('capture_combo.wav'),
  turnChange('turn_change.wav'),
  buttonPress('button_press.wav'),
  playerJoin('player_join.wav'),
  countdown('countdown.wav'),
  victory('victory.wav'),
  defeat('defeat.wav'),
  draw('draw.wav');

  const GameSound(this.assetName);

  final String assetName;
}

class TriGridAudioService {
  TriGridAudioService();

  static const musicAsset = 'music_loop.wav';
  static const ambientAsset = 'ambient_loop.wav';
  static const _continuousBackgroundAudioEnabled = false;
  static const _pooledSounds = <GameSound>{
    GameSound.elasticSnap,
    GameSound.triangleCapture,
    GameSound.captureCombo,
    GameSound.turnChange,
  };

  late final Bgm _music = Bgm(audioCache: FlameAudio.audioCache);
  late final Bgm _ambient = Bgm(audioCache: FlameAudio.audioCache);
  var _settings = GameFeelSettings();
  var _initialized = false;
  Future<void>? _initialization;
  final Map<GameSound, AudioPool> _pools = {};

  Future<void> initialize(GameFeelSettings settings) async {
    _settings = settings;
    if (_initialized) {
      await updateSettings(settings);
      return;
    }
    final pending = _initialization;
    if (pending != null) {
      await pending;
      await updateSettings(settings);
      return;
    }
    final initialization = _initializePlayers();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initializePlayers() async {
    await FlameAudio.audioCache.loadAll(
      GameSound.values.map((sound) => sound.assetName).toList(),
    );
    for (final sound in _pooledSounds) {
      try {
        _pools[sound] = await FlameAudio.createPool(
          sound.assetName,
          minPlayers: 1,
          maxPlayers: 3,
        );
      } on Object {
        // Static playback remains as a safe fallback on unsupported devices.
      }
    }
    if (_continuousBackgroundAudioEnabled) {
      await FlameAudio.audioCache.loadAll([musicAsset, ambientAsset]);
      await _music.initialize();
      await _ambient.initialize();
      await _music.play(musicAsset, volume: _effectiveMusicVolume);
      await _ambient.play(ambientAsset, volume: _effectiveAmbientVolume);
    }
    _initialized = true;
  }

  Future<void> updateSettings(GameFeelSettings settings) async {
    _settings = settings;
    if (!_initialized) {
      return;
    }
    if (_continuousBackgroundAudioEnabled) {
      await Future.wait([
        _music.audioPlayer.setVolume(_effectiveMusicVolume),
        _ambient.audioPlayer.setVolume(_effectiveAmbientVolume),
      ]);
    }
  }

  Future<void> play(GameSound sound) async {
    final volume = _effectiveSoundEffectsVolume;
    if (volume <= 0) {
      return;
    }
    final pool = _pools[sound];
    if (pool != null) {
      await pool.start(volume: volume);
      return;
    }
    await FlameAudio.play(sound.assetName, volume: volume);
  }

  Future<void> dispose() async {
    await Future.wait(_pools.values.map((pool) => pool.dispose()));
    _pools.clear();
    if (_continuousBackgroundAudioEnabled) {
      await Future.wait([_music.dispose(), _ambient.dispose()]);
    }
    _initialized = false;
  }

  double get _effectiveMusicVolume =>
      _settings.muted ? 0 : _settings.musicVolume;

  double get _effectiveAmbientVolume =>
      _settings.muted ? 0 : _settings.ambientVolume;

  double get _effectiveSoundEffectsVolume =>
      _settings.muted ? 0 : _settings.soundEffectsVolume;
}
