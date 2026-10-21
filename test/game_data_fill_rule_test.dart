import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// IMPLEMENTATION 8.4: the fill rule fills one place (8.4.0, 8.4.1), late
// check-in (8.4.3), check-out (8.4.4), Move to waitlist (8.4.5), and the
// COURT-14 edit rule (8.4.6). UAT WL-01…03, CHK-02, CHK-05, COURT-14…16.

void main() {
  late RepositorySandbox sandbox;
  late TimerData timer;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_fill_rule_test');
    timer = TimerData()..duration = const Duration(minutes: 10);
  });

  tearDown(() {
    timer.dispose();
    sandbox.tearDown();
  });

  Future<Player> player(String name, Elo elo) async {
    final created = Player.create(firstName: name, lastName: 'X', elo: elo);
    await PlayerRepository.instance.add(created);
    return created;
  }

  Future<List<Player>> four([Elo elo = Elo.b2]) async => [
    for (var i = 0; i < 4; i++) await player('C$i', elo),
  ];

  /// One court in READY that holds exactly [court]; [waiting] sit out, in
  /// that check-in order.
  GameData oneCourtDraft(List<Player> court, List<Player> waiting) {
    final gameData = GameData(timer: timer, random: Random(1))
      ..setNumberOfCourt(1);
    [...court, ...waiting].forEach(gameData.checkInPlayer);
    gameData.generateFirstRound();
    gameData.stagingMatches = [Game.create(court)];
    return gameData;
  }

  /// A session with [players] checked in, in that order, and no lineup.
  GameData checkedIn(List<Player> players) {
    final gameData = GameData(timer: timer);
    players.forEach(gameData.checkInPlayer);
    return gameData;
  }

  /// Gives [player] one logged round in this session.
  void playedOnce(GameData gameData, Player player) => gameData.history.add([
    Game.create([player]),
  ]);

  Future<GameData> fourCourts(int total) async {
    final gameData = GameData(timer: timer, random: Random(11));
    (await createTestPlayers(total)).forEach(gameData.checkInPlayer);
    return gameData;
  }

  Player byId(String id) => PlayerRepository.instance.byId(id)!;

  Set<String> idsOf(GameContainer lineup) => {
    for (final game in lineup) ...game.playerIds,
  };

  group('pickForSlot (8.4.1)', () {
    test('should_pick_fewest_rounds_when_candidates_differ', () async {
      final court = Game.create((await four()).take(3));
      final played = await player('Played', Elo.b2);
      final fresh = await player('Fresh', Elo.s1);
      final gameData = checkedIn([played, fresh]);
      playedOnce(gameData, played);

      expect(gameData.pickForSlot(court, [played, fresh]), fresh);
    });

    test('should_pick_smallest_level_gap_when_rounds_tie', () async {
      final court = Game.create((await four()).take(3));
      final far = await player('Far', Elo.s1);
      final near = await player('Near', Elo.b1);
      final gameData = checkedIn([far, near]);

      expect(gameData.pickForSlot(court, [far, near]), near);
    });

    test('should_pick_smaller_elo_gap_when_tier_gap_ties', () async {
      final court = Game.create((await four(Elo.b2)).take(3));
      final sameTierFar = await player('B1', Elo.b1);
      final same = await player('B2', Elo.b2);
      final gameData = checkedIn([sameTierFar, same]);

      expect(gameData.pickForSlot(court, [sameTierFar, same]), same);
    });

    test('should_pick_earliest_check_in_when_rounds_and_gap_tie', () async {
      final court = Game.create((await four()).take(3));
      final first = await player('First', Elo.b2);
      final second = await player('Second', Elo.b2);
      final gameData = checkedIn([first, second]);

      expect(gameData.pickForSlot(court, [second, first]), first);
    });

    test('should_return_null_when_no_candidates', () async {
      final court = Game.create((await four()).take(3));
      final gameData = checkedIn([]);

      expect(gameData.pickForSlot(court, []), isNull);
    });
  });

  group('full round keeps the matchmaker (8.4.0, R10-Q1)', () {
    test('should_seat_same_players_as_make_game_when_seeded', () async {
      final everyone = await createTestPlayers(18);
      final generated = GameData(timer: timer, random: Random(5));
      final made = GameData(timer: TimerData(), random: Random(5));
      everyone.forEach(generated.checkInPlayer);
      everyone.forEach(made.checkInPlayer);

      generated.generateFirstRound();
      await made.makeGame();

      expect(idsOf(generated.stagingMatches), idsOf(made.stagingMatches));
    });

    test('should_vary_who_sits_out_when_seed_changes', () async {
      final everyone = [
        for (final elo in [Elo.c2, Elo.c1, Elo.b2, Elo.b1, Elo.a2, Elo.a1])
          await player(elo.name, elo),
      ];
      final sitOuts = <Set<String>>{};
      for (var seed = 0; seed < 10; seed++) {
        final gameData = GameData(timer: TimerData(), random: Random(seed))
          ..setNumberOfCourt(1);
        everyone.forEach(gameData.checkInPlayer);
        gameData.generateFirstRound();
        sitOuts.add({for (final p in gameData.waitlistedPlayers) p.id});
      }

      expect(sitOuts.length, greaterThan(1));
    });
  });

  group('check-out fills one place (8.4.4, WL-02, CHK-05)', () {
    test('should_fill_by_fewest_rounds_when_draft_slot_freed', () async {
      // Fewest rounds beats the level gap, and the old highest-level order.
      final court = await four();
      final played = await player('Played', Elo.b2);
      final fresh = await player('Fresh', Elo.c2);
      final gameData = oneCourtDraft(court, [played, fresh]);
      playedOnce(gameData, played);

      gameData.checkOutPlayer(court.first);

      expect(gameData.stagingMatches[0].playerIds, contains(fresh.id));
    });

    test('should_fill_freed_slot_in_place_when_draft_slot_freed', () async {
      final court = await four();
      final waiter = await player('W', Elo.b2);
      final gameData = oneCourtDraft(court, [waiter]);

      gameData.checkOutPlayer(court[1]);

      expect(gameData.stagingMatches[0].playerIds[1], waiter.id);
    });

    test('should_name_who_takes_slot_when_checked_out', () async {
      final court = await four();
      final waiter = await player('W', Elo.b2);
      final gameData = oneCourtDraft(court, [waiter]);

      final fills = gameData.checkOutPlayer(court.first);

      expect(fills, [(player: waiter, courtIndex: 0, round: 1)]);
    });

    test('should_name_nobody_when_waitlisted_player_checked_out', () async {
      final court = await four();
      final waiter = await player('W', Elo.b2);
      final gameData = oneCourtDraft(court, [waiter]);

      expect(gameData.checkOutPlayer(waiter), isEmpty);
    });

    test('should_leave_open_slot_when_nobody_waits', () async {
      final court = await four();
      final gameData = oneCourtDraft(court, []);

      gameData.checkOutPlayer(court.first);

      expect(gameData.stagingMatches[0].playerIds, hasLength(3));
    });

    test('should_keep_player_on_live_court_when_clock_runs', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      final leaving = byId(gameData.stagingMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.stagingMatches[0].playerIds, contains(leaving.id));
    });

    test('should_drop_checked_in_count_when_clock_runs', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();

      gameData.checkOutPlayer(byId(gameData.stagingMatches[0].playerIds[0]));

      expect(gameData.checkedInCount, 17);
    });

    test('should_hide_slot_menu_when_checked_out_on_running_court', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      final leaving = byId(gameData.stagingMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.isCheckedOutOnLiveCourt(leaving), isTrue);
    });

    test('should_show_slot_menu_when_player_still_checked_in', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      final staying = byId(gameData.stagingMatches[0].playerIds[0]);

      expect(gameData.isCheckedOutOnLiveCourt(staying), isFalse);
    });

    test('should_log_player_in_round_when_checked_out_while_running', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      final leaving = byId(gameData.stagingMatches[0].playerIds[0]);
      gameData.checkOutPlayer(leaving);

      gameData.startNextRound();
      await gameData.startNextNow();

      expect(idsOf(gameData.history.last), contains(leaving.id));
    });

    test('should_fill_saved_next_round_when_clock_runs', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.quickSaveNextRound();
      final leaving = byId(gameData.nextLineup![0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.nextLineup![0].playerIds, hasLength(4));
    });

    test('should_name_round_2_when_saved_next_round_filled', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.quickSaveNextRound();
      final leaving = byId(gameData.nextLineup![2].playerIds[0]);

      final fills = gameData.checkOutPlayer(leaving);

      // A player on the running live court stays there: no live fill.
      expect(fills.map((fill) => (fill.courtIndex, fill.round)), [(2, 2)]);
    });

    test('should_fill_next_round_when_changeover', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.startNextRound();
      final leaving = byId(gameData.nextLineup![1].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.nextLineup![1].playerIds, hasLength(4));
    });

    test('should_keep_round_n_player_when_changeover', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.startNextRound();
      final leaving = byId(gameData.stagingMatches[1].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.stagingMatches[1].playerIds, contains(leaving.id));
    });

    test('should_fill_planned_round_when_time_up', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      timer.elapse(const Duration(minutes: 10));
      final leaving = byId(gameData.nextLineup![0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.nextLineup![0].playerIds, hasLength(4));
    });

    test('should_fill_live_court_when_paused', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.pause();
      final leaving = byId(gameData.stagingMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.stagingMatches[0].playerIds, isNot(contains(leaving.id)));
    });

    test('should_fill_edit_lineup_when_edit_mode_open', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.makeNextRound();
      final leaving = byId(gameData.visibleMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.visibleMatches[0].playerIds, hasLength(4));
    });

    test('should_keep_no_unsaved_edits_when_edit_lineup_filled', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.quickSaveNextRound();
      gameData.editNextRound();
      final leaving = byId(gameData.visibleMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.hasUnsavedEdits, isFalse);
    });

    test('should_not_refill_playing_court_when_next_round_on_screen', () async {
      // 8.4.2: the PLAYING check read the round on screen.
      await PersistentSetting.instance.setGameType(GameType.gameBased);
      final gameData = GameData(timer: timer, random: Random(2))
        ..setNumberOfCourt(3);
      (await createTestPlayers(14)).forEach(gameData.checkInPlayer);
      await gameData.makeGame();
      await gameData.saveSingleGame(gameData.stagingMatches[0]);
      gameData.stageNextRound();
      final leaving = byId(gameData.stagingMatches[0].playerIds[0]);

      gameData.checkOutPlayer(leaving);

      expect(gameData.stagingMatches[0].playerIds, hasLength(3));
    });
  });

  group('late check-in waits (8.4.3, CHK-02)', () {
    Future<Player> lateComer() => player('Late', Elo.b1);

    test('should_waitlist_late_player_when_draft_has_open_slot', () async {
      final gameData = await fourCourts(16);
      gameData.generateFirstRound();
      gameData.checkOutPlayer(byId(gameData.stagingMatches[0].playerIds[0]));
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.gameContainingPlayer(late), isNull);
    });

    test('should_waitlist_late_player_when_live_court_has_open_slot', () async {
      final gameData = await fourCourts(16);
      gameData.generateFirstRound();
      gameData.checkOutPlayer(byId(gameData.stagingMatches[0].playerIds[0]));
      gameData.startFirstRound();
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.gameContainingPlayer(late), isNull);
    });

    test('should_not_add_late_player_to_saved_next_round', () async {
      // Passes before 8.4.3 too: check-in never touched round n+1.
      final gameData = await fourCourts(16);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.quickSaveNextRound();
      gameData.checkOutPlayer(byId(gameData.nextLineup![0].playerIds[0]));
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(idsOf(gameData.nextLineup!), isNot(contains(late.id)));
    });

    test('should_waitlist_late_player_when_time_up', () async {
      final gameData = await fourCourts(16);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      gameData.pause();
      gameData.checkOutPlayer(byId(gameData.stagingMatches[0].playerIds[0]));
      gameData.resume();
      timer.elapse(const Duration(minutes: 10));
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(
        idsOf([...gameData.stagingMatches, ...gameData.nextLineup!]),
        isNot(contains(late.id)),
      );
    });

    test('should_start_late_player_at_zero_rounds', () async {
      final gameData = await fourCourts(16);
      gameData.generateFirstRound();
      gameData.history.add(gameData.stagingMatches);
      final late = await lateComer();

      gameData.checkInPlayer(late);

      expect(gameData.getCurrentPlayersHistory()[late], 0);
    });
  });

  group('Move to waitlist (8.4.5, COURT-15)', () {
    test('should_keep_player_checked_in_when_moved', () async {
      final court = await four();
      final gameData = oneCourtDraft(court, [await player('W', Elo.b2)]);

      gameData.moveToWaitlist(court.first);

      expect(gameData.isPlayerCheckedIn(court.first), isTrue);
    });

    test('should_waitlist_player_when_moved', () async {
      final court = await four();
      final gameData = oneCourtDraft(court, [await player('W', Elo.b2)]);

      gameData.moveToWaitlist(court.first);

      expect(gameData.visibleWaitlistedPlayers, contains(court.first));
    });

    test('should_fill_place_from_other_waiting_players_when_moved', () async {
      final court = await four();
      final waiter = await player('W', Elo.c2);
      final gameData = oneCourtDraft(court, [waiter]);

      gameData.moveToWaitlist(court.first);

      expect(gameData.stagingMatches[0].playerIds.first, waiter.id);
    });

    test('should_leave_open_slot_when_nobody_else_waits', () async {
      final court = await four();
      final gameData = oneCourtDraft(court, []);

      gameData.moveToWaitlist(court.first);

      expect(gameData.stagingMatches[0].playerIds, hasLength(3));
    });

    test('should_refuse_move_when_live_clock_runs', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();

      final moved = gameData.moveToWaitlist(
        byId(gameData.stagingMatches[0].playerIds[0]),
      );

      expect(moved, isFalse);
    });

    test('should_change_only_round_n_plus_1_when_edit_mode_open', () async {
      final gameData = await fourCourts(18);
      gameData.generateFirstRound();
      gameData.startFirstRound();
      final live = [
        for (final game in gameData.stagingMatches) List.of(game.playerIds),
      ];
      gameData.makeNextRound();

      gameData.moveToWaitlist(byId(gameData.visibleMatches[0].playerIds[0]));

      expect([
        for (final game in gameData.stagingMatches) game.playerIds,
      ], live);
    });
  });

  group('waitlist order (WL-01)', () {
    test('should_list_fewest_rounds_first', () async {
      final played = await player('Played', Elo.b2);
      final fresh = await player('Fresh', Elo.b2);
      final gameData = oneCourtDraft(await four(), [played, fresh]);
      playedOnce(gameData, played);

      expect(gameData.waitlistOrder, [fresh, played]);
    });

    test('should_break_tie_by_gap_on_first_open_court', () async {
      final court = (await four()).take(3).toList();
      final far = await player('Far', Elo.s1);
      final near = await player('Near', Elo.b1);
      final gameData = oneCourtDraft(court, [far, near]);

      expect(gameData.waitlistOrder, [near, far]);
    });

    test('should_break_tie_by_check_in_when_no_open_place', () async {
      final low = await player('Low', Elo.c2);
      final high = await player('High', Elo.s1);
      final gameData = oneCourtDraft(await four(), [low, high]);

      expect(gameData.waitlistOrder, [low, high]);
    });

    test('should_list_check_in_order_when_no_lineup', () async {
      final first = await player('First', Elo.s1);
      final second = await player('Second', Elo.c2);
      final gameData = GameData(timer: timer)
        ..checkInPlayer(first)
        ..checkInPlayer(second);
      playedOnce(gameData, first);

      expect(gameData.waitlistOrder, [first, second]);
    });
  });

  group('courts that can change (8.4.6, COURT-14)', () {
    late GameData gameData;

    setUp(() async {
      gameData = await fourCourts(18);
      gameData.generateFirstRound();
    });

    test('should_allow_edits_when_ready', () {
      expect(gameData.canEditCourts, isTrue);
    });

    test('should_refuse_edits_when_running', () {
      gameData.startFirstRound();

      expect(gameData.canEditCourts, isFalse);
    });

    test('should_allow_edits_when_paused', () {
      gameData.startFirstRound();
      gameData.pause();

      expect(gameData.canEditCourts, isTrue);
    });

    test('should_allow_edits_when_time_up', () {
      gameData.startFirstRound();
      timer.elapse(const Duration(minutes: 10));

      expect(gameData.canEditCourts, isTrue);
    });

    test('should_refuse_edits_when_changeover', () {
      gameData.startFirstRound();
      gameData.startNextRound();

      expect(gameData.canEditCourts, isFalse);
    });

    test('should_allow_edits_when_changeover_paused', () {
      gameData.startFirstRound();
      gameData.startNextRound();
      gameData.pause();

      expect(gameData.canEditCourts, isTrue);
    });

    test('should_allow_edits_when_editing_next_round', () {
      gameData.startFirstRound();
      gameData.makeNextRound();

      expect(gameData.canEditCourts, isTrue);
    });
  });
}
