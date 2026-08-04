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
    final mission = levels[store.unlockedLevel - 1];
    return CampaignLevelSelectScreen(
      title: 'LE REPAS DES ANIMAUX',
      tagline: 'Observe · Planifie · Nourris',
      icon: Icons.restaurant_rounded,
      helpKind: GameHelpKind.repasAnimaux,
      keyPrefix: 'repas',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      progressLabel: 'REPAS DISTRIBUÉS',
      missionTitle: mission.stage.title,
      missionSubtitle: mission.stage.species,
      missionArtAsset: mission.stage.artAsset!,
      missionStats: [
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
