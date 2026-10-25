import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SudokuProgressStore {
  SudokuProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'sudoku:unlockedLevel';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'sudoku',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => bestTime(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<SudokuProgressStore> load() async {
    final store = SudokuProgressStore._(await SharedPreferences.getInstance());
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) => _records.duration('sudoku:bestTime:$level');

  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Future<void> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    await campaign.complete(level);
    await _records.saveDuration('sudoku:bestTime:$level', elapsed);
    await campaign.rewardAndUnlock(level, footprints);
  }
}
