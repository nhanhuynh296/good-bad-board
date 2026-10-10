import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Shared setup: players in repo + session, game generated ──

  Future<void> setupWithGame(WidgetTester tester, Size size) async {
    await pumpAppWithPlayers(tester, playerCount: 5, surfaceSize: size);

    // Generate a game from the 5 players.
    await generateGame(tester);
  }

  // ── NAV-06: Stat strip reflow ─────────────────────────────

  group('NAV-06 — Stat strip reflow', () {
    testWidgets('desktop shows 6 stats in a single row', (tester) async {
      await setupWithGame(tester, desktopSize);

      // All 6 stat labels should be present on desktop.
      // AppStatCell uppercases labels, so search for uppercase.
      expect(find.text('CHECKED IN'), findsWidgets);
      expect(find.text('REMAINING SLOTS'), findsWidgets);
      expect(find.text('WAITLIST'), findsWidgets);
      expect(find.text('AVG LEVEL'), findsWidgets);
      expect(find.text('AVG LEVEL GAP'), findsWidgets);
      expect(find.text('RE-ROLLS'), findsWidgets);
    });

    testWidgets('tablet shows all 6 stats', (tester) async {
      await setupWithGame(tester, tabletSize);

      // Tablet also shows all 6 stat labels.
      expect(find.text('CHECKED IN'), findsWidgets);
      expect(find.text('REMAINING SLOTS'), findsWidgets);
      expect(find.text('WAITLIST'), findsWidgets);
      expect(find.text('AVG LEVEL'), findsWidgets);
      expect(find.text('AVG LEVEL GAP'), findsWidgets);
      expect(find.text('RE-ROLLS'), findsWidgets);
    });

    testWidgets('phone shows stats in compact layout', (tester) async {
      await setupWithGame(tester, phoneSize);

      // Phone shows core stats in compact layout.
      expect(find.text('CHECKED IN'), findsWidgets);
      expect(find.text('WAITLIST'), findsWidgets);
      expect(find.text('AVG LEVEL'), findsWidgets);
    });
  });

  // ── NAV-07: Dashboard layout reflow ───────────────────────

  group('NAV-07 — Dashboard layout reflow', () {
    testWidgets('desktop shows court grid with waitlist sidebar', (
      tester,
    ) async {
      await setupWithGame(tester, desktopSize);

      // Desktop layout has a Waitlist sidebar with title.
      // At desktop width, the sidebar renders as a card.
      expect(find.text('Waitlist'), findsWidgets);

      // Court labels should be present.
      expect(find.textContaining('COURT'), findsWidgets);
    });

    testWidgets('tablet/phone shows chips above courts', (tester) async {
      await setupWithGame(tester, tabletSize);

      // At tablet width (<1080px), waitlist renders as chips.
      expect(find.text('Waitlist'), findsWidgets);
      expect(find.textContaining('COURT'), findsWidgets);
    });
  });
}
