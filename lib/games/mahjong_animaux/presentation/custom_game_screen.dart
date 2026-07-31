import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';

class MahjongCustomGameScreen extends StatefulWidget {
  const MahjongCustomGameScreen({
    required this.onBack,
    required this.onStart,
    super.key,
  });

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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('mahjong-custom-back'),
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Crée ton mahjong',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Dropdown<String>(
                        key: const Key('mahjong-custom-layout'),
                        label: 'Disposition',
                        value: _layoutId,
                        items: [
                          for (final name in mahjongLayoutNames)
                            DropdownMenuItem(
                              value: name.toLowerCase().replaceAll(' ', '-'),
                              child: Text(name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _layoutId = value),
                      ),
                      const SizedBox(height: 14),
                      _Dropdown<MahjongDifficulty>(
                        key: const Key('mahjong-custom-difficulty'),
                        label: 'Difficulté',
                        value: _difficulty,
                        items: [
                          for (final value in MahjongDifficulty.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _difficulty = value),
                      ),
                      const SizedBox(height: 14),
                      _Dropdown<LevelBiome>(
                        key: const Key('mahjong-custom-biome'),
                        label: 'Biome',
                        value: _biome,
                        items: [
                          for (final value in LevelBiome.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) => setState(() => _biome = value),
                      ),
                      const SizedBox(height: 20),
                      _LayoutPreview(layout: _layout),
                      const SizedBox(height: 12),
                      Text(
                        '${_layout.tileCount} tuiles · ${_layout.maxLayers} couche(s) · ${_layout.speciesCount} espèces',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('mahjong-start-custom'),
                        onPressed: () => widget.onStart(
                          MahjongFreeGameConfig(
                            layoutId: _layoutId,
                            difficulty: _difficulty,
                            biome: _biome,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('COMMENCER'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items,
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
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
