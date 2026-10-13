import 'package:flutter/widgets.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Setting { background, gameType, gameDuration, language, autoMakegame }

enum GameType {
  timeBased,
  gameBased;

  String toDisplayString(BuildContext context) => switch (this) {
    GameType.timeBased => AppLocalizations.of(context)!.time_based,
    GameType.gameBased => AppLocalizations.of(context)!.game_based,
  };
}

/// Release flag for game-based mode.
///
/// Off in the release build: the app always runs time-based and the mode
/// toggle is hidden. All game-based code stays. Tests that cover it set this
/// to `true`. The saved `gameType` setting is never rewritten by this flag.
abstract final class GameMode {
  static bool enabled = false;
}

class PersistentSetting extends ChangeNotifier {
  PersistentSetting._init();

  static final PersistentSetting instance = PersistentSetting._init();

  SharedPreferencesWithCache? _prefs;

  /// Uses `SharedPreferencesWithCache`, the same API as the released build
  /// on `main`. Its keys have no `flutter.` prefix. The legacy
  /// `SharedPreferences` API prefixes every key, so it cannot read the
  /// settings that clubs already saved.
  SharedPreferencesWithCache get sharedPreference {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'PersistentSetting not initialized. Call initialize() first.',
      );
    }
    return prefs;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  Future<void> setCourtBackground(String image) async {
    await sharedPreference.setString(Setting.background.name, image);
    notifyListeners();
  }

  String getBackground() =>
      sharedPreference.getString(Setting.background.name) ??
      'asset/image/badminton.webp';

  Future<void> setGameType(GameType type) async {
    await sharedPreference.setString(Setting.gameType.name, type.name);
    notifyListeners();
  }

  Future<void> setGameDuration(Duration duration) async {
    await sharedPreference.setInt(
      Setting.gameDuration.name,
      duration.inSeconds,
    );
    notifyListeners();
  }

  Duration getGameDuration() {
    return Duration(
      seconds:
          sharedPreference.getInt(Setting.gameDuration.name) ??
          10 * Duration.secondsPerMinute,
    );
  }

  /// The round mode. Always time-based while [GameMode.enabled] is off, even
  /// when a game-based mode is saved.
  GameType getGameType() {
    if (!GameMode.enabled) return GameType.timeBased;
    return GameType.values.firstWhere(
      (element) =>
          element.name == sharedPreference.getString(Setting.gameType.name),
      orElse: () => GameType.timeBased,
    );
  }

  Future<void> setLanguage(Locale locale) async {
    await sharedPreference.setStringList(Setting.language.name, [
      locale.languageCode,
      ?locale.countryCode,
    ]);
    notifyListeners();
  }

  Locale getLanguage() {
    final localeString = sharedPreference.getStringList(Setting.language.name);
    if (localeString == null) return const Locale('en');
    final languageCode = localeString.elementAtOrNull(0) ?? 'en';
    final countryCode = localeString.elementAtOrNull(1);
    return Locale(languageCode, countryCode);
  }

  Future<void> setAutoMakeGame(bool value) async {
    await sharedPreference.setBool(Setting.autoMakegame.name, value);
    notifyListeners();
  }

  bool getAutoMakeGame() {
    return sharedPreference.getBool(Setting.autoMakegame.name) ?? false;
  }

  Future<void> clear() async {
    await sharedPreference.clear();
    notifyListeners();
  }
}
