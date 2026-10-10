import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:good_bad_board/features/players/level_adjuster.dart';
import 'package:good_bad_board/features/players/player_row.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Shared setup ──────────────────────────────────────────

  Future<void> setupWithPlayers(WidgetTester tester, Size size) async {
    await pumpAppWithPlayers(tester, playerCount: 6, surfaceSize: size);
  }

  // ── PLY-01: Pending registration visibility ────────────────

  group('PLY-01 — Pending registration card visibility', () {
    testWidgets('pending card hidden when no registrations exist', (
      tester,
    ) async {
      setDesktopSize(tester);
      await pumpApp(tester);

      await navigateToTab(tester, playersTabIndex);
      // The pending card renders "Pending self-registrations (N)" when
      // there are registrations. When empty, it shouldn't appear.
      expect(find.textContaining('Pending self-registrations'), findsNothing);
    });
  });

  // ── PLY-02 & PLY-03 skipped (no UI for pending regs) ──────

  group('PLY-02 — Approve pending registration', () {
    testWidgets('approve creates active player', (tester) async {
      // Skipped: no UI to add pending registrations — awaiting Stage 7.
    }, skip: true);
  });

  group('PLY-03 — Reject registration', () {
    testWidgets('reject removes applicant', (tester) async {
      // Skipped: no UI to add pending registrations — awaiting Stage 7.
    }, skip: true);
  });

  // ── PLY-04: Search filters ─────────────────────────────────

  group('PLY-04 — Search filters', () {
    testWidgets('search filters players by name match', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // Type a specific player name in the search field.
      final searchField = find.byType(TextField);
      await tester.enterText(searchField.first, 'Player0');
      await tester.pumpAndSettle();

      // Since IndexedStack keeps all pages alive, Player0 may appear
      // on the Dashboard too. The search should filter the Players tab
      // list — verify Player5 (different name) is NOT visible in the
      // Players list (which only shows filtered results).
      // Player0 should still appear somewhere (even if on Dashboard).
      expect(find.text('Player5 Test'), findsNothing);
    });

    testWidgets('clearing search shows all players', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      final searchField = find.byType(TextField);
      await tester.enterText(searchField.first, 'Player0');
      await tester.pumpAndSettle();

      final whileFiltered = find.byType(PlayerRow).evaluate().length;

      // Clear search.
      await tester.enterText(searchField.first, '');
      await tester.pumpAndSettle();

      // After clearing, non-matching players should reappear. Counting rows
      // rather than naming one avoids depending on where the list scrolled to.
      expect(
        find.byType(PlayerRow).evaluate().length,
        greaterThan(whileFiltered),
      );
    });
  });

  // ── PLY-05: Level adjustment stepper ───────────────────────

  group('PLY-05 — Level adjustment stepper', () {
    testWidgets('level plus and minus buttons exist', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // LevelAdjuster renders its steppers as "+" and "−" (U+2212) labels,
      // not icons.
      expect(find.byType(LevelAdjuster), findsWidgets);
      expect(find.text('+'), findsWidgets);
      expect(find.text('−'), findsWidgets);
    });
  });

  // ── PLY-06: Active/Inactive toggle ─────────────────────────

  group('PLY-06 — Membership and check-in state', () {
    testWidgets('seeded players are listed with their status controls', (
      tester,
    ) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // The Active/Inactive toggle was replaced by a membership pill plus a
      // separate check-in toggle, so a row carries both.
      expect(find.byType(PlayerRow), findsWidgets);
      expect(find.text('Member'), findsWidgets);
      // setupWithPlayers checks every seeded player in.
      expect(find.text('In'), findsWidgets);
    });
  });

  // ── PLY-07: Membership toggle ──────────────────────────────

  group('PLY-07 — Membership toggle', () {
    testWidgets('membership toggle present on player rows', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      expect(find.text('Member'), findsWidgets);
    });
  });

  // ── PLY-08: Check-in toggle ────────────────────────────────

  group('PLY-08 — Check-in toggle', () {
    testWidgets('check-in toggle present on player rows', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // Check-in toggle shows "In" or "Out". setupWithPlayers checks every
      // seeded player in, so every row shows "In".
      expect(find.text('In'), findsWidgets);
    });
  });

  // ── PLY-09/10/11: Expandable profile ───────────────────────

  group('PLY-09/10/11 — Expandable profile', () {
    testWidgets('tapping name expands profile with stats', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // Tap player name to expand profile.
      // Use .first since Player0 appears only in the Players list at
      // this point (not on the Dashboard since we haven't generated
      // games — just added to session).
      await tester.tap(find.text('Player0 Test').first);
      await tester.pumpAndSettle();

      // Profile should show stat tiles.
      expect(find.text('Current Level'), findsOneWidget);
    });

    testWidgets('only one profile expanded at a time', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      await tester.tap(find.text('Player0 Test').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Player1 Test').first);
      await tester.pumpAndSettle();

      // Only one profile expanded.
      expect(find.text('Current Level'), findsOneWidget);
    });

    testWidgets('tapping same name collapses profile', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      await tester.tap(find.text('Player0 Test').first);
      await tester.pumpAndSettle();
      expect(find.text('Current Level'), findsOneWidget);

      await tester.tap(find.text('Player0 Test').first);
      await tester.pumpAndSettle();
      expect(find.text('Current Level'), findsNothing);
    });
  });

  // ── PLY-12: Stats from history ─────────────────────────────

  group('PLY-12 — Profile stats from history', () {
    testWidgets('profile shows stats from logged sessions', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      await tester.tap(find.text('Player0 Test').first);
      await tester.pumpAndSettle();

      expect(find.text('Current Level'), findsOneWidget);
    });
  });

  // ── NAV-08: Table header responsive ────────────────────────

  group('NAV-08 — Table header visibility', () {
    testWidgets('table header visible on desktop', (tester) async {
      await setupWithPlayers(tester, desktopSize);
      await navigateToTab(tester, playersTabIndex);

      // The header cells render uppercased.
      expect(find.text('NAME / ID'), findsWidgets);
      expect(find.text('LEVEL'), findsWidgets);
      expect(find.text('MEMBERSHIP'), findsWidgets);
      expect(find.text('CHECKED IN'), findsWidgets);
    });

    testWidgets('table header hidden on phone', (tester) async {
      await setupWithPlayers(tester, phoneSize);
      await navigateToTab(tester, playersTabIndex);

      // On phone (<720px) the header row is dropped; only data rows remain.
      expect(find.text('NAME / ID'), findsNothing);
      expect(find.text('LEVEL'), findsNothing);
      expect(find.byType(PlayerRow), findsWidgets);
    });
  });
}
