import 'package:flutter/material.dart';

import 'app_theme.dart';

class ParkJourneyProgress extends StatelessWidget {
  const ParkJourneyProgress({
    required this.currentLevel,
    required this.itemCount,
    super.key,
  });

  final int currentLevel;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 500;
    return DecoratedBox(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 20,
            ),
            SizedBox(width: compact ? 4 : 7),
            Text(
              compact ? '$currentLevel/$itemCount' : '$currentLevel / $itemCount',
              style: const TextStyle(
                color: AppColors.deep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParkJourneyLegend extends StatelessWidget {
  const ParkJourneyLegend({super.key});

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

class ParkJourneyMap extends StatelessWidget {
  const ParkJourneyMap({
    required this.itemCount,
    required this.unlockedLevel,
    required this.keyPrefix,
    required this.labelBuilder,
    required this.onSelect,
    super.key,
  });

  final int itemCount;
  final int unlockedLevel;
  final String keyPrefix;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xfffff4dc),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(
          BoxFit.contain,
          const Size(1491, 1055),
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
                children: [
                  Positioned.fill(
                    child: Image.asset('assets/park_map.png', fit: BoxFit.fill),
                  ),
                  for (var index = 0; index < itemCount; index++)
                    if (index + 1 > unlockedLevel)
                      _Marker(
                        index: index,
                        unlockedLevel: unlockedLevel,
                        size: markerSize,
                        mapSize: size,
                        keyPrefix: keyPrefix,
                        label: labelBuilder(index),
                        onTap: () => onSelect(index),
                      ),
                  for (var index = 0; index < itemCount; index++)
                    if (index + 1 < unlockedLevel)
                      _Marker(
                        index: index,
                        unlockedLevel: unlockedLevel,
                        size: markerSize,
                        mapSize: size,
                        keyPrefix: keyPrefix,
                        label: labelBuilder(index),
                        onTap: () => onSelect(index),
                      ),
                  if (unlockedLevel <= itemCount)
                    _Marker(
                      index: unlockedLevel - 1,
                      unlockedLevel: unlockedLevel,
                      size: markerSize,
                      mapSize: size,
                      keyPrefix: keyPrefix,
                      label: labelBuilder(unlockedLevel - 1),
                      onTap: () => onSelect(unlockedLevel - 1),
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

class _Marker extends StatelessWidget {
  const _Marker({
    required this.index,
    required this.unlockedLevel,
    required this.size,
    required this.mapSize,
    required this.keyPrefix,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int unlockedLevel;
  final double size;
  final Size mapSize;
  final String keyPrefix;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = index + 1;
    final unlocked = level <= unlockedLevel;
    final current = level == unlockedLevel;
    final color = level < unlockedLevel
        ? AppColors.success
        : current
        ? AppColors.sun
        : AppColors.deep.withValues(alpha: .68);
    final position = parkLevelPositions[index];
    return Positioned(
      left: position.dx * mapSize.width - size / 2,
      top: position.dy * mapSize.height - size / 2,
      child: Tooltip(
        message: 'Niveau $level · $label',
        child: InkWell(
          key: Key('$keyPrefix-level-$level'),
          onTap: unlocked ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: current ? Colors.white : const Color(0xfffff8e9),
                width: current ? 4 : 2,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x55245b4a), blurRadius: 7),
              ],
            ),
            child: unlocked
                ? Text(
                    '$level',
                    style: TextStyle(
                      color: current ? AppColors.deep : Colors.white,
                      fontSize: size * .34,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: size * .5,
                  ),
          ),
        ),
      ),
    );
  }
}

const parkLevelPositions = [
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
