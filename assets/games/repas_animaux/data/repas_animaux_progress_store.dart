import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class RepasAnimauxProgressStore {
  RepasAnimauxProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'repas:unlockedLevel';
  final SharedPreferences _preferences;

  static Future<RepasAnimauxProgressStore> load() async =>
      RepasAnimauxProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  int? bestPushes(int level) => _preferences.getInt('repas:bestPushes:$level');

  int footprints(int level) =>
      _preferences.getInt('repas:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += footprints(level);
    }
    return total;
  }

  Future<bool> completeLevel(int level, int pushes, int footprints) async {
    final previous = bestPushes(level);
    final newRecord = previous == null || pushes < previous;
    if (newRecord) {
      await _preferences.setInt('repas:bestPushes:$level', pushes);
    }
    if (footprints > this.footprints(level)) {
      await _preferences.setInt('repas:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt(_unlockedLevelKey, min(45, level + 1));
    }
    return newRecord;
  }
}
