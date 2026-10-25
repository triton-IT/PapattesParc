import 'package:shared_preferences/shared_preferences.dart';

/// One additive write per campaign; legacy score/time keys remain intact.
class CampaignProgress {
  CampaignProgress(
    this.preferences,
    this.prefix, {
    required this.unlockedLevel,
    required this.legacyCompleted,
    this.itemCount = 45,
  });
  final SharedPreferences preferences;
  final String prefix;
  final int Function() unlockedLevel;
  final bool Function(int level) legacyCompleted;
  final int itemCount;
  String get _key => '$prefix:completedLevels';
  Set<int> get _marked => (preferences.getStringList(_key) ?? const <String>[])
      .map(int.tryParse)
      .whereType<int>()
      .where((i) => i >= 1 && i <= itemCount)
      .toSet();
  bool _evidence(int level) =>
      level < unlockedLevel() ||
      legacyCompleted(level) ||
      preferences.getBool('$prefix:completed:$level') == true;
  bool isCompleted(int level) =>
      level >= 1 &&
      level <= itemCount &&
      (_marked.contains(level) || _evidence(level));
  int get completedCount {
    final marked = _marked;
    return Iterable<int>.generate(
      itemCount,
      (i) => i + 1,
    ).where((i) => marked.contains(i) || _evidence(i)).length;
  }

  Future<void> migrate() async {
    final marked = _marked;
    final inferred = {
      for (var i = 1; i <= itemCount; i++)
        if (_evidence(i)) i,
    };
    if (!marked.containsAll(inferred)) {
      await _save({...marked, ...inferred});
    }
  }

  Future<void> _save(Set<int> levels) async {
    final sorted = levels.toList()..sort();
    await preferences.setStringList(_key, sorted.map((i) => '$i').toList());
  }

  Future<void> complete(int level) async {
    if (level < 1 || level > itemCount) {
      throw RangeError.range(level, 1, itemCount);
    }
    await _save({..._marked, level});
  }

  int reward(int level) => preferences.getInt('$prefix:footprints:$level') ?? 0;
  int get totalRewards => Iterable<int>.generate(
    itemCount,
    (i) => reward(i + 1),
  ).fold(0, (total, value) => total + value);

  Future<void> rewardAndUnlock(int level, int footprints) async {
    if (footprints > reward(level)) {
      await preferences.setInt('$prefix:footprints:$level', footprints);
    }
    if (level < itemCount && unlockedLevel() <= level) {
      await preferences.setInt('$prefix:unlockedLevel', level + 1);
    }
  }
}
