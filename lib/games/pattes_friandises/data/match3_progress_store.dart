import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

class Match3ProgressStore {
  Match3ProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'match3:unlockedLevel';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'match3',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) =>
        _preferences.containsKey('match3:bestScore:$level') ||
        footprints(level) > 0,
  );
  int get completedCount => campaign.completedCount;

  static Future<Match3ProgressStore> load() async {
    final store = Match3ProgressStore._(await SharedPreferences.getInstance());
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  int bestScore(int level) =>
      _preferences.getInt('match3:bestScore:$level') ?? 0;

  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Future<void> completeLevel(int level, int score, int footprints) async {
    await campaign.complete(level);
    await _records.saveInteger(
      'match3:bestScore:$level',
      score,
      order: RecordOrder.higherWins,
      initial: 0,
    );
    await campaign.rewardAndUnlock(level, footprints);
  }
}
