import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// R45-01: a rotation runs once at a time and changes nothing when its write
// fails.

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_rotation_guard_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<GameData> generated() async {
    final gameData = GameData()..setNumberOfCourt(2);
    for (final player in await createTestPlayers(8)) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  /// Puts a directory where the write's temp file goes, so the write fails.
  Directory blockWrites(String fileName) =>
      Directory('${sandbox.tempDir.path}/$fileName.tmp')..createSync();

  group('in-flight guard', () {
    test('should_log_one_round_when_rotate_is_pressed_twice_at_once', () async {
      final gameData = await generated();

      await Future.wait([gameData.rotateNow(), gameData.rotateNow()]);

      expect(gameData.history.length, 1);
    });

    test('should_advance_the_round_once_when_pressed_twice_at_once', () async {
      final gameData = await generated();

      await Future.wait([gameData.rotateNow(), gameData.rotateNow()]);

      expect(gameData.roundNumber, 2);
    });

    test('should_report_that_the_second_press_did_not_rotate', () async {
      final gameData = await generated();

      final results = await Future.wait([
        gameData.rotateNow(),
        gameData.rotateNow(),
      ]);

      expect(results, [true, false]);
    });

    test('should_rotate_again_after_the_first_rotation_ends', () async {
      final gameData = await generated();
      await gameData.rotateNow();

      await gameData.rotateNow();

      expect(gameData.history.length, 2);
    });
  });

  group('failed write', () {
    test('should_not_add_to_history_when_the_games_write_fails', () async {
      final gameData = await generated();
      blockWrites(GameRepository.databaseFilename);

      await expectLater(gameData.rotateNow(), throwsA(anything));

      expect(gameData.history, isEmpty);
    });

    test(
      'should_not_add_to_history_when_the_session_log_write_fails',
      () async {
        final gameData = await generated();
        blockWrites(SessionLogRepository.databaseFilename);

        await expectLater(gameData.rotateNow(), throwsA(anything));

        expect(gameData.history, isEmpty);
      },
    );

    test('should_keep_the_round_number_when_the_write_fails', () async {
      final gameData = await generated();
      blockWrites(GameRepository.databaseFilename);

      await expectLater(gameData.rotateNow(), throwsA(anything));

      expect(gameData.roundNumber, 1);
    });

    test('should_keep_the_lineup_when_the_write_fails', () async {
      final gameData = await generated();
      final before = [for (final g in gameData.stagingMatches) g.id];
      blockWrites(GameRepository.databaseFilename);

      await expectLater(gameData.rotateNow(), throwsA(anything));

      expect([for (final g in gameData.stagingMatches) g.id], before);
    });

    test(
      'should_keep_one_session_log_after_a_failed_log_write_is_retried',
      () async {
        final gameData = await generated();
        final blocker = blockWrites(SessionLogRepository.databaseFilename);
        await expectLater(gameData.rotateNow(), throwsA(anything));
        blocker.deleteSync();

        await gameData.rotateNow();

        expect(SessionLogRepository.instance.getAll().length, 1);
      },
    );

    test('should_rotate_after_a_failed_write_is_retried', () async {
      final gameData = await generated();
      final blocker = blockWrites(GameRepository.databaseFilename);
      await expectLater(gameData.rotateNow(), throwsA(anything));
      blocker.deleteSync();

      await gameData.rotateNow();

      expect(gameData.history.length, 1);
    });
  });
}
