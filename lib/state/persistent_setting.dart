import 'package:shared_preferences/shared_preferences.dart';

enum Setting { background }

class PersistentSetting {
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
  }

  String getBackground() =>
      sharedPreference.getString(Setting.background.name) ??
      'asset/image/badminton.webp';
}
