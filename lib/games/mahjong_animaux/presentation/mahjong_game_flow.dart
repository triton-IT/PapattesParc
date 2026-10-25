import '../../../shared/generation_service.dart';
import '../../../shared/generation_overlay.dart';
import '../../../shared/game_activity.dart';
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
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final MahjongProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<MahjongGameFlow> createState() => _MahjongGameFlowState();
}

class _MahjongGameFlowState extends State<MahjongGameFlow> {
  final GenerationService _generation = GenerationService();
  _MahjongScreen _screen = _MahjongScreen.levels;
  late final List<MahjongLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  MahjongLevelDefinition? _level;
  MahjongFreeGameConfig? _freeConfig;
  MahjongSession? _session;
  late final ActiveGameClock _clock;
  ActiveGameTimer? _hintTimer;
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
    _clock = ActiveGameClock(
      onTick: (delta) {
        if (_session?.status != MahjongStatus.playing) {
          return _session?.elapsed ?? Duration.zero;
        }
        _session!.tick(delta);
        return _session!.elapsed;
      },
    );
  }

  @override
  void dispose() {
    _generation.dispose();
    _clock.dispose();
    _hintTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
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

  Future<void> _startSession(
    MahjongLayoutDefinition layout,
    LevelBiome biome,
    AnimalTemperament temperament,
  ) async {
    try {
      final seed = _seed;
      final prepared = await _generation.mahjong(layout, biome, seed);
      if (!mounted) return;
      _session = MahjongSession(
        layout: layout,
        biome: biome,
        seed: seed,
        prepared: prepared,
      );
      _hintedIds = {};
      _finished = false;
      _newRecord = false;
      _clock.reset();
      unawaited(_audio.playLevel(temperament));
      setState(() => _screen = _MahjongScreen.playing);
    } on StaleGeneration {
      return;
    } catch (_) {
      if (mounted) _toast('Le niveau ne peut pas être préparé. Réessaie.');
    }
  }

  int _newSeed() => DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919;

  void _select(int id) {
    _clock.flush();
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
    _hintTimer = ActiveGameTimer(const Duration(seconds: 2), () {
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
    _generation.cancel();
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
  Widget build(BuildContext context) =>
      GenerationBoundary(service: _generation, child: _buildContents(context));

  Widget _buildContents(BuildContext context) => _handleBack(
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
        onQuit: widget.onQuit,
      ),
      _MahjongScreen.custom => MahjongCustomGameScreen(
        stages: widget.stages,
        onBack: _showLevels,
        onStart: _startFree,
      ),
      _MahjongScreen.playing => MahjongScreen(
        elapsed: _clock,
        session: _session!,
        backgroundAsset:
            (_level?.stage ??
                    widget.stages.firstWhere(
                      (stage) => stage.biome == _freeConfig!.biome,
                    ))
                .artAsset!,
        title: _freeConfig == null
            ? 'Niveau ${_level!.number} · ${_level!.stage.title}'
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
