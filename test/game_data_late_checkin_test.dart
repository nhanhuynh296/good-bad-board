import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// With every court empty. A court added then, and a late check-in,
/// must both behave (SESS-04, CHK-02).
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    // These tests cover court-count changes, hidden in the release.
    CourtCount.editable = true;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('late_checkin_test');
  });

  tearDown(() {
    CourtCount.editable = true;
    sandbox.tearDown();
  });

  Future<GameData> savedSession(int total, {required int courts}) async {
    final gameData = GameData()..setNumberOfCourt(courts);
    for (final player in await createTestPlayers(total)) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    // Every court empty, as after the old time-mode Save (removed in 8.2.2).
    for (final player in [...gameData.checkedInPlayers.values]) {
      gameData.removePlayerFromCourt(player);
    }
    return gameData;
  }

  Future<Player> lateComer() async {
    final player = Player.create(
      firstName: 'Late',
      lastName: 'Comer',
      elo: Elo.b1,
    );
    await PlayerRepository.instance.add(player);
    return player;
  }

  group('court count grows with every court empty', () {
    test('should_pad_the_courts_when_the_count_grows', () async {
      final gameData = await savedSession(8, courts: 2);

      gameData.setNumberOfCourt(3);

      expect(gameData.stagingMatches, hasLength(3));
    });

    test('should_accept_a_slot_tap_on_the_new_court', () async {
      final gameData = await savedSession(8, courts: 2);
      final player = gameData.checkedInPlayers.values.first;
      gameData.setNumberOfCourt(3);

      gameData.placePlayerInSlot(player, 2, 0);

      expect(gameData.stagingMatches[2].playerIds, [player.id]);
    });

    test('should_not_throw_when_the_new_court_is_re_rolled', () async {
      final gameData = await savedSession(8, courts: 2);
      gameData.setNumberOfCourt(3);

      expect(() => gameData.makeSingleCourt(2), returnsNormally);
    });

    test(
      'should_pad_the_courts_when_a_template_with_more_courts_loads',
      () async {
        final gameData = await savedSession(8, courts: 2);
        final template = SessionTemplate.create(
          name: 'T',
          gameType: GameType.timeBased,
          durationMinutes: 20,
          durationSeconds: 0,
          capacity: 20,
          courts: 4,
        );

        gameData.loadTemplate(template);

        expect(gameData.stagingMatches, hasLength(4));
      },
    );
  });

  group('late check-in with every court empty (time mode)', () {
    test('should_waitlist_the_player_when_every_court_is_empty', () async {
      final gameData = await savedSession(8, courts: 2);
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.gameContainingPlayer(late), isNull);
    });

    test('should_list_the_late_player_on_the_waitlist', () async {
      final gameData = await savedSession(8, courts: 2);
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.waitlistedPlayers, contains(late));
    });

    // CHK-02 (R7-Q7): a late player never joins a court in time mode, also
    // when a court has an open slot (was "should_still_fill_a_part_full_court").
    test('should_waitlist_late_player_when_a_court_is_part_full', () async {
      final gameData = await savedSession(8, courts: 2);
      final first = gameData.checkedInPlayers.values.first;
      final second = gameData.checkedInPlayers.values.last;
      gameData.placePlayerInSlot(first, 1, 0);
      gameData.placePlayerInSlot(second, 1, 1);
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.stagingMatches[1].playerIds, isNot(contains(late.id)));
    });
  });
}
