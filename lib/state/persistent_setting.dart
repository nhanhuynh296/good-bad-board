import 'package:flutter/widgets.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Setting { background, gameType, gameDuration, language }

enum GameType {
  timeBased,
  gameBased;

  String toDisplayString(BuildContext context) => switch (this) {
    GameType.timeBased => AppLocalizations.of(context)!.time_based,
    GameType.gameBased => AppLocalizations.of(context)!.game_based,
  };
}

class PersistentSetting extends ChangeNotifier {
  PersistentSetting._init();

  static final PersistentSetting instance = PersistentSetting._init();

  late final SharedPreferencesWithCache sharedPreference;

  Future<void> initialize() async {
    sharedPreference = await SharedPreferencesWithCache.create(
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

  GameType getGameType() => GameType.values.firstWhere(
    (element) =>
        element.name == sharedPreference.getString(Setting.gameType.name),
    orElse: () => GameType.timeBased,
  );

  Future<void> setLanguage(Locale locale) async {
    await sharedPreference.setString(
      Setting.language.name,
      locale.toLanguageTag(),
    );
    notifyListeners();
  }

  Locale getLanguage() {
    final localeString = sharedPreference.getString(Setting.language.name);
    if (localeString != null) {
      return Locale.fromSubtags(languageCode: localeString);
    }
    return const Locale('en'); // Default to English if not set
  }
}
