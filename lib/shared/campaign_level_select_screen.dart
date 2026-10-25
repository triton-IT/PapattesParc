import 'artwork.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'campaign_selection_controller.dart';
import 'game_help.dart';
import 'park_journey_map.dart';

class CampaignMissionStat {
  const CampaignMissionStat(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
}

class CampaignMission {
  const CampaignMission({
    required this.title,
    required this.subtitle,
    required this.artAsset,
    required this.stats,
    this.bestResult = 'Aucun record',
    this.completed = false,
    this.difficultyLabel,
  });
  final String title, subtitle, artAsset, bestResult;
  final bool completed;
  final String? difficultyLabel;
  final List<CampaignMissionStat> stats;
}

class CampaignLevelSelectScreen extends StatefulWidget {
  const CampaignLevelSelectScreen({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.helpKind,
    required this.keyPrefix,
    required this.itemCount,
    required this.unlockedLevel,
    required this.completedCount,
    required this.progressLabel,
    required this.missionBuilder,
    required this.labelBuilder,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onPlay,
    required this.onCustom,
    required this.onToggleMusic,
    required this.onToggleEffects,
    this.onQuit,
    this.onSelectionChanged,
    super.key,
  });
  final String title, tagline, keyPrefix, progressLabel;
  final IconData icon;
  final GameHelpKind helpKind;
  final int itemCount, unlockedLevel, completedCount;
  final CampaignMission Function(int index) missionBuilder;
  final String Function(int index) labelBuilder;
  final bool musicEnabled, effectsEnabled;
  final VoidCallback onBack, onCustom, onToggleMusic, onToggleEffects;
  final VoidCallback? onQuit;
  final ValueChanged<int> onPlay;
  final ValueChanged<int>? onSelectionChanged;
  @override
  State<CampaignLevelSelectScreen> createState() =>
      _CampaignLevelSelectScreenState();
}

class _CampaignLevelSelectScreenState extends State<CampaignLevelSelectScreen> {
  late CampaignSelectionController _selection;
  @override
  void initState() {
    super.initState();
    _selection = CampaignSelectionController.forGame(
      widget.keyPrefix,
      widget.unlockedLevel,
    );
  }

  @override
  void didUpdateWidget(CampaignLevelSelectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selection = CampaignSelectionController.forGame(
      widget.keyPrefix,
      widget.unlockedLevel,
    );
  }

  void _select(int index) {
    _selection.select(index);
    widget.onSelectionChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape = constraints.maxWidth > constraints.maxHeight;
          final large =
              constraints.maxWidth >= 1100 && constraints.maxHeight >= 650;
          final map = ParkJourneyMap(
            key: Key('${widget.keyPrefix}-level-grid'),
            itemCount: widget.itemCount,
            unlockedLevel: widget.unlockedLevel,
            keyPrefix: widget.keyPrefix,
            labelBuilder: widget.labelBuilder,
            controller: _selection,
            onSelect: _select,
          );
          final mission = AnimatedBuilder(
            animation: _selection,
            builder: (context, _) => _mission(context, large: large),
          );
          return Column(
            children: [
              _header(context),
              Expanded(
                child: landscape
                    ? Row(
                        children: [
                          Expanded(child: map),
                          SizedBox(
                            width: constraints.maxWidth < 700
                                ? 220
                                : constraints.maxWidth < 1100
                                ? 280
                                : 360,
                            child: SingleChildScrollView(child: mission),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: map),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .3,
                            ),
                            child: SingleChildScrollView(child: mission),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              key: Key('${widget.keyPrefix}-back-to-games'),
              tooltip: 'Choisir un jeu',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Icon(widget.icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    widget.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Réglages',
              onSelected: (value) {
                switch (value) {
                  case 'music':
                    widget.onToggleMusic();
                  case 'effects':
                    widget.onToggleEffects();
                  case 'quit':
                    widget.onQuit?.call();
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'music',
                  checked: widget.musicEnabled,
                  child: const Text('Musique'),
                ),
                CheckedPopupMenuItem(
                  value: 'effects',
                  checked: widget.effectsEnabled,
                  child: const Text('Effets sonores'),
                ),
                if (widget.onQuit != null)
                  const PopupMenuItem(
                    value: 'quit',
                    child: Text('Quitter l’application'),
                  ),
              ],
            ),
            GameHelpButton(kind: widget.helpKind, compact: true),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                key: Key('${widget.keyPrefix}-journey-progress'),
                value: widget.completedCount / widget.itemCount,
                semanticsLabel:
                    '${widget.completedCount} niveaux terminés sur ${widget.itemCount}',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(widget.completedCount * 100 / widget.itemCount).round()} %',
            ),
          ],
        ),
      ],
    ),
  );
  Widget _mission(BuildContext context, {required bool large}) {
    final index = _selection.selectedIndex.clamp(0, widget.itemCount - 1);
    final mission = widget.missionBuilder(index);
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (large)
            SizedBox(
              height: 150,
              child: ArtworkImage(mission.artAsset, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MISSION ${index + 1} · ${mission.completed ? 'TERMINÉE' : 'DÉBLOQUÉE'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  mission.title,
                  key: const Key('campaign-next-level-title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                FilledButton.icon(
                  key: const Key('campaign-play-selected'),
                  onPressed: index < widget.unlockedLevel
                      ? () => widget.onPlay(index)
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('JOUER'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      key: const Key('campaign-continue'),
                      onPressed: () => widget.onPlay(widget.unlockedLevel - 1),
                      child: const Text('CONTINUER'),
                    ),
                    TextButton.icon(
                      key: Key('${widget.keyPrefix}-open-custom'),
                      onPressed: widget.onCustom,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('PARTIE LIBRE'),
                    ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Détails et record'),
                  children: [
                    Text(mission.subtitle),
                    Text(
                      mission.difficultyLabel == null
                          ? 'Défi : ${mission.stats.take(2).map((stat) => '${stat.value} ${stat.label}').join(' · ')}'
                          : 'Difficulté : ${mission.difficultyLabel}',
                    ),
                    Text(mission.bestResult),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final stat in mission.stats)
                          Text('${stat.value} ${stat.label}'),
                      ],
                    ),
                  ],
                ),
                ParkJourneyLegend(
                  key: Key('${widget.keyPrefix}-journey-legend'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
