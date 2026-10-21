import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/model/player.dart';

import '../support/players_harness.dart';

// IMPLEMENTATION 8.7.3: the desktop player row and table header.
// UAT PLY-05, PLY-06, PLY-08, NAV-08, CHK-06.

void main() {
  setUpPlayersSandbox('players_row_test');

  final alice = testPlayer('Alice', Elo.b1, signInId: 'A100');
  final carl = testPlayer(
    'Carl',
    Elo.s1,
    signInId: 'C300',
    membership: MembershipStatus.casual,
  );
  final dave = testPlayer(
    'Dave',
    Elo.c1,
    signInId: 'D400',
    membership: MembershipStatus.disabled,
  );

  Finder inRow(PlayersHarness h, String name, Finder matching) =>
      find.descendant(of: h.rowOf(name), matching: matching);

  group('Columns', () {
    testWidgets('should_show_the_table_header_labels', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      for (final label in ['NAME', 'SIGN-IN ID', 'LEVEL', 'TYPE']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('should_show_the_sign_in_id_in_the_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(inRow(h, 'Alice', find.text('A100')), findsOneWidget);
    });

    testWidgets('should_show_the_tier_name_as_the_level', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(inRow(h, 'Alice', find.text('Intermediate')), findsOneWidget);
    });

    testWidgets('should_not_show_the_elo_code_in_the_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(inRow(h, 'Alice', find.text('B1')), findsNothing);
    });

    testWidgets('should_leave_type_blank_for_a_member', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(inRow(h, 'Alice', find.text('Member')), findsNothing);
    });

    testWidgets('should_show_casual_in_type', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [carl]);

      expect(inRow(h, 'Carl', find.text('Casual')), findsOneWidget);
    });

    testWidgets('should_show_disabled_in_type', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      expect(inRow(h, 'Dave', find.text('Disabled')), findsOneWidget);
    });

    testWidgets('should_not_show_a_level_stepper_in_the_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.byType(LevelAdjuster), findsNothing);
    });

    testWidgets('should_be_48_px_tall', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(tester.getSize(h.rowOf('Alice')).height, 48);
    });

    testWidgets('should_draw_a_72_by_36_more_button', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(tester.getSize(h.moreOf('Alice')), const Size(72, 36));
    });
  });

  group('States', () {
    testWidgets('should_draw_a_6_px_green_bar_on_a_checked_in_row', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      expect(
        tester
            .getSize(inRow(h, 'Alice', find.byKey(const Key('player-row-bar'))))
            .width,
        6,
      );
    });

    testWidgets('should_draw_no_bar_on_a_row_not_checked_in', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(find.byKey(const Key('player-row-bar')), findsNothing);
    });

    testWidgets('should_fill_a_checked_in_row_green', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      final row = tester.widget<DesktopPlayerRow>(h.rowOf('Alice'));
      expect(row.isCheckedIn, isTrue);
      expect(
        _decoration(tester, h.rowOf('Alice')).color,
        const Color(0xFFBFE5C8),
      );
    });

    testWidgets('should_draw_a_green_border_on_a_checked_in_row', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      expect(
        (_decoration(tester, h.rowOf('Alice')).border! as Border).top.color,
        const Color(0xFF1F7A3D),
      );
    });

    testWidgets('should_fill_a_row_not_checked_in_with_the_card_colour', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(
        _decoration(tester, h.rowOf('Alice')).color,
        const Color(0xFFFBF6EE),
      );
    });

    testWidgets('should_draw_a_disabled_name_in_the_muted_colour', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      final name = tester.widget<Text>(find.text('Dave Test'));
      expect(name.style?.color, const Color(0xFF6F6352));
    });

    testWidgets('should_draw_a_disabled_id_in_the_muted_colour', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      final id = tester.widget<Text>(find.text('D400'));
      expect(id.style?.color, const Color(0xFF6F6352));
    });

    testWidgets('should_show_a_forbidden_cursor_on_a_disabled_row', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      final ink = tester.widget<InkWell>(
        inRow(h, 'Dave', find.byKey(const Key('player-row-toggle'))),
      );
      expect(ink.mouseCursor, SystemMouseCursors.forbidden);
    });
  });

  group('Taps', () {
    testWidgets('should_check_in_when_the_row_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.tapRow('Alice');

      expect(h.gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_check_out_when_a_checked_in_row_is_tapped', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      await h.tapRow('Alice');

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_not_check_in_a_disabled_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [dave]);

      await h.tapRow('Dave');

      expect(h.gameData.isPlayerCheckedIn(dave), isFalse);
    });

    testWidgets('should_not_check_in_when_more_is_tapped', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');

      expect(h.gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_clear_a_half_typed_query_on_a_row_tap', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      await tester.enterText(h.scanField, 'Ali');
      await tester.pump();

      await h.tapRow('Alice');

      expect(h.scanEditable.controller.text, isEmpty);
    });
  });

  group('Semantics (PLY-08, F23)', () {
    testWidgets('should_label_a_row_that_is_not_checked_in', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      expect(
        find.bySemanticsLabel('Alice Test, not checked in. Tap to check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_label_a_checked_in_row', (tester) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);
      h.gameData.checkInPlayer(alice);
      await tester.pump();

      expect(
        find.bySemanticsLabel('Alice Test, checked in. Tap to check out'),
        findsOneWidget,
      );
    });

    testWidgets('should_say_more_is_collapsed_when_the_panel_is_closed', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      final node = tester.getSemantics(
        find.bySemanticsLabel('More about Alice Test'),
      );

      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
    });

    testWidgets('should_say_more_is_expanded_when_the_panel_is_open', (
      tester,
    ) async {
      final h = PlayersHarness(tester);
      await h.pump(players: [alice]);

      await h.openMore('Alice');
      final node = tester.getSemantics(
        find.bySemanticsLabel('More about Alice Test'),
      );

      expect(node.flagsCollection.isExpanded, Tristate.isTrue);
    });
  });
}

BoxDecoration _decoration(WidgetTester tester, Finder row) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: row,
                    matching: find.byKey(const Key('player-row-decoration')),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;
