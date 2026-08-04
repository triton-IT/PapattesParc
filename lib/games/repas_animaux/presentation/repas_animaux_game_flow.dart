import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/repas_animaux_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/generator.dart';
import '../domain/models.dart';
import '../domain/repas_session.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';
import 'repas_screen.dart';

enum _RepasScreen { levels, custom, playing }

class RepasAnimauxGameFlow extends StatefulWidget {
  const RepasAnimauxGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final RepasAnimauxProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<RepasAnimauxGameFlow> createState() => _RepasAnimauxGameFlowState();
}

class _RepasAnimauxGameFlowState extends State<RepasAnimauxGameFlow> {
  _RepasScreen _screen = _RepasScreen.levels;
  late final List<RepasLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  RepasLevelDefinition? _level;
  RepasFreeGameConfig? _freeConfig;
  RepasSession? _session;
  bool _finished = false;
  bool _newRecord = false;
  bool _generating = false;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildRepasCampaign(widget.stages);
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

  void _start(RepasLevelDefinition level) {
    _freeConfig = null;
    _startSession(level);
  }

  void _startSession(RepasLevelDefinition level) {
    _level = level;
    _session = RepasSession(level);
    _finished = false;
    _newRecord = false;
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _RepasScreen.playing);
  }

  Future<void> _startFree(RepasFreeGameConfig config) async {
    if (_generating) return;
    setState(() => _generating = true);
    final seed = DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919;
    try {
      final generated = await compute(generateRepasBoard, (config, seed));
      if (!mounted) return;
      _freeConfig = config;
      _startSession(
        RepasLevelDefinition(
          stage: widget.stages[seed.abs() % widget.stages.length],
          rows: generated.rows,
          parPushes: generated.parPushes,
          referenceSolution: generated.solution,
        ),
      );
    } on StateError {
      if (mounted) {
        _toast('Ce niveau ne peut pas être préparé. Réessaie.');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _move(RepasDirection direction) {
    final result = _session!.move(direction);
    if (result == RepasMoveResult.blocked) {
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast('Impossible de déplacer le soigneur dans cette direction.');
      return;
    }
    unawaited(
      _audio.playEffect(
        result == RepasMoveResult.pushed || result == RepasMoveResult.won
            ? SoundEffect.flag
            : SoundEffect.click,
      ),
    );
    setState(() {});
    if (result == RepasMoveResult.won) unawaited(_finish());
  }

  Future<void> _finish() async {
    unawaited(_audio.playEffect(SoundEffect.win));
    if (_freeConfig == null) {
      _newRecord = await widget.progress.completeLevel(
        _level!.number,
        _session!.pushes,
        _session!.footprints(),
      );
    }
    if (mounted) setState(() => _finished = true);
  }

  void _undo() {
    if (!_session!.undo()) return;
    unawaited(_audio.playEffect(SoundEffect.click));
    setState(() {});
  }

  Future<void> _requestRestart() async {
    if (_session!.hasMoved) {
      final restart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recommencer ce niveau ?'),
          content: const Text(
            'Les déplacements de cette partie seront perdus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Recommencer'),
            ),
          ],
        ),
      );
      if (restart != true) return;
    }
    _startSession(_level!);
  }

  Future<void> _requestLevels() async {
    if (_session?.status == RepasStatus.playing && _session!.hasMoved) {
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
      _screen = _RepasScreen.levels;
      _session = null;
    });
  }

  void _showCustom() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _RepasScreen.custom;
      _session = null;
    });
  }

  void _leaveCustom() {
    if (_generating) {
      _toast('Le niveau est en cours de préparation.');
      return;
    }
    _showLevels();
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
  Widget build(BuildContext context) => _handleBack(
    switch (_screen) {
      _RepasScreen.levels => widget.onExit,
      _RepasScreen.custom => _leaveCustom,
      _RepasScreen.playing => () => unawaited(_requestLevels()),
    },
    switch (_screen) {
      _RepasScreen.levels => RepasLevelSelectScreen(
        levels: _levels,
        store: widget.progress,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onBack: widget.onExit,
        onPlay: _start,
        onCustom: _showCustom,
        onToggleMusic: _toggleMusic,
        onToggleEffects: _toggleEffects,
        onQuit: widget.onQuit,
      ),
      _RepasScreen.custom => RepasCustomGameScreen(
        generating: _generating,
        onBack: _leaveCustom,
        onStart: (config) => unawaited(_startFree(config)),
      ),
      _RepasScreen.playing => RepasScreen(
        session: _session!,
        finished: _finished,
        newRecord: _newRecord,
        freeGameLabel: _freeConfig == null
            ? null
            : 'PARTIE LIBRE · ${_freeConfig!.difficulty.label}',
        onMove: _move,
        onUndo: _undo,
        onRestart: () => unawaited(_requestRestart()),
        onLevels: () => unawaited(_requestLevels()),
        onRetry: () => _startSession(_level!),
        onNew: _freeConfig == null
            ? null
            : () => unawaited(_startFree(_freeConfig!)),
        onConfigure: _freeConfig == null ? null : _showCustom,
        onNext: _freeConfig == null && _level!.number < _levels.length
            ? () => _start(_levels[_level!.number])
            : null,
      ),
    },
  );

  Widget _handleBack(VoidCallback onBack, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: child,
  );
}
