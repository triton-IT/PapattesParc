import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../data/sudoku_progress_store.dart';
import '../domain/models.dart';

class SudokuLevelSelectScreen extends StatelessWidget {
  const SudokuLevelSelectScreen({
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

  final List<SudokuLevelDefinition> levels;
  final SudokuProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<SudokuLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final mission = levels[store.unlockedLevel - 1];
    return CampaignLevelSelectScreen(
      title: 'LE DÉFI DES PAPATTES',
      tagline: 'Observe · Raisonne · Replace',
      icon: Icons.grid_view_rounded,
      helpKind: GameHelpKind.sudoku,
      keyPrefix: 'sudoku',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      progressLabel: 'PARADE PRÊTE',
      missionTitle: mission.stage.title,
      missionSubtitle: mission.stage.species,
      missionArtAsset: mission.stage.artAsset!,
      missionStats: [
        CampaignMissionStat(
          Icons.grid_view_rounded,
          '${mission.size} × ${mission.size}',
          'grille',
        ),
        CampaignMissionStat(
          Icons.pets_rounded,
          '${mission.animals.length}',
          'animaux',
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
