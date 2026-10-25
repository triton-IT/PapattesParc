import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/animal_sort_progress_store.dart';
import '../domain/animal_sort_session.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';
import 'animal_sort_screen.dart';
import 'custom_game_screen.dart';
import 'level_select_screen.dart';

enum _AnimalSortScreen { levels, custom, playing }

class AnimalSortGameFlow extends StatefulWidget {
  const AnimalSortGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final AnimalSortProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<AnimalSortGameFlow> createState() => _AnimalSortGameFlowState();
}

class _AnimalSortGameFlowState extends State<AnimalSortGameFlow> {
  _AnimalSortScreen _screen = _AnimalSortScreen.levels;
  late final List<AnimalSortLevelDefinition> _levels;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  AnimalSortLevelDefinition? _level;
  AnimalSortFreeGameConfig? _freeConfig;
  AnimalSortSession? _session;
  AnimalSortMove? _hintMove;
  int? _selectedZone;
  bool _finished = false;
  bool _newRecord = false;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildAnimalSortCampaign(widget.stages);
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

  void _startLevel(AnimalSortLevelDefinition level) {
    _freeConfig = null;
    _startSession(level);
  }

  void _startFree(AnimalSortFreeGameConfig config) {
    _freeConfig = config;
    final stage = widget.stages.firstWhere(
      (stage) => stage.biome == config.biome,
    );
    _startSession(
      buildAnimalSortLevel(
        stage,
        speciesCount: config.speciesCount,
        seed: DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919,
      ),
    );
  }

  void _startSession(AnimalSortLevelDefinition level) {
    _level = level;
    _session = AnimalSortSession(level);
    _selectedZone = null;
    _hintMove = null;
    _finished = false;
    _newRecord = false;
    unawaited(_audio.playLevel(level.stage.temperament));
    setState(() => _screen = _AnimalSortScreen.playing);
  }

  void _tapZone(int index) {
    final session = _session!;
    if (_selectedZone == null) {
      if (session.zones[index].isEmpty) {
        _reject('Choisis d’abord une réserve contenant de la nourriture.');
        return;
      }
      setState(() {
        _selectedZone = index;
        _hintMove = null;
      });
      unawaited(_audio.playEffect(SoundEffect.click));
      return;
    }
    if (_selectedZone == index) {
      setState(() => _selectedZone = null);
      return;
    }
    final result = session.move(_selectedZone!, index);
    if (result == AnimalSortMoveResult.blocked) {
      _reject(
        session.zones[index].length == animalSortZoneCapacity
            ? 'Cette réserve est pleine.'
            : 'Ces portions ne peuvent rejoindre que le même repas ou une réserve vide.',
      );
      return;
    }
    _selectedZone = null;
    _hintMove = null;
    if (result == AnimalSortMoveResult.won) {
      unawaited(_finish());
    } else {
      unawaited(_audio.playEffect(SoundEffect.animalFound));
    }
    setState(() {});
  }

  void _undo() {
    if (!_session!.undo()) return;
    _selectedZone = null;
    _hintMove = null;
    _finished = false;
    unawaited(_audio.playEffect(SoundEffect.click));
    setState(() {});
  }

  void _hint() {
    final move = _session!.hint();
    if (move == null) {
      _toast(
        _session!.hintsRemaining == 0
            ? 'Les trois indices ont déjà été utilisés.'
            : 'Annule le dernier déplacement pour revenir à une solution connue.',
      );
      return;
    }
    _selectedZone = null;
    _hintMove = move;
    unawaited(_audio.playEffect(SoundEffect.reveal));
    setState(() {});
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    if (_freeConfig == null) {
      _newRecord = await widget.progress.completeLevel(
        _level!.number,
        _session!.moves,
        _session!.footprints(),
      );
    }
    unawaited(_audio.playEffect(SoundEffect.win));
    if (mounted) setState(() {});
  }

  Future<void> _requestBack() async {
    if (_session!.hasMoved && !_finished) {
      final leave = await _confirm(
        'Quitter cette partie ?',
        'Les regroupements en cours seront perdus.',
        'Quitter',
      );
      if (!leave) return;
    }
    _freeConfig == null ? _showLevels() : _showCustom();
  }

  Future<void> _requestRestart() async {
    if (_session!.hasMoved && !_finished) {
      final restart = await _confirm(
        'Recommencer cette partie ?',
        'Tous les déplacements seront effacés.',
        'Recommencer',
      );
      if (!restart) return;
    }
    _startSession(_level!);
  }

  Future<bool> _confirm(String title, String message, String label) async =>
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
              child: Text(label),
            ),
          ],
        ),
      ) ??
      false;

  void _showLevels() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _AnimalSortScreen.levels;
      _session = null;
    });
  }

  void _showCustom() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _AnimalSortScreen.custom;
      _session = null;
    });
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
        case _AnimalSortScreen.levels:
          widget.onExit();
        case _AnimalSortScreen.custom:
          _showLevels();
        case _AnimalSortScreen.playing:
          unawaited(_requestBack());
      }
    },
    child: switch (_screen) {
      _AnimalSortScreen.levels => AnimalSortLevelSelectScreen(
        levels: _levels,
        store: widget.progress,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onBack: widget.onExit,
        onPlay: _startLevel,
        onCustom: _showCustom,
        onToggleMusic: _toggleMusic,
        onToggleEffects: _toggleEffects,
        onQuit: widget.onQuit,
      ),
      _AnimalSortScreen.custom => AnimalSortCustomGameScreen(
        stages: widget.stages,
        initialConfig: _freeConfig,
        onBack: _showLevels,
        onStart: _startFree,
      ),
      _AnimalSortScreen.playing => AnimalSortScreen(
        session: _session!,
        selectedZone: _selectedZone,
        hintMove: _hintMove,
        finished: _finished,
        newRecord: _newRecord,
        freeGame: _freeConfig != null,
        onTapZone: _tapZone,
        onUndo: _undo,
        onHint: _hint,
        onBack: () => unawaited(_requestBack()),
        onRestart: () => unawaited(_requestRestart()),
        onReplay: () => _startSession(_level!),
        onLevels: _showLevels,
        onNext: _freeConfig == null && _level!.number < _levels.length
            ? () => _startLevel(_levels[_level!.number])
            : null,
        onNewGame: _freeConfig == null ? null : () => _startFree(_freeConfig!),
        onConfigure: _freeConfig == null ? null : _showCustom,
      ),
    },
  );
}
