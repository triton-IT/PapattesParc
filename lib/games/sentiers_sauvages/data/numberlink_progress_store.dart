import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

class NumberlinkProgressStore {
  NumberlinkProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'numberlink:unlockedLevel';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'numberlink',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => bestTime(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<NumberlinkProgressStore> load() async {
    final store = NumberlinkProgressStore._(
      await SharedPreferences.getInstance(),
    );
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) =>
      _records.duration('numberlink:bestTime:$level');

  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    await campaign.complete(level);
    final isRecord = await _records.saveDuration(
      'numberlink:bestTime:$level',
      elapsed,
    );
    await campaign.rewardAndUnlock(level, footprints);
    return isRecord;
  }
}
