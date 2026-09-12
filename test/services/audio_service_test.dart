import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trigrid/services/audio/trigrid_audio_service.dart';
import 'package:trigrid/services/game_feel/game_feel_settings.dart';

class _Player extends Fake implements AudioPlayer {
  @override
  late AudioCache audioCache;
  @override
  PlayerState state = PlayerState.stopped;
  bool disposed = false;
  bool polling = true;
  @override
  double volume = 0;
  @override
  set positionUpdater(PositionUpdater? value) {
    polling = value != null;
  }

  @override
  Future<void> setAudioContext(AudioContext context) async {}
  @override
  Future<void> setPlayerMode(PlayerMode mode) async {}
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> setSource(Source source) async {}
  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Future<void> stop() async {
    state = PlayerState.stopped;
  }

  @override
  Future<void> pause() async {
    state = PlayerState.paused;
  }

  @override
  Future<void> resume() async {
    expect(disposed, isFalse);
    state = PlayerState.playing;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    state = PlayerState.disposed;
  }
}

void main() {
  testWidgets(
    'preloads once, disables polling, preempts low priority and mutes immediately',
    (tester) async {
      final players = <_Player>[];
      final audio = TriGridAudioService(
        createPlayer: () {
          final player = _Player();
          players.add(player);
          return player;
        },
      );
      final settings = GameFeelSettings(musicVolume: 0);
      await audio.initialize(settings);
      await tester.pump();
      expect(players, hasLength(GameSound.values.length + 1));
      expect(players.every((player) => !player.polling), isTrue);
      await audio.play(GameSound.buttonPress);
      expect(players[GameSound.buttonPress.index].state, PlayerState.playing);
      await audio.play(GameSound.triangleCapture);
      expect(players[GameSound.buttonPress.index].state, PlayerState.stopped);
      expect(
        players[GameSound.triangleCapture.index].state,
        PlayerState.playing,
      );
      await audio.play(GameSound.turnChange);
      expect(
        players[GameSound.turnChange.index].state,
        isNot(PlayerState.playing),
      );
      await audio.updateSettings(settings.copyWith(muted: true));
      expect(
        players.where((player) => player.state == PlayerState.playing),
        isEmpty,
      );
      await audio.initialize(settings);
      expect(players, hasLength(GameSound.values.length + 1));
      await audio.dispose();
      await tester.pump();
      expect(players.every((player) => player.disposed), isTrue);
    },
  );

  testWidgets(
    'music fades, sleeps in background and disposes mid-fade without a pending timer',
    (tester) async {
      final players = <_Player>[];
      final audio = TriGridAudioService(
        createPlayer: () {
          final player = _Player();
          players.add(player);
          return player;
        },
      );
      await audio.initialize(GameFeelSettings(musicVolume: 0.3));
      await tester.pump();
      for (var i = 0; i < 18; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final music = players.last;
      expect(music.state, PlayerState.playing);
      expect(music.volume, closeTo(0.3, 0.006));
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(music.state, PlayerState.paused);
      expect(music.volume, 0);
      await audio.play(GameSound.buttonPress);
      expect(
        players[GameSound.buttonPress.index].state,
        isNot(PlayerState.playing),
      );
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(music.state, PlayerState.playing);
      await audio.dispose();
      await tester.pump();
      expect(players.every((player) => player.disposed), isTrue);
    },
  );
}
