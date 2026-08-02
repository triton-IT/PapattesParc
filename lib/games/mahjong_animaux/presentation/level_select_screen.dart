import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
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
    this.onQuit,
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
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final mission = levels[store.unlockedLevel - 1];
    return CampaignLevelSelectScreen(
      title: 'MAHJONG DES ANIMAUX',
      tagline: 'Observe · Libère · Réunis',
      icon: Icons.view_module_rounded,
      helpKind: GameHelpKind.mahjong,
      keyPrefix: 'mahjong',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      progressLabel: 'DUOS RÉUNIS',
      missionTitle: mission.stage.title,
      missionSubtitle: mission.stage.species,
      missionArtAsset: mission.stage.artAsset!,
      missionStats: [
        CampaignMissionStat(
          Icons.view_module_rounded,
          '${mission.layout.tileCount}',
          'tuiles',
        ),
        CampaignMissionStat(
          Icons.pets_rounded,
          '${mission.layout.speciesCount}',
          'espèces',
        ),
        CampaignMissionStat(
          Icons.workspace_premium_rounded,
          '${store.totalFootprints} / 135',
          'empreintes',
        ),
      ],
      labelBuilder: (index) => levels[index].layout.name,
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
