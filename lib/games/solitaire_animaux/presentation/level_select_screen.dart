import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../data/solitaire_progress_store.dart';
import '../domain/models.dart';

class SolitaireLevelSelectScreen extends StatelessWidget {
  const SolitaireLevelSelectScreen({
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

  final List<SolitaireLevelDefinition> levels;
  final SolitaireProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<SolitaireLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    return CampaignLevelSelectScreen(
      title: 'SOLITAIRE DES ANIMAUX',
      tagline: 'Révèle · Range · Complète',
      icon: Icons.style_rounded,
      helpKind: GameHelpKind.solitaire,
      keyPrefix: 'solitaire',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      completedCount: store.completedCount,
      progressLabel: 'CARTES RANGÉES',
      missionBuilder: (index) {
        final mission = levels[index];
        return CampaignMission(
          completed: store.campaign.isCompleted(index + 1),
          title: mission.stage.title,
          subtitle: mission.stage.species,
          artAsset: mission.stage.artAsset!,
          stats: [
            CampaignMissionStat(
              Icons.style_rounded,
              '${mission.mode.drawCount} carte${mission.mode.drawCount > 1 ? 's' : ''}',
              'pioche',
            ),
            CampaignMissionStat(
              Icons.replay_rounded,
              '${mission.targetRedeals}',
              'objectif',
            ),
            CampaignMissionStat(
              Icons.workspace_premium_rounded,
              '${store.totalFootprints} / 135',
              'empreintes',
            ),
          ],
          bestResult:
              store.levelBestTime(index + 1)?.toString() ?? 'Aucun record',
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
