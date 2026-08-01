import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../domain/levels.dart';
import '../domain/models.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';

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
              onGames: _withClick(onGames),
              musicEnabled: musicEnabled,
              effectsEnabled: effectsEnabled,
              onToggleMusic: _withClick(onToggleMusic),
              onToggleEffects: _withClick(onToggleEffects),
              onQuit: onQuit == null ? null : _withClick(onQuit!),
            );
            final customGameButton = FilledButton.tonalIcon(
              key: const Key('open-custom-game'),
              onPressed: _withClick(onCreateCustom),
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
                        const Positioned(
                          top: 8,
                          left: 12,
                          child: GameHelpButton(kind: GameHelpKind.refuge),
                        ),
                        const Positioned(top: 8, right: 12, child: _MapLabel()),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: customGameButton,
                        ),
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
                const Positioned(
                  top: 88,
                  left: 28,
                  child: GameHelpButton(kind: GameHelpKind.refuge),
                ),
                const Positioned(top: 88, right: 28, child: _MapLabel()),
                Positioned(right: 28, bottom: 28, child: customGameButton),
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
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(heightFactor: .9, child: content),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
    required this.onGames,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onQuit,
  });

  final int unlockedLevel;
  final VoidCallback onGames;
  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback? onQuit;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 500;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 24, 16, compact ? 12 : 24, 8),
      child: Row(
        children: [
          _HudButton(
            key: const Key('back-to-games'),
            tooltip: 'Choisir un jeu',
            onPressed: onGames,
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
          _HudButton(
            key: const Key('toggle-effects'),
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
          DecoratedBox(
            key: const Key('journey-progress'),
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
          if (onQuit != null) ...[
            SizedBox(width: compact ? 5 : 8),
            _HudButton(
              key: const Key('quit-app'),
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
    return Stack(
      children: [
        Positioned.fill(
          child: compact
              ? Image.asset(
                  level.artAsset!,
                  key: const Key('level-art'),
                  fit: BoxFit.cover,
                )
              : ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0, .66, 1],
                  ).createShader(bounds),
                  child: Image.asset(
                    level.artAsset!,
                    key: const Key('level-art'),
                    fit: BoxFit.cover,
                  ),
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
                  const Expanded(
                    child: Text(
                      'PARC EN SÉCURITÉ',
                      style: TextStyle(
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
                'PROCHAINE MISSION · ${level.number.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: AppColors.sun,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                level.title,
                key: const Key('home-level-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Text(
                level.species,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xffe3eee8)),
              ),
              SizedBox(height: compact ? 10 : 14),
              _MissionStats(
                level: level,
                bestTime: bestTime,
                color: Colors.white,
              ),
              SizedBox(height: compact ? 10 : 14),
              FilledButton.icon(
                key: const Key('start-mission'),
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
  Widget build(BuildContext context) => const IgnorePointer(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 18),
        SizedBox(width: 7),
        Text(
          'Clique sur un point de la carte',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              level.artAsset!,
              key: const Key('selected-level-art'),
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: horizontal
                      ? Alignment.centerLeft
                      : Alignment.topCenter,
                  end: horizontal
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  colors: const [Colors.transparent, Color(0xf218382f)],
                  stops: horizontal ? const [.18, .68] : const [.2, .5],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: horizontal
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 12, child: SizedBox(height: 420)),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 10,
                        child: _MissionInfo(
                          level: level,
                          unlocked: unlocked,
                          bestTime: bestTime,
                          onPlay: onPlay,
                          onButtonClick: onButtonClick,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 220),
                      _MissionInfo(
                        level: level,
                        unlocked: unlocked,
                        bestTime: bestTime,
                        onPlay: onPlay,
                        onButtonClick: onButtonClick,
                      ),
                    ],
                  ),
          ),
        ],
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
          color: AppColors.sun,
          letterSpacing: 1.3,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        level.title,
        key: const Key('selected-level-title'),
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 5),
      Text(level.species, style: const TextStyle(color: Color(0xffe3eee8))),
      const SizedBox(height: 20),
      _MissionStats(level: level, bestTime: bestTime, color: Colors.white),
      const SizedBox(height: 18),
      Row(
        children: [
          Icon(
            unlocked ? Icons.explore_rounded : Icons.lock_rounded,
            color: unlocked ? AppColors.sun : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unlocked
                  ? 'Mission disponible'
                  : 'Termine la mission précédente pour continuer.',
              style: TextStyle(
                color: unlocked ? Colors.white : AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
        style: TextButton.styleFrom(foregroundColor: Colors.white),
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
  const _MissionStats({
    required this.level,
    required this.bestTime,
    this.color = AppColors.primary,
  });

  final LevelDefinition level;
  final double bestTime;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Metric(
          icon: Icons.grid_view_rounded,
          value: '${level.config.width} × ${level.config.height}',
          color: color,
        ),
      ),
      Expanded(
        child: _Metric(
          icon: Icons.pets_rounded,
          value: '${level.config.animalCount}',
          color: color,
        ),
      ),
      Expanded(
        child: _Metric(
          icon: Icons.timer_rounded,
          value: bestTime > 0 ? formatSeconds(bestTime) : '—',
          color: color,
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
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
