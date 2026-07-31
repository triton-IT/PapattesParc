import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../games/pattes_friandises/data/match3_progress_store.dart';
import '../games/mahjong_animaux/data/mahjong_progress_store.dart';
import '../games/refuge/data/progress_store.dart';
import '../shared/app_theme.dart';

enum GameId { refuge, pattesFriandises, mahjongAnimaux }

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.refugeStore,
    required this.match3Store,
    required this.mahjongStore,
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
  final bool musicEnabled;
  final bool effectsEnabled;
  final ValueChanged<GameId> onSelect;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .12,
              child: Image.asset('assets/park_map.png', fit: BoxFit.cover),
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
                    final wide =
                        constraints.maxWidth >= 780 &&
                        constraints.maxWidth > constraints.maxHeight;
                    final cards = [
                      _GameCard(
                        key: const Key('game-refuge'),
                        title: 'Balises du refuge',
                        description:
                            'Observe les indices et localise les animaux sans les effrayer.',
                        progress: '${refugeStore.unlockedLevel} / 45 missions',
                        artAsset:
                            'assets/level_art/level-01-suricates-porcs-epics.png',
                        icon: Icons.grid_on_rounded,
                        color: AppColors.primary,
                        onPlay: () => onSelect(GameId.refuge),
                      ),
                      _GameCard(
                        key: const Key('game-pattes-friandises'),
                        title: 'Pattes & Friandises',
                        description:
                            'Aligne les animaux, prépare les paniers et nettoie les habitats.',
                        progress:
                            '${match3Store.unlockedLevel} / 45 niveaux · '
                            '${match3Store.totalFootprints} empreintes',
                        artAsset: 'assets/level_art/level-45-alpagas.png',
                        icon: Icons.pets_rounded,
                        color: const Color(0xffc9694b),
                        onPlay: () => onSelect(GameId.pattesFriandises),
                      ),
                      _GameCard(
                        key: const Key('game-mahjong-animaux'),
                        title: 'Mahjong des animaux',
                        description:
                            'Libère les tuiles et rassemble les animaux par paires.',
                        progress:
                            '${mahjongStore.unlockedLevel} / 45 niveaux · '
                            '${mahjongStore.totalFootprints} empreintes',
                        artAsset: 'assets/mahjong/mahjong-cover.png',
                        icon: Icons.view_module_rounded,
                        color: AppColors.success,
                        onPlay: () => onSelect(GameId.mahjongAnimaux),
                      ),
                    ];
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1060),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                          child: wide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (
                                      var index = 0;
                                      index < cards.length;
                                      index++
                                    ) ...[
                                      if (index > 0) const SizedBox(width: 14),
                                      Expanded(child: cards[index]),
                                    ],
                                  ],
                                )
                              : ListView.separated(
                                  itemCount: cards.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (_, index) => SizedBox(
                                    height: constraints.maxHeight < 700
                                        ? 255
                                        : 300,
                                    child: cards[index],
                                  ),
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
          Image.asset(artAsset, fit: BoxFit.cover),
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
                  maxLines: 1,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
