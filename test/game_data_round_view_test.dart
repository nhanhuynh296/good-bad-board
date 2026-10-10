import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';
import 'support/prefs_sandbox.dart';

/// RND-05 (revised): the pre-made next round is shown on the courts.
///
/// The organizer selects which round the court grid renders — the live round
/// or the pre-made next round — and can edit the next round in place before
/// it starts.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('round_view_test');
  });

  tearDown(() => sandbox.tearDown());

  /// A session with [total] checked-in players across 2 generated courts.
  Future<GameData> session(int total) async {
    final gameData = GameData()..setNumberOfCourt(2);
    for (final player in await createTestPlayers(total)) {
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  Set<String> idsOn(GameContainer courts) =>
      courts.expand((game) => game.players).map((p) => p.id).toSet();

  // ---------------------------------------------------------------------
  // View selection
  // ---------------------------------------------------------------------
  group('round view selection', () {
    test('should_start_on_current_view', () async {
      final data = await session(12);

      expect(data.roundView, equals(RoundView.current));
    });

    test('should_ignore_next_view_when_nothing_is_staged', () async {
      final data = await session(12);

      data.setRoundView(RoundView.next);

      expect(data.roundView, equals(RoundView.current));
    });

    test('should_select_next_view_when_a_round_is_staged', () async {
      final data = await session(12);

      data.stageNextRound();

      expect(data.roundView, equals(RoundView.next));
    });

    test('should_return_to_current_view_when_staged_round_cancelled', () async {
      final data = await session(12);
      data.stageNextRound();

      data.cancelStagedRound();

      expect(data.roundView, equals(RoundView.current));
    });

    test('should_not_stage_when_no_lineup_can_be_computed', () async {
      final data = GameData()..setNumberOfCourt(2);

      data.stageNextRound();

      expect(data.isStaged, isFalse);
      expect(data.roundView, equals(RoundView.current));
    });
  });

  // ---------------------------------------------------------------------
  // What the courts render
  // ---------------------------------------------------------------------
  group('visibleMatches', () {
    test('should_return_live_lineup_on_current_view', () async {
      final data = await session(12);

      expect(data.visibleMatches, same(data.stagingMatches));
    });

    test('should_return_staged_lineup_on_next_view', () async {
      final data = await session(12);
      data.stageNextRound();

      expect(data.visibleMatches, same(data.stagedLineup));
    });

    test('should_return_live_lineup_after_switching_back', () async {
      final data = await session(12);
      data.stageNextRound();

      data.setRoundView(RoundView.current);

      expect(data.visibleMatches, same(data.stagingMatches));
    });

    test('should_leave_live_lineup_untouched_when_staging', () async {
      final data = await session(12);
      final liveBefore = idsOn(data.stagingMatches);

      data.stageNextRound();

      expect(idsOn(data.stagingMatches), equals(liveBefore));
    });
  });

  // ---------------------------------------------------------------------
  // The waitlist follows the visible round — otherwise the committee can
  // double-book a player or lose one.
  // ---------------------------------------------------------------------
  group('visibleWaitlistedPlayers', () {
    test('should_match_live_waitlist_on_current_view', () async {
      final data = await session(12);

      expect(
        data.visibleWaitlistedPlayers.map((p) => p.id).toSet(),
        equals(data.waitlistedPlayers.map((p) => p.id).toSet()),
      );
    });

    test('should_list_players_off_the_staged_courts_on_next_view', () async {
      final data = await session(12);
      data.stageNextRound();

      final onStaged = idsOn(data.stagedLineup!);
      final visibleWaitlist = data.visibleWaitlistedPlayers
          .map((p) => p.id)
          .toSet();

      expect(visibleWaitlist.intersection(onStaged), isEmpty);
      expect(
        visibleWaitlist.union(onStaged),
        equals(data.checkedInPlayers.keys.toSet()),
      );
    });

    test('should_drop_a_player_placed_onto_a_staged_court', () async {
      final data = await session(12);
      data.stageNextRound();
      final spare = data.visibleWaitlistedPlayers.first;

      data.placePlayerInSlot(spare, 0, 0);

      expect(
        data.visibleWaitlistedPlayers.map((p) => p.id),
        isNot(contains(spare.id)),
      );
    });

    test('should_not_show_the_same_player_twice_after_a_staged_swap', () async {
      final data = await session(12);
      data.stageNextRound();
      final spare = data.visibleWaitlistedPlayers.first;

      data.placePlayerInSlot(spare, 0, 0);

      final staged = idsOn(data.stagedLineup!).toList();
      final allStagedIds = data.stagedLineup!
          .expand((g) => g.players)
          .map((p) => p.id)
          .toList();
      expect(allStagedIds.length, equals(staged.length));
    });
  });

  // ---------------------------------------------------------------------
  // Editing the staged round
  // ---------------------------------------------------------------------
  group('editing the next round', () {
    test('should_place_player_onto_the_staged_court_only', () async {
      final data = await session(12);
      final liveBefore = idsOn(data.stagingMatches);
      data.stageNextRound();
      final spare = data.visibleWaitlistedPlayers.first;

      data.placePlayerInSlot(spare, 0, 0);

      expect(data.stagedLineup![0].players.first.id, equals(spare.id));
      expect(idsOn(data.stagingMatches), equals(liveBefore));
    });

    test('should_reroll_the_staged_court_only', () async {
      final data = await session(12);
      final liveBefore = idsOn(data.stagingMatches);
      data.stageNextRound();

      data.makeSingleCourt(0);

      expect(data.stagedLineup![0].players, hasLength(Game.playerPerCourt));
      expect(idsOn(data.stagingMatches), equals(liveBefore));
    });

    test('should_place_on_the_live_court_when_current_view_selected', () async {
      final data = await session(12);
      data.stageNextRound();
      data.setRoundView(RoundView.current);
      final stagedBefore = idsOn(data.stagedLineup!);
      final spare = data.visibleWaitlistedPlayers.first;

      data.placePlayerInSlot(spare, 0, 0);

      expect(data.stagingMatches[0].players.first.id, equals(spare.id));
      expect(idsOn(data.stagedLineup!), equals(stagedBefore));
    });
  });

  // ---------------------------------------------------------------------
  // Rotation adopts what the organizer edited
  // ---------------------------------------------------------------------
  group('rotateNow with an edited staged round', () {
    test('should_adopt_the_edited_lineup', () async {
      final data = await session(12);
      data.stageNextRound();
      final spare = data.visibleWaitlistedPlayers.first;
      data.placePlayerInSlot(spare, 0, 0);

      await data.rotateNow();

      expect(data.stagingMatches[0].players.first.id, equals(spare.id));
    });

    test('should_return_to_the_current_view', () async {
      final data = await session(12);
      data.stageNextRound();

      await data.rotateNow();

      expect(data.roundView, equals(RoundView.current));
      expect(data.isStaged, isFalse);
    });

    test('should_log_the_finished_round_to_history', () async {
      final data = await session(12);
      final finished = idsOn(data.stagingMatches);
      data.stageNextRound();

      await data.rotateNow();

      expect(data.history, hasLength(1));
      expect(idsOn(data.history.first), equals(finished));
    });

    test('should_write_a_session_log_snapshot', () async {
      final data = await session(12);

      await data.rotateNow();

      final logs = SessionLogRepository.instance.getAll();
      expect(logs, hasLength(1));
    });

    test('should_reset_the_reroll_counter_when_the_round_is_logged', () async {
      final data = await session(12);
      data.makeSingleCourt(0);
      expect(data.sessionRerollCount, greaterThan(0));

      await data.rotateNow();

      expect(data.sessionRerollCount, equals(0));
    });

    test('should_log_an_incomplete_court_instead_of_throwing', () async {
      final data = await session(12);
      // Strip a player so court 0 is no longer playable.
      data.removePlayerFromCourt(data.stagingMatches[0].players.first);
      expect(data.stagingMatches[0].players, hasLength(3));

      await data.rotateNow();

      expect(data.history, hasLength(1));
    });

    test('should_not_log_an_empty_round', () async {
      final data = GameData()..setNumberOfCourt(2);

      await data.rotateNow();

      expect(data.history, isEmpty);
    });
  });

  // ---------------------------------------------------------------------
  // A half-made lineup must never block or break the rotation. The clock
  // running out starts the next round regardless; the committee fills the
  // gaps afterwards.
  // ---------------------------------------------------------------------
  group('rotating a half-made lineup', () {
    test('should_rotate_when_a_live_court_holds_three_players', () async {
      final data = await session(12);
      data.removePlayerFromCourt(data.stagingMatches[0].players.first);
      expect(data.stagingMatches[0].players, hasLength(3));

      await data.rotateNow();

      expect(data.roundNumber, equals(2));
    });

    test('should_rotate_when_a_live_court_is_empty', () async {
      final data = await session(12);
      for (final player in data.stagingMatches[0].players.toList()) {
        data.removePlayerFromCourt(player);
      }
      expect(data.stagingMatches[0].players, isEmpty);

      await data.rotateNow();

      expect(data.roundNumber, equals(2));
    });

    test('should_keep_the_players_on_a_half_made_staged_court', () async {
      final data = await session(12);
      data.stageNextRound();
      final victim = data.stagedLineup![0].players.first;
      data.removePlayerFromCourt(victim);
      final kept = data.stagedLineup![0].players.map((p) => p.id).toList();
      expect(kept, hasLength(3));

      await data.rotateNow();

      // Adopted exactly as edited — the short court is not refilled or wiped.
      expect(
        data.stagingMatches[0].players.map((p) => p.id).toList(),
        equals(kept),
      );
      expect(data.roundNumber, equals(2));
    });

    test('should_rotate_with_fewer_players_than_court_slots', () async {
      // 6 players across 2 courts — one court can never be filled.
      final data = await session(6);

      await data.rotateNow();

      expect(data.roundNumber, equals(2));
      expect(data.stagingMatches, hasLength(2));
    });

    test('should_balance_a_lineup_that_holds_a_short_court', () async {
      // The optimizer used to index every court's 4 slots blindly, so a court
      // holding fewer than 4 players threw a RangeError.
      final data = await session(12);
      data.removePlayerFromCourt(data.stagingMatches[0].players.first);

      expect(
        () => GameData.improveEloSpreadForTesting(data.stagingMatches),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------
  // The staged lineup must not go stale
  // ---------------------------------------------------------------------
  group('staged lineup upkeep', () {
    test('should_remove_a_checked_out_player_from_staged_courts', () async {
      final data = await session(12);
      data.stageNextRound();
      final victim = data.stagedLineup![0].players.first;

      data.checkOutPlayer(victim);

      expect(idsOn(data.stagedLineup!), isNot(contains(victim.id)));
    });

    test('should_pad_the_staged_lineup_when_courts_are_added', () async {
      final data = await session(12);
      data.stageNextRound();

      data.setNumberOfCourt(3);

      expect(data.stagedLineup!.length, greaterThanOrEqualTo(3));
    });
  });
}
