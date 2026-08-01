import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../games/pattes_friandises/data/match3_progress_store.dart';
import '../games/pattes_friandises/presentation/match3_game_flow.dart';
import '../games/mahjong_animaux/data/mahjong_progress_store.dart';
import '../games/mahjong_animaux/presentation/mahjong_game_flow.dart';
import '../games/refuge/data/progress_store.dart';
import '../games/refuge/domain/levels.dart';
import '../games/refuge/presentation/game_app.dart';
import '../games/solitaire_animaux/data/solitaire_progress_store.dart';
import '../games/solitaire_animaux/presentation/solitaire_game_flow.dart';
import '../shared/app_theme.dart';
import '../shared/settings_store.dart';
import 'main_menu_screen.dart';

const _applicationChannel = MethodChannel('papatte_parc/application');

class PapatteParcApp extends StatelessWidget {
  const PapatteParcApp({
    required this.refugeStore,
    required this.match3Store,
    required this.mahjongStore,
    required this.solitaireStore,
    required this.settings,
    super.key,
  });

  final ProgressStore refugeStore;
  final Match3ProgressStore match3Store;
  final MahjongProgressStore mahjongStore;
  final SolitaireProgressStore solitaireStore;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Papatte Parc',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: _AppFlow(
      refugeStore: refugeStore,
      match3Store: match3Store,
      mahjongStore: mahjongStore,
      solitaireStore: solitaireStore,
      settings: settings,
    ),
  );
}

class _AppFlow extends StatefulWidget {
  const _AppFlow({
    required this.refugeStore,
    required this.match3Store,
    required this.mahjongStore,
    required this.solitaireStore,
    required this.settings,
  });

  final ProgressStore refugeStore;
  final Match3ProgressStore match3Store;
  final MahjongProgressStore mahjongStore;
  final SolitaireProgressStore solitaireStore;
  final SettingsStore settings;

  @override
  State<_AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<_AppFlow> {
  GameId? _selectedGame;

  @override
  Widget build(BuildContext context) => switch (_selectedGame) {
    GameId.refuge => RefugeGameFlow(
      store: widget.refugeStore,
      onExit: _showMenu,
    ),
    GameId.pattesFriandises => Match3GameFlow(
      stages: levels,
      progress: widget.match3Store,
      settings: widget.settings,
      onExit: _showMenu,
    ),
    GameId.mahjongAnimaux => MahjongGameFlow(
      stages: levels,
      progress: widget.mahjongStore,
      settings: widget.settings,
      onExit: _showMenu,
    ),
    GameId.solitaireAnimaux => SolitaireGameFlow(
      progress: widget.solitaireStore,
      settings: widget.settings,
      onExit: _showMenu,
    ),
    null => MainMenuScreen(
      refugeStore: widget.refugeStore,
      match3Store: widget.match3Store,
      mahjongStore: widget.mahjongStore,
      solitaireStore: widget.solitaireStore,
      musicEnabled: widget.settings.musicEnabled,
      effectsEnabled: widget.settings.effectsEnabled,
      onSelect: (game) => setState(() => _selectedGame = game),
      onToggleMusic: () => unawaited(_toggleMusic()),
      onToggleEffects: () => unawaited(_toggleEffects()),
      onQuit: !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
          ? () => unawaited(_applicationChannel.invokeMethod<void>('quit'))
          : null,
    ),
  };

  void _showMenu() => setState(() => _selectedGame = null);

  Future<void> _toggleMusic() async {
    await widget.settings.setMusicEnabled(!widget.settings.musicEnabled);
    if (mounted) setState(() {});
  }

  Future<void> _toggleEffects() async {
    await widget.settings.setEffectsEnabled(!widget.settings.effectsEnabled);
    if (mounted) setState(() {});
  }
}
