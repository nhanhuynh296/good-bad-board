import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/shell/shell.dart';

import '../support/courts_harness.dart';
import '../support/shell_harness.dart';

/// The desktop session bar (IMPLEMENTATION 8.6.2, ARCHITECTURE §2.1
/// SessionBar; UAT NAV-10, NAV-11).
void main() {
  setUpCourtsSandbox('session_bar_test');

  final bar = find.byType(SessionBar);
  Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);
  final time = find.byKey(const Key('session-bar-time'));
  final chip = find.byKey(const Key('session-bar-chip'));
  Color? timeColour(WidgetTester tester) =>
      tester.widget<Text>(time).style?.color;
  Color? chipFill(WidgetTester tester) =>
      (tester.widget<Container>(chip).decoration as BoxDecoration?)?.color;

  /// Pumps the shell on the Players tab with [count] checked-in players.
  Future<ShellHarness> onPlayers(
    WidgetTester tester, {
    int count = 18,
    void Function(ShellHarness h)? arrange,
    Size size = const Size(1280, 720),
  }) async {
    final h = ShellHarness(tester)..checkIn(count);
    arrange?.call(h);
    await h.pump(initialLocation: '/players', size: size);
    return h;
  }

  group('NAV-10 where the bar shows', () {
    testWidgets('should_hide_session_bar_on_courts_tab', (tester) async {
      await ShellHarness(tester).pump();

      expect(bar, findsNothing);
    });

    for (final (index, name) in [
      (1, 'players'),
      (2, 'sessions'),
      (3, 'analytics'),
      (4, 'settings'),
    ]) {
      testWidgets('should_show_session_bar_on_${name}_tab', (tester) async {
        final h = ShellHarness(tester);
        await h.pump();

        await h.go(index);

        expect(bar, findsOneWidget);
      });
    }

    testWidgets('should_hide_session_bar_on_tablet', (tester) async {
      await onPlayers(tester, size: const Size(900, 1000));

      expect(bar, findsNothing);
    });

    testWidgets('should_be_40_px_high', (tester) async {
      await onPlayers(tester);

      expect(tester.getSize(bar).height, 40);
    });

    testWidgets('should_sit_under_the_top_nav', (tester) async {
      await onPlayers(tester);

      expect(
        tester.getTopLeft(bar).dy,
        tester.getBottomLeft(find.byType(DesktopTopNavBar)).dy,
      );
    });

    testWidgets('should_show_view_courts_link', (tester) async {
      await onPlayers(tester);

      expect(inBar(find.text('View courts →')), findsOneWidget);
    });

    testWidgets('should_put_view_courts_at_the_right_end', (tester) async {
      await onPlayers(tester);

      expect(
        tester.getTopRight(inBar(find.text('View courts →'))).dx,
        tester.getTopRight(bar).dx - AppSpacing.xl,
      );
    });

    testWidgets('should_open_courts_when_bar_tapped', (tester) async {
      final h = await onPlayers(tester, arrange: (h) => h.toRunning());

      await tester.tap(inBar(find.text('View courts →')));
      await h.settle();

      expect(h.currentIndex, 0);
    });

    testWidgets('should_mark_bar_as_a_link', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      final link = find.ancestor(
        of: inBar(find.text('View courts →')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.link == true,
        ),
      );
      expect(link, findsOneWidget);
    });
    testWidgets('should_show_focus_ring_when_bar_has_keyboard_focus', (
      tester,
    ) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      Focus.of(
        tester.element(inBar(find.text('View courts →'))),
      ).requestFocus();
      await tester.pump();

      expect(find.byKey(const Key('session-bar-focus-ring')), findsOneWidget);
    });
  });

  group('NAV-10 content', () {
    testWidgets('should_show_round_time_and_chip_when_running', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      expect(
        (
          inBar(find.text('ROUND 1')).evaluate().length,
          inBar(find.text('10:00')).evaluate().length,
          inBar(find.text('RUNNING')).evaluate().length,
        ),
        (1, 1, 1),
      );
    });

    testWidgets('should_order_round_then_time_then_chip', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      final xs = [
        tester.getTopLeft(inBar(find.text('ROUND 1'))).dx,
        tester.getTopLeft(time).dx,
        tester.getTopLeft(chip).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('should_show_counts_and_next_round_not_saved', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      expect(
        inBar(find.text('18/20 in · 2 waiting · round 2 not saved')),
        findsOneWidget,
      );
    });

    testWidgets('should_show_next_round_saved_when_saved', (tester) async {
      await onPlayers(
        tester,
        arrange: (h) {
          h.toRunning();
          h.gameData.quickSaveNextRound();
        },
      );

      expect(
        inBar(find.text('18/20 in · 2 waiting · round 2 saved')),
        findsOneWidget,
      );
    });

    testWidgets('should_show_counts_only_when_ready', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toReady());

      expect(inBar(find.text('18/20 in · 2 waiting')), findsOneWidget);
    });

    testWidgets('should_show_ready_chip_and_full_duration_when_ready', (
      tester,
    ) async {
      await onPlayers(tester, arrange: (h) => h.toReady());

      expect(
        (
          inBar(find.text('READY')).evaluate().length,
          inBar(find.text('10:00')).evaluate().length,
        ),
        (1, 1),
      );
    });

    testWidgets('should_show_changeover_chip_and_next_round_number', (
      tester,
    ) async {
      await onPlayers(tester, arrange: (h) => h.toChangeover());

      expect(
        (
          inBar(find.text('CHANGEOVER')).evaluate().length,
          inBar(find.text('ROUND 2')).evaluate().length,
        ),
        (1, 1),
      );
    });

    testWidgets('should_make_chip_a_live_region', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      final live = find.ancestor(
        of: chip,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
    });

    testWidgets('should_not_make_time_a_live_region', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      final live = find.ancestor(
        of: time,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(live, findsNothing);
    });

    testWidgets('should_update_when_round_starts_on_another_tab', (
      tester,
    ) async {
      final h = await onPlayers(tester, arrange: (h) => h.toReady());

      h.gameData.startFirstRound();
      await tester.pump();

      expect(inBar(find.text('RUNNING')), findsOneWidget);
    });

    testWidgets('should_show_no_message_when_round_starts_on_another_tab', (
      tester,
    ) async {
      final h = await onPlayers(tester, arrange: (h) => h.toReady());

      h.gameData.startFirstRound();
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should_update_time_when_clock_ticks', (tester) async {
      final h = await onPlayers(tester, arrange: (h) => h.toRunning());

      h.timer.elapse(const Duration(seconds: 3));
      await tester.pump();

      expect(inBar(find.text('09:57')), findsOneWidget);
    });
  });

  group('NAV-11 states', () {
    testWidgets('should_show_no_round_yet_before_first_lineup', (tester) async {
      await onPlayers(tester);

      expect(inBar(find.text('No round yet')), findsOneWidget);
    });

    testWidgets('should_hide_round_chip_and_time_before_first_lineup', (
      tester,
    ) async {
      await onPlayers(tester);

      expect(
        (
          time.evaluate().length,
          chip.evaluate().length,
          inBar(find.text('ROUND 1')).evaluate().length,
        ),
        (0, 0, 0),
      );
    });

    testWidgets('should_show_no_round_yet_after_end_session', (tester) async {
      final h = await onPlayers(tester, arrange: (h) => h.toRunning());

      // Round 1 goes into the history: real file I/O, so out of fake time.
      await tester.runAsync(h.gameData.endSession);
      await tester.pump();

      expect(inBar(find.text('No round yet')), findsOneWidget);
    });

    testWidgets('should_colour_time_white_above_one_minute', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toRunning());

      expect(timeColour(tester), AppColors.headerText);
    });

    testWidgets('should_colour_time_amber_in_final_minute_when_running', (
      tester,
    ) async {
      final h = await onPlayers(tester, arrange: (h) => h.toRunning());

      h.timer.elapse(const Duration(minutes: 9));
      await tester.pump();

      expect(timeColour(tester), AppColors.urgentOnDark);
    });

    testWidgets('should_not_colour_time_amber_when_paused', (tester) async {
      await onPlayers(
        tester,
        arrange: (h) {
          h.toRunning();
          h.timer.elapse(const Duration(minutes: 9, seconds: 30));
          h.gameData.pause();
        },
      );

      expect(timeColour(tester), isNot(AppColors.urgentOnDark));
    });

    testWidgets('should_show_paused_chip_when_paused', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toPaused());

      expect(inBar(find.text('PAUSED')), findsOneWidget);
    });

    testWidgets('should_show_time_up_chip_red', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toTimeUp());

      expect(chipFill(tester), AppColors.timeUpBg);
    });

    testWidgets('should_show_time_up_chip_text_white', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toTimeUp());

      expect(
        tester.widget<Text>(inBar(find.text('TIME UP'))).style?.color,
        AppColors.timeUpText,
      );
    });

    testWidgets('should_colour_time_orange_when_time_up', (tester) async {
      await onPlayers(tester, arrange: (h) => h.toTimeUp());

      expect(timeColour(tester), AppColors.timeUpTime);
    });

    testWidgets('should_show_same_time_as_round_bar_when_paused', (
      tester,
    ) async {
      await onPlayers(
        tester,
        arrange: (h) {
          h.toRunning();
          h.timer.elapse(const Duration(minutes: 5, seconds: 48));
          h.gameData.pause();
        },
      );

      expect(inBar(find.text('04:12')), findsOneWidget);
    });
  });
}
