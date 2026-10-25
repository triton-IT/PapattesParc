import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AnimalSortProgressStore {
  AnimalSortProgressStore._(this._preferences);

  static const _prefix = 'animalSort';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'animalSort',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => bestMoves(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<AnimalSortProgressStore> load() async {
    final store = AnimalSortProgressStore._(
      await SharedPreferences.getInstance(),
    );
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt('$_prefix:unlockedLevel') ?? 1).clamp(1, 45);

  int? bestMoves(int level) => _preferences.getInt('$_prefix:bestMoves:$level');

  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Future<bool> completeLevel(int level, int moves, int footprints) async {
    await campaign.complete(level);
    final isRecord = await _records.saveInteger(
      '$_prefix:bestMoves:$level',
      moves,
      order: RecordOrder.lowerWins,
    );
    await campaign.rewardAndUnlock(level, footprints);
    return isRecord;
  }
}
