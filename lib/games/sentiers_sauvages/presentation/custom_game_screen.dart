import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/free_game_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';

class NumberlinkCustomGameScreen extends StatefulWidget {
  const NumberlinkCustomGameScreen({
    required this.stages,
    required this.onBack,
    required this.onStart,
    this.initialConfig,
    super.key,
  });

  final List<ParkStage> stages;
  final VoidCallback onBack;
  final ValueChanged<NumberlinkFreeGameConfig> onStart;
  final NumberlinkFreeGameConfig? initialConfig;

  @override
  State<NumberlinkCustomGameScreen> createState() =>
      _NumberlinkCustomGameScreenState();
}

class _NumberlinkCustomGameScreenState
    extends State<NumberlinkCustomGameScreen> {
  late int _size;
  late NumberlinkDifficulty _difficulty;
  late LevelBiome _biome;

  @override
  void initState() {
    super.initState();
    _size = widget.initialConfig?.size ?? 5;
    _difficulty = widget.initialConfig?.difficulty ?? NumberlinkDifficulty.easy;
    _biome = widget.initialConfig?.biome ?? LevelBiome.savanna;
  }

  NumberlinkFreeGameConfig get _config => NumberlinkFreeGameConfig(
    size: _size,
    difficulty: _difficulty,
    biome: _biome,
  );

  ParkStage get _stage =>
      widget.stages.firstWhere((stage) => stage.biome == _biome);

  @override
  Widget build(BuildContext context) {
    final pairCount = numberlinkFreePairCount(_config);
    return FreeGameScaffold(
      backgroundAsset: _stage.artAsset!,
      backgroundKey: Key('numberlink-custom-background-${_biome.name}'),
      title: 'Crée tes sentiers',
      subtitle: 'Choisis la grille, la difficulté et le biome des animaux.',
      backKey: const Key('numberlink-custom-back'),
      onBack: widget.onBack,
      maxContentWidth: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreeGameDropdown<int>(
            key: const Key('numberlink-custom-size'),
            label: 'Taille de la grille',
            value: _size,
            icon: Icons.grid_view_rounded,
            items: [
              for (final size in const [5, 7, 9])
                DropdownMenuItem(value: size, child: Text('$size × $size')),
            ],
            onChanged: (value) => setState(() => _size = value),
          ),
          const SizedBox(height: 16),
          FreeGameDropdown<NumberlinkDifficulty>(
            key: const Key('numberlink-custom-difficulty'),
            label: 'Difficulté',
            value: _difficulty,
            icon: Icons.speed_rounded,
            items: [
              for (final value in NumberlinkDifficulty.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) => setState(() => _difficulty = value),
          ),
          const SizedBox(height: 16),
          FreeGameDropdown<LevelBiome>(
            key: const Key('numberlink-custom-biome'),
            label: 'Biome',
            value: _biome,
            icon: Icons.landscape_rounded,
            items: [
              for (final value in LevelBiome.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) => setState(() => _biome = value),
          ),
          const SizedBox(height: 18),
          _NumberlinkPreview(size: _size, pairCount: pairCount),
          const SizedBox(height: 12),
          FreeGameSummary(
            '$pairCount sentiers · grille $_size × $_size · ${_difficulty.label}',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('numberlink-start-custom'),
            onPressed: () => widget.onStart(_config),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('COMMENCER'),
          ),
        ],
      ),
    );
  }
}

class _NumberlinkPreview extends StatelessWidget {
  const _NumberlinkPreview({required this.size, required this.pairCount});

  final int size;
  final int pairCount;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('numberlink-custom-preview'),
    height: 180,
    child: CustomPaint(painter: _PreviewPainter(size, pairCount)),
  );
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.size, this.pairCount);

  static const _colors = [
    Color(0xffff9f43),
    Color(0xff4dabf7),
    Color(0xffcc78dd),
    Color(0xff65bd76),
    Color(0xffff7675),
    Color(0xffffcf4a),
    Color(0xff3bc9db),
    Color(0xff8f72d8),
  ];
  final int size;
  final int pairCount;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final side = min(canvasSize.width, canvasSize.height);
    final origin = Offset((canvasSize.width - side) / 2, 0);
    final board = origin & Size.square(side);
    final cell = side / size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: .9),
    );
    final gridPaint = Paint()
      ..color = AppColors.deep.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var line = 1; line < size; line++) {
      canvas.drawLine(
        origin + Offset(line * cell, 0),
        origin + Offset(line * cell, side),
        gridPaint,
      );
      canvas.drawLine(
        origin + Offset(0, line * cell),
        origin + Offset(side, line * cell),
        gridPaint,
      );
    }
    for (var slot = 0; slot < pairCount; slot++) {
      final row = ((slot + .5) * size / pairCount).floor();
      final start = Offset(
        origin.dx + cell * .5,
        origin.dy + (row + .5) * cell,
      );
      final end = Offset(origin.dx + side - cell * .5, start.dy);
      final color = _colors[slot % _colors.length];
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(3, cell * .18),
      );
      canvas.drawCircle(start, max(3, cell * .2), Paint()..color = color);
      canvas.drawCircle(end, max(3, cell * .2), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) =>
      oldDelegate.size != size || oldDelegate.pairCount != pairCount;
}
