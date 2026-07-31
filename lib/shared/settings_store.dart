import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  SettingsStore._(this._preferences);

  static const _musicEnabledKey = 'settings:musicEnabled';
  static const _effectsEnabledKey = 'settings:effectsEnabled';
  final SharedPreferences _preferences;

  static Future<SettingsStore> load() async =>
      SettingsStore._(await SharedPreferences.getInstance());

  bool get musicEnabled => _preferences.getBool(_musicEnabledKey) ?? true;
  bool get effectsEnabled => _preferences.getBool(_effectsEnabledKey) ?? true;

  Future<void> setMusicEnabled(bool enabled) =>
      _preferences.setBool(_musicEnabledKey, enabled);

  Future<void> setEffectsEnabled(bool enabled) =>
      _preferences.setBool(_effectsEnabledKey, enabled);
}
