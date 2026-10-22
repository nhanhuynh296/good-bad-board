import 'package:flutter/widgets.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';

/// The released build on `main` stores settings through
/// `SharedPreferencesWithCache`, with unprefixed keys. The new build must
/// read those keys, or every club loses its settings on upgrade.
void main() {
  setUp(() async {
    GameMode.enabled = true;
    mockPreferences({
      'gameType': 'gameBased',
      'gameDuration': 2100,
      'language': ['zh', 'HK'],
      'autoMakegame': true,
      'background': 'asset/image/pickle_ball.webp',
    });
    await PersistentSetting.instance.initialize();
  });

  tearDown(() => GameMode.enabled = false);

  test('should_read_game_type_written_by_main', () {
    expect(PersistentSetting.instance.getGameType(), GameType.gameBased);
  });

  test('should_read_game_duration_written_by_main', () {
    expect(
      PersistentSetting.instance.getGameDuration(),
      const Duration(seconds: 2100),
    );
  });

  test('should_read_language_written_by_main', () {
    expect(PersistentSetting.instance.getLanguage(), const Locale('zh', 'HK'));
  });

  // R45-37: the new build has no auto make game setting, but it leaves
  // main's key on disk, so a rollback to main keeps the value.
  test('should_leave_main_auto_make_game_key_on_disk', () async {
    await PersistentSetting.instance.setGameDuration(
      const Duration(minutes: 10),
    );

    expect(
      PersistentSetting.instance.sharedPreference.getBool('autoMakegame'),
      isTrue,
    );
  });

  test('should_have_no_auto_make_game_setting', () {
    expect(Setting.values.map((s) => s.name), isNot(contains('autoMakegame')));
  });

  test('should_read_background_written_by_main', () {
    expect(
      PersistentSetting.instance.getBackground(),
      'asset/image/pickle_ball.webp',
    );
  });
}
