import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../domain/levels.dart';
import '../domain/models.dart';
import 'app_theme.dart';
import 'formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.levelIndex,
    required this.store,
    required this.onSelectLevel,
    required this.onPlayLevel,
    required this.musicEnabled,
    required this.onToggleMusic,
    required this.onButtonClick,
    this.onQuit,
    super.key,
  });

  final int levelIndex;
  final ProgressStore store;
  final ValueChanged<int> onSelectLevel;
  final ValueChanged<int> onPlayLevel;
  final bool musicEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onButtonClick;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final nextLevel = levels[store.unlockedLevel - 1];
    return Scaffold(
      backgroundColor: const Color(0xfffff4dc),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 850 &&
                constraints.maxWidth > constraints.maxHeight;
            final mission = _MissionCard(
              level: nextLevel,
              completedLevels: store.unlockedLevel - 1,
              bestTime: store.bestTime(nextLevel),
              onPlay: _withClick(() => onPlayLevel(nextLevel.number - 1)),
              compact: !wide,
            );
            final map = _MapSection(
              selectedIndex: levelIndex,
              unlockedLevel: store.unlockedLevel,
              onSelect: (index) {
                onButtonClick();
                _openMission(context, index);
              },
            );
            final header = _ParkHeader(
              unlockedLevel: store.unlockedLevel,
              musicEnabled: musicEnabled,
              onToggleMusic: _withClick(onToggleMusic),
              onQuit: onQuit == null ? null : _withClick(onQuit!),
            );
            if (!wide) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: map),
                        const Positioned(top: 8, right: 12, child: _MapLabel()),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: mission,
                  ),
                ],
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: map),
                const Positioned.fill(child: _MapVignette()),
                Positioned(left: 0, right: 0, top: 0, child: header),
                const Positioned(top: 88, right: 28, child: _MapLabel()),
                Positioned(
                  left: 28,
                  bottom: 28,
                  width: constraints.maxWidth < 1200 ? 340 : 390,
                  child: mission,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openMission(BuildContext context, int index) {
    onSelectLevel(index);
    final level = levels[index];
    final content = _MissionPopup(
      level: level,
      unlocked: level.number <= store.unlockedLevel,
      bestTime: store.bestTime(level),
      onPlay: () {
        onButtonClick();
        Navigator.pop(context);
        onPlayLevel(index);
      },
      onButtonClick: onButtonClick,
    );
    if (MediaQuery.sizeOf(context).width < 700) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        builder: (_) => FractionallySizedBox(heightFactor: .9, child: content),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: content,
        ),
      ),
    );
  }

  VoidCallback _withClick(VoidCallback action) => () {
    onButtonClick();
    action();
  };
}

class _ParkHeader extends StatelessWidget {
  const _ParkHeader({
    required this.unlockedLevel,
    required this.musicEnabled,
    required this.onToggleMusic,
    required this.onQuit,
  });

  final int unlockedLevel;
  final bool musicEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 500;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 16, compact ? 12 : 24, 8),
      child: Row(
        children: [
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
            child: const Icon(Icons.pets_rounded, color: Colors.white),
          ),
          SizedBox(width: compact ? 9 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAPATTE PARC',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 19 : null,
                    letterSpacing: compact ? .7 : 1.2,
                  ),
                ),
                if (!compact)
                  const Text(
                    'Observe · Déduis · Protège',
                    style: TextStyle(
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
            key: const Key('toggle-music'),
            tooltip: musicEnabled ? 'Couper la musique' : 'Activer la musique',
            onPressed: onToggleMusic,
            icon: Icon(
              musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
              color: musicEnabled ? AppColors.primary : AppColors.muted,
            ),
          ),
          SizedBox(width: compact ? 5 : 8),
          if (onQuit != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _HudButton(
                key: const Key('quit-app'),
                tooltip: 'Quitter l’application',
                onPressed: onQuit!,
                icon: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.danger,
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24245b4a),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 9 : 13,
                vertical: 11,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  SizedBox(width: compact ? 4 : 7),
                  Text(
                    compact
                        ? '$unlockedLevel/${levels.length}'
                        : '$unlockedLevel / ${levels.length}',
                    style: const TextStyle(
                      color: AppColors.deep,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface.withValues(alpha: .92),
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: AppColors.deep.withValues(alpha: .2),
    child: IconButton(tooltip: tooltip, onPressed: onPressed, icon: icon),
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.level,
    required this.completedLevels,
    required this.bestTime,
    required this.onPlay,
    required this.compact,
  });

  final LevelDefinition level;
  final int completedLevels;
  final double bestTime;
  final VoidCallback onPlay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = completedLevels / levels.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(color: Colors.white.withValues(alpha: .8), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.deep.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PARC EN SÉCURITÉ',
                    style: TextStyle(
                      color: AppColors.deep,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()} %',
                  style: const TextStyle(
                    color: AppColors.primary,
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
              backgroundColor: AppColors.background,
              color: AppColors.success,
            ),
            SizedBox(height: compact ? 12 : 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: compact ? 92 : 145,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      level.artAsset!,
                      key: const Key('level-art'),
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x990f3027)],
                          stops: [.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 9,
                      child: Text(
                        'PROCHAINE MISSION · ${level.number.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              level.title,
              key: const Key('home-level-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              level.species,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: compact ? 10 : 14),
            _MissionStats(level: level, bestTime: bestTime),
            SizedBox(height: compact ? 10 : 14),
            FilledButton.icon(
              key: const Key('start-mission'),
              onPressed: onPlay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.deep.withValues(alpha: .35),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('CONTINUER L’AVENTURE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.selectedIndex,
    required this.unlockedLevel,
    required this.onSelect,
  });

  final int selectedIndex;
  final int unlockedLevel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => _ParkMap(
    selectedIndex: selectedIndex,
    unlockedLevel: unlockedLevel,
    onSelect: onSelect,
  );
}

class _MapLabel extends StatelessWidget {
  const _MapLabel();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.deep.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(99),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33245b4a),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, color: AppColors.sun, size: 19),
          SizedBox(width: 8),
          Text(
            'CHOISIS UN REFUGE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
        ],
      ),
    ),
  );
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

class _ParkMap extends StatelessWidget {
  const _ParkMap({
    required this.selectedIndex,
    required this.unlockedLevel,
    required this.onSelect,
  });

  static const _imageSize = Size(1491, 1055);
  final int selectedIndex;
  final int unlockedLevel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xfffff4dc),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(
          BoxFit.contain,
          _imageSize,
          constraints.biggest,
        );
        final size = fitted.destination;
        final markerSize = size.width < 500
            ? 26.0
            : size.width < 900
            ? 32.0
            : 38.0;
        return InteractiveViewer(
          minScale: 1,
          maxScale: 3,
          child: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/park_map.png',
                      key: const Key('park-map'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  for (var index = 0; index < levels.length; index++)
                    if (index != selectedIndex)
                      _LevelMarker(
                        index: index,
                        selected: false,
                        unlockedLevel: unlockedLevel,
                        size: markerSize,
                        mapSize: size,
                        onTap: () => onSelect(index),
                      ),
                  _LevelMarker(
                    index: selectedIndex,
                    selected: true,
                    unlockedLevel: unlockedLevel,
                    size: markerSize,
                    mapSize: size,
                    onTap: () => onSelect(selectedIndex),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _LevelMarker extends StatelessWidget {
  const _LevelMarker({
    required this.index,
    required this.selected,
    required this.unlockedLevel,
    required this.size,
    required this.mapSize,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final int unlockedLevel;
  final double size;
  final Size mapSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = levels[index];
    final position = _levelPositions[index];
    final completed = level.number < unlockedLevel;
    final available = level.number == unlockedLevel;
    final color = completed
        ? AppColors.success
        : available
        ? AppColors.sun
        : AppColors.deep.withValues(alpha: .68);
    return Positioned(
      left: position.dx * mapSize.width - size / 2,
      top: position.dy * mapSize.height - size / 2,
      child: Tooltip(
        message: 'Niveau ${level.number} · ${level.title}',
        child: Semantics(
          button: true,
          selected: selected,
          label: 'Niveau ${level.number}, ${level.title}',
          child: InkWell(
            key: Key('level-marker-${level.number}'),
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xfffff8e9),
                  width: selected ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deep.withValues(
                      alpha: selected ? .42 : .22,
                    ),
                    blurRadius: selected ? 10 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${level.number}',
                style: TextStyle(
                  color: available ? AppColors.deep : Colors.white,
                  fontSize: size * .34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionPopup extends StatelessWidget {
  const _MissionPopup({
    required this.level,
    required this.unlocked,
    required this.bestTime,
    required this.onPlay,
    required this.onButtonClick,
  });

  final LevelDefinition level;
  final bool unlocked;
  final double bestTime;
  final VoidCallback onPlay;
  final VoidCallback onButtonClick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 700;
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            level.artAsset!,
            key: const Key('selected-level-art'),
            fit: BoxFit.cover,
          ),
        ),
      );
      final info = _MissionInfo(
        level: level,
        unlocked: unlocked,
        bestTime: bestTime,
        onPlay: onPlay,
        onButtonClick: onButtonClick,
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 12, child: image),
                  const SizedBox(width: 24),
                  Expanded(flex: 10, child: info),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [image, const SizedBox(height: 18), info],
              ),
      );
    },
  );
}

class _MissionInfo extends StatelessWidget {
  const _MissionInfo({
    required this.level,
    required this.unlocked,
    required this.bestTime,
    required this.onPlay,
    required this.onButtonClick,
  });

  final LevelDefinition level;
  final bool unlocked;
  final double bestTime;
  final VoidCallback onPlay;
  final VoidCallback onButtonClick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'MISSION ${level.number.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.3,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        level.title,
        key: const Key('selected-level-title'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 5),
      Text(level.species, style: const TextStyle(color: AppColors.muted)),
      const SizedBox(height: 20),
      _MissionStats(level: level, bestTime: bestTime),
      const SizedBox(height: 18),
      DecoratedBox(
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.background
              : AppColors.danger.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Icon(
                unlocked ? Icons.explore_rounded : Icons.lock_rounded,
                color: unlocked ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  unlocked
                      ? 'Mission disponible'
                      : 'Termine la mission précédente pour continuer.',
                  style: TextStyle(
                    color: unlocked ? AppColors.deep : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        key: const Key('start-selected-mission'),
        onPressed: unlocked ? onPlay : null,
        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('COMMENCER LA MISSION'),
      ),
      TextButton(
        onPressed: () {
          onButtonClick();
          Navigator.pop(context);
        },
        child: const Text('RETOUR AU PLAN'),
      ),
    ],
  );
}

class _MissionStats extends StatelessWidget {
  const _MissionStats({required this.level, required this.bestTime});

  final LevelDefinition level;
  final double bestTime;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Metric(
          icon: Icons.grid_view_rounded,
          value: '${level.config.width} × ${level.config.height}',
        ),
      ),
      Expanded(
        child: _Metric(
          icon: Icons.pets_rounded,
          value: '${level.config.animalCount}',
        ),
      ),
      Expanded(
        child: _Metric(
          icon: Icons.timer_rounded,
          value: bestTime > 0 ? formatSeconds(bestTime) : '—',
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

const _levelPositions = [
  Offset(.625, .590),
  Offset(.647, .616),
  Offset(.612, .718),
  Offset(.777, .682),
  Offset(.827, .680),
  Offset(.753, .610),
  Offset(.727, .639),
  Offset(.708, .646),
  Offset(.711, .544),
  Offset(.659, .522),
  Offset(.641, .567),
  Offset(.582, .476),
  Offset(.534, .446),
  Offset(.548, .393),
  Offset(.542, .325),
  Offset(.593, .336),
  Offset(.614, .219),
  Offset(.500, .299),
  Offset(.422, .333),
  Offset(.393, .291),
  Offset(.423, .296),
  Offset(.393, .238),
  Offset(.467, .189),
  Offset(.425, .155),
  Offset(.346, .208),
  Offset(.358, .125),
  Offset(.314, .227),
  Offset(.187, .144),
  Offset(.123, .068),
  Offset(.182, .187),
  Offset(.227, .287),
  Offset(.321, .280),
  Offset(.326, .318),
  Offset(.369, .336),
  Offset(.398, .333),
  Offset(.347, .408),
  Offset(.358, .457),
  Offset(.467, .420),
  Offset(.550, .525),
  Offset(.393, .514),
  Offset(.288, .435),
  Offset(.363, .571),
  Offset(.513, .586),
  Offset(.550, .571),
  Offset(.775, .854),
];
