import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/park_catalog.dart';
import '../../../shared/game_help.dart';
import '../data/match3_progress_store.dart';
import '../domain/models.dart';

class Match3LevelSelectScreen extends StatelessWidget {
  const Match3LevelSelectScreen({
    required this.levels,
    required this.store,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onPlay,
    required this.onToggleMusic,
    required this.onToggleEffects,
    super.key,
  });

  final List<Match3LevelDefinition> levels;
  final Match3ProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<Match3LevelDefinition> onPlay;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Column(
        children: [
          _Header(
            progress: store.unlockedLevel,
            footprints: store.totalFootprints,
            musicEnabled: musicEnabled,
            effectsEnabled: effectsEnabled,
            onBack: onBack,
            onToggleMusic: onToggleMusic,
            onToggleEffects: onToggleEffects,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                key: const Key('match3-level-grid'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: constraints.maxWidth < 600 ? 180 : 210,
                  childAspectRatio: .84,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final unlocked = level.number <= store.unlockedLevel;
                  return _LevelCard(
                    level: level,
                    unlocked: unlocked,
                    footprints: store.footprints(level.number),
                    onPlay: unlocked ? () => onPlay(level) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.progress,
    required this.footprints,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onToggleMusic,
    required this.onToggleEffects,
  });

  final int progress;
  final int footprints;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
    child: Row(
      children: [
        IconButton(
          key: const Key('match3-back-to-games'),
          tooltip: 'Choisir un jeu',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          backgroundColor: AppColors.sun,
          foregroundColor: AppColors.deep,
          child: Icon(Icons.pets_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATTES & FRIANDISES',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '$progress / 45 niveaux · $footprints / 135 empreintes',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('match3-toggle-music'),
          tooltip: musicEnabled ? 'Couper la musique' : 'Activer la musique',
          onPressed: onToggleMusic,
          icon: Icon(
            musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
          ),
        ),
        const GameHelpButton(kind: GameHelpKind.match3),
        IconButton(
          key: const Key('match3-toggle-effects'),
          tooltip: effectsEnabled
              ? 'Couper les effets sonores'
              : 'Activer les effets sonores',
          onPressed: onToggleEffects,
          icon: Icon(
            effectsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
        ),
      ],
    ),
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.footprints,
    required this.onPlay,
  });

  final Match3LevelDefinition level;
  final bool unlocked;
  final int footprints;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: Key('match3-level-${level.number}'),
      onTap: onPlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (unlocked && level.stage.artAsset != null)
                  Image.asset(level.stage.artAsset!, fit: BoxFit.cover),
                if (!unlocked)
                  ColoredBox(
                    color: _lockedColor(level.stage.biome),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: unlocked ? AppColors.sun : Colors.white70,
                    child: Text(
                      '${level.number}',
                      style: const TextStyle(
                        color: AppColors.deep,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.stage.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        Icons.pets_rounded,
                        size: 17,
                        color: i < footprints
                            ? AppColors.sun
                            : AppColors.muted.withValues(alpha: .28),
                      ),
                    const Spacer(),
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${level.moves}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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

  Color _lockedColor(LevelBiome biome) => switch (biome) {
    LevelBiome.savanna => const Color(0xff8f724c),
    LevelBiome.tropical => const Color(0xff47715d),
    LevelBiome.riverside => const Color(0xff56818a),
    LevelBiome.woodland => const Color(0xff4c624f),
    LevelBiome.steppe => const Color(0xff7d7b4e),
    LevelBiome.mountain => const Color(0xff65716d),
    LevelBiome.tundra => const Color(0xff6d858b),
  };
}
