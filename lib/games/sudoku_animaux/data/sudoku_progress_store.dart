import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SudokuProgressStore {
  SudokuProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'sudoku:unlockedLevel';
  final SharedPreferences _preferences;

  static Future<SudokuProgressStore> load() async =>
      SudokuProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) {
    final milliseconds = _preferences.getInt('sudoku:bestTime:$level');
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  int footprints(int level) =>
      _preferences.getInt('sudoku:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += footprints(level);
    }
    return total;
  }

  Future<void> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    final timeKey = 'sudoku:bestTime:$level';
    final current = bestTime(level);
    if (current == null || elapsed < current) {
      await _preferences.setInt(timeKey, elapsed.inMilliseconds);
    }
    if (footprints > this.footprints(level)) {
      await _preferences.setInt('sudoku:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt(_unlockedLevelKey, min(45, level + 1));
    }
  }
}
