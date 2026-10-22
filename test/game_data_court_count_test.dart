import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// SESS-04 / SESS-06 (R13-Q1, Nathan 2026-10-22): a new court count (typed,
/// or from a template) changes the current courts only. It never reshuffles
/// the lineup: an added court is empty, and the players of a removed court go
/// to the waitlist.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    CourtCount.editable = true;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('court_count_test');
  });

  tearDown(() {
    CourtCount.editable = true;
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

  List<List<String>> rosters(GameContainer lineup) => [
    for (final game in lineup) [...game.playerIds],
  ];

  test('should_add_an_empty_court_when_courts_increase', () async {
    // Arrange — 12 players, 2 courts: 4 wait.
    final gameData = await session(12, courts: 2);

    // Act
    gameData.setNumberOfCourt(3);

    // Assert
    expect(gameData.stagingMatches[2].playerIds, isEmpty);
  });

  test('should_keep_the_lineup_when_courts_increase', () async {
    // Arrange
    final gameData = await session(12, courts: 2);
    final before = rosters(gameData.stagingMatches);

    // Act
    gameData.setNumberOfCourt(3);

    // Assert
    expect(rosters(gameData.stagingMatches).take(2), before);
  });

  test('should_keep_the_waitlist_when_courts_increase', () async {
    // Arrange
    final gameData = await session(12, courts: 2);

    // Act
    gameData.setNumberOfCourt(3);

    // Assert
    expect(gameData.waitlistedPlayers, hasLength(4));
  });

  test('should_keep_the_other_courts_when_courts_decrease', () async {
    // Arrange
    final gameData = await session(12, courts: 3);
    final before = rosters(gameData.stagingMatches);

    // Act
    gameData.setNumberOfCourt(2);

    // Assert
    expect(rosters(gameData.stagingMatches), before.take(2));
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

  test('should_add_an_empty_court_when_a_template_has_more', () async {
    // Arrange
    final gameData = await session(12, courts: 2);

    // Act
    gameData.loadTemplate(template(courts: 3));

    // Assert
    expect(gameData.stagingMatches[2].playerIds, isEmpty);
  });

  test('should_keep_the_lineup_when_a_template_has_more_courts', () async {
    // Arrange
    final gameData = await session(12, courts: 2);
    final before = rosters(gameData.stagingMatches);

    // Act
    gameData.loadTemplate(template(courts: 3));

    // Assert
    expect(rosters(gameData.stagingMatches).take(2), before);
  });

  test('should_waitlist_a_removed_court_when_a_template_has_less', () async {
    // Arrange
    final gameData = await session(12, courts: 3);

    // Act
    gameData.loadTemplate(template(courts: 1));

    // Assert
    expect(gameData.waitlistedPlayers, hasLength(8));
  });

  test(
    'SESS-06: should_keep_the_lineup_when_the_template_has_the_same_courts',
    () async {
      // Arrange
      final gameData = await session(12, courts: 2);
      final before = [
        for (final game in gameData.stagingMatches) [...game.playerIds],
      ];

      // Act
      gameData.loadTemplate(template(courts: 2));

      // Assert
      expect([
        for (final game in gameData.stagingMatches) game.playerIds,
      ], before);
    },
  );

  test(
    'SESS-06: should_keep_the_lineup_when_court_count_is_not_editable',
    () async {
      // Arrange
      final gameData = await session(12, courts: 4);
      final before = [
        for (final game in gameData.stagingMatches) [...game.playerIds],
      ];
      CourtCount.editable = false;

      // Act
      gameData.loadTemplate(template(courts: 3));

      // Assert
      expect([
        for (final game in gameData.stagingMatches) game.playerIds,
      ], before);
    },
  );

  group('round state (R13-Q1)', () {
    Future<GameData> runningSession({required int courts}) async {
      final gameData = await session(16, courts: courts, generate: false);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      return gameData;
    }

    test('should_keep_the_round_running_when_courts_change', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);

      // Act
      gameData.setNumberOfCourt(4);

      // Assert
      expect(gameData.phase, RoundPhase.running);
    });

    test('should_keep_the_live_lineup_when_courts_change_in_a_round', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);
      final before = rosters(gameData.stagingMatches);

      // Act
      gameData.setNumberOfCourt(4);

      // Assert
      expect(rosters(gameData.stagingMatches).take(3), before);
    });

    test('should_drop_a_removed_court_from_the_saved_next_round', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);
      gameData.makeNextRound();
      await gameData.saveNextRound();

      // Act
      gameData.setNumberOfCourt(2);

      // Assert
      expect(gameData.nextLineup, hasLength(2));
    });

    test('should_add_an_empty_court_to_the_saved_next_round', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);
      gameData.makeNextRound();
      await gameData.saveNextRound();

      // Act
      gameData.setNumberOfCourt(4);

      // Assert
      expect(gameData.nextLineup![3].playerIds, isEmpty);
    });

    test('should_apply_the_count_to_the_lineup_in_edit_mode', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);
      gameData.makeNextRound();

      // Act
      gameData.setNumberOfCourt(2);

      // Assert
      expect(gameData.visibleMatches, hasLength(2));
    });

    test('should_not_count_an_added_court_as_an_unsaved_edit', () async {
      // Arrange
      final gameData = await runningSession(courts: 3);
      gameData.makeNextRound();

      // Act
      gameData.setNumberOfCourt(4);

      // Assert
      expect(gameData.hasUnsavedEdits, isFalse);
    });
  });
}
