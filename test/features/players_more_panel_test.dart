import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_confirm_dialog.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';

import '../support/players_harness.dart';

// IMPLEMENTATION 8.7.6: the desktop More panel, as drawn on the canvas
// board "Players · More panel" (R6-Q17). UAT PLY-05 … PLY-07, PLY-09 …
// PLY-11, PLY-15.

void main() {
  setUpPlayersSandbox('players_more_panel_test');

  final alice = testPlayer('Alice', Elo.b1, signInId: 'A100');
  final bob = testPlayer('Bob', Elo.a2, signInId: 'B200');

  Player stored(String id) => PlayerRepository.instance.byId(id)!;

  Finder key(String value) => find.byKey(Key(value));

  group('Open and close (PLY-09 … PLY-11)', () {
    testWidgets('should_open_the_panel_when_more_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.openMore('Alice');

      expect(find.byType(MorePanel), findsOneWidget);
    });

    testWidgets('should_open_the_panel_under_its_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);

      await h.openMore('Alice');

      expect(
        tester.getTopLeft(find.byType(MorePanel)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(h.rowOf('Alice')).dy),
      );
    });

    testWidgets('should_open_one_panel_at_a_time', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.openMore('Alice');

      await h.openMore('Bob');

      expect(find.byType(MorePanel), findsOneWidget);
    });

    testWidgets('should_close_the_panel_when_more_is_tapped_again', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.openMore('Alice');

      expect(find.byType(MorePanel), findsNothing);
    });

    testWidgets('should_close_the_panel_when_close_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-close'));

      expect(find.byType(MorePanel), findsNothing);
    });

    testWidgets('should_show_the_stat_tiles', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      for (final label in ['CURRENT LEVEL', 'MATCHES', 'DIVERSITY']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('should_say_no_sessions_when_none_are_logged', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      expect(find.text('No sessions logged yet'), findsOneWidget);
    });

    testWidgets('should_refocus_the_scan_field_after_the_panel_closes', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-close'));
      await tester.pump();

      expect(h.scanEditable.focusNode.hasFocus, isTrue);
    });
  });

  group('Level (PLY-05)', () {
    testWidgets('should_show_the_tier_name_in_the_panel', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      expect(
        find.descendant(
          of: find.byType(MorePanel),
          matching: find.text('Intermediate'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should_show_the_elo_code_beside_the_tier_name', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      expect(find.text('(B1)'), findsOneWidget);
    });

    testWidgets('should_raise_the_level_when_plus_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-level-up'));
      await h.flush();

      expect(stored('Alice').elo, Elo.a2);
    });

    testWidgets('should_lower_the_level_when_minus_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-level-down'));
      await h.flush();

      expect(stored('Alice').elo, Elo.b2);
    });

    testWidgets('should_do_nothing_when_a_dimmed_minus_is_tapped', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      final low = testPlayer('Low', Elo.c2);
      await h.pump(players: [low]);
      await h.openMore('Low');

      await h.tap(key('more-level-down'));
      await h.flush();

      expect(stored('Low').elo, Elo.c2);
    });

    testWidgets('should_dim_plus_at_the_top_level', (tester) async {
      final h = PlayersHarness(tester);
      final top = testPlayer('Top', Elo.s1);
      await h.pump(players: [top]);

      await h.openMore('Top');

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: key('more-level-up'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.35);
    });

    testWidgets('should_not_check_in_when_a_panel_control_is_tapped', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-level-up'));

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });
  });

  group('Membership (PLY-06, F23)', () {
    testWidgets('should_show_member_casual_and_disabled', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      expect(
        MembershipStatus.values.map(
          (s) => key('more-membership-${s.name}').evaluate().length,
        ),
        [1, 1, 1],
      );
    });

    testWidgets('should_set_casual_when_casual_is_picked', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-membership-casual'));
      await h.flush();

      expect(stored('Alice').membership, MembershipStatus.casual);
    });

    testWidgets('should_disable_at_once_when_the_player_is_not_checked_in', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-membership-disabled'));
      await h.flush();

      expect(stored('Alice').membership, MembershipStatus.disabled);
    });

    testWidgets('should_ask_before_disabling_a_checked_in_player', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await h.openMore('Alice');

      await h.tap(key('more-membership-disabled'));
      await tester.pumpAndSettle();

      expect(find.text('Disable Alice Test?'), findsOneWidget);
    });

    testWidgets('should_use_the_one_confirm_dialog_pattern', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await h.openMore('Alice');

      await h.tap(key('more-membership-disabled'));
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsOneWidget);
    });

    testWidgets('should_check_out_when_the_disable_is_confirmed', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await h.openMore('Alice');
      await h.tap(key('more-membership-disabled'));
      await tester.pumpAndSettle();

      await h.tap(key('courts-confirm-action'));
      await tester.pumpAndSettle();

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_keep_the_player_in_when_the_disable_is_cancelled', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await h.openMore('Alice');
      await h.tap(key('more-membership-disabled'));
      await tester.pumpAndSettle();

      await h.tap(key('courts-confirm-cancel'));
      await tester.pumpAndSettle();

      expect(stored('Alice').membership, MembershipStatus.member);
    });
  });

  group('Sign-in ID (PLY-15, F23, F30)', () {
    testWidgets('should_select_all_the_id_text_on_focus', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('player-sign-in-id-field'));
      await tester.pump();

      final field = tester.widget<EditableText>(
        find.descendant(
          of: key('player-sign-in-id-field'),
          matching: find.byType(EditableText),
        ),
      );
      expect(
        field.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
    });

    testWidgets('should_save_the_trimmed_id', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');
      await tester.enterText(key('player-sign-in-id-field'), '  A999 ');

      await h.tap(key('player-sign-in-id-save'));
      await h.flush();

      expect(stored('Alice').signInId, 'A999');
    });

    testWidgets('should_say_saved_after_a_save', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');
      await tester.enterText(key('player-sign-in-id-field'), 'A999');

      await h.tap(key('player-sign-in-id-save'));
      await h.flush();

      expect(find.text('Saved.'), findsOneWidget);
    });

    testWidgets('should_refuse_an_id_and_name_the_player_who_has_it', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.openMore('Alice');
      await tester.enterText(key('player-sign-in-id-field'), 'B200');

      await h.tap(key('player-sign-in-id-save'));

      expect(find.text('ID B200 is used by Bob Test.'), findsOneWidget);
    });

    testWidgets('should_keep_the_old_id_when_the_save_is_refused', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice, bob]);
      await h.openMore('Alice');
      await tester.enterText(key('player-sign-in-id-field'), 'B200');

      await h.tap(key('player-sign-in-id-save'));
      await h.flush();

      expect(stored('Alice').signInId, 'A100');
    });

    testWidgets('should_not_show_a_snackbar_after_a_save', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');
      await tester.enterText(key('player-sign-in-id-field'), 'A999');

      await h.tap(key('player-sign-in-id-save'));

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Delete (PLY-07, F23)', () {
    testWidgets('should_draw_delete_as_a_red_outline_button', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      final material = tester.widget<Material>(
        find
            .descendant(of: key('more-delete'), matching: find.byType(Material))
            .first,
      );
      expect(
        (material.shape! as RoundedRectangleBorder).side.color,
        const Color(0xFFB91C1C),
      );
    });

    testWidgets('should_ask_before_deleting', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');

      await h.tap(key('more-delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete player?'), findsOneWidget);
    });

    testWidgets('should_anonymise_the_player_when_delete_is_confirmed', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await h.openMore('Alice');
      await h.tap(key('more-delete'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(key('courts-confirm-action'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(stored('Alice').isAnonymised, isTrue);
    });
  });
}
