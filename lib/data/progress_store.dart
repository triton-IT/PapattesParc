import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class ProgressStore {
  ProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'journey:unlockedLevel';
  static const _musicEnabledKey = 'settings:musicEnabled';
  static const _effectsEnabledKey = 'settings:effectsEnabled';
  final SharedPreferences _preferences;

  static Future<ProgressStore> load() async =>
      ProgressStore._(await SharedPreferences.getInstance());

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  bool get musicEnabled => _preferences.getBool(_musicEnabledKey) ?? true;

  bool get effectsEnabled => _preferences.getBool(_effectsEnabledKey) ?? true;

  double bestTime(LevelDefinition level) =>
      _preferences.getDouble('bestTime:level:${level.number}') ?? 0;

  Future<bool> saveIfBetter(LevelDefinition level, Duration elapsed) async {
    final seconds = elapsed.inMilliseconds / 1000;
    final current = bestTime(level);
    if (current > 0 && current <= seconds) return false;
    await _preferences.setDouble('bestTime:level:${level.number}', seconds);
    return true;
  }

  Future<void> unlockAfter(int completedLevel) async {
    if (completedLevel >= 45 || unlockedLevel > completedLevel) return;
    await _preferences.setInt(_unlockedLevelKey, completedLevel + 1);
  }

  Future<void> setMusicEnabled(bool enabled) =>
      _preferences.setBool(_musicEnabledKey, enabled);

  Future<void> setEffectsEnabled(bool enabled) =>
      _preferences.setBool(_effectsEnabledKey, enabled);
}
