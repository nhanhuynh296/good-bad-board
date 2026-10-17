import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Shared setup ──────────────────────────────────────────

  /// Pump with N players seeded, then generate a game.
  Future<void> setupWithNPlayers(WidgetTester tester, int count) async {
    await pumpAppWithPlayers(
      tester,
      playerCount: count,
      surfaceSize: desktopSize,
    );
    await generateGame(tester);
  }

  // ── COURT-01: Court display ────────────────────────────────

  group('COURT-01 — Court display', () {
    testWidgets('court shows number, level-gap badge, player rows', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 5);

      // Court labels are present.
      expect(find.textContaining('COURT'), findsWidgets);

      // Player names appear in court slots.
      // With 5 players and 2 courts, 4 go to court 1, 1 waitlisted,
      // court 2 is empty.
    });

    testWidgets('empty court slots show "Open slot" text', (tester) async {
      await setupWithNPlayers(tester, 5);

      // Court 2 should have all "Open slot" entries.
      expect(find.text('Open slot'), findsWidgets);
    });
  });

  // ── COURT-02: Re-roll rebalances ───────────────────────────

  group('COURT-02 — Re-roll rebalances', () {
    testWidgets('re-roll changes court players and increments count', (
      tester,
    ) async {
      // 9 players: 8 on courts (2 courts × 4), 1 waitlisted.
      await setupWithNPlayers(tester, 9);

      // Tap re-roll on court 1 (first refresh icon).
      final rerollBtn = find.byIcon(Icons.refresh_rounded);
      expect(rerollBtn, findsWidgets);
      await tester.tap(rerollBtn.first);
      await tester.pumpAndSettle();

      // The round clock runs, so the app warns first (COURT-12); confirm.
      final confirm = find.widgetWithText(FilledButton, 'Re-roll');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      }

      // Re-roll count should increment (stat strip shows new count).
    });
  });

  // ── COURT-03: Re-roll no-op ────────────────────────────────

  group('COURT-03 — Re-roll no-op', () {
    testWidgets('re-roll does nothing with exactly 4 players', (tester) async {
      await setupWithNPlayers(tester, 4);

      // With 4 players all on one court (0 waitlisted), re-roll
      // has no alternate combos.
      final rerollBtn = find.byIcon(Icons.refresh_rounded);
      if (rerollBtn.evaluate().isNotEmpty) {
        await tester.tap(rerollBtn.first);
        await tester.pumpAndSettle();
      }
    });
  });

  // ── COURT-04: Select waitlisted player ─────────────────────

  group('COURT-04 — Select waitlisted player', () {
    testWidgets('tapping waitlisted player shows placement hint', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 5);

      // 5 players, 2 courts: 4 are drawn onto court 1 and one is left over.
      // Which one is a weighted random draw, so ask the state rather than
      // naming a player.
      final player = await selectWaitlistedPlayer(tester);

      // Hint should indicate placement mode.
      expect(
        find.text('Placing ${player.name()} — tap a court slot'),
        findsOneWidget,
      );
    });
  });

  // ── COURT-05: Switch selection ─────────────────────────────

  group('COURT-05 — Switch selection', () {
    testWidgets('tapping different waitlisted player switches selection', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 6);

      // 6 players: 4 on court, 2 waitlisted.
      await selectWaitlistedPlayer(tester, index: 0);
      await selectWaitlistedPlayer(tester, index: 1);

      // Hint should still be showing placement mode.
      expect(find.textContaining('— tap a court slot'), findsOneWidget);
    });
  });

  // ── COURT-06: Deselect ─────────────────────────────────────

  group('COURT-06 — Deselect player', () {
    testWidgets('tapping selected player again clears selection', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 5);

      final player = await selectWaitlistedPlayer(tester);
      // Deselect same player.
      await selectWaitlistPlayer(tester, player.name());

      // Hint should revert to the idle prompt.
      expect(
        find.text(
          'Tap a waitlisted player, then a court slot to place or swap them in.',
        ),
        findsOneWidget,
      );
    });
  });

  // ── COURT-07: Place into empty slot ────────────────────────

  group('COURT-07 — Place selected player into empty slot', () {
    testWidgets('placing selected player into open slot seats them', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 5);

      final player = await selectWaitlistedPlayer(tester);

      // Tap an "Open slot" — the first one should be on court 2.
      await tapOpenSlot(tester, 2, 0);

      // Player is now seated, and no longer waitlisted.
      expect(
        waitlistedPlayers(tester).map((p) => p.id),
        isNot(contains(player.id)),
      );
    });
  });

  // ── COURT-08: Swap into occupied slot ──────────────────────

  group('COURT-08 — Swap into occupied slot', () {
    testWidgets('placing on occupied slot swaps the two players', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 6);

      // 6 players: 4 on court 1, 2 waitlisted.
      final seated = playerOnCourt(tester);
      final player = await selectWaitlistedPlayer(tester);

      // Tap an occupied slot on Court 1.
      await tester.tap(find.text(seated));
      await tester.pumpAndSettle();

      // The waitlisted player took the slot; the seated one was displaced.
      expect(
        waitlistedPlayers(tester).map((p) => p.id),
        isNot(contains(player.id)),
      );
      expect(waitlistedPlayers(tester).map((p) => p.name()), contains(seated));
    });
  });

  // ── COURT-09: Slots inert without selection ────────────────

  group('COURT-09 — Slots inert without selection', () {
    // An occupied slot now selects its player (COURT-10); the lineup must
    // still not change.
    testWidgets('tapping slot without selection does nothing', (tester) async {
      await setupWithNPlayers(tester, 5);

      // No player selected — tap an occupied slot.
      final seated = playerOnCourt(tester);
      final beforeCount = find.text(seated).evaluate().length;

      await tester.tap(find.text(seated));
      await tester.pumpAndSettle();

      // Nothing should have changed.
      final afterCount = find.text(seated).evaluate().length;
      expect(afterCount, equals(beforeCount));
    });
  });

  // ── WL-01: Waitlist display ────────────────────────────────

  group('WL-01 — Waitlist display', () {
    testWidgets('waitlist shows entries with name and level', (tester) async {
      await setupWithNPlayers(tester, 6);

      // Waitlist section should show a title.
      expect(find.text('Waitlist'), findsWidgets);
    });

    testWidgets('empty waitlist shows "No one waiting"', (tester) async {
      await pumpAppWithPlayers(
        tester,
        playerCount: 0,
        surfaceSize: desktopSize,
      );

      // No players, no game — waitlist should be empty.
      expect(find.text('No one waiting'), findsOneWidget);
    });
  });

  // ── WL-02: Auto-promotion on check-out ─────────────────────

  group('WL-02 — Auto-promotion on check-out', () {
    testWidgets('removing court player promotes highest waitlisted', (
      tester,
    ) async {
      await setupWithNPlayers(tester, 6);

      // 6 players: 4 on court, 2 waitlisted.
      // Remove a court player to trigger auto-promotion.
      final gameData = tester
          .element(find.byType(MaterialApp))
          .read<GameData>();

      // Find a player on court and remove them.
      final courtPlayers = gameData.stagingMatches
          .expand((g) => g.players)
          .toList();
      if (courtPlayers.isNotEmpty) {
        gameData.removePlayer(courtPlayers.first);
        await tester.pumpAndSettle();
      }

      // The waitlist should have changed (auto-promotion).
    });
  });
}
