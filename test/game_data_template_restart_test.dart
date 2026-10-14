import 'package:good_bad_board/repository/session_template_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// PERSISTENCE.md §3.4: saved templates must survive an app restart, and a
/// deleted template must stay deleted. A "restart" here loads the
/// repository again from the same directory.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('template_restart_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<void> restart() async {
    SessionTemplateRepository.instance =
        await SessionTemplateRepository.initialize(
          rootDir: sandbox.tempDir.path,
        );
  }

  test('should_list_saved_template_after_restart', () async {
    await GameData().saveTemplate(
      'Tuesday',
      GameType.gameBased,
      const Duration(minutes: 20),
      16,
      4,
    );
    await restart();

    expect(GameData().templates.map((t) => t.name), ['Tuesday']);
  });

  test('should_not_list_deleted_template_after_restart', () async {
    final gameData = GameData();
    await gameData.saveTemplate(
      'Tuesday',
      GameType.gameBased,
      const Duration(minutes: 20),
      16,
      4,
    );
    await gameData.saveTemplate(
      'Thursday',
      GameType.timeBased,
      const Duration(minutes: 20),
      12,
      3,
    );
    await gameData.deleteTemplate(0);
    await restart();

    expect(GameData().templates.map((t) => t.name), ['Thursday']);
  });
}
