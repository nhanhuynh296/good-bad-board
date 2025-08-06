import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Setting { background, gameType, gameDuration }

enum GameType {
  timeBased,
  gameBased;

  String toDisplayString() => switch (this) {
    GameType.timeBased => 'TIME BASED',
    GameType.gameBased => 'GAME BASED',
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
}
