import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class Match3ProgressStore {
  Match3ProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'match3:unlockedLevel';
  final SharedPreferences _preferences;

  static Future<Match3ProgressStore> load() async =>
      Match3ProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  int bestScore(int level) =>
      _preferences.getInt('match3:bestScore:$level') ?? 0;

  int footprints(int level) =>
      _preferences.getInt('match3:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += footprints(level);
    }
    return total;
  }

  Future<void> completeLevel(int level, int score, int footprints) async {
    if (score > bestScore(level)) {
      await _preferences.setInt('match3:bestScore:$level', score);
    }
    if (footprints > this.footprints(level)) {
      await _preferences.setInt('match3:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt(_unlockedLevelKey, min(45, level + 1));
    }
  }
}
