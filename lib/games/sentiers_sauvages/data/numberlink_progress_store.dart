import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class NumberlinkProgressStore {
  NumberlinkProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'numberlink:unlockedLevel';
  final SharedPreferences _preferences;

  static Future<NumberlinkProgressStore> load() async =>
      NumberlinkProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) {
    final milliseconds = _preferences.getInt('numberlink:bestTime:$level');
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  int footprints(int level) =>
      _preferences.getInt('numberlink:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += footprints(level);
    }
    return total;
  }

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    final current = bestTime(level);
    final isRecord = current == null || elapsed < current;
    if (isRecord) {
      await _preferences.setInt(
        'numberlink:bestTime:$level',
        elapsed.inMilliseconds,
      );
    }
    if (footprints > this.footprints(level)) {
      await _preferences.setInt('numberlink:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt(_unlockedLevelKey, min(45, level + 1));
    }
    return isRecord;
  }
}
