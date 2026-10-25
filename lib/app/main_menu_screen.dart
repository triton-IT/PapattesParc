import 'dart:math' as math;
import '../shared/game_catalog.dart';
export '../shared/game_catalog.dart' show GameId;
import '../shared/artwork.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../games/pattes_friandises/data/match3_progress_store.dart';
import '../games/mahjong_animaux/data/mahjong_progress_store.dart';
import '../games/refuge/data/progress_store.dart';
import '../games/repas_animaux/data/repas_animaux_progress_store.dart';
import '../games/sentiers_sauvages/data/numberlink_progress_store.dart';
import '../games/solitaire_animaux/data/solitaire_progress_store.dart';
import '../games/sudoku_animaux/data/sudoku_progress_store.dart';
import '../games/familles_du_parc/data/animal_sort_progress_store.dart';
import '../shared/app_theme.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.refugeStore,
    required this.match3Store,
    required this.mahjongStore,
    required this.solitaireStore,
    required this.sudokuStore,
    required this.repasStore,
    required this.numberlinkStore,
    required this.animalSortStore,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onSelect,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onQuit,
    super.key,
  });

  final ProgressStore refugeStore;
  final Match3ProgressStore match3Store;
  final MahjongProgressStore mahjongStore;
  final SolitaireProgressStore solitaireStore;
  final SudokuProgressStore sudokuStore;
  final RepasAnimauxProgressStore repasStore;
  final NumberlinkProgressStore numberlinkStore;
  final AnimalSortProgressStore animalSortStore;
  final bool musicEnabled;
  final bool effectsEnabled;
  final ValueChanged<GameId> onSelect;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  String _progress(GameId game) {
    final (completed, footprints) = switch (game) {
      GameId.refuge => (refugeStore.completedCount, null),
      GameId.pattesFriandises => (
        match3Store.completedCount,
        match3Store.totalFootprints,
      ),
      GameId.mahjongAnimaux => (
        mahjongStore.completedCount,
        mahjongStore.totalFootprints,
      ),
      GameId.solitaireAnimaux => (
        solitaireStore.completedCount,
        solitaireStore.totalFootprints,
      ),
      GameId.sudokuAnimaux => (
        sudokuStore.completedCount,
        sudokuStore.totalFootprints,
      ),
      GameId.repasAnimaux => (
        repasStore.completedCount,
        repasStore.totalFootprints,
      ),
      GameId.numberlink => (
        numberlinkStore.completedCount,
        numberlinkStore.totalFootprints,
      ),
      GameId.animalSort => (
        animalSortStore.completedCount,
        animalSortStore.totalFootprints,
      ),
    };
    return '$completed / 45 terminés${footprints == null ? '' : ' · $footprints empreintes'}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .12,
              child: ArtworkImage('assets/park_map.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              _Header(
                musicEnabled: musicEnabled,
                effectsEnabled: effectsEnabled,
                onToggleMusic: onToggleMusic,
                onToggleEffects: onToggleEffects,
                onQuit: onQuit,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      for (final game in gameCatalog)
                        _GameCard(
                          key: Key(game.key),
                          title: game.title,
                          description: game.description,
                          progress: _progress(game.id),
                          artAsset: game.artAsset,
                          icon: game.icon,
                          color: game.color,
                          onPlay: () => onSelect(game.id),
                        ),
                    ];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth >= 1280
                                      ? 4
                                      : constraints.maxWidth >= 1100
                                      ? 3
                                      : constraints.maxWidth >= 680
                                      ? 2
                                      : 1,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  mainAxisExtent: math.max(
                                    280 *
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(1).clamp(1.0, 2.0),
                                    constraints.maxWidth >= 1100
                                        ? math.min(
                                            430,
                                            (constraints.maxHeight - 46) / 2,
                                          )
                                        : 280,
                                  ),
                                ),
                            itemCount: cards.length,
                            itemBuilder: (_, index) => cards[index],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onQuit,
  });

  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.pets_rounded),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAPATTE PARC',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!compact)
                  const Text(
                    'Choisis ton aventure',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('menu-toggle-music'),
            tooltip: musicEnabled ? 'Couper la musique' : 'Activer la musique',
            onPressed: onToggleMusic,
            icon: Icon(
              musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
            ),
          ),
          IconButton(
            key: const Key('menu-toggle-effects'),
            tooltip: effectsEnabled
                ? 'Couper les effets sonores'
                : 'Activer les effets sonores',
            onPressed: onToggleEffects,
            icon: Icon(
              effectsEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
          if (!kIsWeb && onQuit != null)
            IconButton(
              key: const Key('quit-app'),
              tooltip: 'Quitter',
              onPressed: onQuit,
              icon: const Icon(Icons.exit_to_app_rounded),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.artAsset,
    required this.icon,
    required this.color,
    required this.onPlay,
    super.key,
  });

  final String title;
  final String description;
  final String progress;
  final String artAsset;
  final IconData icon;
  final Color color;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 5,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: InkWell(
      onTap: onPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ArtworkImage(artAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x05000000), Color(0xdd173a31)],
                stops: [.25, 1],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 27,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  progress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onPlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('JOUER'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
