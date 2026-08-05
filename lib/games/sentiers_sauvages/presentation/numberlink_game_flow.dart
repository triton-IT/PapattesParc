import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/numberlink_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';
import '../domain/numberlink_session.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';
import 'numberlink_screen.dart';

enum _NumberlinkScreen { levels, custom, playing }

class NumberlinkGameFlow extends StatefulWidget {
  const NumberlinkGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final NumberlinkProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<NumberlinkGameFlow> createState() => _NumberlinkGameFlowState();
}

class _NumberlinkGameFlowState extends State<NumberlinkGameFlow> {
  _NumberlinkScreen _screen = _NumberlinkScreen.levels;
  late final List<NumberlinkLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  NumberlinkLevelDefinition? _level;
  NumberlinkFreeGameConfig? _freeConfig;
  NumberlinkSession? _session;
  Timer? _ticker;
  DateTime? _lastTick;
  bool _finished = false;
  bool _newRecord = false;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildNumberlinkCampaign(widget.stages);
    _musicEnabled = widget.settings.musicEnabled;
    _effectsEnabled = widget.settings.effectsEnabled;
    _audio = GameAudio(
      musicEnabled: _musicEnabled,
      effectsEnabled: _effectsEnabled,
    );
    unawaited(_audio.initialize());
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null || _session?.status != NumberlinkStatus.playing) {
      return;
    }
    _session!.tick(now.difference(previous));
    if (mounted && _session!.hasStarted) setState(() {});
  }

  void _startLevel(NumberlinkLevelDefinition level) {
    _freeConfig = null;
    _startSession(level);
  }

  void _startFree(NumberlinkFreeGameConfig config) {
    _freeConfig = config;
    _startNewFreeGame();
  }

  void _startNewFreeGame() {
    final config = _freeConfig!;
    final stage = widget.stages.firstWhere(
      (stage) => stage.biome == config.biome,
    );
    _startSession(
      buildFreeNumberlinkLevel(
        stage,
        config,
        DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919,
      ),
    );
  }

  void _startSession(NumberlinkLevelDefinition level) {
    _level = level;
    _session = NumberlinkSession(level);
    _finished = false;
    _newRecord = false;
    _lastTick = DateTime.now();
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _NumberlinkScreen.playing);
  }

  NumberlinkTraceResult _begin(NumberlinkPosition position) {
    final result = _session!.begin(position);
    if (result == NumberlinkTraceResult.blocked) {
      _reject(
        _coverageMessage ??
            'Commence sur un animal, son enclos ou un sentier déjà tracé.',
      );
    } else {
      unawaited(_audio.playEffect(SoundEffect.click));
      setState(() {});
    }
    return result;
  }

  NumberlinkTraceResult _trace(NumberlinkPosition position) {
    final result = _session!.trace(position);
    switch (result) {
      case NumberlinkTraceResult.blocked:
        _reject(
          _coverageMessage ??
              'Impossible : évite les autres sentiers et rejoins le bon enclos.',
        );
      case NumberlinkTraceResult.connected:
        unawaited(_audio.playEffect(SoundEffect.animalFound));
        if (_coverageMessage case final message?) _toast(message);
        setState(() {});
      case NumberlinkTraceResult.won:
        unawaited(_finish());
        setState(() {});
      case NumberlinkTraceResult.retracted:
        unawaited(_audio.playEffect(SoundEffect.click));
        setState(() {});
      case NumberlinkTraceResult.extended:
        setState(() {});
      case NumberlinkTraceResult.started:
        setState(() {});
    }
    return result;
  }

  void _endTrace() => _session!.endTrace();

  void _hint() {
    final pairId = _session!.hint();
    if (pairId == null) {
      _toast('Aucun nouvel indice disponible.');
      return;
    }
    unawaited(_audio.playEffect(SoundEffect.reveal));
    setState(() {});
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    if (_freeConfig == null) {
      _newRecord = await widget.progress.completeLevel(
        _level!.number,
        _session!.elapsed,
        _session!.footprints,
      );
    }
    unawaited(_audio.playEffect(SoundEffect.win));
    if (mounted) setState(() {});
  }

  void _nextLevel() => _startLevel(_levels[_level!.number]);

  Future<void> _requestBack() async {
    if (_session!.hasMoved && !_finished) {
      final leave = await _confirm(
        title: 'Abandonner cette partie ?',
        message: 'Les sentiers tracés seront perdus.',
        confirmLabel: 'Quitter',
      );
      if (!leave) return;
    }
    _freeConfig == null ? _showLevels() : _showCustom();
  }

  Future<void> _requestRestart() async {
    if (_session!.hasMoved && !_finished) {
      final restart = await _confirm(
        title: 'Recommencer cette partie ?',
        message: 'Tous les sentiers tracés seront effacés.',
        confirmLabel: 'Recommencer',
      );
      if (!restart) return;
    }
    _startSession(_level!);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  void _showLevels() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _NumberlinkScreen.levels;
      _session = null;
    });
  }

  void _showCustom() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _NumberlinkScreen.custom;
      _session = null;
    });
  }

  void _openCustom() {
    _freeConfig = null;
    _showCustom();
  }

  void _reject(String message) {
    unawaited(_audio.playEffect(SoundEffect.blocked));
    _toast(message);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  String? get _coverageMessage {
    final session = _session!;
    if (session.completedPairs != session.level.pairCount ||
        session.remainingCells == 0) {
      return null;
    }
    final plural = session.remainingCells > 1 ? 's' : '';
    return 'Tous les sentiers sont reliés, mais il reste '
        '${session.remainingCells} case$plural libre$plural. '
        'Reprends un sentier pour les couvrir.';
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      switch (_screen) {
        case _NumberlinkScreen.levels:
          widget.onExit();
        case _NumberlinkScreen.custom:
          _showLevels();
        case _NumberlinkScreen.playing:
          unawaited(_requestBack());
      }
    },
    child: switch (_screen) {
      _NumberlinkScreen.levels => NumberlinkLevelSelectScreen(
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
      _NumberlinkScreen.custom => NumberlinkCustomGameScreen(
        stages: widget.stages,
        initialConfig: _freeConfig,
        onBack: _showLevels,
        onStart: _startFree,
      ),
      _NumberlinkScreen.playing => NumberlinkScreen(
        session: _session!,
        finished: _finished,
        newRecord: _newRecord,
        isFreeGame: _freeConfig != null,
        onBegin: _begin,
        onTrace: _trace,
        onEndTrace: _endTrace,
        onHint: _hint,
        onBack: () => unawaited(_requestBack()),
        onRestart: () => unawaited(_requestRestart()),
        onReplay: () => _startSession(_level!),
        onLevels: _showLevels,
        onNext: _freeConfig == null && _level!.number < _levels.length
            ? _nextLevel
            : null,
        onNewGame: _freeConfig == null ? null : _startNewFreeGame,
        onConfigure: _freeConfig == null ? null : _showCustom,
      ),
    },
  );
}
