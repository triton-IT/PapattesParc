import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/free_game_theme.dart';
import '../../../shared/park_catalog.dart';
import '../domain/campaign.dart';
import '../domain/models.dart';

class Match3CustomGameScreen extends StatefulWidget {
  const Match3CustomGameScreen({
    required this.stages,
    required this.onBack,
    required this.onStart,
    this.initialConfig,
    super.key,
  });

  final List<ParkStage> stages;
  final VoidCallback onBack;
  final ValueChanged<Match3FreeGameConfig> onStart;
  final Match3FreeGameConfig? initialConfig;

  @override
  State<Match3CustomGameScreen> createState() => _Match3CustomGameScreenState();
}

class _Match3CustomGameScreenState extends State<Match3CustomGameScreen> {
  late Match3FreeGoal _goal;
  late Match3Difficulty _difficulty;
  late LevelBiome _biome;

  @override
  void initState() {
    super.initState();
    _goal = widget.initialConfig?.goal ?? Match3FreeGoal.collectAnimal;
    _difficulty = widget.initialConfig?.difficulty ?? Match3Difficulty.easy;
    _biome = widget.initialConfig?.biome ?? LevelBiome.savanna;
  }

  Match3FreeGameConfig get _config =>
      Match3FreeGameConfig(goal: _goal, difficulty: _difficulty, biome: _biome);

  Match3LevelDefinition get _level => buildFreeMatch3Level(
    widget.stages.firstWhere((stage) => stage.biome == _biome),
    _config,
  );

  @override
  Widget build(BuildContext context) {
    final level = _level;
    return FreeGameScaffold(
      backgroundAsset: level.stage.artAsset!,
      backgroundKey: Key('match3-custom-background-${_biome.name}'),
      title: 'Crée ton Align’Animaux',
      subtitle: 'Choisis le biome, l’objectif et le rythme de la partie.',
      backKey: const Key('match3-custom-back'),
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreeGameDropdown<Match3FreeGoal>(
            key: const Key('match3-custom-goal'),
            label: 'Objectif',
            value: _goal,
            icon: _goalIcon,
            items: [
              for (final value in Match3FreeGoal.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) => setState(() => _goal = value),
          ),
          const SizedBox(height: 16),
          FreeGameDropdown<Match3Difficulty>(
            key: const Key('match3-custom-difficulty'),
            label: 'Difficulté',
            value: _difficulty,
            icon: Icons.speed_rounded,
            items: [
              for (final value in Match3Difficulty.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) => setState(() => _difficulty = value),
          ),
          const SizedBox(height: 16),
          FreeGameDropdown<LevelBiome>(
            key: const Key('match3-custom-biome'),
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
          SizedBox(
            key: const Key('match3-custom-preview'),
            height: 74,
            child: Icon(_goalIcon, size: 64),
          ),
          const SizedBox(height: 8),
          FreeGameSummary(
            '${level.moves} coups · ${level.animals.length} espèces · ${_goalSummary(level)}',
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('match3-start-custom'),
            onPressed: () => widget.onStart(_config),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('COMMENCER'),
          ),
        ],
      ),
    );
  }

  IconData get _goalIcon => switch (_goal) {
    Match3FreeGoal.collectAnimal => Icons.pets_rounded,
    Match3FreeGoal.clearBlockers => Icons.auto_awesome_rounded,
    Match3FreeGoal.deliverBaskets => Icons.shopping_basket_rounded,
  };

  String _goalSummary(Match3LevelDefinition level) {
    final goal = level.goals.single;
    return switch (goal.kind) {
      Match3GoalKind.collectAnimal =>
        '${goal.target} animaux (${goal.animal!.label})',
      Match3GoalKind.clearBlockers => '${goal.target} obstacles',
      Match3GoalKind.deliverBaskets => '${goal.target} paniers',
    };
  }
}
