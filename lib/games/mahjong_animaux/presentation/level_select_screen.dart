import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/game_help.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('mahjong-open-custom'),
                onPressed: onCustom,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('PARTIE LIBRE'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              key: const Key('mahjong-level-grid'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                childAspectRatio: .84,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final unlocked = level.number <= store.unlockedLevel;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('mahjong-level-${level.number}'),
                    onTap: unlocked ? () => onPlay(level) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (unlocked && level.stage.artAsset != null)
                                Image.asset(
                                  level.stage.artAsset!,
                                  fit: BoxFit.cover,
                                ),
                              if (!unlocked)
                                const ColoredBox(
                                  color: AppColors.muted,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              Positioned(
                                left: 8,
                                top: 8,
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: AppColors.sun,
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
                                level.layout.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                level.layout.difficulty.label,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  for (var paw = 0; paw < 3; paw++)
                                    Icon(
                                      Icons.pets_rounded,
                                      size: 17,
                                      color:
                                          paw < store.footprints(level.number)
                                          ? AppColors.sun
                                          : AppColors.muted.withValues(
                                              alpha: .28,
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
              },
            ),
          ),
        ],
      ),
    ),
  );
}
