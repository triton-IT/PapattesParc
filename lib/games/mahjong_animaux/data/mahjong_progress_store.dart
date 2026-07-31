import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class MahjongProgressStore {
  MahjongProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'mahjong:unlockedLevel';
  final SharedPreferences _preferences;

  static Future<MahjongProgressStore> load() async =>
      MahjongProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) => _duration('mahjong:bestTime:$level');
  int footprints(int level) =>
      _preferences.getInt('mahjong:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += footprints(level);
    }
    return total;
  }

  Duration? freeBestTime(MahjongFreeGameConfig config) => _duration(
    'mahjong:freeBestTime:${config.layoutId}:${config.difficulty.name}:${config.biome.name}',
  );

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    final key = 'mahjong:bestTime:$level';
    final isRecord = await _saveBest(key, elapsed);
    if (footprints > this.footprints(level)) {
      await _preferences.setInt('mahjong:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt(_unlockedLevelKey, min(45, level + 1));
    }
    return isRecord;
  }

  Future<bool> completeFreeGame(
    MahjongFreeGameConfig config,
    Duration elapsed,
  ) => _saveBest(
    'mahjong:freeBestTime:${config.layoutId}:${config.difficulty.name}:${config.biome.name}',
    elapsed,
  );

  Duration? _duration(String key) {
    final milliseconds = _preferences.getInt(key);
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  Future<bool> _saveBest(String key, Duration elapsed) async {
    final current = _duration(key);
    if (current != null && current <= elapsed) return false;
    await _preferences.setInt(key, elapsed.inMilliseconds);
    return true;
  }
}
