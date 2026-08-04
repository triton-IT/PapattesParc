import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import '../../../shared/animal_catalog.dart';
import '../domain/models.dart';

class SolitaireProgressStore {
  SolitaireProgressStore._(this._preferences);

  static const _animalKey = 'solitaire:backAnimal';
  static const _modeKey = 'solitaire:mode';
  final SharedPreferences _preferences;

  static Future<SolitaireProgressStore> load() async =>
      SolitaireProgressStore._(await SharedPreferences.getInstance());

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

  Duration? levelBestTime(int level) {
    final milliseconds = _preferences.getInt('solitaire:bestTime:$level');
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  int levelFootprints(int level) =>
      _preferences.getInt('solitaire:footprints:$level') ?? 0;

  int get totalFootprints {
    var total = 0;
    for (var level = 1; level <= 45; level++) {
      total += levelFootprints(level);
    }
    return total;
  }

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
    final current = bestTime(mode);
    if (current != null && current <= elapsed) return false;
    await _preferences.setInt(
      'solitaire:bestTime:${mode.name}',
      elapsed.inMilliseconds,
    );
    return true;
  }

  Future<bool> completeLevel(
    int level,
    Duration elapsed,
    int footprints,
  ) async {
    final current = levelBestTime(level);
    final newRecord = current == null || elapsed < current;
    if (newRecord) {
      await _preferences.setInt(
        'solitaire:bestTime:$level',
        elapsed.inMilliseconds,
      );
    }
    if (footprints > levelFootprints(level)) {
      await _preferences.setInt('solitaire:footprints:$level', footprints);
    }
    if (level < 45 && unlockedLevel <= level) {
      await _preferences.setInt('solitaire:unlockedLevel', min(45, level + 1));
    }
    return newRecord;
  }
}
