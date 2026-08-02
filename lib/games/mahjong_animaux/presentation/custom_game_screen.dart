import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/free_game_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';

class MahjongCustomGameScreen extends StatefulWidget {
  const MahjongCustomGameScreen({
    required this.stages,
    required this.onBack,
    required this.onStart,
    super.key,
  });

  final List<ParkStage> stages;
  final VoidCallback onBack;
  final ValueChanged<MahjongFreeGameConfig> onStart;

  @override
  State<MahjongCustomGameScreen> createState() =>
      _MahjongCustomGameScreenState();
}

class _MahjongCustomGameScreenState extends State<MahjongCustomGameScreen> {
  String _layoutId = mahjongLayouts.first.id;
  MahjongDifficulty _difficulty = MahjongDifficulty.easy;
  LevelBiome _biome = LevelBiome.savanna;

  MahjongLayoutDefinition get _layout => mahjongLayout(_layoutId, _difficulty);
  ParkStage get _stage =>
      widget.stages.firstWhere((stage) => stage.biome == _biome);

  @override
  Widget build(BuildContext context) => FreeGameScaffold(
    backgroundAsset: _stage.artAsset!,
    backgroundKey: Key('mahjong-custom-background-${_biome.name}'),
    title: 'Crée ton mahjong',
    subtitle: 'Choisis la disposition, la difficulté et le biome.',
    backKey: const Key('mahjong-custom-back'),
    onBack: widget.onBack,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreeGameDropdown<String>(
          key: const Key('mahjong-custom-layout'),
          label: 'Disposition',
          value: _layoutId,
          icon: Icons.layers_rounded,
          items: [
            for (final name in mahjongLayoutNames)
              DropdownMenuItem(
                value: name.toLowerCase().replaceAll(' ', '-'),
                child: Text(name),
              ),
          ],
          onChanged: (value) => setState(() => _layoutId = value),
        ),
        const SizedBox(height: 16),
        FreeGameDropdown<MahjongDifficulty>(
          key: const Key('mahjong-custom-difficulty'),
          label: 'Difficulté',
          value: _difficulty,
          icon: Icons.speed_rounded,
          items: [
            for (final value in MahjongDifficulty.values)
              DropdownMenuItem(value: value, child: Text(value.label)),
          ],
          onChanged: (value) => setState(() => _difficulty = value),
        ),
        const SizedBox(height: 16),
        FreeGameDropdown<LevelBiome>(
          key: const Key('mahjong-custom-biome'),
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
        _LayoutPreview(layout: _layout),
        const SizedBox(height: 12),
        FreeGameSummary(
          '${_layout.tileCount} tuiles · ${_layout.maxLayers} couche(s) · ${_layout.speciesCount} espèces',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('mahjong-start-custom'),
          onPressed: () => widget.onStart(
            MahjongFreeGameConfig(
              layoutId: _layoutId,
              difficulty: _difficulty,
              biome: _biome,
            ),
          ),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('COMMENCER'),
        ),
      ],
    ),
  );
}

class _LayoutPreview extends StatelessWidget {
  const _LayoutPreview({required this.layout});

  final MahjongLayoutDefinition layout;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('mahjong-layout-preview'),
    height: 170,
    child: CustomPaint(painter: _LayoutPainter(layout)),
  );
}

class _LayoutPainter extends CustomPainter {
  const _LayoutPainter(this.layout);

  final MahjongLayoutDefinition layout;

  @override
  void paint(Canvas canvas, Size size) {
    final maxX =
        layout.positions.fold(0, (value, p) => p.x > value ? p.x : value) + 2;
    final maxY =
        layout.positions.fold(0, (value, p) => p.y > value ? p.y : value) + 2;
    final scale = (size.width / maxX).clamp(4.0, size.height / maxY);
    final origin = Offset((size.width - maxX * scale) / 2, 8);
    for (final position in layout.positions) {
      final rect = Rect.fromLTWH(
        origin.dx + position.x * scale,
        origin.dy + position.y * scale - position.layer * 2,
        scale * 1.8,
        scale * 1.8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..color = position.layer == 0 ? AppColors.surface : AppColors.sun,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AppColors.primary,
      );
    }
  }

  @override
  bool shouldRepaint(_LayoutPainter oldDelegate) =>
      oldDelegate.layout != layout;
}
