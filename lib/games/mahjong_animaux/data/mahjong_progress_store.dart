import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class MahjongProgressStore {
  MahjongProgressStore._(this._preferences);

  static const _unlockedLevelKey = 'mahjong:unlockedLevel';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'mahjong',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => bestTime(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<MahjongProgressStore> load() async {
    final store = MahjongProgressStore._(await SharedPreferences.getInstance());
    await store.campaign.migrate();
    return store;
  }

  int get unlockedLevel =>
      (_preferences.getInt(_unlockedLevelKey) ?? 1).clamp(1, 45);

  Duration? bestTime(int level) => _duration('mahjong:bestTime:$level');
  int footprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Duration? freeBestTime(MahjongFreeGameConfig config) => _duration(
    'mahjong:freeBestTime:${config.layoutId}:${config.difficulty.name}:${config.biome.name}',
  );

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    await campaign.complete(level);
    final key = 'mahjong:bestTime:$level';
    final isRecord = await _saveBest(key, elapsed);
    await campaign.rewardAndUnlock(level, footprints);
    return isRecord;
  }

  Future<bool> completeFreeGame(
    MahjongFreeGameConfig config,
    Duration elapsed,
  ) => _saveBest(
    'mahjong:freeBestTime:${config.layoutId}:${config.difficulty.name}:${config.biome.name}',
    elapsed,
  );

  Duration? _duration(String key) => _records.duration(key);

  Future<bool> _saveBest(String key, Duration elapsed) =>
      _records.saveDuration(key, elapsed);
}
