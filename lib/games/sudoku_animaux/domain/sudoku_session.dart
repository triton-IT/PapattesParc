import 'models.dart';

class SudokuSession {
  SudokuSession(this.level)
    : entries = [for (final value in level.puzzle) value < 0 ? null : value],
      notes = [for (var index = 0; index < level.puzzle.length; index++) {}];

  final SudokuLevelDefinition level;
  final List<int?> entries;
  final List<Set<int>> notes;
  SudokuStatus status = SudokuStatus.playing;
  Duration elapsed = Duration.zero;
  int hintsUsed = 0;
  bool hasMoved = false;

  int get footprints => hintsUsed == 0
      ? 3
      : hintsUsed == 1
      ? 2
      : 1;
  int get hintsRemaining => 3 - hintsUsed;

  bool isGiven(int index) => level.puzzle[index] >= 0;

  SudokuPlacementResult place(int index, int animal) {
    if (level.solution[index] != animal) return SudokuPlacementResult.wrong;
    entries[index] = animal;
    notes[index].clear();
    _removePeerNotes(index, animal);
    hasMoved = true;
    if (entries.every((value) => value != null)) {
      status = SudokuStatus.won;
      return SudokuPlacementResult.won;
    }
    return SudokuPlacementResult.placed;
  }

  void clear(int index) {
    if (entries[index] == null && notes[index].isEmpty) return;
    entries[index] = null;
    notes[index].clear();
    hasMoved = true;
  }

  void toggleNote(int index, int animal) {
    final candidates = notes[index];
    candidates.contains(animal)
        ? candidates.remove(animal)
        : candidates.add(animal);
    hasMoved = true;
  }

  int? hint([int? selectedIndex]) {
    if (hintsRemaining == 0) return null;
    final target = selectedIndex != null && entries[selectedIndex] == null
        ? selectedIndex
        : _bestEmptyCell();
    if (target == null) return null;
    hintsUsed++;
    place(target, level.solution[target]);
    return target;
  }

  void tick(Duration duration) {
    if (status == SudokuStatus.playing) elapsed += duration;
  }

  int? _bestEmptyCell() {
    int? best;
    var bestCount = level.size + 1;
    for (var index = 0; index < entries.length; index++) {
      if (entries[index] != null) continue;
      final count = _candidateCount(index);
      if (count < bestCount) {
        best = index;
        bestCount = count;
      }
    }
    return best;
  }

  int _candidateCount(int index) {
    final used = <int>{};
    for (final peer in _peers(index)) {
      final value = entries[peer];
      if (value != null) used.add(value);
    }
    return level.size - used.length;
  }

  void _removePeerNotes(int index, int animal) {
    for (final peer in _peers(index)) {
      notes[peer].remove(animal);
    }
  }

  Set<int> _peers(int index) {
    final size = level.size;
    final row = index ~/ size;
    final column = index % size;
    final firstBoxRow = row ~/ level.boxHeight * level.boxHeight;
    final firstBoxColumn = column ~/ level.boxWidth * level.boxWidth;
    return {
      for (var offset = 0; offset < size; offset++) row * size + offset,
      for (var offset = 0; offset < size; offset++) offset * size + column,
      for (var y = 0; y < level.boxHeight; y++)
        for (var x = 0; x < level.boxWidth; x++)
          (firstBoxRow + y) * size + firstBoxColumn + x,
    }..remove(index);
  }
}
