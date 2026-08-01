import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/mahjong_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/mahjong_session.dart';
import '../domain/models.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';
import 'mahjong_screen.dart';

enum _MahjongScreen { levels, custom, playing }

class MahjongGameFlow extends StatefulWidget {
  const MahjongGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    super.key,
  });

  final List<ParkStage> stages;
  final MahjongProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;

  @override
  State<MahjongGameFlow> createState() => _MahjongGameFlowState();
}

class _MahjongGameFlowState extends State<MahjongGameFlow> {
  _MahjongScreen _screen = _MahjongScreen.levels;
  late final List<MahjongLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  MahjongLevelDefinition? _level;
  MahjongFreeGameConfig? _freeConfig;
  MahjongSession? _session;
  Timer? _ticker;
  Timer? _hintTimer;
  DateTime? _lastTick;
  Set<int> _hintedIds = {};
  bool _finished = false;
  bool _newRecord = false;
  int _seed = 0;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildMahjongCampaign(widget.stages);
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
    _hintTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null || _session?.status != MahjongStatus.playing) return;
    _session!.tick(now.difference(previous));
    if (mounted) setState(() {});
  }

  void _startLevel(MahjongLevelDefinition level) {
    _level = level;
    _freeConfig = null;
    _seed = _newSeed();
    _startSession(level.layout, level.stage.biome, level.stage.temperament);
  }

  void _startFree(MahjongFreeGameConfig config) {
    _level = null;
    _freeConfig = config;
    _seed = _newSeed();
    final temperament = widget.stages
        .firstWhere((stage) => stage.biome == config.biome)
        .temperament;
    _startSession(
      mahjongLayout(config.layoutId, config.difficulty),
      config.biome,
      temperament,
    );
  }

  void _startSession(
    MahjongLayoutDefinition layout,
    LevelBiome biome,
    AnimalTemperament temperament,
  ) {
    _session = MahjongSession(layout: layout, biome: biome, seed: _seed);
    _hintedIds = {};
    _finished = false;
    _newRecord = false;
    _lastTick = DateTime.now();
    unawaited(_audio.playLevel(temperament));
    setState(() => _screen = _MahjongScreen.playing);
  }

  int _newSeed() => DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919;

  void _select(int id) {
    final result = _session!.select(id);
    switch (result) {
      case MahjongSelectionResult.ignored:
        _blockedMessage();
      case MahjongSelectionResult.matched:
        unawaited(_audio.playEffect(SoundEffect.reveal));
        if (_session!.isBlocked) {
          _toast('Aucune paire libre. Utilise un mélange pour continuer.');
        }
      case MahjongSelectionResult.won || MahjongSelectionResult.lost:
        unawaited(_finish());
      case MahjongSelectionResult.selected ||
          MahjongSelectionResult.deselected ||
          MahjongSelectionResult.replaced:
        unawaited(_audio.playEffect(SoundEffect.click));
    }
    setState(() {});
  }

  void _hint() {
    final pair = _session!.hint();
    if (pair == null) return;
    _hintTimer?.cancel();
    setState(() => _hintedIds = {pair.first, pair.second});
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _hintedIds = {});
    });
  }

  void _shuffle() {
    if (!_session!.shuffle()) return;
    _hintTimer?.cancel();
    _hintedIds = {};
    unawaited(_audio.playEffect(SoundEffect.flag));
    setState(() {});
  }

  Future<void> _finish() async {
    final won = _session!.status == MahjongStatus.won;
    unawaited(_audio.playEffect(won ? SoundEffect.win : SoundEffect.lose));
    if (won) {
      _newRecord = _freeConfig == null
          ? await widget.progress.completeLevel(
              _level!.number,
              _session!.elapsed,
              _session!.footprints,
            )
          : await widget.progress.completeFreeGame(
              _freeConfig!,
              _session!.elapsed,
            );
    }
    if (mounted) setState(() => _finished = true);
  }

  void _replaySame() {
    final temperament =
        _level?.stage.temperament ??
        widget.stages
            .firstWhere((stage) => stage.biome == _freeConfig!.biome)
            .temperament;
    _startSession(_session!.layout, _session!.biome, temperament);
  }

  void _replayNew() {
    _seed = _newSeed();
    _replaySame();
  }

  void _nextLevel() => _startLevel(_levels[_level!.number]);

  Future<void> _requestBack() async {
    if (_session!.hasMoved && !_finished) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner cette partie ?'),
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
      _screen = _MahjongScreen.levels;
      _session = null;
    });
  }

  void _showCustom() => setState(() {
    _screen = _MahjongScreen.custom;
    _session = null;
  });

  void _blockedMessage() {
    unawaited(_audio.playEffect(SoundEffect.blocked));
    _toast('Cette tuile est encore bloquée.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
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
  Widget build(BuildContext context) => _handleBack(
    switch (_screen) {
      _MahjongScreen.levels => widget.onExit,
      _MahjongScreen.custom => _showLevels,
      _MahjongScreen.playing => () => unawaited(_requestBack()),
    },
    switch (_screen) {
      _MahjongScreen.levels => MahjongLevelSelectScreen(
        levels: _levels,
        store: widget.progress,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onBack: widget.onExit,
        onPlay: _startLevel,
        onCustom: () => setState(() => _screen = _MahjongScreen.custom),
        onToggleMusic: _toggleMusic,
        onToggleEffects: _toggleEffects,
      ),
      _MahjongScreen.custom => MahjongCustomGameScreen(
        onBack: _showLevels,
        onStart: _startFree,
      ),
      _MahjongScreen.playing => MahjongScreen(
        session: _session!,
        title: _freeConfig == null
            ? 'Niveau ${_level!.number} · ${_level!.layout.name}'
            : '${_session!.layout.name} · ${_session!.layout.difficulty.label}',
        isFreeGame: _freeConfig != null,
        hintedIds: _hintedIds,
        finished: _finished,
        newRecord: _newRecord,
        onSelect: _select,
        onBlocked: _blockedMessage,
        onHint: _hint,
        onShuffle: _shuffle,
        onBack: () => unawaited(_requestBack()),
        onReplaySame: _replaySame,
        onReplayNew: _replayNew,
        onLevels: _showLevels,
        onConfigure: _freeConfig == null ? null : _showCustom,
        onNext: _freeConfig == null && _level!.number < _levels.length
            ? _nextLevel
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
