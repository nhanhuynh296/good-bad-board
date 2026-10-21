import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/courts_harness.dart';

/// The swap Undo bottom message on the Courts tab (IMPLEMENTATION 8.3,
/// 8.5.6; UAT COURT-08, COURT-10, COURT-17; R6-Q6, R7-Q2, F15).
void main() {
  setUpCourtsSandbox('courts_swap_undo_test');

  testWidgets('should_show_swap_message_when_two_court_players_swapped', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final a = h.gameData.visibleMatches[0].players[0];
    final b = h.gameData.visibleMatches[1].players[0];
    await h.pump();

    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    expect(find.text('Swapped ${a.name()} and ${b.name()}.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('should_trade_places_when_two_court_players_swapped', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final a = h.gameData.visibleMatches[0].players[0];
    await h.pump();

    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));

    expect(h.gameData.visibleMatches[1].players[0], a);
  });

  testWidgets('should_restore_players_when_undo_tapped', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final a = h.gameData.visibleMatches[0].players[0];
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    await h.tapText('Undo');
    await tester.pumpAndSettle();

    expect(h.gameData.visibleMatches[0].players[0], a);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('should_hide_swap_message_after_ten_seconds', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('should_keep_swap_message_before_ten_seconds', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 8));

    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('should_hide_swap_message_when_other_change_made', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    h.gameData.checkOutPlayer(h.gameData.visibleMatches[2].players[0]);
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('should_not_show_message_when_player_moved_to_open_slot', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(16)
      ..toReady();
    h.gameData.checkOutPlayer(h.gameData.visibleMatches[3].players[3]);
    await h.pump();

    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(3, 3));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('should_swap_waitlisted_player_into_occupied_slot', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final waiting = h.gameData.waitlistOrder.first;
    await h.pump();

    await h.tap(find.byKey(Key('waitlist-item-${waiting.id}')));
    await h.tap(slotFinder(0, 0));
    await tester.pumpAndSettle();

    expect(h.gameData.visibleMatches[0].players[0], waiting);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('should_not_undo_swap_with_keyboard_shortcut', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final a = h.gameData.visibleMatches[0].players[0];
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(h.gameData.visibleMatches[1].players[0], a);
  });

  testWidgets('should_keep_message_box_within_360_by_48', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    await h.pump();
    await h.tap(slotFinder(0, 0));
    await h.tap(slotFinder(1, 0));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(SnackBar));
    expect(size.width <= 400 && size.height <= 64, isTrue);
  });
}
