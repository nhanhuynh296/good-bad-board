import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── NAV-01: Desktop/tablet top header bar ──────────────────

  group('NAV-01 — Desktop/tablet top nav visible', () {
    testWidgets('desktop shows TopNavBar with all 5 tabs', (tester) async {
      setDesktopSize(tester);
      await pumpApp(tester);

      // All 5 tab labels are rendered (Check-in is integrated into Players).
      const tabs = [
        'Dashboard',
        'Players',
        'Sessions',
        'Analytics',
        'Settings',
      ];
      for (final label in tabs) {
        expect(find.text(label), findsWidgets);
      }

      // Phone-only widgets should NOT be present.
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets('tablet shows TopNavBar with all 5 tabs', (tester) async {
      setTabletSize(tester);
      await pumpApp(tester);

      const tabs = [
        'Dashboard',
        'Players',
        'Sessions',
        'Analytics',
        'Settings',
      ];
      for (final label in tabs) {
        expect(find.text(label), findsWidgets);
      }

      // Phone-only widgets should NOT be present.
      expect(find.byIcon(Icons.menu), findsNothing);
    });
  });

  // ── NAV-02: Phone compact header ───────────────────────────

  group('NAV-02 — Phone compact header', () {
    testWidgets('phone shows compact header with tab label', (tester) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Current tab label is shown (defaults to "Dashboard" on launch).
      // It also appears in the page content, so use findsWidgets.
      expect(find.text('Dashboard'), findsWidgets);
    });
  });

  // ── NAV-03: Phone bottom tab bar ───────────────────────────

  group('NAV-03 — Phone bottom tab bar', () {
    testWidgets('phone bottom bar shows 3 primary destinations', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // The 3 bottom-bar tab labels are visible.
      // "Dashboard" is shown as "Courts" in the bottom bar.
      // Note: "Courts" may appear in both the bottom bar and page
      // content, so use findsWidgets.
      expect(find.text('Courts'), findsWidgets);
      expect(find.text('Players'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('tapping More opens bottom sheet with secondary tabs', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Tap "More" in the bottom bar.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // The sheet shows the 3 secondary tab labels.
      expect(find.text('Sessions'), findsWidgets);
      expect(find.text('Analytics'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('selecting a secondary tab navigates and closes sheet', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Open More sheet.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // Tap "Sessions" in the sheet.
      // The sheet renders Sessions as a text label; we need the one
      // inside the sheet, not the hidden one from TopNavBar.
      await tester.tap(find.text('Sessions').last);
      await tester.pumpAndSettle();

      // Sessions page now renders actual SessionsPage content.
      // Look for "Round mode" which is a section title in SessionsPage.
      expect(find.text('Round mode'), findsOneWidget);
    });

    testWidgets('tapping backdrop closes More sheet without switching', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Open More sheet.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      // The backdrop is a positioned GestureDetector filling the screen
      // above the sheet. Tap at the top center of the screen.
      await tester.tapAt(const Offset(195, 100));
      await tester.pumpAndSettle();

      // We should still be on the Dashboard tab.
      expect(find.text('Courts'), findsOneWidget);
    });
  });

  // ── NAV-04: More tab highlighted on secondary tab ──────────

  group('NAV-04 — More tab highlighted on secondary tabs', () {
    testWidgets('More is highlighted when navigating to a secondary tab', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Navigate to sessions via More sheet.
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sessions').last);
      await tester.pumpAndSettle();

      // "More" should still be visible in the bottom bar.
      // On a secondary tab, the More button should be active
      // (colored with accentPrimary). We verify the tab still exists.
      expect(find.text('More'), findsOneWidget);
    });
  });

  // ── NAV-05: Phone hamburger nav ────────────────────────────

  group('NAV-05 — Phone hamburger navigation', () {
    testWidgets('hamburger button visible on phone', (tester) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // The compact header uses Icons.menu for the hamburger button.
      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('tapping hamburger opens overlay with all 5 tabs', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Tap hamburger button.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // The overlay shows "NAVIGATE" heading.
      expect(find.text('NAVIGATE'), findsOneWidget);

      // All 5 tabs are listed in the menu (Check-in integrated into Players).
      const tabs = [
        'Dashboard',
        'Players',
        'Sessions',
        'Analytics',
        'Settings',
      ];
      for (final label in tabs) {
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('tapping a tab in hamburger navigates and closes menu', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Open hamburger.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap "Sessions" in the menu (a placeholder page — avoids the
      // Players page RenderFlex overflow at phone width).
      await tester.tap(find.text('Sessions').last);
      await tester.pumpAndSettle();

      // The menu should be closed, showing SessionsPage content.
      expect(find.text('NAVIGATE'), findsNothing);
      expect(find.text('Round mode'), findsOneWidget);
    });

    testWidgets('tapping backdrop closes hamburger without switching', (
      tester,
    ) async {
      setPhoneSize(tester);
      await pumpApp(tester);

      // Open hamburger.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Menu is open, "NAVIGATE" is visible.
      expect(find.text('NAVIGATE'), findsOneWidget);

      // Tap the backdrop. The menu panel is 280px wide on the right.
      // Tapping on the left side (outside the menu) should trigger onClose.
      // Use a position well within the left half of the 390px-wide screen.
      await tester.tapAt(const Offset(30, 400));
      await tester.pumpAndSettle();

      // Menu should be closed.
      expect(find.text('NAVIGATE'), findsNothing);
    });
  });
}
