import 'package:shared_preferences/shared_preferences.dart';

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
}
