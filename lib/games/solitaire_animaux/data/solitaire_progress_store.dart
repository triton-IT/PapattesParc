import '../../../shared/game_records.dart';
import '../../../shared/campaign_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/animal_catalog.dart';
import '../domain/models.dart';

class SolitaireProgressStore {
  SolitaireProgressStore._(this._preferences);

  static const _animalKey = 'solitaire:backAnimal';
  static const _modeKey = 'solitaire:mode';
  final SharedPreferences _preferences;
  late final GameRecords _records = GameRecords(_preferences);
  late final CampaignProgress campaign = CampaignProgress(
    _preferences,
    'solitaire',
    unlockedLevel: () => unlockedLevel,
    legacyCompleted: (level) => levelBestTime(level) != null,
  );
  int get completedCount => campaign.completedCount;

  static Future<SolitaireProgressStore> load() async {
    final store = SolitaireProgressStore._(
      await SharedPreferences.getInstance(),
    );
    await store.campaign.migrate();
    return store;
  }

  AnimalKind get backAnimal => AnimalKind.values.firstWhere(
    (animal) => animal.name == _preferences.getString(_animalKey),
    orElse: () => AnimalKind.suricate,
  );

  SolitaireMode get mode => SolitaireMode.values.firstWhere(
    (mode) => mode.name == _preferences.getString(_modeKey),
    orElse: () => SolitaireMode.drawOne,
  );

  int wins(SolitaireMode mode) =>
      _preferences.getInt('solitaire:wins:${mode.name}') ?? 0;

  int get unlockedLevel =>
      (_preferences.getInt('solitaire:unlockedLevel') ?? 1).clamp(1, 45);

  Duration? levelBestTime(int level) =>
      _records.duration('solitaire:bestTime:$level');

  int levelFootprints(int level) => campaign.reward(level);

  int get totalFootprints => campaign.totalRewards;

  Duration? bestTime(SolitaireMode mode) {
    final milliseconds = _preferences.getInt('solitaire:bestTime:${mode.name}');
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  Future<void> setBackAnimal(AnimalKind animal) =>
      _preferences.setString(_animalKey, animal.name);

  Future<void> setMode(SolitaireMode mode) =>
      _preferences.setString(_modeKey, mode.name);

  Future<bool> complete(SolitaireMode mode, Duration elapsed) async {
    await _preferences.setInt('solitaire:wins:${mode.name}', wins(mode) + 1);
    return _records.saveDuration('solitaire:bestTime:${mode.name}', elapsed);
  }

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    await campaign.complete(level);
    final newRecord = await _records.saveDuration(
      'solitaire:bestTime:$level',
      elapsed,
    );
    await campaign.rewardAndUnlock(level, footprints);
    return newRecord;
  }
}
