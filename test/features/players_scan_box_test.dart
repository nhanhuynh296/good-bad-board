import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';

import '../support/players_harness.dart';

// IMPLEMENTATION 8.7.1, 8.7.2, 8.7.4, 8.7.7: the desktop scan field, the
// scan result box, the scanned-twice guard and the refused row tap.
// UAT PLY-13, PLY-14, PLY-16 … PLY-19, CHK-01, CHK-03, CHK-06.

void main() {
  setUpPlayersSandbox('players_scan_box_test');

  final alice = testPlayer('Alice', Elo.b1, signInId: 'A100');
  final bob = testPlayer('Bob', Elo.a2, signInId: 'B200');
  final dave = testPlayer(
    'Dave',
    Elo.c1,
    signInId: 'D400',
    membership: MembershipStatus.disabled,
  );

  group('Scan field (8.7.1)', () {
    testWidgets('should_show_the_check_in_label', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.text('CHECK IN'), findsOneWidget);
    });

    testWidgets('should_show_the_scan_placeholder', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.text('Scan card or search name'), findsOneWidget);
    });

    testWidgets('should_be_52_px_tall', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(tester.getSize(h.scanField).height, 52);
    });

    testWidgets('should_draw_the_focus_ring_only_around_the_scan_field', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(
        tester.getSize(find.byKey(const Key('players-scan-focus-ring'))).height,
        tester.getSize(h.scanField).height + 10,
      );
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('should_draw_no_second_border_inside_the_scan_field', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      final decoration = tester
          .widget<TextField>(
            find.descendant(of: h.scanField, matching: find.byType(TextField)),
          )
          .decoration!;

      expect(
        [decoration.enabledBorder, decoration.focusedBorder],
        [InputBorder.none, InputBorder.none],
      );
    });

    testWidgets('should_keep_the_rows_clear_of_the_scroll_bar', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(
        players: [for (var i = 0; i < 30; i++) testPlayer('Player $i', Elo.b1)],
      );

      expect(
        tester.getTopRight(h.rowOf('Player 0')).dx,
        lessThanOrEqualTo(tester.getTopRight(find.byType(ListView)).dx - 16),
      );
    });

    testWidgets('should_focus_the_scan_field_when_the_page_opens', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });

    testWidgets('should_show_the_checked_in_count_over_the_capacity', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('/ 20 in'), findsOneWidget);
    });

    testWidgets('should_show_the_places_left', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      expect(find.text('19 places left'), findsOneWidget);
    });

    testWidgets('should_say_one_place_left_when_one_place_remains', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      final four = [for (var i = 0; i < 4; i++) testPlayer('P$i', Elo.b1)];
      await h.pump(players: [...four, alice], sessionCapacity: 5);
      four.forEach(h.gameData.checkInPlayer);
      await tester.pump();

      expect(find.text('1 place left'), findsOneWidget);
    });

    testWidgets('should_not_show_a_capacity_bar_on_desktop', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.byType(CapacityBar), findsNothing);
    });

    testWidgets('should_open_the_add_dialog_when_add_player_is_tapped', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.tap(find.text('Add player'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPlayerDialog), findsOneWidget);
    });

    testWidgets('should_show_the_at_capacity_banner_at_capacity', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      final four = [for (var i = 0; i < 4; i++) testPlayer('P$i', Elo.b1)];
      await h.pump(players: four, sessionCapacity: 4);
      four.forEach(h.gameData.checkInPlayer);
      await tester.pump();

      expect(find.byType(AtCapacityBanner), findsOneWidget);
    });
  });

  group('Tier chips (R6-Q13)', () {
    testWidgets('should_show_four_tier_chips', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(SkillTier.values.map((t) => h.tierChip(t).evaluate().length), [
        1,
        1,
        1,
        1,
      ]);
    });

    testWidgets('should_not_show_elo_code_chips', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.text('C2'), findsNothing);
    });

    testWidgets('should_list_only_the_tier_of_a_chip_that_is_on', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.tap(h.tierChip(SkillTier.advanced));

      expect(find.byType(DesktopPlayerRow), findsOneWidget);
    });

    testWidgets('should_list_everyone_again_when_the_chip_is_off', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.tap(h.tierChip(SkillTier.advanced));

      await h.tap(h.tierChip(SkillTier.advanced));

      expect(find.byType(DesktopPlayerRow), findsNWidgets(2));
    });

    testWidgets(
      'should_check_in_by_exact_sign_in_id_when_tier_chip_hides_player',
      (tester) async {
        final h = PlayersHarness(tester);
        await h.pump(players: [alice, bob]);
        await h.tap(h.tierChip(SkillTier.advanced));

        await h.scan('A100');

        expect(h.gameData.isPlayerCheckedIn(alice), isTrue);
      },
    );

    testWidgets('should_keep_the_tier_chip_on_after_a_scan', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.tap(h.tierChip(SkillTier.advanced));

      await h.scan('A100');

      expect(
        tester
            .getSemantics(h.tierChip(SkillTier.advanced))
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );
    });

    testWidgets('should_refocus_the_scan_field_after_a_chip_tap', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.tap(h.tierChip(SkillTier.advanced));
      await tester.pump();

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });
  });

  group('Scan text and focus (PLY-14, F19, F21)', () {
    testWidgets('should_select_all_the_text_after_a_scan', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');
      await tester.pump();

      expect(
        h.scanEditable.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
    });

    testWidgets('should_put_the_caret_at_the_end_after_many_matches', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.scan('Test');
      await tester.pump();

      expect(
        h.scanEditable.controller.selection,
        const TextSelection.collapsed(offset: 4),
      );
    });

    testWidgets('should_keep_focus_in_the_scan_field_after_a_scan', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');
      await tester.pump();

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });

    testWidgets('should_return_focus_to_the_scan_field_on_esc', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');
      await h.tap(find.byKey(const Key('player-sign-in-id-field')));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });

    testWidgets('should_check_in_when_the_done_action_is_sent', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await tester.enterText(h.scanField, 'A100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(h.gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_do_nothing_when_enter_is_sent_on_an_empty_field', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('');

      expect(h.result.kind, ScanKind.ready);
    });
  });

  group('Scan result box (8.7.2, PLY-16 … PLY-18)', () {
    testWidgets('should_show_ready_before_the_first_scan', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.text('Ready to scan'), findsOneWidget);
      expect(
        find.text('Scan a card, or type a name and press Enter.'),
        findsOneWidget,
      );
    });

    testWidgets('should_say_who_is_in_and_the_round_they_wait_for', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');

      expect(h.result.kind, ScanKind.checkedIn);
      expect(find.text('is in · waits for round 1'), findsOneWidget);
    });

    testWidgets('should_name_the_player_in_the_result_box', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');

      expect(
        find.descendant(
          of: find.byType(ScanResultBox),
          matching: find.text('Alice Test'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_say_is_out_when_nobody_takes_the_slot', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      await h.scan('A100');

      expect(h.result.kind, ScanKind.checkedOut);
      expect(find.text('is out'), findsOneWidget);
    });

    testWidgets('should_name_who_takes_the_freed_court_slot', (tester) async {
      final h = PlayersHarness(tester);
      final players = [
        for (var i = 0; i < 5; i++) testPlayer('P$i', Elo.b1, signInId: 'S$i'),
      ];
      await h.pump(players: players, courts: 1);
      players.forEach(h.gameData.checkInPlayer);
      h.gameData.generateFirstRound();
      final onCourt = h.gameData.stagingMatches.first.playerIds.first;
      final waiting = players.firstWhere(
        (p) => !h.gameData.stagingMatches.first.playerIds.contains(p.id),
      );
      await tester.pump();

      await h.scan('S${onCourt.substring(1)}');

      expect(
        find.text('is out · ${waiting.name()} takes Court 1 in round 1'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_not_found_when_nothing_matches', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('ZZZ');

      expect(find.text('No match'), findsOneWidget);
      expect(
        find.text('for “ZZZ”. Check the card, or add the player.'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_many_matches_when_the_list_has_many', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.scan('Test');

      expect(find.text('2 players match'), findsOneWidget);
      expect(
        find.text('“Test” · nothing changed. Tap a row, or type more.'),
        findsOneWidget,
      );
    });

    testWidgets('should_change_nobody_on_many_matches', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.scan('Test');

      expect(h.gameData.checkedInCount, 0);
    });

    testWidgets('should_show_session_full_when_at_capacity', (tester) async {
      final h = PlayersHarness(tester);
      final four = [for (var i = 0; i < 4; i++) testPlayer('P$i', Elo.b1)];
      await h.pump(players: [...four, alice], sessionCapacity: 4);
      four.forEach(h.gameData.checkInPlayer);
      await tester.pump();

      await h.scan('A100');

      expect(find.text('Session full'), findsOneWidget);
      expect(
        find.text('4 / 4 in · Alice Test is not checked in.'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_disabled_for_a_disabled_player', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      await h.scan('D400');

      expect(
        find.text('is disabled · enable the player in More to check in.'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_duplicate_id_when_two_players_share_it', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(
        players: [
          alice,
          testPlayer('Ann', Elo.b1, signInId: 'A100'),
        ],
      );

      await h.scan('A100');

      expect(find.text('ID A100'), findsOneWidget);
      expect(
        find.text(
          'is used by 2 players · nothing changed. Fix the ID in More.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_not_change_the_box_when_a_row_is_tapped', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.scan('A100');

      await h.tapRow('Alice');

      expect(h.result.kind, ScanKind.checkedIn);
    });

    testWidgets('should_have_no_undo_button', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');

      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('should_not_show_a_snackbar_after_a_scan', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should_read_the_box_as_a_polite_live_region', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      final node = tester.getSemantics(find.byType(ScanResultBox));

      expect(node.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('should_keep_the_result_until_the_next_scan', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.scan('A100');

      await h.scan('B200');

      expect(h.result.player?.id, 'Bob');
    });

    testWidgets('should_fill_the_checked_in_box_green', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.scan('A100');

      final box = tester.widget<DecoratedBox>(
        find.byKey(const Key('scan-result-decoration')),
      );
      expect((box.decoration as BoxDecoration).color, const Color(0xFFBFE5C8));
    });
  });

  group('Scanned twice (8.7.4, PLY-19)', () {
    testWidgets('should_change_nothing_when_the_last_card_is_scanned_again', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');

      await h.scan('A100');

      expect(h.gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_show_scanned_twice_for_the_last_card', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');

      await h.scan('A100');

      expect(
        find.text(
          'is already in (same card as the last scan). Nothing changed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_guard_with_no_time_limit', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');
      await tester.pump(const Duration(minutes: 5));

      await h.scan('A100');

      expect(h.result.kind, ScanKind.scannedTwice);
    });

    testWidgets('should_check_out_from_the_scanned_twice_box', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');
      await h.scan('A100');

      await h.tap(find.text('Check out'));

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_show_checked_out_after_check_out_in_the_box', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');
      await h.scan('A100');

      await h.tap(find.text('Check out'));

      expect(h.result.kind, ScanKind.checkedOut);
    });

    testWidgets('should_check_out_when_another_card_was_scanned_between', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.scan('A100');
      await h.scan('B200');

      await h.scan('A100');

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_check_in_again_after_a_guarded_player_checked_out', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.scan('A100');
      await h.tapRow('Alice');

      await h.scan('A100');

      expect(h.gameData.isPlayerCheckedIn(alice), isTrue);
    });
  });

  group('Row tap messages (R4-Q1, CHK-03, CHK-06)', () {
    testWidgets('should_show_a_bottom_message_for_a_disabled_row_tap', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      await h.tapRow('Dave');

      expect(
        find.text('Dave Test is disabled — cannot check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_the_capacity_message_for_a_refused_row_tap', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      final four = [for (var i = 0; i < 4; i++) testPlayer('P$i', Elo.b1)];
      await h.pump(players: [...four, alice], sessionCapacity: 4);
      four.forEach(h.gameData.checkInPlayer);
      await tester.pump();

      await h.tapRow('Alice');

      expect(
        find.text('Session at capacity — cannot check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_no_message_for_a_row_tap_that_checks_in', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.tapRow('Alice');

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should_refocus_the_scan_field_after_a_row_tap', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.tapRow('Alice');
      await tester.pump();

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });
  });

  test('ScanKind has the nine result states (8.7.2)', () {
    expect(ScanKind.values.length, 9);
  });
}
