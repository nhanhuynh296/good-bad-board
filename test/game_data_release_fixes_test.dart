import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// Release fixes F1 (Save), F3 (court count), F4 (tier gap), F6 (re-rolls).
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('release_fixes_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<GameData> session(int total, {required int courts}) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (final player in await createTestPlayers(total)) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  Future<Player> playerWith(Elo elo) async {
    final player = Player.create(firstName: 'P', lastName: elo.name, elo: elo);
    await PlayerRepository.instance.add(player);
    return player;
  }

  group('F1 Save', () {
    test('should_keep_one_empty_court_per_court_after_save', () async {
      final gameData = await session(8, courts: 2);

      await gameData.saveCurrentGame();

      expect(gameData.stagingMatches, hasLength(2));
    });

    test('should_accept_a_slot_tap_after_save', () async {
      final gameData = await session(8, courts: 2);
      final player = gameData.checkedInPlayers.values.first;
      await gameData.saveCurrentGame();

      gameData.placePlayerInSlot(player, 0, 0);

      expect(gameData.stagingMatches[0].playerIds, [player.id]);
    });

    test('should_refuse_a_second_save_when_all_courts_are_empty', () async {
      final gameData = await session(8, courts: 2);
      await gameData.saveCurrentGame();

      expect(gameData.saveCurrentGame(), throwsException);
    });

    test('should_clear_the_staged_round_after_save', () async {
      final gameData = await session(12, courts: 2);
      gameData.stageNextRound();

      await gameData.saveCurrentGame();

      expect(gameData.isStaged, isFalse);
    });

    test('should_show_the_current_round_after_save', () async {
      final gameData = await session(12, courts: 2);
      gameData.stageNextRound();

      await gameData.saveCurrentGame();

      expect(gameData.roundView, RoundView.current);
    });
  });

  group('F3 court count', () {
    /// Four players on court 1, then one leaves and the other three are
    /// moved to court 2. Fewer than 4 are checked in, so a smaller count
    /// does not reshuffle.
    Future<GameData> threePlayersOnCourtTwo() async {
      final gameData = await session(4, courts: 2);
      final players = gameData.checkedInPlayers.values.toList();
      gameData.checkOutPlayer(players.first);
      for (var i = 1; i < 4; i++) {
        gameData.placePlayerInSlot(players[i], 1, i - 1);
      }
      return gameData;
    }

    test(
      'should_waitlist_players_on_removed_court_when_few_checked_in',
      () async {
        final gameData = await threePlayersOnCourtTwo();

        gameData.setNumberOfCourt(1);

        expect(gameData.waitlistedPlayers, hasLength(3));
      },
    );

    test('should_drop_court_beyond_new_count_when_few_checked_in', () async {
      final gameData = await threePlayersOnCourtTwo();

      gameData.setNumberOfCourt(1);

      expect(gameData.stagingMatches, hasLength(1));
    });

    test('should_drop_staged_court_beyond_new_count', () async {
      final gameData = await threePlayersOnCourtTwo();
      gameData.setNumberOfCourt(2);
      gameData.stageNextRound();

      gameData.setNumberOfCourt(1);

      expect(gameData.stagedLineup, hasLength(1));
    });
  });

  group('F4 tier gap', () {
    test('should_report_zero_tier_gap_for_two_intermediate_players', () async {
      final game = Game.create([
        await playerWith(Elo.b2),
        await playerWith(Elo.b1),
      ]);

      expect(game.tierGap(), 0);
    });

    test('should_report_one_tier_gap_across_neighbour_tiers', () async {
      final game = Game.create([
        await playerWith(Elo.c1),
        await playerWith(Elo.b2),
      ]);

      expect(game.tierGap(), 1);
    });

    test('should_report_three_tier_gap_from_amateur_to_professional', () async {
      final game = Game.create([
        await playerWith(Elo.c2),
        await playerWith(Elo.s1),
      ]);

      expect(game.tierGap(), 3);
    });

    test('should_report_zero_tier_gap_for_one_player', () async {
      final game = Game.create([await playerWith(Elo.c2)]);

      expect(game.tierGap(), 0);
    });

    test('should_keep_elo_gap_in_steps_of_the_eight_elo_values', () async {
      final game = Game.create([
        await playerWith(Elo.b2),
        await playerWith(Elo.b1),
      ]);

      expect(game.eloGap(), 1);
    });
  });

  group('F6 re-roll count', () {
    test('should_count_a_re_roll_on_the_current_round', () async {
      final gameData = await session(12, courts: 2);

      gameData.makeSingleCourt(0);

      expect(gameData.sessionRerollCount, 1);
    });

    test('should_not_count_a_re_roll_on_the_next_round', () async {
      final gameData = await session(12, courts: 2);
      gameData.stageNextRound();

      gameData.makeSingleCourt(0);

      expect(gameData.sessionRerollCount, 0);
    });
  });
}
