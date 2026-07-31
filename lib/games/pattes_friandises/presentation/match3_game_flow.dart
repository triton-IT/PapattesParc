import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/match3_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/match3_session.dart';
import '../domain/models.dart';
import 'level_select_screen.dart';
import 'match3_screen.dart';

enum _Match3Screen { levels, playing }

class Match3GameFlow extends StatefulWidget {
  const Match3GameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    super.key,
  });

  final List<ParkStage> stages;
  final Match3ProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;

  @override
  State<Match3GameFlow> createState() => _Match3GameFlowState();
}

class _Match3GameFlowState extends State<Match3GameFlow> {
  _Match3Screen _screen = _Match3Screen.levels;
  late final List<Match3LevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  Match3LevelDefinition? _level;
  Match3Session? _session;
  Match3Position? _selected;
  bool _hasMoved = false;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildMatch3Campaign(widget.stages);
    _musicEnabled = widget.settings.musicEnabled;
    _effectsEnabled = widget.settings.effectsEnabled;
    _audio = GameAudio(
      musicEnabled: _musicEnabled,
      effectsEnabled: _effectsEnabled,
    );
    unawaited(_audio.initialize());
  }

  @override
  void dispose() {
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _start(Match3LevelDefinition level) {
    _level = level;
    _session = Match3Session(
      level,
      DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919,
    );
    _selected = null;
    _hasMoved = false;
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _Match3Screen.playing);
  }

  void _select(Match3Position position) {
    if (_session!.status != Match3Status.playing) return;
    final selected = _selected;
    if (selected == null) {
      setState(() => _selected = position);
      return;
    }
    if (selected == position) {
      setState(() => _selected = null);
      return;
    }
    if ((selected.x - position.x).abs() + (selected.y - position.y).abs() ==
        1) {
      _swap(selected, position);
      return;
    }
    setState(() => _selected = position);
  }

  void _swap(Match3Position first, Match3Position second) {
    final result = _session!.swap(first, second);
    _selected = null;
    if (!result.changed) {
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast('Ce déplacement ne crée aucun alignement.');
      setState(() {});
      return;
    }
    _hasMoved = true;
    unawaited(_audio.playEffect(SoundEffect.reveal));
    if (result.reshuffled) _toast('Plus de combinaison : plateau mélangé.');
    if (_session!.status != Match3Status.playing) {
      unawaited(_finishLevel());
    }
    setState(() {});
  }

  Future<void> _finishLevel() async {
    final won = _session!.status == Match3Status.won;
    unawaited(_audio.playEffect(won ? SoundEffect.win : SoundEffect.lose));
    if (!won) return;
    await widget.progress.completeLevel(
      _level!.number,
      _session!.score,
      _session!.footprintsForScore(),
    );
    if (mounted) setState(() {});
  }

  Future<void> _requestLevels() async {
    if (_session?.status == Match3Status.playing && _hasMoved) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner ce niveau ?'),
          content: const Text('La progression de cette partie sera perdue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    _showLevels();
  }

  void _showLevels() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _Match3Screen.levels;
      _session = null;
      _selected = null;
    });
  }

  Future<void> _toggleMusic() async {
    final value = !_musicEnabled;
    setState(() => _musicEnabled = value);
    await widget.settings.setMusicEnabled(value);
    await _audio.setMusicEnabled(value);
  }

  Future<void> _toggleEffects() async {
    final value = !_effectsEnabled;
    setState(() => _effectsEnabled = value);
    await widget.settings.setEffectsEnabled(value);
    _audio.setEffectsEnabled(value);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == _Match3Screen.levels) {
      return Match3LevelSelectScreen(
        levels: _levels,
        store: widget.progress,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onBack: widget.onExit,
        onPlay: _start,
        onToggleMusic: _toggleMusic,
        onToggleEffects: _toggleEffects,
      );
    }
    return Match3Screen(
      session: _session!,
      selected: _selected,
      onSelect: _select,
      onSwap: _swap,
      onLevels: () => unawaited(_requestLevels()),
      onRetry: () => _start(_level!),
      onNext: _level!.number < _levels.length
          ? () => _start(_levels[_level!.number])
          : null,
    );
  }
}
