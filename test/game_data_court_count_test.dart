import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// SESS-04 / SESS-06: a new court count (typed, or from a template) is a full
/// reshuffle of the checked-in pool, like a fresh makeGame.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    // These tests cover court-count changes, hidden in the release.
    CourtCount.editable = true;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('court_count_test');
  });

  tearDown(() {
    CourtCount.editable = false;
    sandbox.tearDown();
  });

  Future<GameData> session(
    int total, {
    required int courts,
    bool generate = true,
  }) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (final player in await createTestPlayers(total)) {
      gameData.checkInPlayer(player);
    }
    if (generate) await gameData.makeGame();
    return gameData;
  }

  SessionTemplate template({required int courts}) => SessionTemplate.create(
    name: 'T',
    gameType: GameType.timeBased,
    durationMinutes: 20,
    durationSeconds: 0,
    capacity: 20,
    courts: courts,
  );

  test('should_seat_the_whole_pool_when_courts_increase', () async {
    // Arrange — 12 players, 2 courts: 4 wait.
    final gameData = await session(12, courts: 2);

    // Act
    gameData.setNumberOfCourt(3);

    // Assert
    expect(gameData.waitlistedPlayers, isEmpty);
  });

  test(
    'should_drop_courts_beyond_the_new_count_when_courts_decrease',
    () async {
      // Arrange
      final gameData = await session(12, courts: 3);

      // Act
      gameData.setNumberOfCourt(1);

      // Assert
      expect(gameData.stagingMatches, hasLength(1));
    },
  );

  test('should_waitlist_everyone_off_court_when_courts_decrease', () async {
    // Arrange
    final gameData = await session(12, courts: 3);

    // Act
    gameData.setNumberOfCourt(1);

    // Assert
    expect(gameData.waitlistedPlayers, hasLength(8));
  });

  test('should_not_generate_a_lineup_when_no_court_has_players', () async {
    // Arrange
    final gameData = await session(12, courts: 2, generate: false);

    // Act
    gameData.setNumberOfCourt(3);

    // Assert
    expect(gameData.hasAnyCourtLineup, isFalse);
  });

  test(
    'should_keep_lineup_when_fewer_than_four_players_are_checked_in',
    () async {
      // Arrange
      final gameData = await session(4, courts: 1);
      gameData.checkOutPlayer(gameData.checkedInPlayers.values.first);
      final before = [...gameData.stagingMatches[0].playerIds];

      // Act
      gameData.setNumberOfCourt(2);

      // Assert
      expect(gameData.stagingMatches[0].playerIds, before);
    },
  );

  test('should_reshuffle_pool_when_template_is_loaded', () async {
    // Arrange
    final gameData = await session(12, courts: 2);

    // Act
    gameData.loadTemplate(template(courts: 3));

    // Assert
    expect(gameData.waitlistedPlayers, isEmpty);
  });

  test(
    'should_report_reshuffle_pending_only_with_lineup_and_four_players',
    () async {
      // Arrange
      final withLineup = await session(12, courts: 2);
      final withoutLineup = await session(12, courts: 2, generate: false);

      // Assert
      expect(withLineup.wouldReshuffleLineup, isTrue);
      expect(withoutLineup.wouldReshuffleLineup, isFalse);
    },
  );
}
