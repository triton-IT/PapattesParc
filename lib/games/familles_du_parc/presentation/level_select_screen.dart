import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../data/animal_sort_progress_store.dart';
import '../domain/models.dart';

class AnimalSortLevelSelectScreen extends StatelessWidget {
  const AnimalSortLevelSelectScreen({
    required this.levels,
    required this.store,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onPlay,
    required this.onCustom,
    required this.onToggleMusic,
    required this.onToggleEffects,
    this.onQuit,
    super.key,
  });

  final List<AnimalSortLevelDefinition> levels;
  final AnimalSortProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<AnimalSortLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    return CampaignLevelSelectScreen(
      title: 'RÉSERVES DU PARC',
      tagline: 'Classe · Regroupe · Prépare',
      icon: Icons.inventory_2_rounded,
      helpKind: GameHelpKind.animalSort,
      keyPrefix: 'animal-sort',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      completedCount: store.completedCount,
      progressLabel: 'REPAS CLASSÉS',
      missionBuilder: (index) {
        final mission = levels[index];
        return CampaignMission(
          completed: store.campaign.isCompleted(index + 1),
          title: mission.stage.title,
          subtitle: mission.stage.species,
          artAsset: mission.stage.artAsset!,
          stats: [
            CampaignMissionStat(
              Icons.pets_rounded,
              '${mission.animals.length}',
              'régimes',
            ),
            CampaignMissionStat(
              Icons.view_column_rounded,
              '${mission.initialZones.length}',
              'réserves',
            ),
            CampaignMissionStat(
              Icons.pets_rounded,
              '${store.totalFootprints} / 135',
              'empreintes',
            ),
          ],
          bestResult: store.bestMoves(index + 1) == null
              ? 'Aucun record'
              : '${store.bestMoves(index + 1)} déplacements',
        );
      },
      labelBuilder: (index) => levels[index].stage.title,
      musicEnabled: musicEnabled,
      effectsEnabled: effectsEnabled,
      onBack: onBack,
      onPlay: (index) => onPlay(levels[index]),
      onCustom: onCustom,
      onToggleMusic: onToggleMusic,
      onToggleEffects: onToggleEffects,
      onQuit: onQuit,
    );
  }
}
