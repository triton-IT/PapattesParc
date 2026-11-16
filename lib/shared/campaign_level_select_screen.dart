import 'dart:math' as math;
import 'artwork.dart';
import 'clay_text.dart';
import 'clay_hud_icon.dart';
import 'wooden_sign.dart';
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
    this.clayStyle = false,
    this.onQuit,
    this.onSelectionChanged,
    super.key,
  });
  final bool clayStyle;
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
  bool _detailsExpanded = false;
  final _sceneRootKey = GlobalKey();
  final _mapViewKey = GlobalKey();
  final _journeyMapKey = GlobalKey<ParkJourneyMapState>();
  @override
  void initState() {
    super.initState();
    _selection = CampaignSelectionController.forGame(
      widget.keyPrefix,
      widget.unlockedLevel,
    );
    // The retained camera may not emit a change when this screen is remounted.
    // Rebuild once after layout so the backdrop can locate the new map viewport.
    if (widget.clayStyle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
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
    body: Stack(
      key: _sceneRootKey,
      fit: StackFit.expand,
      children: [
        if (widget.clayStyle)
          AnimatedBuilder(
            animation: _selection.camera,
            builder: (context, child) {
              final viewport = _selection.viewport;
              final mapBox =
                  _mapViewKey.currentContext?.findRenderObject() as RenderBox?;
              final rootBox =
                  _sceneRootKey.currentContext?.findRenderObject()
                      as RenderBox?;
              if (viewport == null ||
                  viewport.isEmpty ||
                  mapBox == null ||
                  rootBox == null ||
                  !mapBox.hasSize ||
                  !rootBox.hasSize) {
                return child!;
              }
              final origin = mapBox.localToGlobal(
                Offset.zero,
                ancestor: rootBox,
              );
              final fit = math.min(
                viewport.width / 1491,
                viewport.height / 1055,
              );
              final sceneWidth = math.max(1491.0, viewport.width / fit);
              final sceneHeight = math.max(1055.0, viewport.height / fit);
              final matrix = _selection.camera.value;
              final scale = matrix.getMaxScaleOnAxis();
              final mapOffset = Offset(
                (sceneWidth - 1491) / 2,
                (sceneHeight - 1055) / 2,
              );
              final imageOrigin =
                  origin +
                  Offset(matrix.getTranslation().x, matrix.getTranslation().y) +
                  mapOffset * scale;
              return ParkSceneBackdrop(
                imageRect:
                    (imageOrigin - Offset(147 * scale, 90 * scale)) &
                    Size(2215 * scale, 1246 * scale),
              );
            },
            child: const ColoredBox(color: Color(0xffc77b2a)),
          ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final large =
                  constraints.maxWidth >= 1100 && constraints.maxHeight >= 650;
              final map = KeyedSubtree(
                key: _mapViewKey,
                child: KeyedSubtree(
                  key: Key('${widget.keyPrefix}-level-grid'),
                  child: ParkJourneyMap(
                    key: _journeyMapKey,
                    itemCount: widget.itemCount,
                    unlockedLevel: widget.unlockedLevel,
                    keyPrefix: widget.keyPrefix,
                    labelBuilder: widget.labelBuilder,
                    clayStyle: widget.clayStyle,
                    showControls: !widget.clayStyle,
                    controller: _selection,
                    onSelect: _select,
                  ),
                ),
              );
              final mission = AnimatedBuilder(
                animation: _selection,
                builder: (context, _) => widget.clayStyle
                    ? _clayMission(context, large: large)
                    : _mission(context, large: large),
              );
              return Column(
                children: [
                  widget.clayStyle ? _clayHeader(context) : _header(context),
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
      ],
    ),
  );
  Widget _clayHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    child: SizedBox(
      height: 70,
      child: WoodenSign(
        green: false,
        child: Row(
          children: [
            IconButton(
              key: Key('${widget.keyPrefix}-back-to-games'),
              tooltip: 'Choisir un jeu',
              onPressed: widget.onBack,
              icon: const ClayHudIcon(ClayHudIconKind.back, size: 32),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ClayText(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xffffd475),
                    ),
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Réglages',
              color: const Color(0xfffff4dc),
              icon: const ClayMenuIcon(
                ClayMenuIconKind.settings,
                size: 26,
                onDark: true,
              ),
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
                PopupMenuItem(
                  value: 'music',
                  child: _settingLabel('Musique', widget.musicEnabled),
                ),
                PopupMenuItem(
                  value: 'effects',
                  child: _settingLabel('Effets sonores', widget.effectsEnabled),
                ),
                if (widget.onQuit != null)
                  PopupMenuItem(
                    value: 'quit',
                    child: _settingLabel('Quitter l’application', null),
                  ),
              ],
            ),
            GameHelpButton(
              kind: widget.helpKind,
              clay: true,
              color: const Color(0xffffedcb),
              iconSize: 32,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    ),
  );

  Widget _settingLabel(String label, bool? enabled) => Semantics(
    label: enabled == null
        ? label
        : '$label, ${enabled ? 'activé' : 'désactivé'}',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ClayText(
                label,
                style: const TextStyle(fontSize: 18, color: Color(0xff315a3c)),
              ),
            ),
          ),
          if (enabled != null) ...[
            const SizedBox(width: 12),
            ClayText(
              enabled ? 'OUI' : 'NON',
              style: const TextStyle(fontSize: 16, color: Color(0xff315a3c)),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _clayMission(BuildContext context, {required bool large}) {
    final index = _selection.selectedIndex.clamp(0, widget.itemCount - 1);
    final mission = widget.missionBuilder(index);
    Widget sign(String label, VoidCallback? action, Key key) => SizedBox(
      height: 52,
      child: WoodenSign(
        child: TextButton(
          key: key,
          onPressed: action,
          style: TextButton.styleFrom(foregroundColor: const Color(0xffffedcb)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ClayText(
              label,
              style: const TextStyle(fontSize: 22, color: Color(0xffffedcb)),
            ),
          ),
        ),
      ),
    );
    return Container(
      key: const Key('campaign-mission-panel'),
      margin: const EdgeInsets.all(8),
      decoration: parchmentDecoration,
      padding: const EdgeInsets.fromLTRB(30, 32, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (large)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 120,
                child: ArtworkImage(mission.artAsset, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ClayText(
              'MISSION ${index + 1} · ${mission.completed ? 'TERMINÉE' : 'DÉBLOQUÉE'}',
              style: const TextStyle(fontSize: 14, color: Color(0xff315a3c)),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ClayText(
              mission.title,
              key: const Key('campaign-next-level-title'),
              style: const TextStyle(fontSize: 24, color: Color(0xff315a3c)),
            ),
          ),
          const SizedBox(height: 8),
          sign(
            'JOUER',
            index < widget.unlockedLevel ? () => widget.onPlay(index) : null,
            const Key('campaign-play-selected'),
          ),
          sign(
            'CONTINUER',
            () => widget.onPlay(widget.unlockedLevel - 1),
            const Key('campaign-continue'),
          ),
          sign(
            'PARTIE LIBRE',
            widget.onCustom,
            Key('${widget.keyPrefix}-open-custom'),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ClayText(
                'Détails et record',
                style: TextStyle(fontSize: 19, color: Color(0xff315a3c)),
              ),
            ),
            onExpansionChanged: (expanded) =>
                setState(() => _detailsExpanded = expanded),
            trailing: RotatedBox(
              quarterTurns: _detailsExpanded ? 2 : 0,
              child: const ClayMenuIcon(ClayMenuIconKind.chevron, size: 22),
            ),
            children: [
              ClayParagraph(
                mission.subtitle,
                alignment: WrapAlignment.center,
                style: const TextStyle(fontSize: 16, color: Color(0xff315a3c)),
              ),
              ClayParagraph(
                mission.difficultyLabel == null
                    ? 'Défi : ${mission.stats.take(2).map((stat) => '${stat.value} ${stat.label}').join(' · ')}'
                    : 'Difficulté : ${mission.difficultyLabel}',
                alignment: WrapAlignment.center,
                style: const TextStyle(fontSize: 16, color: Color(0xff315a3c)),
              ),
              ClayParagraph(
                mission.bestResult,
                alignment: WrapAlignment.center,
                style: const TextStyle(fontSize: 16, color: Color(0xff315a3c)),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final stat in mission.stats)
                    ClayParagraph(
                      '${stat.value} ${stat.label}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff315a3c),
                      ),
                    ),
                ],
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ClayText(
              'Sélectionne un niveau',
              key: Key('${widget.keyPrefix}-journey-legend'),
              style: const TextStyle(fontSize: 16, color: Color(0xff315a3c)),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              IconButton(
                tooltip: 'Zoom +',
                onPressed: () => _journeyMapKey.currentState?.zoomIn(),
                icon: const ClayHudIcon(
                  ClayHudIconKind.zoomIn,
                  size: 26,
                  color: Color(0xff315a3c),
                ),
              ),
              IconButton(
                tooltip: 'Zoom −',
                onPressed: () => _journeyMapKey.currentState?.zoomOut(),
                icon: const ClayHudIcon(
                  ClayHudIconKind.zoomOut,
                  size: 26,
                  color: Color(0xff315a3c),
                ),
              ),
              IconButton(
                tooltip: 'Recentrer',
                onPressed: () => _journeyMapKey.currentState?.recenter(),
                icon: const ClayHudIcon(
                  ClayHudIconKind.recenter,
                  size: 26,
                  color: Color(0xff315a3c),
                ),
              ),
              IconButton(
                tooltip: 'Vue du parc',
                onPressed: () => _journeyMapKey.currentState?.showOverview(),
                icon: const ClaySymbol(
                  Icons.route_rounded,
                  size: 26,
                  color: Color(0xff315a3c),
                ),
              ),
              IconButton(
                key: Key('${widget.keyPrefix}-level-list'),
                tooltip: 'Liste des niveaux',
                onPressed: () => _journeyMapKey.currentState?.showLevelList(),
                icon: const ClayMenuIcon(ClayMenuIconKind.list, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
