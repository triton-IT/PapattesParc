import 'package:flutter/material.dart';

import '../../../shared/free_game_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/models.dart';

class AnimalSortCustomGameScreen extends StatefulWidget {
  const AnimalSortCustomGameScreen({
    required this.stages,
    required this.onBack,
    required this.onStart,
    this.initialConfig,
    super.key,
  });

  final List<ParkStage> stages;
  final AnimalSortFreeGameConfig? initialConfig;
  final VoidCallback onBack;
  final ValueChanged<AnimalSortFreeGameConfig> onStart;

  @override
  State<AnimalSortCustomGameScreen> createState() =>
      _AnimalSortCustomGameScreenState();
}

class _AnimalSortCustomGameScreenState
    extends State<AnimalSortCustomGameScreen> {
  late int _speciesCount;
  late LevelBiome _biome;

  @override
  void initState() {
    super.initState();
    _speciesCount = widget.initialConfig?.speciesCount ?? 5;
    _biome = widget.initialConfig?.biome ?? LevelBiome.savanna;
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stages.firstWhere((stage) => stage.biome == _biome);
    return FreeGameScaffold(
      backgroundAsset: stage.artAsset!,
      title: 'Prépare le garde-manger',
      subtitle: 'Choisis le biome et le nombre de régimes à classer.',
      backKey: const Key('animal-sort-custom-back'),
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreeGameDropdown<LevelBiome>(
            label: 'BIOME',
            value: _biome,
            icon: Icons.landscape_rounded,
            items: [
              for (final biome in LevelBiome.values)
                DropdownMenuItem(value: biome, child: Text(biome.label)),
            ],
            onChanged: (value) => setState(() => _biome = value),
          ),
          const SizedBox(height: 18),
          FreeGameDropdown<int>(
            label: 'NOMBRE D’ESPÈCES',
            value: _speciesCount,
            icon: Icons.pets_rounded,
            items: [
              for (var count = 3; count <= 8; count++)
                DropdownMenuItem(value: count, child: Text('$count régimes')),
            ],
            onChanged: (value) => setState(() => _speciesCount = value),
          ),
          const SizedBox(height: 18),
          FreeGameSummary(
            '$_speciesCount régimes · ${_speciesCount + 2} réserves · '
            '${_speciesCount <= 4
                ? 'Accessible'
                : _speciesCount <= 6
                ? 'Intermédiaire'
                : 'Expert'}',
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('animal-sort-custom-start'),
            onPressed: () => widget.onStart(
              AnimalSortFreeGameConfig(
                speciesCount: _speciesCount,
                biome: _biome,
              ),
            ),
            icon: const Icon(Icons.shuffle_rounded),
            label: const Text('MÉLANGER LES PORTIONS'),
          ),
        ],
      ),
    );
  }
}
