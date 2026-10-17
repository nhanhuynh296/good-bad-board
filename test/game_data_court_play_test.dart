import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';
import 'support/prefs_sandbox.dart';

/// Game-based mode: a court is driven by hand — re-roll, Save (which logs the
/// match and marks the court in play), then re-roll again once the real game
/// has finished.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('court_play_test');
  });

  tearDown(() => sandbox.tearDown());

  /// Two full courts drawn from [total] players.
  Future<GameData> twoCourts(int total) async {
    final gameData = GameData()..setNumberOfCourt(2);
    for (final player in await createTestPlayers(total)) {
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  // ---------------------------------------------------------------------
  // Save keeps the lineup on court
  // ---------------------------------------------------------------------

  test('should_keep_players_on_court_when_single_game_saved', () async {
    // Arrange
    final gameData = await twoCourts(8);
    final lineup = [...gameData.stagingMatches[0].players];

    // Act
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Assert
    expect(gameData.stagingMatches[0].players, lineup);
  });

  test('should_leave_no_one_waitlisted_when_single_game_saved', () async {
    // Arrange — 8 players fill both courts exactly, nobody waiting.
    final gameData = await twoCourts(8);

    // Act
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Assert — the saved players are still playing, not back in the pool.
    expect(gameData.waitlistedPlayers, isEmpty);
  });

  // ---------------------------------------------------------------------
  // PLAYING flag lifecycle
  // ---------------------------------------------------------------------

  test('should_mark_court_playing_when_single_game_saved', () async {
    // Arrange
    final gameData = await twoCourts(8);

    // Act
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Assert
    expect(gameData.isCourtPlaying(0), isTrue);
  });

  test('should_leave_other_courts_not_playing_when_one_court_saved', () async {
    // Arrange
    final gameData = await twoCourts(8);

    // Act
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Assert
    expect(gameData.isCourtPlaying(1), isFalse);
  });

  test('should_clear_playing_flag_when_court_rerolled', () async {
    // Arrange
    final gameData = await twoCourts(12);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Act — the real game finished, so the organizer re-rolls the court.
    gameData.makeSingleCourt(0);

    // Assert
    expect(gameData.isCourtPlaying(0), isFalse);
  });

  test('should_clear_all_playing_flags_when_game_regenerated', () async {
    // Arrange
    final gameData = await twoCourts(8);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    // Act
    await gameData.makeGame();

    // Assert
    expect(gameData.isCourtPlaying(0), isFalse);
  });

  test('should_report_not_playing_for_out_of_range_court', () async {
    // Arrange
    final gameData = await twoCourts(8);

    // Act & Assert
    expect(gameData.isCourtPlaying(9), isFalse);
  });

  // ---------------------------------------------------------------------
  // A logged lineup is locked
  // ---------------------------------------------------------------------

  test('should_ignore_slot_placement_into_playing_court', () async {
    // Arrange — 12 players so 4 are waitlisted.
    final gameData = await twoCourts(12);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    final lineup = [...gameData.stagingMatches[0].players];
    final waiting = gameData.waitlistedPlayers.first;

    // Act
    gameData.placePlayerInSlot(waiting, 0, 0);

    // Assert
    expect(gameData.stagingMatches[0].players, lineup);
  });

  test('should_still_allow_slot_placement_into_an_idle_court', () async {
    // Arrange
    final gameData = await twoCourts(12);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    final waiting = gameData.waitlistedPlayers.first;

    // Act — court 1 was never saved, so it stays editable.
    gameData.placePlayerInSlot(waiting, 1, 0);

    // Assert
    expect(gameData.stagingMatches[1].players.first, waiting);
  });

  // ---------------------------------------------------------------------
  // Players in play are unavailable to other courts
  // ---------------------------------------------------------------------

  test('should_exclude_playing_players_from_other_court_reroll', () async {
    // Arrange — exactly 8 players across 2 courts leaves no spare pool, so
    // re-rolling court 1 can only draw from court 1 itself.
    final gameData = await twoCourts(8);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    final playing = gameData.stagingMatches[0].players.toSet();

    // Act
    gameData.makeSingleCourt(1);

    // Assert
    expect(gameData.stagingMatches[1].players.any(playing.contains), isFalse);
  });

  // ---------------------------------------------------------------------
  // Regenerate visibility signal
  // ---------------------------------------------------------------------

  test('should_report_no_court_lineup_before_the_first_game', () async {
    // Arrange
    final gameData = GameData()..setNumberOfCourt(2);
    (await createTestPlayers(8)).forEach(gameData.addFullPricedPlayer);

    // Act & Assert
    expect(gameData.hasAnyCourtLineup, isFalse);
  });

  test('should_report_a_court_lineup_once_a_game_is_made', () async {
    // Arrange & Act
    final gameData = await twoCourts(8);

    // Assert
    expect(gameData.hasAnyCourtLineup, isTrue);
  });
}
