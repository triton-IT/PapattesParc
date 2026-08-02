import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/sudoku_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';
import '../domain/sudoku_session.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';
import 'sudoku_screen.dart';

enum _SudokuScreen { levels, custom, playing }

class SudokuGameFlow extends StatefulWidget {
  const SudokuGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final SudokuProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<SudokuGameFlow> createState() => _SudokuGameFlowState();
}

class _SudokuGameFlowState extends State<SudokuGameFlow> {
  _SudokuScreen _screen = _SudokuScreen.levels;
  late final List<SudokuLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  SudokuLevelDefinition? _level;
  SudokuFreeGameConfig? _freeConfig;
  SudokuSession? _session;
  Timer? _ticker;
  Timer? _wrongTimer;
  DateTime? _lastTick;
  int? _selectedIndex;
  int? _wrongIndex;
  bool _noteMode = false;
  bool _finished = false;
  bool _newRecord = false;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildSudokuCampaign(widget.stages);
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
    _wrongTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null || _session?.status != SudokuStatus.playing) return;
    _session!.tick(now.difference(previous));
    if (mounted) setState(() {});
  }

  void _startLevel(SudokuLevelDefinition level) {
    _freeConfig = null;
    _startSession(level);
  }

  void _startFree(SudokuFreeGameConfig config) {
    _freeConfig = config;
    _startNewFreeGame();
  }

  void _startNewFreeGame() {
    final config = _freeConfig!;
    final stage = widget.stages.firstWhere(
      (stage) => stage.biome == config.biome,
    );
    _startSession(
      buildFreeSudokuLevel(
        stage,
        config,
        DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919,
      ),
    );
  }

  void _startSession(SudokuLevelDefinition level) {
    _level = level;
    _session = SudokuSession(level);
    _selectedIndex = null;
    _wrongIndex = null;
    _noteMode = false;
    _finished = false;
    _newRecord = false;
    _lastTick = DateTime.now();
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _SudokuScreen.playing);
  }

  void _selectCell(int index) => setState(() {
    _selectedIndex = index;
    if (_session!.entries[index] != null) _noteMode = false;
  });

  void _selectAnimal(int animal) {
    final index = _selectedIndex!;
    if (_noteMode && _session!.entries[index] == null) {
      _session!.toggleNote(index, animal);
      unawaited(_audio.playEffect(SoundEffect.flag));
      setState(() {});
      return;
    }
    final result = _session!.place(index, animal);
    if (result == SudokuPlacementResult.wrong) {
      _reject(index);
      return;
    }
    unawaited(_audio.playEffect(SoundEffect.click));
    if (result == SudokuPlacementResult.won) unawaited(_finish());
    setState(() {});
  }

  void _reject(int index) {
    _wrongTimer?.cancel();
    setState(() => _wrongIndex = index);
    unawaited(_audio.playEffect(SoundEffect.blocked));
    _toast(
      'Ce n’est pas cet animal. Observe la ligne, la colonne et l’enclos.',
    );
    _wrongTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _wrongIndex = null);
    });
  }

  void _toggleNotes() => setState(() {
    if (_session!.entries[_selectedIndex!] == null) _noteMode = !_noteMode;
  });

  void _clear() {
    _session!.clear(_selectedIndex!);
    setState(() {});
  }

  void _hint() {
    final target = _session!.hint(_selectedIndex);
    if (target == null) return;
    _selectedIndex = target;
    _noteMode = false;
    unawaited(_audio.playEffect(SoundEffect.reveal));
    if (_session!.status == SudokuStatus.won) unawaited(_finish());
    setState(() {});
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    if (_freeConfig == null) {
      final previous = widget.progress.bestTime(_level!.number);
      _newRecord = previous == null || _session!.elapsed < previous;
      await widget.progress.completeLevel(
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
      _screen = _SudokuScreen.levels;
      _session = null;
    });
  }

  void _showCustom() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _SudokuScreen.custom;
      _session = null;
    });
  }

  void _openCustom() {
    _freeConfig = null;
    _showCustom();
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
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      switch (_screen) {
        case _SudokuScreen.levels:
          widget.onExit();
        case _SudokuScreen.custom:
          _showLevels();
        case _SudokuScreen.playing:
          unawaited(_requestBack());
      }
    },
    child: switch (_screen) {
      _SudokuScreen.levels => SudokuLevelSelectScreen(
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
      _SudokuScreen.custom => SudokuCustomGameScreen(
        stages: widget.stages,
        initialConfig: _freeConfig,
        onBack: _showLevels,
        onStart: _startFree,
      ),
      _SudokuScreen.playing => SudokuScreen(
        session: _session!,
        selectedIndex: _selectedIndex,
        noteMode: _noteMode,
        wrongIndex: _wrongIndex,
        finished: _finished,
        newRecord: _newRecord,
        isFreeGame: _freeConfig != null,
        onSelectCell: _selectCell,
        onSelectAnimal: _selectAnimal,
        onToggleNotes: _toggleNotes,
        onClear: _clear,
        onHint: _hint,
        onBack: () => unawaited(_requestBack()),
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
