import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
import '../../../shared/park_journey_map.dart';
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
            child: ParkJourneyMap(
              key: const Key('match3-level-grid'),
              itemCount: levels.length,
              unlockedLevel: store.unlockedLevel,
              keyPrefix: 'match3',
              labelBuilder: (index) => levels[index].stage.title,
              onSelect: (index) => onPlay(levels[index]),
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
                'ALIGN’ANIMAUX',
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
