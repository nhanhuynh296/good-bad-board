import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// R45-02: GameData refuses a lineup with a typed LineupError, not English
// Exception text.

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_lineup_error_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<GameData> session(int players, {int courts = 2}) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (final player in await createTestPlayers(players)) {
      gameData.checkInPlayer(player);
    }
    return gameData;
  }

  Future<Object?> errorOf(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      return e;
    }
    return null;
  }

  test(
    'should_refuse_generate_with_two_players_as_not_enough_players',
    () async {
      final gameData = await session(2);

      final error = await errorOf(gameData.makeGame);

      expect(error, const NotEnoughPlayers(count: 2));
    },
  );

  test(
    'should_refuse_generate_with_no_players_as_not_enough_players',
    () async {
      final gameData = await session(0);

      final error = await errorOf(gameData.makeGame);

      expect(error, const NotEnoughPlayers(count: 0));
    },
  );

  test('should_refuse_save_with_a_three_player_court_as_unbalanced', () async {
    final gameData = await session(8);
    await gameData.makeGame();
    final court2 = gameData.stagingMatches[1].players;
    gameData.removePlayerFromCourt(court2.first);

    final error = await errorOf(gameData.saveCurrentGame);

    expect(error, const UnbalancedCourts(courtNumbers: [2]));
  });

  test('should_refuse_save_with_empty_courts_as_nothing_to_save', () async {
    final gameData = await session(8);

    final error = await errorOf(gameData.saveCurrentGame);

    expect(error, const NothingToSave());
  });

  test('should_refuse_saving_an_empty_court_as_nothing_to_save', () async {
    final gameData = await session(8);

    final error = await errorOf(() => gameData.saveSingleGame(Game.create([])));

    expect(error, const NothingToSave());
  });

  test('should_refuse_saving_a_three_player_court_as_unbalanced', () async {
    final gameData = await session(8);
    await gameData.makeGame();
    final court1 = gameData.stagingMatches[0];
    gameData.removePlayerFromCourt(court1.players.first);

    final error = await errorOf(
      () => gameData.saveSingleGame(gameData.stagingMatches[0]),
    );

    expect(error, const UnbalancedCourts(courtNumbers: [1]));
  });

  test('should_keep_a_lineup_error_an_exception', () async {
    final gameData = await session(2);

    expect(gameData.makeGame(), throwsException);
  });
}
