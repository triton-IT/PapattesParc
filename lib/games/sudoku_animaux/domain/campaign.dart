import 'dart:math';

import '../../../shared/animal_catalog.dart';
import '../../../shared/park_catalog.dart';
import 'models.dart';

List<SudokuLevelDefinition> buildSudokuCampaign(List<ParkStage> stages) => [
  for (final stage in stages) _buildLevel(stage),
];

SudokuLevelDefinition buildFreeSudokuLevel(
  ParkStage stage,
  SudokuFreeGameConfig config,
  int seed,
) {
  final (boxWidth, boxHeight) = switch (config.size) {
    4 => (2, 2),
    6 => (3, 2),
    _ => (3, 3),
  };
  return _createLevel(
    stage,
    config.size,
    boxWidth,
    boxHeight,
    sudokuFreeClueCount(config),
    seed,
  );
}

int sudokuFreeClueCount(SudokuFreeGameConfig config) =>
    switch ((config.size, config.difficulty)) {
      (4, SudokuDifficulty.easy) => 10,
      (4, SudokuDifficulty.medium) => 8,
      (4, SudokuDifficulty.hard) => 6,
      (6, SudokuDifficulty.easy) => 24,
      (6, SudokuDifficulty.medium) => 19,
      (6, SudokuDifficulty.hard) => 15,
      (9, SudokuDifficulty.easy) => 45,
      (9, SudokuDifficulty.medium) => 36,
      _ => 28,
    };

int countSudokuSolutions(SudokuLevelDefinition level) => _countSolutions(
  level.puzzle.toList(),
  level.size,
  level.boxWidth,
  level.boxHeight,
);

SudokuLevelDefinition _buildLevel(ParkStage stage) {
  final tier = (stage.number - 1) ~/ 15;
  final size = [4, 6, 9][tier];
  final boxWidth = [2, 3, 3][tier];
  final boxHeight = [2, 2, 3][tier];
  return _createLevel(
    stage,
    size,
    boxWidth,
    boxHeight,
    _targetClues(stage.number, tier),
    stage.number * 104729,
  );
}

SudokuLevelDefinition _createLevel(
  ParkStage stage,
  int size,
  int boxWidth,
  int boxHeight,
  int targetClues,
  int seed,
) {
  final random = Random(seed);
  final solution = _solution(size, boxWidth, boxHeight, random);
  final puzzle = _puzzle(
    solution,
    size,
    boxWidth,
    boxHeight,
    targetClues,
    random,
  );
  return SudokuLevelDefinition(
    stage: stage,
    size: size,
    boxWidth: boxWidth,
    boxHeight: boxHeight,
    animals: _animals(stage, size, seed),
    solution: solution,
    puzzle: puzzle,
  );
}

List<AnimalKind> _animals(ParkStage stage, int size, int seed) {
  final biome = animalsByBiome[stage.biome]!;
  final rotated = [
    for (var index = 0; index < biome.length; index++)
      biome[(index + seed) % biome.length],
  ];
  return [
    ...rotated,
    ...AnimalKind.values.where((animal) => !rotated.contains(animal)),
  ].take(size).toList();
}

int _targetClues(int level, int tier) {
  final slot = (level - 1) % 15;
  return switch (tier) {
    0 => 10 - slot * 3 ~/ 14,
    1 => 24 - slot * 8 ~/ 14,
    _ => 45 - slot * 15 ~/ 14,
  };
}

List<int> _solution(int size, int boxWidth, int boxHeight, Random random) {
  final rows = _groupedOrder(size, boxHeight, random);
  final columns = _groupedOrder(size, boxWidth, random);
  final symbols = [for (var value = 0; value < size; value++) value]
    ..shuffle(random);
  return [
    for (final row in rows)
      for (final column in columns)
        symbols[(boxWidth * (row % boxHeight) + row ~/ boxHeight + column) %
            size],
  ];
}

List<int> _groupedOrder(int size, int groupSize, Random random) {
  final groups = [for (var group = 0; group < size ~/ groupSize; group++) group]
    ..shuffle(random);
  return [
    for (final group in groups)
      ...([
        for (var offset = 0; offset < groupSize; offset++) offset,
      ]..shuffle(random)).map((offset) => group * groupSize + offset),
  ];
}

List<int> _puzzle(
  List<int> solution,
  int size,
  int boxWidth,
  int boxHeight,
  int targetClues,
  Random random,
) {
  final puzzle = solution.toList();
  final order = [for (var index = 0; index < puzzle.length; index++) index]
    ..shuffle(random);
  var clues = puzzle.length;
  for (final index in order) {
    if (clues == targetClues) break;
    final value = puzzle[index];
    puzzle[index] = -1;
    if (_countSolutions(puzzle, size, boxWidth, boxHeight) == 1) {
      clues--;
    } else {
      puzzle[index] = value;
    }
  }
  return puzzle;
}

int _countSolutions(List<int> cells, int size, int boxWidth, int boxHeight) {
  final fullMask = (1 << size) - 1;
  final rows = List.filled(size, 0);
  final columns = List.filled(size, 0);
  final boxes = List.filled(size, 0);
  for (var index = 0; index < cells.length; index++) {
    final value = cells[index];
    if (value < 0) continue;
    final row = index ~/ size;
    final column = index % size;
    final box = row ~/ boxHeight * (size ~/ boxWidth) + column ~/ boxWidth;
    final bit = 1 << value;
    rows[row] |= bit;
    columns[column] |= bit;
    boxes[box] |= bit;
  }

  int search() {
    var bestIndex = -1;
    var bestMask = 0;
    var bestCount = size + 1;
    for (var index = 0; index < cells.length; index++) {
      if (cells[index] >= 0) continue;
      final row = index ~/ size;
      final column = index % size;
      final box = row ~/ boxHeight * (size ~/ boxWidth) + column ~/ boxWidth;
      final mask = fullMask & ~(rows[row] | columns[column] | boxes[box]);
      final count = _bitCount(mask);
      if (count == 0) return 0;
      if (count < bestCount) {
        bestIndex = index;
        bestMask = mask;
        bestCount = count;
        if (count == 1) break;
      }
    }
    if (bestIndex < 0) return 1;

    final row = bestIndex ~/ size;
    final column = bestIndex % size;
    final box = row ~/ boxHeight * (size ~/ boxWidth) + column ~/ boxWidth;
    var count = 0;
    var candidates = bestMask;
    while (candidates != 0 && count < 2) {
      final bit = candidates & -candidates;
      candidates &= ~bit;
      final value = bit.bitLength - 1;
      cells[bestIndex] = value;
      rows[row] |= bit;
      columns[column] |= bit;
      boxes[box] |= bit;
      count += search();
      cells[bestIndex] = -1;
      rows[row] &= ~bit;
      columns[column] &= ~bit;
      boxes[box] &= ~bit;
    }
    return count;
  }

  return search();
}

int _bitCount(int value) {
  var count = 0;
  while (value != 0) {
    value &= value - 1;
    count++;
  }
  return count;
}
