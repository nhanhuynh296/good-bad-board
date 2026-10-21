import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/shell/shell.dart';

import '../support/courts_harness.dart';
import '../support/shell_harness.dart';

/// The desktop top nav (IMPLEMENTATION 8.6.1, ARCHITECTURE §2.1 TopNavBar;
/// UAT NAV-01, NAV-09).
void main() {
  setUpCourtsSandbox('top_nav_test');

  Finder inNav(Finder finder) =>
      find.descendant(of: find.byType(DesktopTopNavBar), matching: finder);
  Finder tab(int index) => find.byKey(Key('top-nav-tab-$index'));
  final more = find.byKey(const Key('top-nav-more'));
  TextStyle? labelStyle(WidgetTester tester, String label) =>
      tester.widget<Text>(inNav(find.text(label))).style;
  BoxDecoration? decoration(WidgetTester tester, Finder finder) =>
      tester.widget<Container>(finder).decoration as BoxDecoration?;

  group('NAV-01 header text', () {
    testWidgets('should_show_session_over_duration_rounds_on_desktop', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      expect(inNav(find.text('Session')), findsOneWidget);
      expect(inNav(find.text('10 min rounds')), findsOneWidget);
    });

    testWidgets('should_put_duration_line_under_session_line', (tester) async {
      await ShellHarness(tester).pump();

      final top = tester.getTopLeft(inNav(find.text('Session')));
      final bottom = tester.getTopLeft(inNav(find.text('10 min rounds')));
      expect(bottom.dy, greaterThan(top.dy));
    });

    testWidgets('should_show_m_ss_when_duration_is_not_whole_minutes', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      h.timer.updateDuration(const Duration(minutes: 10, seconds: 30));

      await h.pump();

      expect(inNav(find.text('10:30 rounds')), findsOneWidget);
    });

    testWidgets('should_update_duration_text_when_duration_changes', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();

      h.timer.updateDuration(const Duration(minutes: 12));
      await tester.pump();

      expect(inNav(find.text('12 min rounds')), findsOneWidget);
    });

    testWidgets('should_show_french_header_when_locale_is_fr', (
      tester,
    ) async {
      await ShellHarness(tester).pump(locale: const Locale('fr'));

      expect(inNav(find.text('Séance')), findsOneWidget);
    });

    testWidgets('should_be_56_px_high', (tester) async {
      await ShellHarness(tester).pump();

      expect(tester.getSize(find.byType(DesktopTopNavBar)).height, 56);
    });
  });

  group('NAV-01 tabs', () {
    testWidgets('should_show_courts_players_sessions_tabs_on_desktop', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      for (final label in ['Courts', 'Players', 'Sessions']) {
        expect(inNav(find.text(label)), findsOneWidget);
      }
    });

    testWidgets('should_not_show_analytics_settings_or_dashboard_tabs', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      for (final label in ['Dashboard', 'Analytics', 'Settings']) {
        expect(inNav(find.text(label)), findsNothing);
      }
    });

    testWidgets('should_show_active_tab_white_and_semibold', (tester) async {
      await ShellHarness(tester).pump();

      final style = labelStyle(tester, 'Courts');
      expect(
        (style?.color, style?.fontWeight),
        (AppColors.headerText, AppTypography.semibold),
      );
    });

    testWidgets('should_show_inactive_tab_muted_and_regular', (tester) async {
      await ShellHarness(tester).pump();

      final style = labelStyle(tester, 'Players');
      expect(
        (style?.color, style?.fontWeight),
        (AppColors.headerSub, AppTypography.regular),
      );
    });

    testWidgets('should_underline_active_tab_with_3_px_orange', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      final border = decoration(tester, tab(0))?.border as Border?;
      expect(
        (border?.bottom.width, border?.bottom.color),
        (3.0, AppColors.accentPrimary),
      );
    });

    testWidgets('should_not_fill_active_tab', (tester) async {
      await ShellHarness(tester).pump();

      expect(decoration(tester, tab(0))?.color, isNull);
    });

    testWidgets('should_switch_to_players_when_players_tab_tapped', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();

      await tester.tap(inNav(find.text('Players')));
      await tester.pumpAndSettle();

      expect(h.currentIndex, 1);
    });

    testWidgets('should_not_show_phone_chrome_on_desktop', (tester) async {
      await ShellHarness(tester).pump();

      expect(
        find.byType(CompactHeader).evaluate().length +
            find.byType(BottomTabBar).evaluate().length,
        0,
      );
    });

    testWidgets('should_show_focus_ring_when_tab_has_keyboard_focus', (
      tester,
    ) async {
      await ShellHarness(tester).pump();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      Focus.of(tester.element(inNav(find.text('Players')))).requestFocus();
      await tester.pump();

      expect(
        find.descendant(
          of: tab(1),
          matching: find.byKey(const Key('top-nav-focus-ring')),
        ),
        findsOneWidget,
      );
    });
  });

  group('NAV-09 "⋯" menu', () {
    testWidgets('should_open_menu_with_analytics_and_settings', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      await tester.tap(more);
      await tester.pumpAndSettle();

      expect(
        (
          find.text('Analytics').evaluate().length,
          find.text('Settings').evaluate().length,
        ),
        (1, 1),
      );
    });

    testWidgets('should_label_more_button_for_screen_readers', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      expect(
        find.bySemanticsLabel('More pages: Analytics, Settings'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_analytics_when_menu_item_selected', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(h.currentIndex, 3);
    });

    testWidgets('should_close_menu_when_item_selected', (tester) async {
      final h = ShellHarness(tester);
      await h.pump();
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsNothing);
    });

    testWidgets('should_close_menu_on_escape_without_changing_tab', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect((find.text('Analytics').evaluate().length, h.currentIndex), (
        0,
        0,
      ));
    });

    testWidgets('should_close_menu_on_outside_click_without_changing_tab', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();
      await tester.tap(more);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(600, 500));
      await tester.pumpAndSettle();

      expect((find.text('Analytics').evaluate().length, h.currentIndex), (
        0,
        0,
      ));
    });

    testWidgets('should_show_more_button_active_on_settings_tab', (
      tester,
    ) async {
      final h = ShellHarness(tester);
      await h.pump();

      await h.go(4);

      final border = decoration(tester, more)?.border as Border?;
      expect(border?.bottom.color, AppColors.accentPrimary);
    });

    testWidgets('should_show_no_tab_active_on_analytics_tab', (tester) async {
      final h = ShellHarness(tester);
      await h.pump();

      await h.go(3);

      final active = [
        for (var i = 0; i < 3; i++)
          (decoration(tester, tab(i))?.border as Border?)?.bottom.width ?? 0,
      ];
      expect(active, [0.0, 0.0, 0.0]);
    });

    testWidgets('should_show_more_button_inactive_on_courts_tab', (
      tester,
    ) async {
      await ShellHarness(tester).pump();

      final border = decoration(tester, more)?.border as Border?;
      expect(border?.bottom.width ?? 0, 0);
    });
  });

  group('NAV-01 tablet', () {
    testWidgets('should_keep_five_tabs_with_dashboard_on_tablet', (
      tester,
    ) async {
      await ShellHarness(tester).pump(size: const Size(900, 1000));

      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(TopNavBar),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(labels, [
        'Dashboard',
        'Players',
        'Sessions',
        'Analytics',
        'Settings',
      ]);
    });

    testWidgets('should_not_show_desktop_nav_on_tablet', (tester) async {
      await ShellHarness(tester).pump(size: const Size(900, 1000));

      expect(find.byType(DesktopTopNavBar), findsNothing);
    });
  });
}
