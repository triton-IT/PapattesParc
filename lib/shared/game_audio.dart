import 'dart:async';
import 'game_activity.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'park_catalog.dart';

enum SoundEffect { click, reveal, flag, blocked, animalFound, win, lose }

class GameAudio {
  GameAudio({required this.musicEnabled, required this.effectsEnabled}) {
    if (_instances.isEmpty) {
      HardwareKeyboard.instance.addHandler(_keyboardGesture);
    }
    _instances.add(this);
    GameActivity.instance.addListener(_activityChanged);
  }
  static final Set<GameAudio> _instances = {};
  bool _disposed = false;
  bool _needsGesture = false;
  bool _starting = false;
  Future<void>? _configuration;
  static void onUserGesture() {
    for (final audio in _instances.toList()) {
      if (audio._needsGesture) unawaited(audio._playCurrent());
    }
  }

  static bool _keyboardGesture(KeyEvent event) {
    if (event is KeyDownEvent) onUserGesture();
    return false;
  }

  void _activityChanged() {
    unawaited(_safeActivityChange());
  }

  Future<void> _safeActivityChange() async {
    try {
      if (_disposed) return;
      if (!GameActivity.instance.value) {
        await _music?.pause();
        await _effect?.stop();
      } else if (musicEnabled && _music != null) {
        await _musicPlayer.resume();
      }
    } catch (_) {
      _needsGesture = true;
    }
  }

  static final _homeSource = AssetSource('audio/home_theme.m4a');
  AudioPlayer? _music;
  AudioPlayer get _musicPlayer => _music ??= AudioPlayer();
  AudioPlayer? _effect;
  AudioPlayer get _effectPlayer => _effect ??= AudioPlayer();
  AssetSource _source = _homeSource;
  bool musicEnabled;
  bool effectsEnabled;

  Future<void> _configure() =>
      _configuration ??= _configurePlayers().onError((error, stack) {
        _configuration = null;
        Error.throwWithStackTrace(
          error ?? StateError('Audio initialization failed'),
          stack,
        );
      });

  Future<void> _configurePlayers() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(.2);
    await _effectPlayer.setReleaseMode(ReleaseMode.stop);
    await _effectPlayer.setVolume(.55);
  }

  Future<void> initialize() async {
    if (_disposed || !musicEnabled && !effectsEnabled) return;
    try {
      await _configure();
      await _playCurrent();
    } catch (_) {
      _needsGesture = true;
    }
  }

  Future<void> playHome() => _play(_homeSource);

  Future<void> playLevel(AnimalTemperament temperament) =>
      _play(AssetSource('audio/level_${temperament.name}.m4a'));

  Future<void> _play(AssetSource source) async {
    _source = source;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_disposed ||
        _starting ||
        !musicEnabled ||
        !GameActivity.instance.value) {
      return;
    }
    _starting = true;
    try {
      await _configure();
      if (_disposed) return;
      await _musicPlayer.stop();
      if (_disposed || !musicEnabled || !GameActivity.instance.value) return;
      await _musicPlayer.play(_source);
      _needsGesture = false;
    } catch (_) {
      _needsGesture = true;
    } finally {
      _starting = false;
    }
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    if (musicEnabled) {
      await _playCurrent();
      return;
    }
    try {
      await _music?.pause();
    } catch (_) {
      // Disabling music must also work when initialization was refused.
    }
  }

  Future<void> playEffect(SoundEffect effect) async {
    if (_disposed || !effectsEnabled || !GameActivity.instance.value) return;
    final name = switch (effect) {
      SoundEffect.animalFound => 'animal_found',
      _ => effect.name,
    };
    try {
      await _configure();
      if (_disposed) return;
      await _effectPlayer.stop();
      if (!_disposed && effectsEnabled && GameActivity.instance.value) {
        await _effectPlayer.play(AssetSource('audio/sfx_$name.m4a'));
      }
    } catch (_) {
      /* A blocked effect is not replayed after a later gesture. */
    }
  }

  void setEffectsEnabled(bool value) => effectsEnabled = value;

  Future<void> dispose() async {
    _disposed = true;
    _instances.remove(this);
    if (_instances.isEmpty) {
      HardwareKeyboard.instance.removeHandler(_keyboardGesture);
    }
    GameActivity.instance.removeListener(_activityChanged);
    try {
      await _configuration;
    } catch (_) {
      /* Failed initialization still needs disposal. */
    }
    await _music?.dispose();
    await _effect?.dispose();
  }
}
