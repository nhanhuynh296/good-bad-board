import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';

import '../support/courts_harness.dart';

/// R13-Q7, R13-Q8 (Nathan 2026-10-22): while the clock runs, a waitlist
/// player can go on a court with no players. R13-Q12: many courts scroll.
void main() {
  setUpCourtsSandbox('courts_hand_fill_test');

  /// RUNNING on 4 courts, 4 players waiting, then a 5th court added.
  CourtsHarness runningWithNewCourt(WidgetTester tester) {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();
    h.gameData.setNumberOfCourt(5);
    return h;
  }

  Finder waitlistItem(String id) => find.byKey(Key('waitlist-item-$id'));

  testWidgets('should_put_a_waitlist_player_on_the_new_court_while_running', (
    tester,
  ) async {
    final h = runningWithNewCourt(tester);
    final player = h.gameData.waitlistOrder.first;
    await h.pump(size: const Size(1920, 1080));

    await h.tap(waitlistItem(player.id));
    await h.tap(slotFinder(4, 0));

    expect(h.gameData.stagingMatches[4].playerIds, [player.id]);
  });

  testWidgets('should_not_move_a_waitlist_player_onto_a_court_with_players', (
    tester,
  ) async {
    final h = runningWithNewCourt(tester);
    final before = [...h.gameData.stagingMatches[0].playerIds];
    final player = h.gameData.waitlistOrder.first;
    await h.pump(size: const Size(1920, 1080));

    await h.tap(waitlistItem(player.id));
    await h.tap(slotFinder(0, 0));

    expect(h.gameData.stagingMatches[0].playerIds, before);
  });

  testWidgets('should_show_ten_courts_without_overflow_at_1280', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();
    h.gameData.setNumberOfCourt(10);

    await h.pump(size: const Size(1280, 720));

    expect(tester.takeException(), isNull);
  });

  testWidgets('should_scroll_to_the_tenth_court_at_1280', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();
    h.gameData.setNumberOfCourt(10);
    await h.pump(size: const Size(1280, 720));

    await tester.scrollUntilVisible(
      find.text('Court 10'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(GridView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    expect(find.text('Court 10'), findsOneWidget);
  });

  testWidgets('should_show_court_cards_for_ten_courts', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();
    h.gameData.setNumberOfCourt(10);

    await h.pump(size: const Size(1280, 720));

    expect(find.byType(DesktopCourtCard), findsWidgets);
  });
}
