import '../../../shared/campaign_progress.dart';
import '../../../shared/game_records.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class ProgressStore {
  ProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'journey:unlockedLevel';
  static const _musicEnabledKey = 'settings:musicEnabled';
  static const _effectsEnabledKey = 'settings:effectsEnabled';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'journey',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) =>
        _preferences.containsKey('bestTime:level:$level'),
  );
  int get completedCount => campaign.completedCount;

  static Future<ProgressStore> load() async {
    final store = ProgressStore._(await SharedPreferences.getInstance());
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  bool get musicEnabled => _preferences.getBool(_musicEnabledKey) ?? true;

  bool get effectsEnabled => _preferences.getBool(_effectsEnabledKey) ?? true;

  double bestTime(LevelDefinition level) =>
      _preferences.getDouble('bestTime:level:${level.number}') ?? 0;

  bool hasBestTime(LevelDefinition level) =>
      _preferences.containsKey('bestTime:level:${level.number}');

  Future<bool> saveIfBetter(LevelDefinition level, Duration elapsed) =>
      _records.saveSeconds('bestTime:level:${level.number}', elapsed);

  Future<void> unlockAfter(int completedLevel) async {
    await campaign.complete(completedLevel);
    await campaign.rewardAndUnlock(completedLevel, 0);
  }

  Future<void> setMusicEnabled(bool enabled) =>
      _preferences.setBool(_musicEnabledKey, enabled);

  Future<void> setEffectsEnabled(bool enabled) =>
      _preferences.setBool(_effectsEnabledKey, enabled);
}
