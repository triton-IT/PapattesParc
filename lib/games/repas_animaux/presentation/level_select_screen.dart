import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../data/repas_animaux_progress_store.dart';
import '../domain/models.dart';

class RepasLevelSelectScreen extends StatelessWidget {
  const RepasLevelSelectScreen({
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

  final List<RepasLevelDefinition> levels;
  final RepasAnimauxProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<RepasLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    return CampaignLevelSelectScreen(
      title: 'LE REPAS DES ANIMAUX',
      tagline: 'Observe · Planifie · Nourris',
      icon: Icons.restaurant_rounded,
      helpKind: GameHelpKind.repasAnimaux,
      keyPrefix: 'repas',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      completedCount: store.completedCount,
      progressLabel: 'REPAS DISTRIBUÉS',
      missionBuilder: (index) {
        final mission = levels[index];
        return CampaignMission(
          completed: store.campaign.isCompleted(index + 1),
          title: mission.stage.title,
          subtitle: mission.stage.species,
          artAsset: mission.stage.artAsset!,
          stats: [
            CampaignMissionStat(
              Icons.grid_view_rounded,
              '${mission.width} × ${mission.height}',
              'grille',
            ),
            CampaignMissionStat(
              Icons.inventory_2_rounded,
              '${mission.initialCrates.length}',
              'caisses',
            ),
            CampaignMissionStat(
              Icons.workspace_premium_rounded,
              '${store.totalFootprints} / 135',
              'empreintes',
            ),
          ],
          bestResult: store.bestPushes(index + 1) == null
              ? 'Aucun record'
              : '${store.bestPushes(index + 1)} poussées',
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
