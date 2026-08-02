import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'game_help.dart';
import 'park_journey_map.dart';

class CampaignMissionStat {
  const CampaignMissionStat(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;
}

class CampaignLevelSelectScreen extends StatelessWidget {
  const CampaignLevelSelectScreen({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.helpKind,
    required this.keyPrefix,
    required this.itemCount,
    required this.unlockedLevel,
    required this.progressLabel,
    required this.missionTitle,
    required this.missionSubtitle,
    required this.missionArtAsset,
    required this.missionStats,
    required this.labelBuilder,
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

  final String title;
  final String tagline;
  final IconData icon;
  final GameHelpKind helpKind;
  final String keyPrefix;
  final int itemCount;
  final int unlockedLevel;
  final String progressLabel;
  final String missionTitle;
  final String missionSubtitle;
  final String missionArtAsset;
  final List<CampaignMissionStat> missionStats;
  final String Function(int index) labelBuilder;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final ValueChanged<int> onPlay;
  final VoidCallback onCustom;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 850 &&
              constraints.maxWidth > constraints.maxHeight;
          final map = ParkJourneyMap(
            key: Key('$keyPrefix-level-grid'),
            itemCount: itemCount,
            unlockedLevel: unlockedLevel,
            keyPrefix: keyPrefix,
            labelBuilder: labelBuilder,
            onSelect: onPlay,
          );
          final header = _Header(
            title: title,
            tagline: tagline,
            icon: icon,
            keyPrefix: keyPrefix,
            unlockedLevel: unlockedLevel,
            itemCount: itemCount,
            musicEnabled: musicEnabled,
            effectsEnabled: effectsEnabled,
            onBack: onBack,
            onToggleMusic: onToggleMusic,
            onToggleEffects: onToggleEffects,
            onQuit: onQuit,
          );
          final mission = _MissionCard(
            level: unlockedLevel,
            itemCount: itemCount,
            progressLabel: progressLabel,
            title: missionTitle,
            subtitle: missionSubtitle,
            artAsset: missionArtAsset,
            stats: missionStats,
            compact: !wide,
            onPlay: () => onPlay(unlockedLevel - 1),
          );
          final custom = FilledButton.tonalIcon(
            key: Key('$keyPrefix-open-custom'),
            onPressed: onCustom,
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text('PARTIE LIBRE'),
          );
          if (!wide) {
            return Column(
              children: [
                header,
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: map),
                      Positioned(
                        top: 8,
                        left: 12,
                        child: GameHelpButton(kind: helpKind),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: ParkJourneyLegend(
                          key: Key('$keyPrefix-journey-legend'),
                        ),
                      ),
                      Positioned(right: 12, bottom: 12, child: custom),
                    ],
                  ),
                ),
                mission,
              ],
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: map),
              const Positioned.fill(child: _MapVignette()),
              Positioned(left: 0, right: 0, top: 0, child: header),
              Positioned(
                top: 88,
                left: 28,
                child: GameHelpButton(kind: helpKind),
              ),
              Positioned(
                top: 88,
                right: 28,
                child: ParkJourneyLegend(key: Key('$keyPrefix-journey-legend')),
              ),
              Positioned(right: 28, bottom: 28, child: custom),
              Positioned(
                left: 0,
                bottom: 0,
                width: constraints.maxWidth < 1200 ? 420 : 520,
                child: mission,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.keyPrefix,
    required this.unlockedLevel,
    required this.itemCount,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onBack,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onQuit,
  });

  final String title;
  final String tagline;
  final IconData icon;
  final String keyPrefix;
  final int unlockedLevel;
  final int itemCount;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 500;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 11 : 24, 16, compact ? 11 : 24, 8),
      child: Row(
        children: [
          _HudButton(
            key: Key('$keyPrefix-back-to-games'),
            compact: compact,
            tooltip: 'Choisir un jeu',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          SizedBox(width: compact ? 7 : 10),
          Container(
            width: compact ? 40 : 44,
            height: compact ? 40 : 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33245b4a),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 19 : null,
                    letterSpacing: compact ? .7 : 1.2,
                  ),
                ),
                if (!compact)
                  Text(
                    tagline,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                    ),
                  ),
              ],
            ),
          ),
          _HudButton(
            key: Key('$keyPrefix-toggle-music'),
            compact: compact,
            tooltip: musicEnabled ? 'Couper la musique' : 'Activer la musique',
            onPressed: onToggleMusic,
            icon: Icon(
              musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
              color: musicEnabled ? AppColors.primary : AppColors.muted,
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          _HudButton(
            key: Key('$keyPrefix-toggle-effects'),
            compact: compact,
            tooltip: effectsEnabled
                ? 'Couper les effets sonores'
                : 'Activer les effets sonores',
            onPressed: onToggleEffects,
            icon: Icon(
              effectsEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: effectsEnabled ? AppColors.primary : AppColors.muted,
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          ParkJourneyProgress(
            key: Key('$keyPrefix-journey-progress'),
            currentLevel: unlockedLevel,
            itemCount: itemCount,
          ),
          if (onQuit != null) ...[
            SizedBox(width: compact ? 5 : 8),
            _HudButton(
              key: Key('$keyPrefix-quit-app'),
              compact: compact,
              tooltip: 'Quitter l’application',
              onPressed: onQuit!,
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.compact,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    super.key,
  });

  final bool compact;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface.withValues(alpha: .92),
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: AppColors.deep.withValues(alpha: .2),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact
          ? const BoxConstraints.tightFor(width: 40, height: 40)
          : null,
      icon: icon,
    ),
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.level,
    required this.itemCount,
    required this.progressLabel,
    required this.title,
    required this.subtitle,
    required this.artAsset,
    required this.stats,
    required this.compact,
    required this.onPlay,
  });

  final int level;
  final int itemCount;
  final String progressLabel;
  final String title;
  final String subtitle;
  final String artAsset;
  final List<CampaignMissionStat> stats;
  final bool compact;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final progress = (level - 1) / itemCount;
    return Stack(
      children: [
        Positioned.fill(
          child: compact
              ? Image.asset(artAsset, fit: BoxFit.cover)
              : ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, .66, 1],
                  ).createShader(bounds),
                  child: Image.asset(artAsset, fit: BoxFit.cover),
                ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x0018382f),
                  Color(0x5518382f),
                  Color(0xf218382f),
                ],
                stops: [0, .44, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: AppColors.sun,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progressLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()} %',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white24,
                color: AppColors.success,
              ),
              SizedBox(height: compact ? 112 : 170),
              Text(
                'PROCHAINE MISSION · ${level.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.sun,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                key: const Key('campaign-next-level-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xffe3eee8)),
              ),
              SizedBox(height: compact ? 10 : 14),
              Row(
                children: [
                  for (final stat in stats)
                    Expanded(
                      child: Column(
                        children: [
                          Icon(stat.icon, color: Colors.white, size: 20),
                          const SizedBox(height: 5),
                          Text(
                            stat.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            stat.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xffe3eee8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              FilledButton.icon(
                key: const Key('campaign-continue'),
                onPressed: onPlay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('CONTINUER L’AVENTURE'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapVignette extends StatelessWidget {
  const _MapVignette();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.center,
          colors: [AppColors.deep.withValues(alpha: .14), Colors.transparent],
          stops: const [0, .35],
        ),
      ),
    ),
  );
}
