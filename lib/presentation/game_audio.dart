import 'package:audioplayers/audioplayers.dart';

import '../domain/models.dart';

enum SoundEffect { click, reveal, flag, blocked, animalFound, win, lose }

class GameAudio {
  GameAudio({required this.musicEnabled});

  static final _homeSource = AssetSource('audio/home_theme.m4a');
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  AssetSource _source = _homeSource;
  bool musicEnabled;

  Future<void> initialize() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(.2);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setVolume(.55);
    await _playCurrent();
  }

  Future<void> playHome() => _play(_homeSource);

  Future<void> playLevel(AnimalTemperament temperament) =>
      _play(AssetSource('audio/level_${temperament.name}.m4a'));

  Future<void> _play(AssetSource source) async {
    _source = source;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (!musicEnabled) return;
    await _musicPlayer.stop();
    await _musicPlayer.play(_source);
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    if (musicEnabled) {
      await _musicPlayer.play(_source);
      return;
    }
    if (_musicPlayer.state == PlayerState.playing) await _musicPlayer.pause();
  }

  Future<void> playEffect(SoundEffect effect) async {
    final name = switch (effect) {
      SoundEffect.animalFound => 'animal_found',
      _ => effect.name,
    };
    await _effectPlayer.stop();
    await _effectPlayer.play(AssetSource('audio/sfx_$name.m4a'));
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _effectPlayer.dispose();
  }
}
