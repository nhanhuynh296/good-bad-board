import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/state/game_data.dart';

import '../support/courts_harness.dart';
import '../support/next_round_steps.dart';

/// Round bar, next-round strip and edit mode on the desktop Courts tab
/// (IMPLEMENTATION 8.5.2, 8.5.3; UAT RND-01, RND-02, RND-05, RND-09, RND-10,
/// RND-12 … RND-19, RND-22).
void main() {
  setUpCourtsSandbox('courts_round_bar_test');

  Finder inBar(Finder finder) =>
      find.descendant(of: find.byType(RoundBar), matching: finder);
  Finder inStrip(Finder finder) =>
      find.descendant(of: find.byType(NextRoundStrip), matching: finder);
  Color? timeColour(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('round-bar-time'))).style?.color;

  group('RoundBar states', () {
    testWidgets('should_show_generate_round_one_when_no_lineup', (
      tester,
    ) async {
      final h = CourtsHarness(tester)..checkIn(20);

      await h.pump();

      expect(inBar(find.text('Generate round 1')), findsOneWidget);
    });

    testWidgets('should_show_round_one_ready_and_full_time_when_no_lineup', (
      tester,
    ) async {
      final h = CourtsHarness(tester)..checkIn(20);

      await h.pump();

      expect(inBar(find.text('ROUND 1')), findsOneWidget);
      expect(inBar(find.text('READY')), findsOneWidget);
      expect(inBar(find.text('10:00')), findsOneWidget);
    });

    testWidgets('should_fill_courts_when_generate_round_one_tapped', (
      tester,
    ) async {
      final h = CourtsHarness(tester)..checkIn(20);
      await h.pump();

      await h.tapText('Generate round 1');

      expect(h.gameData.phase, RoundPhase.ready);
    });

    testWidgets('should_show_message_when_generate_with_fewer_than_four', (
      tester,
    ) async {
      final h = CourtsHarness(tester)..checkIn(3);
      await h.pump();

      await h.tapText('Generate round 1');

      expect(find.text('Check in at least 4 players. 3 checked in.'), findsOne);
    });

    testWidgets('should_show_discard_and_start_round_one_when_ready', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();

      await h.pump();

      expect(inBar(find.text('Discard & regenerate')), findsOneWidget);
      expect(inBar(find.text('Start round 1')), findsOneWidget);
      expect(inBar(find.text('Not started')), findsOneWidget);
    });

    testWidgets('should_start_round_one_at_once_when_start_tapped', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();

      await h.tapText('Start round 1');

      expect(h.gameData.phase, RoundPhase.running);
    });

    // R13-Q5 (Nathan 2026-10-22): "Start round n+1" only after round n+1 is
    // saved.
    testWidgets('should_show_pause_and_discard_when_running_not_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(inBar(find.text('Pause')), findsOneWidget);
      expect(inBar(find.text('Discard round 1 and start again')), findsOne);
      expect(inBar(find.text('Start round 2')), findsNothing);
    });

    testWidgets('should_show_start_next_when_running_and_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunningWithNext();

      await h.pump();

      expect(inBar(find.text('Start round 2')), findsOneWidget);
    });

    testWidgets('should_show_no_sub_label_when_running', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(inBar(find.text('Not started')), findsNothing);
      expect(inBar(find.text('RUNNING')), findsOneWidget);
    });

    testWidgets('should_show_pause_only_when_running_in_edit_mode', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();

      await h.pump();

      expect(inBar(find.text('Pause')), findsOneWidget);
      expect(inBar(find.text('Start round 2')), findsNothing);
      expect(inBar(find.text('Discard round 1 and start again')), findsNothing);
    });

    testWidgets('should_show_discard_and_resume_when_paused_not_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();

      await h.pump();

      expect(inBar(find.text('Discard round 1 and start again')), findsOne);
      expect(inBar(find.text('Start round 2')), findsNothing);
      expect(inBar(find.text('Resume round 1')), findsOneWidget);
      expect(inBar(find.text('Clock paused')), findsOneWidget);
    });

    testWidgets('should_show_discard_start_and_resume_when_paused_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPausedWithNext();

      await h.pump();

      expect(inBar(find.text('Discard round 1 and start again')), findsOne);
      expect(inBar(find.text('Start round 2')), findsOneWidget);
      expect(inBar(find.text('Resume round 1')), findsOneWidget);
    });

    testWidgets('should_resume_round_when_resume_tapped', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();
      await h.pump();

      await h.tapText('Resume round 1');

      expect(h.gameData.phase, RoundPhase.running);
    });

    testWidgets('should_show_start_and_resume_when_paused_editing_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunningWithNext();
      h.gameData.editNextRound();
      h.gameData.pause();

      await h.pump();

      expect(inBar(find.text('Start round 2')), findsOneWidget);
      expect(inBar(find.text('Resume round 1')), findsOneWidget);
      expect(inBar(find.text('Discard round 1 and start again')), findsNothing);
    });

    testWidgets('should_show_resume_only_when_paused_editing_new_round', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      h.gameData.pause();

      await h.pump();

      expect(inBar(find.text('Start round 2')), findsNothing);
      expect(inBar(find.text('Resume round 1')), findsOneWidget);
    });

    testWidgets('should_show_discard_only_when_time_up', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      expect(inBar(find.text('TIME UP')), findsOneWidget);
      expect(inBar(find.text('Clock stopped at 0:00')), findsOneWidget);
      expect(inBar(find.text('Discard round 1 and start again')), findsOne);
      expect(inBar(find.text('Start round 2')), findsNothing);
    });

    testWidgets('should_show_no_start_buttons_when_time_up_in_edit_mode', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      h.timer.elapse(h.timer.duration);

      await h.pump();

      expect(inBar(find.text('Start round 2')), findsNothing);
      expect(inBar(find.text('Discard round 1 and start again')), findsNothing);
    });

    testWidgets('should_show_pause_and_start_now_when_changeover', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();

      await h.pump();

      expect(inBar(find.text('ROUND 2')), findsOneWidget);
      expect(inBar(find.text('Players to courts')), findsOneWidget);
      expect(inBar(find.text('CHANGEOVER')), findsOneWidget);
      expect(inBar(find.text('Pause')), findsOneWidget);
      expect(inBar(find.text('Start round 2 now')), findsOneWidget);
    });

    testWidgets('should_keep_round_number_in_changeover_after_discard', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover(discarded: true);

      await h.pump();

      expect(inBar(find.text('ROUND 1')), findsOneWidget);
      expect(inBar(find.text('Start round 1 now')), findsOneWidget);
    });

    testWidgets('should_show_resume_changeover_when_changeover_paused', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();
      h.gameData.pause();

      await h.pump();

      expect(inBar(find.text('Resume changeover')), findsOneWidget);
      expect(inBar(find.text('PAUSED')), findsOneWidget);
      expect(inBar(find.text('Start round 2 now')), findsNothing);
    });

    testWidgets('should_show_no_buttons_when_changeover_waits_for_edit', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.gameData.saveNewNextRound();
      h.gameData.editNextRound();
      final lineup = h.gameData.visibleMatches;
      h.gameData.swapPlayers(lineup[0].players[0], lineup[1].players[0]);
      h.timer.elapse(h.timer.duration);
      h.timer.elapse(const Duration(seconds: 20));
      expect(h.gameData.waitingForEdit, isTrue);

      await h.pump();

      expect(inBar(find.byType(RoundBarButton)), findsNothing);
      expect(find.byKey(const Key('round-menu-button')), findsOneWidget);
    });

    testWidgets('should_colour_time_amber_in_final_minute_when_running', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.timer.elapse(h.timer.duration - const Duration(seconds: 45));

      await h.pump();

      expect(timeColour(tester), AppColors.urgentOnDark);
    });

    testWidgets('should_not_colour_time_amber_when_paused', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.timer.elapse(h.timer.duration - const Duration(seconds: 45));
      h.gameData.pause();

      await h.pump();

      expect(timeColour(tester), AppColors.headerSub);
    });

    testWidgets('should_colour_time_up_chip_red_with_white_text', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      final chip = tester.widget<Container>(
        find.byKey(const Key('round-bar-chip')),
      );
      expect((chip.decoration! as BoxDecoration).color, AppColors.timeUpBg);
      expect(timeColour(tester), AppColors.timeUpTime);
    });

    testWidgets('should_mark_state_chip_as_live_region', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      final semantics = tester.getSemantics(
        find.byKey(const Key('round-bar-chip')),
      );
      expect(semantics.flagsCollection.isLiveRegion, isTrue);
    });

    testWidgets('should_fill_progress_with_elapsed_time', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.timer.elapse(h.timer.duration ~/ 4);

      await h.pump();

      final bar = tester.widget<FractionallySizedBox>(
        find.byKey(const Key('round-bar-progress')),
      );
      expect(bar.widthFactor, closeTo(0.25, 0.001));
    });

    testWidgets('should_show_counts_in_and_waiting', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(18)
        ..toRunning();

      await h.pump();

      expect(inBar(find.text('18/20 in · 2 waiting')), findsOneWidget);
    });

    testWidgets('should_update_time_every_second_while_running', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await tester.pump(const Duration(seconds: 1));

      expect(inBar(find.text('09:59')), findsOneWidget);
    });
  });

  group('NextRoundStrip', () {
    // R13-Q3 (Nathan 2026-10-22): one button "Generate next round (n+1)".
    testWidgets('should_show_generate_when_running_not_saved', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(inStrip(find.text('Round 2 not saved')), findsOneWidget);
      expect(inStrip(find.text('Clock stops at 0:00 if not saved.')), findsOne);
      expect(inStrip(find.text('Generate next round (2)')), findsOneWidget);
    });

    testWidgets('should_show_no_quick_save_when_running_not_saved', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(inStrip(find.text('Save round 2')), findsNothing);
    });

    testWidgets('should_make_no_next_round_before_generate', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(h.gameData.nextLineup, isNull);
    });

    testWidgets('should_show_generate_when_paused_not_saved', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();

      await h.pump();

      expect(inStrip(find.text('Generate next round (2)')), findsOneWidget);
    });

    testWidgets('should_show_generate_when_time_up', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      expect(inStrip(find.text('Generate next round (2)')), findsOneWidget);
    });

    testWidgets('should_hide_the_clock_stops_text_when_time_up', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      expect(
        inStrip(find.text('Clock stops at 0:00 if not saved.')),
        findsNothing,
      );
    });

    testWidgets('should_open_edit_mode_when_generate_tapped_in_time_up', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();
      await h.pump();

      await h.tap(inStrip(find.text('Generate next round (2)')));

      expect(inStrip(find.text('Editing round 2')), findsOneWidget);
    });

    testWidgets('should_show_edit_round_when_next_saved', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.gameData.saveNewNextRound();

      await h.pump();

      expect(inStrip(find.text('Round 2 saved')), findsOneWidget);
      expect(inStrip(find.text('Starts 20 s after round 1 ends.')), findsOne);
      expect(inStrip(find.text('Edit round 2')), findsOneWidget);
      expect(inStrip(find.text('Generate next round (2)')), findsNothing);
    });

    testWidgets('should_open_edit_mode_when_generate_tapped', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await h.tapText('Generate next round (2)');

      expect(h.gameData.isEditingNext, isTrue);
      expect(inStrip(find.text('Editing round 2')), findsOneWidget);
    });

    testWidgets('should_tag_every_card_next_in_edit_mode', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();

      await h.pump();

      expect(find.text('NEXT'), findsNWidgets(4));
    });

    testWidgets('should_draw_dashed_border_on_cards_in_edit_mode', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();

      await h.pump();

      final cards = tester.widgetList<DesktopCourtCard>(
        find.byType(DesktopCourtCard),
      );
      expect(cards.every((card) => card.isNextRound), isTrue);
    });

    testWidgets('should_show_edit_strip_buttons_in_edit_mode', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();

      await h.pump();

      expect(inStrip(find.text('Discard & regenerate')), findsOneWidget);
      expect(inStrip(find.text('Save round 2')), findsOneWidget);
      expect(find.byKey(const Key('edit-close-button')), findsOneWidget);
    });

    testWidgets('should_leave_edit_mode_when_save_round_tapped', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      await h.pump();

      await h.tap(inStrip(find.text('Save round 2')));

      expect(h.gameData.isNextRoundSaved, isTrue);
      expect(h.gameData.isEditingNext, isFalse);
    });

    testWidgets('should_start_changeover_when_save_tapped_in_time_up_edit', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      h.timer.elapse(h.timer.duration);
      await h.pump();

      await h.tap(inStrip(find.text('Save round 2')));

      expect(h.gameData.phase, RoundPhase.changeover);
    });

    testWidgets('should_show_round_ended_strip_in_changeover', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();

      await h.pump();

      expect(inStrip(find.text('Round 1 ended')), findsOneWidget);
    });

    testWidgets('should_show_discarded_strip_after_discard', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover(discarded: true);

      await h.pump();

      expect(
        inStrip(find.text('Round 1 discarded · new lineup for round 1')),
        findsOneWidget,
      );
    });

    testWidgets('should_show_strip_when_time_up', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      expect(find.byType(NextRoundStrip), findsOneWidget);
    });

    testWidgets('should_not_tag_cards_with_next_round_when_time_up', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toTimeUp();

      await h.pump();

      expect(find.text('ROUND 2'), findsNothing);
    });

    testWidgets('should_hide_strip_when_ready', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();

      await h.pump();

      expect(find.byType(NextRoundStrip), findsNothing);
    });

    testWidgets('should_tag_court_that_is_one_player_short', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(16)
        ..toReady();
      final court = h.gameData.visibleMatches[3];
      h.gameData.checkOutPlayer(court.players.first);
      // Nobody waits, so the place stays open.

      await h.pump();

      expect(find.text('3 players'), findsOneWidget);
    });
  });
}
