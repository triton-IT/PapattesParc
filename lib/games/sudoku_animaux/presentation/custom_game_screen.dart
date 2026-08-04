import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/free_game_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';

class SudokuCustomGameScreen extends StatefulWidget {
  const SudokuCustomGameScreen({
    required this.stages,
    required this.onBack,
    required this.onStart,
    this.initialConfig,
    super.key,
  });

  final List<ParkStage> stages;
  final VoidCallback onBack;
  final ValueChanged<SudokuFreeGameConfig> onStart;
  final SudokuFreeGameConfig? initialConfig;

  @override
  State<SudokuCustomGameScreen> createState() => _SudokuCustomGameScreenState();
}

class _SudokuCustomGameScreenState extends State<SudokuCustomGameScreen> {
  late int _size;
  late SudokuDifficulty _difficulty;
  late LevelBiome _biome;

  @override
  void initState() {
    super.initState();
    _size = widget.initialConfig?.size ?? 4;
    _difficulty = widget.initialConfig?.difficulty ?? SudokuDifficulty.easy;
    _biome = widget.initialConfig?.biome ?? LevelBiome.savanna;
  }

  SudokuFreeGameConfig get _config =>
      SudokuFreeGameConfig(size: _size, difficulty: _difficulty, biome: _biome);

  ParkStage get _stage =>
      widget.stages.firstWhere((stage) => stage.biome == _biome);

  @override
  Widget build(BuildContext context) => FreeGameScaffold(
    backgroundAsset: _stage.artAsset!,
    backgroundKey: Key('sudoku-custom-background-${_biome.name}'),
    title: 'Crée ton défi',
    subtitle: 'Choisis la grille, la difficulté et le biome des animaux.',
    backKey: const Key('sudoku-custom-back'),
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreeGameDropdown<int>(
          key: const Key('sudoku-custom-size'),
          label: 'Taille de la grille',
          value: _size,
          icon: Icons.grid_view_rounded,
          items: [
            for (final size in const [4, 6, 9])
              DropdownMenuItem(value: size, child: Text('$size × $size')),
          ],
          onChanged: (value) => setState(() => _size = value),
        ),
        const SizedBox(height: 16),
        FreeGameDropdown<SudokuDifficulty>(
          key: const Key('sudoku-custom-difficulty'),
          label: 'Difficulté',
          value: _difficulty,
          icon: Icons.speed_rounded,
          items: [
            for (final value in SudokuDifficulty.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) => setState(() => _difficulty = value),
        ),
        const SizedBox(height: 16),
        FreeGameDropdown<LevelBiome>(
          key: const Key('sudoku-custom-biome'),
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
        _GridPreview(size: _size),
        const SizedBox(height: 12),
        FreeGameSummary(
          '$_size animaux · ${sudokuFreeClueCount(_config)} cases déjà remplies',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('sudoku-start-custom'),
          onPressed: () => widget.onStart(_config),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('COMMENCER'),
        ),
      ],
    ),
  );
}

class _GridPreview extends StatelessWidget {
  const _GridPreview({required this.size});

  final int size;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('sudoku-custom-preview'),
    height: 180,
    child: CustomPaint(painter: _GridPainter(size)),
  );
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.size);

  final int size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final side = canvasSize.height;
    final left = (canvasSize.width - side) / 2;
    final cell = side / size;
    final boxWidth = size == 6
        ? 3
        : size == 4
        ? 2
        : 3;
    final boxHeight = size == 4
        ? 2
        : size == 6
        ? 2
        : 3;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, side, side),
      Paint()..color = Colors.white,
    );
    for (var line = 0; line <= size; line++) {
      final verticalWidth = line % boxWidth == 0 ? 3.0 : 1.0;
      final horizontalWidth = line % boxHeight == 0 ? 3.0 : 1.0;
      canvas.drawLine(
        Offset(left + line * cell, 0),
        Offset(left + line * cell, side),
        Paint()
          ..color = AppColors.deep
          ..strokeWidth = verticalWidth,
      );
      canvas.drawLine(
        Offset(left, line * cell),
        Offset(left + side, line * cell),
        Paint()
          ..color = AppColors.deep
          ..strokeWidth = horizontalWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.size != size;
}
