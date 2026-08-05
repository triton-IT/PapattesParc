import 'package:flutter/material.dart';

import '../../../shared/campaign_level_select_screen.dart';
import '../../../shared/game_help.dart';
import '../data/numberlink_progress_store.dart';
import '../domain/models.dart';

class NumberlinkLevelSelectScreen extends StatelessWidget {
  const NumberlinkLevelSelectScreen({
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

  final List<NumberlinkLevelDefinition> levels;
  final NumberlinkProgressStore store;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<NumberlinkLevelDefinition> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final mission = levels[store.unlockedLevel - 1];
    return CampaignLevelSelectScreen(
      title: 'SENTIERS SAUVAGES',
      tagline: 'Relie · Guide · Protège',
      icon: Icons.route_rounded,
      helpKind: GameHelpKind.numberlink,
      keyPrefix: 'numberlink',
      itemCount: levels.length,
      unlockedLevel: store.unlockedLevel,
      progressLabel: 'ANIMAUX À L’ABRI',
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
          Icons.route_rounded,
          '${mission.pairCount}',
          'sentiers',
        ),
        CampaignMissionStat(
          Icons.pets_rounded,
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
