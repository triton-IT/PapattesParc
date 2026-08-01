import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
import '../../../shared/park_journey_map.dart';
import '../data/mahjong_progress_store.dart';
import '../domain/models.dart';

class MahjongLevelSelectScreen extends StatelessWidget {
  const MahjongLevelSelectScreen({
    required this.levels,
    required this.store,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onPlay,
    required this.onCustom,
    required this.onToggleMusic,
    required this.onToggleEffects,
    super.key,
  });

  final List<MahjongLevelDefinition> levels;
  final MahjongProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<MahjongLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                IconButton(
                  key: const Key('mahjong-back-to-games'),
                  tooltip: 'Choisir un jeu',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const CircleAvatar(
                  backgroundColor: AppColors.sun,
                  foregroundColor: AppColors.deep,
                  child: Icon(Icons.view_module_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAHJONG DES ANIMAUX',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${store.unlockedLevel} / 45 niveaux · ${store.totalFootprints} / 135 empreintes',
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
                  tooltip: musicEnabled
                      ? 'Couper la musique'
                      : 'Activer la musique',
                  onPressed: onToggleMusic,
                  icon: Icon(
                    musicEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                  ),
                ),
                const GameHelpButton(kind: GameHelpKind.mahjong),
                IconButton(
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
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ParkJourneyMap(
                    key: const Key('mahjong-level-grid'),
                    itemCount: levels.length,
                    unlockedLevel: store.unlockedLevel,
                    keyPrefix: 'mahjong',
                    labelBuilder: (index) => levels[index].layout.name,
                    onSelect: (index) => onPlay(levels[index]),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FilledButton.icon(
                    key: const Key('mahjong-open-custom'),
                    onPressed: onCustom,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('PARTIE LIBRE'),
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
