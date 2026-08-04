import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';
import '../domain/board_generator.dart';
import '../domain/game_session.dart';
import '../domain/levels.dart';
import '../domain/models.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/game_audio.dart';
import 'custom_game_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';

export 'game_screen.dart' show BoardView;

const _applicationChannel = MethodChannel('papatte_parc/application');

enum _Screen { home, custom, playing, generating, finished }

class RefugeGameFlow extends StatefulWidget {
  const RefugeGameFlow({required this.store, required this.onExit, super.key});

  final ProgressStore store;
  final VoidCallback onExit;

  @override
  State<RefugeGameFlow> createState() => _RefugeGameFlowState();
}

class _RefugeGameFlowState extends State<RefugeGameFlow> {
  _Screen _screen = _Screen.home;
  late int _selectedLevelIndex;
  int _generationNonce = 0;
  GameSession? _session;
  GeneratedBoard? _board;
  LevelDefinition? _level;
  Timer? _timer;
  DateTime? _lastTick;
  bool _newRecord = false;
  late final GameAudio _audio;
  late bool _musicEnabled;
  late bool _effectsEnabled;

  @override
  void initState() {
    super.initState();
    _selectedLevelIndex = widget.store.unlockedLevel - 1;
    _musicEnabled = widget.store.musicEnabled;
    _effectsEnabled = widget.store.effectsEnabled;
    _audio = GameAudio(
      musicEnabled: _musicEnabled,
      effectsEnabled: _effectsEnabled,
    );
    unawaited(_audio.initialize());
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null || _session?.status != GameStatus.running) return;
    _session!.tick(now.difference(previous));
    if (mounted) setState(() {});
  }

  void _startSelectedLevel() {
    _level = levels[_selectedLevelIndex];
    unawaited(_audio.playLevel(_level!.temperament));
    _board = null;
    _session = GameSession(_level!.config);
    _lastTick = DateTime.now();
    setState(() => _screen = _Screen.playing);
  }

  void _startLevel(int index) {
    _selectedLevelIndex = index;
    _startSelectedLevel();
  }

  void _startCustomLevel(LevelDefinition level) {
    _level = level;
    unawaited(_audio.playLevel(level.temperament));
    _board = null;
    _session = GameSession(level.config);
    _lastTick = DateTime.now();
    setState(() => _screen = _Screen.playing);
  }

  Future<void> _reveal(CellPosition position) async {
    if (_screen != _Screen.playing) return;
    if (_session!.status == GameStatus.waitingFirstMove) {
      await _generateBoard(position);
      return;
    }
    _session!.reveal(position);
    if (_session!.status == GameStatus.running) {
      unawaited(_audio.playEffect(SoundEffect.reveal));
    }
    await _refreshAfterMove();
  }

  Future<void> _toggleFlag(CellPosition position) async {
    if (_screen != _Screen.playing) return;
    if (_session!.status == GameStatus.waitingFirstMove) {
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast('La première action doit révéler une case.');
      return;
    }
    final result = _session!.toggleFlag(position);
    if (result == FlagResult.limitReached) {
      unawaited(_audio.playEffect(SoundEffect.blocked));
      _toast('Toutes les balises sont déjà placées.');
    }
    if (result == FlagResult.changed) {
      if (_session!.status == GameStatus.running) {
        final cell = _session!.cell(position);
        final effect = cell.isFlagged && cell.isAnimal
            ? SoundEffect.animalFound
            : SoundEffect.flag;
        unawaited(_audio.playEffect(effect));
      }
      await _refreshAfterMove();
    }
  }

  Future<void> _generateBoard(CellPosition firstMove) async {
    setState(() => _screen = _Screen.generating);
    final config = _level!.config;
    final seed =
        DateTime.now().millisecondsSinceEpoch + ++_generationNonce * 7919;
    final board = await compute(
      generateBoard,
      BoardGenerationRequest(config, firstMove, seed),
    );
    if (!mounted) return;
    if (board == null) {
      _showHome();
      _toast('Ce refuge ne peut pas être préparé. Réessaie la mission.');
      return;
    }
    _board = board;
    _session!.prepare(board, practice: false);
    unawaited(_audio.playEffect(SoundEffect.reveal));
    _lastTick = DateTime.now();
    setState(() => _screen = _Screen.playing);
    await _refreshAfterMove();
  }

  Future<void> _refreshAfterMove() async {
    if (_session!.status == GameStatus.won ||
        _session!.status == GameStatus.lost) {
      await _finishGame();
    } else {
      setState(() {});
    }
  }

  Future<void> _finishGame() async {
    final won = _session!.status == GameStatus.won;
    unawaited(_audio.playEffect(won ? SoundEffect.win : SoundEffect.lose));
    _newRecord =
        won &&
        !_level!.isCustom &&
        !_session!.isPractice &&
        await widget.store.saveIfBetter(_level!, _session!.elapsed);
    if (won && !_level!.isCustom) {
      await widget.store.unlockAfter(_level!.number);
    }
    if (mounted) setState(() => _screen = _Screen.finished);
  }

  void _replaySameBoard() {
    _session = GameSession(_level!.config)
      ..prepare(_board!, practice: !_level!.isCustom);
    _lastTick = DateTime.now();
    setState(() => _screen = _Screen.playing);
  }

  void _replayNewBoard() {
    _board = null;
    _session = GameSession(_level!.config);
    _lastTick = DateTime.now();
    setState(() => _screen = _Screen.playing);
  }

  void _startNextLevel() {
    _selectedLevelIndex = _level!.number;
    _startSelectedLevel();
  }

  void _showHome() {
    if (_level != null && !_level!.isCustom) {
      _selectedLevelIndex = _level!.number - 1;
    }
    setState(() => _screen = _Screen.home);
    unawaited(_audio.playHome());
  }

  Future<void> _toggleMusic() async {
    final enabled = !_musicEnabled;
    setState(() => _musicEnabled = enabled);
    await widget.store.setMusicEnabled(enabled);
    await _audio.setMusicEnabled(enabled);
  }

  Future<void> _toggleEffects() async {
    final enabled = !_effectsEnabled;
    setState(() => _effectsEnabled = enabled);
    await widget.store.setEffectsEnabled(enabled);
    _audio.setEffectsEnabled(enabled);
  }

  Future<void> _quit() => _applicationChannel.invokeMethod<void>('quit');

  Future<void> _requestHome() async {
    if (_session?.status == GameStatus.running) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abandonner la partie en cours ?'),
          actions: [
            FilledButton(
              onPressed: () {
                _playClick();
                Navigator.pop(context, false);
              },
              child: const Text('Continuer'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                _playClick();
                Navigator.pop(context, true);
              },
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (leave != true) return;
    }
    _showHome();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  void _playClick() {
    unawaited(_audio.playEffect(SoundEffect.click));
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == _Screen.home) {
      return _handleBack(
        widget.onExit,
        HomeScreen(
          levelIndex: _selectedLevelIndex,
          store: widget.store,
          onSelectLevel: (index) => setState(() => _selectedLevelIndex = index),
          onPlayLevel: _startLevel,
          onCreateCustom: () => setState(() => _screen = _Screen.custom),
          musicEnabled: _musicEnabled,
          onToggleMusic: _toggleMusic,
          effectsEnabled: _effectsEnabled,
          onToggleEffects: _toggleEffects,
          onButtonClick: _playClick,
          onGames: widget.onExit,
          onQuit: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
              ? _quit
              : null,
        ),
      );
    }
    if (_screen == _Screen.custom) {
      return _handleBack(
        _showHome,
        CustomGameScreen(
          onBack: _showHome,
          onStart: _startCustomLevel,
          onButtonClick: _playClick,
        ),
      );
    }
    return _handleBack(
      _requestGameBack,
      GameScreen(
        level: _level!,
        session: _session!,
        generating: _screen == _Screen.generating,
        finished: _screen == _Screen.finished,
        newRecord: _newRecord,
        onHome: () {
          _playClick();
          unawaited(_requestHome());
        },
        onReveal: _reveal,
        onFlag: _toggleFlag,
        onReplaySame: () {
          _playClick();
          _replaySameBoard();
        },
        onReplayNew: () {
          _playClick();
          _replayNewBoard();
        },
        onNext: () {
          _playClick();
          _startNextLevel();
        },
      ),
    );
  }

  void _requestGameBack() {
    if (_screen == _Screen.generating) {
      _toast('Le refuge est en cours de préparation.');
      return;
    }
    unawaited(_requestHome());
  }

  Widget _handleBack(VoidCallback onBack, Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: child,
  );
}
