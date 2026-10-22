import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// Moving a player between courts swaps them with the player in the target
/// slot, and removing a player sends them to the waitlist.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('court_swap_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<GameData> twoCourts(int total) async {
    final gameData = GameData()..setNumberOfCourt(2);
    for (final player in await createTestPlayers(total)) {
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  test('should_put_the_moved_player_in_the_target_slot', () async {
    final gameData = await twoCourts(8);
    final a = gameData.stagingMatches[0].players[1];

    gameData.placePlayerInSlot(a, 1, 2);

    expect(gameData.stagingMatches[1].players[2], a);
  });

  test('should_put_the_displaced_player_in_the_source_slot', () async {
    final gameData = await twoCourts(8);
    final a = gameData.stagingMatches[0].players[1];
    final b = gameData.stagingMatches[1].players[2];

    gameData.placePlayerInSlot(a, 1, 2);

    expect(gameData.stagingMatches[0].players[1], b);
  });

  test('should_keep_every_player_on_court_after_a_swap', () async {
    final gameData = await twoCourts(8);
    final a = gameData.stagingMatches[0].players[1];

    gameData.placePlayerInSlot(a, 1, 2);

    expect(gameData.waitlistedPlayers, isEmpty);
  });

  test('should_move_into_an_open_slot_without_a_swap', () async {
    final gameData = await twoCourts(8);
    gameData.removePlayerFromCourt(gameData.stagingMatches[0].players[3]);
    final a = gameData.stagingMatches[1].players[0];

    gameData.placePlayerInSlot(a, 0, 3);

    expect(gameData.stagingMatches[1].players, hasLength(3));
  });

  test('should_not_take_a_player_out_of_a_playing_court', () async {
    final gameData = await twoCourts(8);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    final lineup = [...gameData.stagingMatches[0].players];

    gameData.placePlayerInSlot(lineup[0], 1, 0);

    expect(gameData.stagingMatches[0].players, lineup);
  });

  test('should_send_a_removed_player_to_the_waitlist', () async {
    final gameData = await twoCourts(8);
    final a = gameData.stagingMatches[0].players[0];

    gameData.removePlayerFromCourt(a);

    expect(gameData.waitlistedPlayers, contains(a));
  });

  test('should_not_remove_a_player_from_a_playing_court', () async {
    final gameData = await twoCourts(8);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    final a = gameData.stagingMatches[0].players[0];

    gameData.removePlayerFromCourt(a);

    expect(gameData.stagingMatches[0].players, contains(a));
  });
}
