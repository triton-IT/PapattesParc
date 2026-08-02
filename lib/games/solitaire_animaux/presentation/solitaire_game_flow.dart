import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/game_audio.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/settings_store.dart';
import '../data/solitaire_progress_store.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';
import '../domain/solitaire_session.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'setup_screen.dart';

enum _SolitaireScreen { levels, setup, playing }

class SolitaireGameFlow extends StatefulWidget {
  const SolitaireGameFlow({
    required this.stages,
    required this.progress,
    required this.settings,
    required this.onExit,
    this.onQuit,
    super.key,
  });

  final List<ParkStage> stages;
  final SolitaireProgressStore progress;
  final SettingsStore settings;
  final VoidCallback onExit;
  final VoidCallback? onQuit;

  @override
  State<SolitaireGameFlow> createState() => _SolitaireGameFlowState();
}

class _SolitaireGameFlowState extends State<SolitaireGameFlow> {
  _SolitaireScreen _screen = _SolitaireScreen.levels;
  late final List<SolitaireLevelDefinition> _levels;
  late SolitaireMode _mode;
  late AnimalKind _animal;
  late bool _musicEnabled;
  late bool _effectsEnabled;
  late final GameAudio _audio;
  SolitaireSession? _session;
  SolitaireLevelDefinition? _level;
  CardLocation? _selected;
  SolitaireHint? _hint;
  Timer? _ticker;
  Timer? _hintTimer;
  bool _finished = false;
  bool _autoFinishing = false;
  bool _newRecord = false;
  int _footprints = 0;
  int _nonce = 0;

  @override
  void initState() {
    super.initState();
    _levels = buildSolitaireCampaign(widget.stages);
    _mode = widget.progress.mode;
    _animal = widget.progress.backAnimal;
    _musicEnabled = widget.settings.musicEnabled;
    _effectsEnabled = widget.settings.effectsEnabled;
    _audio = GameAudio(
      musicEnabled: _musicEnabled,
      effectsEnabled: _effectsEnabled,
    );
    unawaited(_audio.initialize());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_autoFinishing || _session?.status != SolitaireStatus.playing) return;
      setState(() => _session!.tick(const Duration(seconds: 1)));
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hintTimer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_screen) {
    _SolitaireScreen.levels => _handleBack(
      widget.onExit,
      SolitaireLevelSelectScreen(
        levels: _levels,
        store: widget.progress,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onBack: widget.onExit,
        onPlay: _startLevel,
        onCustom: _showSetup,
        onToggleMusic: () => unawaited(_toggleMusic()),
        onToggleEffects: () => unawaited(_toggleEffects()),
        onQuit: widget.onQuit,
      ),
    ),
    _SolitaireScreen.setup => _handleBack(
      _showLevels,
      SolitaireSetupScreen(
        progress: widget.progress,
        mode: _mode,
        animal: _animal,
        musicEnabled: _musicEnabled,
        effectsEnabled: _effectsEnabled,
        onModeChanged: _setMode,
        onAnimalChanged: _setAnimal,
        onToggleMusic: () => unawaited(_toggleMusic()),
        onToggleEffects: () => unawaited(_toggleEffects()),
        onStart: _startFreeGame,
        onExit: _showLevels,
      ),
    ),
    _SolitaireScreen.playing => _handleBack(
      () => unawaited(_requestBack()),
      AbsorbPointer(
        absorbing: _autoFinishing,
        child: SolitaireGameScreen(
          session: _session!,
          backAnimal: _animal,
          backgroundAsset: _level?.stage.artAsset ?? _animal.backgroundAsset,
          level: _level,
          footprints: _footprints,
          selected: _selected,
          hint: _hint,
          finished: _finished,
          newRecord: _newRecord,
          onDraw: _draw,
          onCardTap: _tapCard,
          onDoubleTap: _autoFoundation,
          onMove: _move,
          onUndo: _undo,
          onHint: _showHint,
          onBack: () => unawaited(_requestBack()),
          onNewGame: () => unawaited(_requestReplay()),
          onReplay: _replay,
          onConfigure: _level == null ? _showSetup : null,
          onLevels: _showLevels,
          onNext: _nextLevel,
        ),
      ),
    ),
  };

  void _setMode(SolitaireMode value) {
    setState(() => _mode = value);
    unawaited(widget.progress.setMode(value));
  }

  void _setAnimal(AnimalKind value) {
    setState(() => _animal = value);
    unawaited(widget.progress.setBackAnimal(value));
    unawaited(_audio.playEffect(SoundEffect.click));
  }

  void _startLevel(SolitaireLevelDefinition level) {
    _level = level;
    _mode = level.mode;
    _startSession(level.seed);
  }

  void _startFreeGame() {
    unawaited(widget.progress.setMode(_mode));
    unawaited(widget.progress.setBackAnimal(_animal));
    _level = null;
    _startSession(_newSeed());
  }

  void _startSession(int seed) {
    _session = SolitaireSession(mode: _mode, seed: seed);
    _selected = null;
    _hint = null;
    _finished = false;
    _autoFinishing = false;
    _newRecord = false;
    _footprints = 0;
    unawaited(
      _audio.playLevel(_level?.stage.temperament ?? AnimalTemperament.peaceful),
    );
    setState(() => _screen = _SolitaireScreen.playing);
  }

  int _newSeed() => DateTime.now().millisecondsSinceEpoch + ++_nonce * 7919;

  void _draw() {
    if (!_session!.draw()) return;
    _clearSelection();
    unawaited(_audio.playEffect(SoundEffect.reveal));
    setState(() {});
  }

  void _tapCard(CardLocation location) {
    final current = _selected;
    if (current != null) {
      if (current == location) {
        setState(_clearSelection);
        return;
      }
      final target = switch (location.area) {
        CardArea.tableau => CardLocation.tableau(location.pile, -1),
        CardArea.foundation => location,
        _ => null,
      };
      if (target != null) {
        final move = SolitaireMove(current, target);
        if (_session!.canMove(move)) {
          _move(move);
          return;
        }
      }
    }
    if (_isSource(location)) {
      setState(() {
        _selected = location;
        _hint = null;
      });
      unawaited(_audio.playEffect(SoundEffect.click));
      return;
    }
    _blocked('Cette carte ne peut pas être déplacée ici.');
  }

  bool _isSource(CardLocation location) => switch (location.area) {
    CardArea.waste => _session!.waste.isNotEmpty,
    CardArea.foundation => _session!.foundations[location.pile].isNotEmpty,
    CardArea.tableau =>
      location.card >= 0 &&
          _session!.tableau[location.pile][location.card].faceUp,
    CardArea.stock => false,
  };

  void _autoFoundation(CardLocation source) {
    if (!_session!.moveToFoundation(source)) {
      _blocked(
        'La fondation attend une carte plus petite de la même enseigne.',
      );
      return;
    }
    _afterMove();
  }

  void _move(SolitaireMove move) {
    if (!_session!.move(move)) {
      _blocked(
        'Alterne les couleurs en ordre décroissant. Seul un roi ouvre une colonne.',
      );
      return;
    }
    _afterMove();
  }

  void _afterMove() {
    _clearSelection();
    unawaited(_audio.playEffect(SoundEffect.click));
    if (_session!.status == SolitaireStatus.won) {
      unawaited(_finish());
      setState(() {});
      return;
    }
    setState(() {});
    unawaited(_startAutoFinish());
  }

  Future<void> _startAutoFinish() async {
    final session = _session!;
    if (!session.prepareAutoFinish()) return;
    setState(() => _autoFinishing = true);
    _toast('Finition automatique…');
    while (mounted && identical(_session, session) && _autoFinishing) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted || !identical(_session, session) || !_autoFinishing) return;
      if (!session.autoFinishStep()) break;
      setState(() {});
    }
    if (!mounted || !identical(_session, session)) return;
    _autoFinishing = false;
    if (session.status == SolitaireStatus.won) await _finish();
  }

  void _undo() {
    if (!_session!.undo()) return;
    _clearSelection();
    unawaited(_audio.playEffect(SoundEffect.click));
    setState(() {});
  }

  void _showHint() {
    final value = _session!.hint();
    if (value == null) {
      unawaited(_showBlockedGame());
      return;
    }
    _hintTimer?.cancel();
    setState(() => _hint = value);
    _toast(value.message);
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    final level = _level;
    if (level == null) {
      _newRecord = await widget.progress.complete(_mode, _session!.elapsed);
    } else {
      _footprints = solitaireFootprints(level, _session!.redealCount);
      _newRecord = await widget.progress.completeLevel(
        level.number,
        _session!.elapsed,
        _footprints,
      );
    }
    unawaited(_audio.playEffect(SoundEffect.win));
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() => _finished = true);
    }
  }

  Future<void> _requestBack() async {
    if (_autoFinishing) return;
    if (_session!.hasMoved && !_finished && !await _confirmAbandon()) return;
    _level == null ? _showSetup() : _showLevels();
  }

  Future<void> _requestReplay() async {
    if (_autoFinishing) return;
    if (_session!.hasMoved && !_finished && !await _confirmAbandon()) return;
    _replay();
  }

  Future<bool> _confirmAbandon() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner cette partie ?'),
          content: const Text('La progression de cette donne sera perdue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abandonner'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showBlockedGame() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Aucun mouvement utile'),
      content: const Text(
        'Cette donne est bloquée. Annule un coup ou commence une nouvelle donne.',
      ),
      actions: [
        if (_session!.canUndo)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _undo();
            },
            child: const Text('Annuler un coup'),
          ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _replay();
          },
          child: const Text('Nouvelle donne'),
        ),
      ],
    ),
  );

  void _showSetup() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _SolitaireScreen.setup;
      _session = null;
      _autoFinishing = false;
      _clearSelection();
    });
  }

  void _showLevels() {
    unawaited(_audio.playHome());
    setState(() {
      _screen = _SolitaireScreen.levels;
      _session = null;
      _level = null;
      _autoFinishing = false;
      _clearSelection();
    });
  }

  void _replay() {
    final level = _level;
    if (level == null) {
      _startFreeGame();
      return;
    }
    _startSession(level.seed);
  }

  VoidCallback? get _nextLevel {
    final level = _level;
    if (level == null || level.number >= _levels.length) return null;
    return () => _startLevel(_levels[level.number]);
  }

  void _clearSelection() {
    _selected = null;
    _hint = null;
    _hintTimer?.cancel();
  }

  void _blocked(String message) {
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

  Widget _handleBack(VoidCallback onBack, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: child,
  );
}
