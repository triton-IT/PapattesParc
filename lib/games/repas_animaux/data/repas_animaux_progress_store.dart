import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RepasAnimauxProgressStore {
  RepasAnimauxProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'repas:unlockedLevel';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'repas',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => bestPushes(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<RepasAnimauxProgressStore> load() async {
    final store = RepasAnimauxProgressStore._(
      await SharedPreferences.getInstance(),
    );
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  int? bestPushes(int level) => _preferences.getInt('repas:bestPushes:$level');

  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Future<bool> completeLevel(int level, int pushes, int footprints) async {
    await campaign.complete(level);
    final newRecord = await _records.saveInteger(
      'repas:bestPushes:$level',
      pushes,
      order: RecordOrder.lowerWins,
    );
    await campaign.rewardAndUnlock(level, footprints);
    return newRecord;
  }
}
