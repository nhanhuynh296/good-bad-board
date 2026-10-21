import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/state/game_data.dart';

import '../support/courts_harness.dart';

/// The one confirm pattern on the Courts tab (IMPLEMENTATION 8.5.6; UAT
/// RND-04, RND-06, RND-07, RND-16, RND-20; F03, F09, F14, F18, R12-Q1).
void main() {
  setUpCourtsSandbox('courts_confirm_dialog_test');

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(RoundBar), matching: finder);
  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(CourtsConfirmDialog), matching: finder);

  Future<void> openEndSession(CourtsHarness h) async {
    await h.tap(find.byKey(const Key('round-menu-button')));
    await h.tester.pumpAndSettle();
    await h.tap(find.text('End session'));
    await h.tester.pumpAndSettle();
  }

  group('Early start (R12-Q1)', () {
    testWidgets('should_ask_before_ending_round_early', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.timer.elapse(const Duration(minutes: 5, seconds: 48));
      await h.pump();

      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      expect(find.text('End round 1 now?'), findsOneWidget);
      expect(find.text('04:12 left.'), findsOneWidget);
      expect(h.gameData.phase, RoundPhase.running);
    });

    testWidgets('should_start_changeover_when_early_start_confirmed', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      await h.tap(inDialog(find.text('Start round 2')));
      await tester.pumpAndSettle();

      expect(h.gameData.phase, RoundPhase.changeover);
    });

    testWidgets('should_keep_running_when_early_start_cancelled', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      await h.tap(inDialog(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.phase, RoundPhase.running);
    });

    testWidgets('should_start_round_without_dialog_when_paused', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();
      await h.pump();

      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.phase, RoundPhase.changeover);
    });

    testWidgets('should_start_round_without_dialog_when_time_up', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();
      await h.pump();

      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.phase, RoundPhase.changeover);
    });

    testWidgets('should_close_early_start_dialog_when_time_reaches_zero', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      h.timer.elapse(h.timer.duration);
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.phase, RoundPhase.timeUp);
    });

    testWidgets('should_start_one_changeover_when_confirm_tapped_twice', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();
      final confirm = inDialog(find.text('Start round 2'));

      await tester.tap(confirm);
      await tester.tap(confirm, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(h.gameData.phase, RoundPhase.changeover);
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });

  group('Confirm pattern (F14)', () {
    testWidgets('should_focus_cancel_when_dialog_opens', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      final focused = FocusManager.instance.primaryFocus!.context!;
      final inCancel = find.descendant(
        of: find.byKey(const Key('courts-confirm-cancel')),
        matching: find.byElementPredicate((element) => element == focused),
      );
      expect(inCancel, findsOneWidget);
    });

    testWidgets('should_cancel_dialog_when_escape_pressed', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.phase, RoundPhase.running);
    });

    testWidgets('should_give_dialog_alert_dialog_role', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await h.tap(inBar(find.text('Start round 2')));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(
        find.byKey(const Key('courts-confirm-dialog')),
      );
      expect(node.role, SemanticsRole.alertDialog);
    });
  });

  group('Discard (RND-16)', () {
    testWidgets('should_ask_before_discard', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await h.tapText('Discard round 1 and start again');
      await tester.pumpAndSettle();

      expect(find.text('Discard round 1?'), findsOneWidget);
      expect(
        find.text(
          'Round 1 is not logged. The next lineup goes on the courts and '
          'round 1 starts again.',
        ),
        findsOneWidget,
      );
      expect(h.gameData.phase, RoundPhase.running);
    });

    testWidgets('should_start_discarded_changeover_when_discard_confirmed', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tapText('Discard round 1 and start again');
      await tester.pumpAndSettle();

      await h.tapText('Discard round');
      await tester.pumpAndSettle();

      expect(h.gameData.discarded, isTrue);
    });

    testWidgets('should_close_discard_dialog_when_phase_changes', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await h.tapText('Discard round 1 and start again');
      await tester.pumpAndSettle();

      h.timer.elapse(h.timer.duration);
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.discarded, isFalse);
    });
  });

  group('End session (RND-20, F09)', () {
    testWidgets('should_name_running_round_in_end_session_text', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await openEndSession(h);

      expect(find.text('End session?'), findsOneWidget);
      expect(
        find.text('Round 1 goes into the history. Everyone is checked out.'),
        findsOneWidget,
      );
    });

    testWidgets('should_name_ended_round_in_changeover_text', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();
      await h.pump();

      await openEndSession(h);

      expect(
        find.text('Round 1 goes into the history. Everyone is checked out.'),
        findsOneWidget,
      );
    });

    testWidgets('should_say_nothing_logged_when_ready', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();

      await openEndSession(h);

      expect(
        find.text('Nothing is logged. Everyone is checked out.'),
        findsOneWidget,
      );
    });

    testWidgets('should_say_nothing_logged_in_changeover_after_discard', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover(discarded: true);
      await h.pump();

      await openEndSession(h);

      expect(
        find.text('Nothing is logged. Everyone is checked out.'),
        findsOneWidget,
      );
    });

    testWidgets('should_end_session_when_confirmed', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();
      await openEndSession(h);

      await h.tap(inDialog(find.text('End session')));
      await tester.pumpAndSettle();

      expect(h.gameData.phase, RoundPhase.noLineup);
      expect(h.gameData.checkedInCount, 0);
    });

    testWidgets('should_check_everyone_out_when_ended_with_no_lineup', (
      tester,
    ) async {
      final h = CourtsHarness(tester)..checkIn(6);
      await h.pump();
      await openEndSession(h);

      await h.tap(inDialog(find.text('End session')));
      await tester.pumpAndSettle();

      expect(h.gameData.checkedInCount, 0);
    });

    testWidgets('should_close_end_session_dialog_when_phase_changes', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await openEndSession(h);

      h.gameData.pause();
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.checkedInCount, 20);
    });
  });

  group('Close without saving (RND-07, F03)', () {
    testWidgets('should_close_edit_at_once_when_nothing_changed', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      await h.pump();

      await h.tap(find.byKey(const Key('edit-close-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CourtsConfirmDialog), findsNothing);
      expect(h.gameData.isEditingNext, isFalse);
    });

    testWidgets('should_ask_before_close_when_edit_changed', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      final lineup = h.gameData.visibleMatches;
      h.gameData.swapPlayers(lineup[0].players[0], lineup[1].players[0]);
      await h.pump();

      await h.tap(find.byKey(const Key('edit-close-button')));
      await tester.pumpAndSettle();

      expect(find.text('Close without saving?'), findsOneWidget);
      expect(inDialog(find.text('Keep editing')), findsOneWidget);
      expect(inDialog(find.text('Close')), findsOneWidget);
    });

    testWidgets('should_keep_editing_when_keep_editing_tapped', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      final lineup = h.gameData.visibleMatches;
      h.gameData.swapPlayers(lineup[0].players[0], lineup[1].players[0]);
      await h.pump();
      await h.tap(find.byKey(const Key('edit-close-button')));
      await tester.pumpAndSettle();

      await h.tapText('Keep editing');
      await tester.pumpAndSettle();

      expect(h.gameData.isEditingNext, isTrue);
      expect(h.gameData.hasUnsavedEdits, isTrue);
    });

    testWidgets('should_drop_edits_when_close_tapped', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      final lineup = h.gameData.visibleMatches;
      h.gameData.swapPlayers(lineup[0].players[0], lineup[1].players[0]);
      await h.pump();
      await h.tap(find.byKey(const Key('edit-close-button')));
      await tester.pumpAndSettle();

      await h.tap(inDialog(find.text('Close')));
      await tester.pumpAndSettle();

      expect(h.gameData.isEditingNext, isFalse);
    });
  });
}
