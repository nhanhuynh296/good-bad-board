import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

import '../support/sessions_harness.dart';

// The desktop Sessions tab (canvas board "Sessions", R7-Q3), UAT SESS-01 …
// SESS-06 with the design review rule F25.

const _confirm = Key('courts-confirm-action');
const _cancel = Key('courts-confirm-cancel');
const _removeCourtAction = Key('remove-court-action');
const _removeCourtCancel = Key('remove-court-cancel');
Key removeCourtOption(int index) => Key('remove-court-option-$index');

void main() {
  setUpSessionsSandbox('sessions_desktop_test');

  SessionsStepButton stepButton(WidgetTester tester, Key key) =>
      tester.widget<SessionsStepButton>(find.byKey(key));

  String fieldText(WidgetTester tester, Key key) =>
      tester.widget<TextField>(find.byKey(key)).controller!.text;

  group('Layout', () {
    testWidgets('should_show_the_round_settings_card', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('Round settings'), findsOneWidget);
    });

    testWidgets('should_show_the_templates_card', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('Session templates'), findsOneWidget);
    });

    testWidgets('should_place_the_two_cards_side_by_side', (tester) async {
      await SessionsHarness(tester).pump();

      final settings = tester.getTopLeft(find.text('Round settings'));
      final templates = tester.getTopLeft(find.text('Session templates'));

      expect(templates.dy, settings.dy);
    });

    testWidgets('should_not_scroll_the_page', (tester) async {
      await SessionsHarness(tester).pump();

      expect(
        find.descendant(
          of: find.byType(SessionsPage),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
    });

    testWidgets('SESS-01: should_hide_the_round_mode_toggle', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('Game-based'), findsNothing);
    });

    testWidgets('SESS-04: should_hide_the_court_row_when_not_editable', (
      tester,
    ) async {
      CourtCount.editable = false;
      await SessionsHarness(tester).pump();

      expect(find.byKey(courtsValue), findsNothing);
    });

    testWidgets('SESS-04: should_show_the_court_row_by_default', (
      tester,
    ) async {
      await SessionsHarness(tester).pump();

      expect(find.byKey(courtsValue), findsOneWidget);
    });

    testWidgets('should_show_the_fixed_changeover', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('20 s · fixed'), findsOneWidget);
    });

    for (final locale in const [
      Locale('en'),
      Locale('fr'),
      Locale('zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
    ]) {
      testWidgets('should_fit_1280_by_720_with_courts_in_$locale', (
        tester,
      ) async {
        CourtCount.editable = true;
        final h = SessionsHarness(tester);
        h.checkIn(18);
        h.toRunning();
        for (var i = 0; i < 12; i++) {
          await h.saveTemplate(name: 'Template with a long name number $i');
        }

        await h.pump(locale: locale);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('SESS-02 round duration', () {
    testWidgets('should_show_the_stored_minutes', (tester) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 12, seconds: 45),
      );
      await SessionsHarness(tester).pump();

      expect(fieldText(tester, minutesField), '12');
    });

    testWidgets('should_show_the_stored_seconds', (tester) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 12, seconds: 45),
      );
      await SessionsHarness(tester).pump();

      expect(fieldText(tester, secondsField), '45');
    });

    testWidgets('should_add_one_minute_on_plus', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(durationMore));

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 11),
      );
    });

    testWidgets('should_remove_one_minute_on_minus', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(durationLess));

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 9),
      );
    });

    testWidgets('should_disable_minus_at_one_minute', (tester) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 1),
      );
      await SessionsHarness(tester).pump();

      expect(stepButton(tester, durationLess).onPressed, isNull);
    });

    testWidgets('should_disable_plus_at_99_59', (tester) async {
      await PersistentSetting.instance.setGameDuration(
        const Duration(minutes: 99, seconds: 59),
      );
      await SessionsHarness(tester).pump();

      expect(stepButton(tester, durationMore).onPressed, isNull);
    });

    testWidgets('should_persist_a_typed_duration', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await tester.enterText(find.byKey(minutesField), '7');
      await h.submit(secondsField, '30');

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 7, seconds: 30),
      );
    });

    testWidgets('should_clamp_seconds_above_59', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await tester.enterText(find.byKey(minutesField), '5');
      await h.submit(secondsField, '90');

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 5, seconds: 59),
      );
    });

    testWidgets('should_keep_the_duration_when_zero_is_typed', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await tester.enterText(find.byKey(minutesField), '0');
      await h.submit(secondsField, '0');

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 10),
      );
    });

    testWidgets('should_select_the_whole_minutes_on_focus', (tester) async {
      await SessionsHarness(tester).pump();

      await tester.tap(find.byKey(minutesField));
      await tester.pump();

      final controller = tester
          .widget<TextField>(find.byKey(minutesField))
          .controller!;
      expect(controller.selection.extentOffset, controller.text.length);
    });

    testWidgets('should_apply_a_change_while_paused_at_once', (tester) async {
      // R9-Q6: the time shows the new duration minus the elapsed time.
      final h = SessionsHarness(tester);
      h.checkIn(8);
      h.toRunning();
      h.timer.elapse(const Duration(minutes: 2));
      h.gameData.pause();
      await h.pump();

      await h.tap(find.byKey(durationMore));

      expect(h.timer.remaining, const Duration(minutes: 9));
    });

    testWidgets('should_say_how_long_the_running_round_has_left', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      h.checkIn(8);
      h.toRunning();
      h.timer.elapse(const Duration(minutes: 5, seconds: 48));
      await h.pump();

      expect(find.text('Applies now · round 1 has 04:12 left'), findsOneWidget);
    });

    testWidgets('should_say_the_next_round_gets_it_in_time_up', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(8);
      h.toTimeUp();
      await h.pump();

      expect(find.text('Applies from round 2'), findsOneWidget);
    });

    testWidgets('should_say_every_round_gets_it_before_round_one', (
      tester,
    ) async {
      await SessionsHarness(tester).pump();

      expect(find.text('Applies now to every round'), findsOneWidget);
    });

    testWidgets('should_label_the_minus_button_for_screen_readers', (
      tester,
    ) async {
      await SessionsHarness(tester).pump();

      expect(find.bySemanticsLabel('One minute less'), findsOneWidget);
    });
  });

  group('SESS-03 session capacity', () {
    testWidgets('should_add_one_place_on_plus', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(capacityMore));

      expect(h.gameData.sessionCapacity, 21);
    });

    testWidgets('should_remove_one_place_on_minus', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(capacityLess));

      expect(h.gameData.sessionCapacity, 19);
    });

    testWidgets('should_disable_minus_at_four', (tester) async {
      final h = SessionsHarness(tester);
      h.gameData.setSessionCapacity(4);
      await h.pump();

      expect(stepButton(tester, capacityLess).onPressed, isNull);
    });

    testWidgets('should_clamp_an_empty_entry_up_to_four', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.submit(capacityField, '');

      expect(h.gameData.sessionCapacity, 4);
    });

    testWidgets('should_show_the_clamped_number_in_the_field', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.submit(capacityField, '2');

      expect(fieldText(tester, capacityField), '4');
    });

    testWidgets('should_show_the_field_value_after_plus', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(capacityMore));

      expect(fieldText(tester, capacityField), '21');
    });

    testWidgets('should_show_the_checked_in_count_and_minimum', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(6);
      await h.pump();

      expect(find.text('6 checked in · min 4'), findsOneWidget);
    });

    testWidgets('should_say_no_one_is_checked_out_below_the_count', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      h.checkIn(6);
      h.gameData.setSessionCapacity(5);
      await h.pump();

      expect(find.text('6 checked in · no one is checked out'), findsOneWidget);
    });
  });

  group('SESS-04 number of courts', () {
    setUp(() => CourtCount.editable = true);

    testWidgets('should_show_the_court_count', (tester) async {
      await SessionsHarness(tester).pump();

      expect(
        find.descendant(of: find.byKey(courtsValue), matching: find.text('4')),
        findsOneWidget,
      );
    });

    testWidgets('should_say_that_a_new_court_starts_empty', (tester) async {
      await SessionsHarness(tester).pump();

      expect(
        find.text('No reshuffle · a new court starts empty'),
        findsOneWidget,
      );
    });

    testWidgets('should_add_a_court_without_asking_before_round_one', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(courtsMore));

      expect(h.gameData.numberOfCourt, 5);
    });

    testWidgets('should_disable_minus_at_one_court', (tester) async {
      final h = SessionsHarness(tester);
      h.gameData.setNumberOfCourt(1);
      await h.pump();

      expect(stepButton(tester, courtsLess).onPressed, isNull);
    });

    // R13-Q12 (Nathan 2026-10-22): no upper limit.
    testWidgets('should_allow_plus_at_eight_courts', (tester) async {
      final h = SessionsHarness(tester);
      h.gameData.setNumberOfCourt(8);
      await h.pump();

      expect(stepButton(tester, courtsMore).onPressed, isNotNull);
    });

    testWidgets('should_add_a_ninth_court', (tester) async {
      final h = SessionsHarness(tester);
      h.gameData.setNumberOfCourt(8);
      await h.pump();

      await h.tap(find.byKey(courtsMore));

      expect(h.gameData.numberOfCourt, 9);
    });

    // R13-Q1, R13-Q9 (Nathan 2026-10-22): no reshuffle. When a court holds
    // players, "−" asks which court to remove.
    testWidgets('should_ask_which_court_to_remove_in_a_round', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();

      await h.tap(find.byKey(courtsLess));

      expect(find.text('Remove which court?'), findsOneWidget);
    });

    testWidgets('should_list_each_court_with_its_players', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();

      await h.tap(find.byKey(courtsLess));

      expect(find.text('Court 2 · 4 players'), findsOneWidget);
    });

    testWidgets('should_remove_the_chosen_court', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final before = h.rosters;
      await h.tap(find.byKey(courtsLess));

      await h.tap(find.byKey(removeCourtOption(1)));
      await h.tap(find.byKey(_removeCourtAction));

      expect(h.rosters, [before[0], before[2], before[3]]);
    });

    testWidgets('should_keep_every_court_on_cancel', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      await h.tap(find.byKey(courtsLess));

      await h.tap(find.byKey(_removeCourtCancel));

      expect(h.gameData.numberOfCourt, 4);
    });

    testWidgets('should_keep_every_court_on_escape', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      await h.tap(find.byKey(courtsLess));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(h.gameData.numberOfCourt, 4);
    });

    testWidgets('should_preselect_the_last_court', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final before = h.rosters;
      await h.tap(find.byKey(courtsLess));

      await h.tap(find.byKey(_removeCourtAction));

      expect(h.rosters, before.take(3));
    });

    testWidgets('should_remove_the_last_court_at_once_when_courts_are_empty', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(courtsLess));

      expect(h.gameData.numberOfCourt, 3);
    });

    testWidgets('should_not_ask_which_court_when_courts_are_empty', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.tap(find.byKey(courtsLess));

      expect(find.text('Remove which court?'), findsNothing);
    });

    testWidgets('should_add_an_empty_court_while_paused', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toPaused();
      await h.pump();

      await h.tap(find.byKey(courtsMore));

      expect(h.gameData.stagingMatches[4].playerIds, isEmpty);
    });

    testWidgets('should_keep_the_round_paused_when_a_court_is_added', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toPaused();
      await h.pump();

      await h.tap(find.byKey(courtsMore));

      expect(h.gameData.phase, RoundPhase.paused);
    });
  });

  group('SESS-05 save a template', () {
    testWidgets('should_disable_save_with_a_blank_name', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await tester.enterText(find.byKey(templateName), '   ');
      await tester.pump();

      expect(
        tester.widget<SessionsSaveButton>(find.byKey(saveTemplate)).onPressed,
        isNull,
      );
    });

    testWidgets('should_list_a_saved_template', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      await tester.enterText(find.byKey(templateName), 'Friday');
      await tester.pump();

      await h.tapAndFlush(find.byKey(saveTemplate));

      expect(h.gameData.templates.map((t) => t.name), ['Friday']);
    });

    testWidgets('should_save_on_enter_in_the_name_field', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await tester.runAsync(() async {
        await tester.enterText(find.byKey(templateName), 'Friday');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(h.gameData.templates.map((t) => t.name), ['Friday']);
    });

    testWidgets('should_clear_the_name_after_a_save', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      await tester.enterText(find.byKey(templateName), 'Friday');
      await tester.pump();

      await h.tapAndFlush(find.byKey(saveTemplate));

      expect(fieldText(tester, templateName), isEmpty);
    });

    testWidgets('should_summarise_what_save_keeps', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('Saves 10 min · 4 courts · cap 20'), findsOneWidget);
    });

    testWidgets('should_leave_the_courts_out_when_not_editable', (
      tester,
    ) async {
      CourtCount.editable = false;
      await SessionsHarness(tester).pump();

      expect(find.text('Saves 10 min · cap 20'), findsOneWidget);
    });

    testWidgets('should_summarise_a_saved_template', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.saveTemplate(
        duration: const Duration(minutes: 8, seconds: 30),
        capacity: 12,
      );

      expect(find.text('8:30 · 4 courts · cap 12'), findsOneWidget);
    });

    testWidgets('should_say_when_no_template_is_saved', (tester) async {
      await SessionsHarness(tester).pump();

      expect(find.text('No templates yet'), findsOneWidget);
    });
  });

  group('SESS-06 load a template (F25)', () {
    testWidgets('should_apply_the_duration_without_a_dialog', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate();

      await h.tap(find.byKey(loadKey(template)));

      expect(
        PersistentSetting.instance.getGameDuration(),
        const Duration(minutes: 12),
      );
    });

    testWidgets('should_apply_the_capacity_without_a_dialog', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate();

      await h.tap(find.byKey(loadKey(template)));

      expect(h.gameData.sessionCapacity, 24);
    });

    testWidgets('should_not_ask_when_the_court_count_is_the_same', (
      tester,
    ) async {
      CourtCount.editable = true;
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate();

      await h.tap(find.byKey(loadKey(template)));

      expect(find.byKey(_confirm), findsNothing);
    });

    testWidgets('should_keep_the_running_lineup', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate();
      final before = h.rosters;

      await h.tap(find.byKey(loadKey(template)));

      expect(h.rosters, before);
    });

    testWidgets('should_recalculate_the_running_clock', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      h.timer.elapse(const Duration(minutes: 2));
      await h.pump();
      final template = await h.saveTemplate();

      await h.tap(find.byKey(loadKey(template)));

      expect(h.timer.remaining, const Duration(minutes: 10));
    });

    testWidgets('should_not_ask_when_the_court_count_changes', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate(courts: 3);

      await h.tap(find.byKey(loadKey(template)));

      expect(find.byKey(_confirm), findsNothing);
    });

    testWidgets('should_apply_the_template_court_count', (tester) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate(courts: 3);

      await h.tap(find.byKey(loadKey(template)));

      expect(h.gameData.numberOfCourt, 3);
    });

    testWidgets('should_keep_the_other_courts_when_a_template_has_less', (
      tester,
    ) async {
      final h = SessionsHarness(tester);
      h.checkIn(18);
      h.toRunning();
      await h.pump();
      final template = await h.saveTemplate(courts: 3);
      final before = h.rosters;

      await h.tap(find.byKey(loadKey(template)));

      expect(h.rosters, before.take(3));
    });

    testWidgets('should_label_the_load_button_with_the_name', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();

      await h.saveTemplate();

      expect(find.bySemanticsLabel('Load Wednesday night'), findsOneWidget);
    });
  });

  group('SESS-06 delete a template (F25)', () {
    testWidgets('should_ask_before_deleting', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      final template = await h.saveTemplate();

      await h.tap(find.byKey(deleteKey(template)));

      expect(find.text('Delete template “Wednesday night”?'), findsOneWidget);
    });

    testWidgets('should_delete_on_confirm', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      final template = await h.saveTemplate();
      await h.tap(find.byKey(deleteKey(template)));

      await h.tapAndFlush(find.byKey(_confirm));

      expect(h.gameData.templates, isEmpty);
    });

    testWidgets('should_keep_the_template_on_cancel', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      final template = await h.saveTemplate();
      await h.tap(find.byKey(deleteKey(template)));

      await h.tap(find.byKey(_cancel));

      expect(h.gameData.templates, hasLength(1));
    });

    testWidgets('should_not_change_the_settings_on_delete', (tester) async {
      final h = SessionsHarness(tester);
      await h.pump();
      final template = await h.saveTemplate();
      await h.tap(find.byKey(deleteKey(template)));

      await h.tapAndFlush(find.byKey(_confirm));

      expect(h.gameData.sessionCapacity, 20);
    });
  });
}
