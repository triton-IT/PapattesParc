import 'package:shared_preferences/shared_preferences.dart';

enum RecordOrder { lowerWins, higherWins }

/// Stores records under the game's existing keys, including free-mode keys.
class GameRecords {
  const GameRecords(this.preferences);
  final SharedPreferences preferences;

  Duration? duration(String key) {
    final milliseconds = preferences.getInt(key);
    return milliseconds == null ? null : Duration(milliseconds: milliseconds);
  }

  Future<bool> saveInteger(
    String key,
    int candidate, {
    required RecordOrder order,
    int? initial,
  }) async {
    final previous = preferences.getInt(key) ?? initial;
    if (previous != null &&
        (order == RecordOrder.lowerWins
            ? candidate >= previous
            : candidate <= previous)) {
      return false;
    }
    await preferences.setInt(key, candidate);
    return true;
  }

  Future<bool> saveDuration(String key, Duration candidate) =>
      saveInteger(key, candidate.inMilliseconds, order: RecordOrder.lowerWins);

  Future<bool> saveSeconds(String key, Duration candidate) async {
    final seconds = candidate.inMilliseconds / 1000;
    final previous = preferences.getDouble(key);
    if (previous != null && previous <= seconds) return false;
    await preferences.setDouble(key, seconds);
    return true;
  }
}
