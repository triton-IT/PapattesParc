import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/match3_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/match3_session.dart';
import '../domain/models.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';
import 'match3_screen.dart';

enum _Match3Screen { levels, custom, playing }

class Match3GameFlow extends StatefulWidget {
  const Match3GameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final Match3ProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

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
  Match3FreeGameConfig? _freeConfig;
  Match3Session? _session;
  Match3Position? _selected;
  Match3BoardSnapshot? _displayed;
  Set<Match3Position> _clearing = const {};
  int _cascade = 0;
  bool _resolving = false;
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

  void _startLevel(Match3LevelDefinition level) {
    _freeConfig = null;
    _start(level);
  }

  void _startFree(Match3FreeGameConfig config) {
    _freeConfig = config;
    final stage = widget.stages.firstWhere(
      (stage) => stage.biome == config.biome,
    );
    _start(buildFreeMatch3Level(stage, config));
  }

  void _start(Match3LevelDefinition level) {
    _level = level;
    _session = Match3Session(
      level,
      DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919,
    );
    _selected = null;
    _displayed = null;
    _clearing = const {};
    _cascade = 0;
    _resolving = false;
    _hasMoved = false;
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _Match3Screen.playing);
  }

  void _select(Match3Position position) {
    if (_resolving || _session!.status != Match3Status.playing) return;
    if (!_session!.canMove(position)) {
      setState(() => _selected = null);
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast(_blockedMessage(position));
      return;
    }
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
      unawaited(_swap(selected, position));
      return;
    }
    setState(() => _selected = position);
  }

  Future<void> _swap(Match3Position first, Match3Position second) async {
    if (_resolving) return;
    if (!_session!.canMove(first) || !_session!.canMove(second)) {
      final blocked = !_session!.canMove(first) ? first : second;
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast(_blockedMessage(blocked));
      return;
    }
    final result = _session!.swap(first, second);
    _selected = null;
    if (!result.changed) {
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast('Ce déplacement ne crée aucun alignement.');
      setState(() {});
      return;
    }
    _hasMoved = true;
    _resolving = true;
    _displayed = result.initial;
    unawaited(_audio.playEffect(SoundEffect.reveal));
    for (final step in result.steps) {
      setState(() {
        _clearing = step.cleared;
        _cascade = step.cascade;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _displayed = step.result;
        _clearing = const {};
      });
      await Future<void>.delayed(const Duration(milliseconds: 440));
      if (!mounted) return;
    }
    setState(() {
      _displayed = null;
      _cascade = 0;
      _resolving = false;
    });
    if (result.reshuffled) _toast('Plus de combinaison : plateau mélangé.');
    if (_session!.status != Match3Status.playing) {
      unawaited(_finishLevel());
    }
    setState(() {});
  }

  String _blockedMessage(Match3Position position) {
    final cell = _session!.cell(position);
    return switch (cell.blocker) {
      BlockerKind.leaves =>
        'Les feuilles bloquent cet animal. Fais un alignement sur une case voisine.',
      BlockerKind.vines =>
        'Les lianes immobilisent cet animal. Fais un alignement sur sa case ou une voisine.',
      _ => 'Le panier ne se déplace pas. Libère les cases sous lui.',
    };
  }

  Future<void> _finishLevel() async {
    final won = _session!.status == Match3Status.won;
    unawaited(_audio.playEffect(won ? SoundEffect.win : SoundEffect.lose));
    if (!won) return;
    if (_freeConfig == null) {
      await widget.progress.completeLevel(
        _level!.number,
        _session!.score,
        _session!.footprintsForScore(),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestBack() async {
    if (_resolving) {
      _toast('Le coup est en cours de résolution.');
      return;
    }
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
    _freeConfig == null ? _showLevels() : _showCustom();
  }

  void _showLevels() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _Match3Screen.levels;
      _session = null;
      _selected = null;
      _displayed = null;
      _clearing = const {};
      _cascade = 0;
      _resolving = false;
    });
  }

  void _showCustom() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _Match3Screen.custom;
      _session = null;
      _selected = null;
      _displayed = null;
      _clearing = const {};
      _cascade = 0;
      _resolving = false;
    });
  }

  void _openCustom() {
    _freeConfig = null;
    _showCustom();
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
    return switch (_screen) {
      _Match3Screen.levels => _handleBack(
        widget.onExit,
        Match3LevelSelectScreen(
          levels: _levels,
          store: widget.progress,
          musicEnabled: _musicEnabled,
          effectsEnabled: _effectsEnabled,
          onBack: widget.onExit,
          onPlay: _startLevel,
          onCustom: _openCustom,
          onToggleMusic: _toggleMusic,
          onToggleEffects: _toggleEffects,
          onQuit: widget.onQuit,
        ),
      ),
      _Match3Screen.custom => _handleBack(
        _showLevels,
        Match3CustomGameScreen(
          stages: widget.stages,
          initialConfig: _freeConfig,
          onBack: _showLevels,
          onStart: _startFree,
        ),
      ),
      _Match3Screen.playing => _handleBack(
        () => unawaited(_requestBack()),
        Match3Screen(
          session: _session!,
          displayed: _displayed,
          clearing: _clearing,
          cascade: _cascade,
          inputEnabled: !_resolving,
          showResult: !_resolving && _session!.status != Match3Status.playing,
          selected: _selected,
          onSelect: _select,
          onSwap: (first, second) => unawaited(_swap(first, second)),
          onLevels: _showLevels,
          onBack: () => unawaited(_requestBack()),
          onRetry: () => _start(_level!),
          onNext: _freeConfig == null && _level!.number < _levels.length
              ? () => _startLevel(_levels[_level!.number])
              : null,
          isFreeGame: _freeConfig != null,
          onConfigure: _freeConfig == null ? null : _showCustom,
        ),
      ),
    };
  }

  Widget _handleBack(VoidCallback onBack, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: child,
  );
}
