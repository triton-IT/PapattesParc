import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';

enum SudokuStatus { playing, won }

enum SudokuPlacementResult { wrong, placed, won }

enum SudokuDifficulty { easy, medium, hard }

extension SudokuDifficultyLabel on SudokuDifficulty {
  String get label => switch (this) {
    SudokuDifficulty.easy => 'Facile',
    SudokuDifficulty.medium => 'Moyen',
    SudokuDifficulty.hard => 'Difficile',
  };
}

class SudokuFreeGameConfig {
  const SudokuFreeGameConfig({
    required this.size,
    required this.difficulty,
    required this.biome,
  });

  final int size;
  final SudokuDifficulty difficulty;
  final LevelBiome biome;
}

class SudokuLevelDefinition {
  const SudokuLevelDefinition({
    required this.stage,
    required this.size,
    required this.boxWidth,
    required this.boxHeight,
    required this.animals,
    required this.solution,
    required this.puzzle,
  });

  final ParkStage stage;
  final int size;
  final int boxWidth;
  final int boxHeight;
  final List<AnimalKind> animals;
  final List<int> solution;
  final List<int> puzzle;

  int get number => stage.number;
  int get clueCount => puzzle.where((value) => value >= 0).length;
}
