import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
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
    required this.onCustom,
    required this.onToggleMusic,
    required this.onToggleEffects,
    this.onQuit,
    super.key,
  });

  final List<Match3LevelDefinition> levels;
  final Match3ProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<Match3LevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    return CampaignLevelSelectScreen(
      title: 'ALIGN’ANIMAUX',
      tagline: 'Aligne · Combine · Protège',
      icon: Icons.pets_rounded,
      helpKind: GameHelpKind.match3,
      keyPrefix: 'match3',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      completedCount: store.completedCount,
      progressLabel: 'HABITATS PRÉSERVÉS',
      missionBuilder: (index) {
        final mission = levels[index];
        return CampaignMission(
          completed: store.campaign.isCompleted(index + 1),
          title: mission.stage.title,
          subtitle: mission.stage.species,
          artAsset: mission.stage.artAsset!,
          stats: [
            CampaignMissionStat(
              Icons.swap_horiz_rounded,
              '${mission.moves}',
              'coups',
            ),
            CampaignMissionStat(
              Icons.pets_rounded,
              '${mission.animals.length}',
              'espèces',
            ),
            CampaignMissionStat(
              Icons.workspace_premium_rounded,
              '${store.totalFootprints} / 135',
              'empreintes',
            ),
          ],
          bestResult: '${store.bestScore(index + 1)} points',
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
