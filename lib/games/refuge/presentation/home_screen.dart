import 'package:flutter/material.dart';
import '../data/progress_store.dart';
import '../domain/levels.dart';
import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../../../shared/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.levelIndex,
    required this.store,
    required this.onSelectLevel,
    required this.onPlayLevel,
    required this.onCreateCustom,
    required this.musicEnabled,
    required this.onToggleMusic,
    required this.effectsEnabled,
    required this.onToggleEffects,
    required this.onButtonClick,
    required this.onGames,
    this.onQuit,
    super.key,
  });

  final int levelIndex;
  final ProgressStore store;
  final ValueChanged<int> onSelectLevel;
  final ValueChanged<int> onPlayLevel;
  final VoidCallback onCreateCustom;
  final bool musicEnabled;
  final VoidCallback onToggleMusic;
  final bool effectsEnabled;
  final VoidCallback onToggleEffects;
  final VoidCallback onButtonClick;
  final VoidCallback onGames;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) => CampaignLevelSelectScreen(
    title: 'BALISES DU REFUGE',
    tagline: 'Observe · Déduis · Protège',
    icon: Icons.grid_on_rounded,
    helpKind: GameHelpKind.refuge,
    keyPrefix: 'refuge',
    itemCount: levels.length,
    unlockedLevel: store.unlockedLevel,
    completedCount: store.completedCount,
    progressLabel: 'PARC EN SÉCURITÉ',
    missionBuilder: (index) {
      final level = levels[index];
      final record = store.bestTime(level);
      return CampaignMission(
        completed: store.campaign.isCompleted(index + 1),
        title: level.title,
        subtitle: level.species,
        artAsset: level.artAsset!,
        bestResult: store.hasBestTime(level)
            ? formatSeconds(record)
            : 'Aucun record',
        stats: [
          CampaignMissionStat(
            Icons.grid_on,
            '${level.config.width} × ${level.config.height}',
            'terrain',
          ),
          CampaignMissionStat(
            Icons.pets,
            '${level.config.animalCount}',
            'animaux',
          ),
        ],
      );
    },
    labelBuilder: (index) => levels[index].title,
    musicEnabled: musicEnabled,
    effectsEnabled: effectsEnabled,
    onBack: onGames,
    onPlay: onPlayLevel,
    onSelectionChanged: onSelectLevel,
    onCustom: onCreateCustom,
    onToggleMusic: onToggleMusic,
    onToggleEffects: onToggleEffects,
    onQuit: onQuit,
  );
}
