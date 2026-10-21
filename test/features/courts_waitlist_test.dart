import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/game.dart';

import '../support/courts_harness.dart';

/// The desktop waitlist panel (IMPLEMENTATION 8.5.5; UAT WL-01, WL-04,
/// NAV-07, RND-12; F11, F12, F22).
void main() {
  setUpCourtsSandbox('courts_waitlist_test');

  Finder inPanel(Finder finder) =>
      find.descendant(of: find.byType(WaitlistPanel), matching: finder);

  List<String> listedNames(WidgetTester tester) => [
    for (final item in tester.widgetList<WaitlistPanelItem>(
      find.byType(WaitlistPanelItem),
    ))
      item.player.name(),
  ];

  testWidgets(
    'should_list_checked_in_players_in_check_in_order_when_no_lineup',
    (tester) async {
      final h = CourtsHarness(tester)..checkIn(3);

      await h.pump();

      expect(listedNames(tester), ['Player 1', 'Player 2', 'Player 3']);
    },
  );

  testWidgets('should_show_no_next_in_tag_when_no_lineup', (tester) async {
    final h = CourtsHarness(tester)..checkIn(3);

    await h.pump();

    expect(inPanel(find.text('Next in')), findsNothing);
  });

  testWidgets('should_show_title_and_count', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(19)
      ..toReady();

    await h.pump();

    expect(inPanel(find.text('Waitlist')), findsOneWidget);
    expect(inPanel(find.text('3')), findsOneWidget);
  });

  testWidgets('should_list_waitlist_in_waitlist_order', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final waiting = h.gameData.waitlistOrder;
    // One waiting player has played a round, so they go last (WL-01).
    h.gameData.history.add([
      Game.create([waiting.first]),
    ]);
    final expected = h.gameData.waitlistOrder.map((p) => p.name()).toList();

    await h.pump();

    expect(listedNames(tester), expected);
    expect(listedNames(tester).last, waiting.first.name());
  });

  testWidgets('should_show_tier_and_rounds_played_on_each_entry', (
    tester,
  ) async {
    final h = CourtsHarness(tester)..checkIn(1);
    final player = h.players.first;

    await h.pump();

    final tier = player.elo.skillTier.label;
    expect(inPanel(find.text('$tier · 0 rounds')), findsOneWidget);
  });

  testWidgets('should_say_one_round_in_singular', (tester) async {
    final h = CourtsHarness(tester)..checkIn(1);
    final player = h.players.first;
    h.gameData.history.add([
      Game.create([player]),
    ]);

    await h.pump();

    final tier = player.elo.skillTier.label;
    expect(inPanel(find.text('$tier · 1 round')), findsOneWidget);
  });

  testWidgets('should_show_next_in_tag_for_player_in_saved_next_round', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();
    h.gameData.quickSaveNextRound();
    final nextIds = {
      for (final game in h.gameData.nextLineup!) ...game.playerIds,
    };
    final waitingInNext = h.gameData.waitlistOrder
        .where((p) => nextIds.contains(p.id))
        .length;

    await h.pump();

    expect(inPanel(find.text('Next in')), findsNWidgets(waitingInNext));
  });

  testWidgets('should_filter_waitlist_by_search_text', (tester) async {
    final h = CourtsHarness(tester)..checkIn(12);
    await h.pump();

    await tester.enterText(
      find.byKey(const Key('waitlist-search')),
      'player 1',
    );
    await tester.pump();

    expect(listedNames(tester), [
      'Player 1',
      'Player 10',
      'Player 11',
      'Player 12',
    ]);
  });

  testWidgets('should_show_no_match_text_when_search_matches_nobody', (
    tester,
  ) async {
    final h = CourtsHarness(tester)..checkIn(3);
    await h.pump();

    await tester.enterText(find.byKey(const Key('waitlist-search')), 'zed');
    await tester.pump();

    expect(inPanel(find.text('No one matches “zed”')), findsOneWidget);
  });

  testWidgets('should_show_full_list_when_search_cleared', (tester) async {
    final h = CourtsHarness(tester)..checkIn(3);
    await h.pump();
    await tester.enterText(find.byKey(const Key('waitlist-search')), 'zed');
    await tester.pump();

    await tester.enterText(find.byKey(const Key('waitlist-search')), '');
    await tester.pump();

    expect(listedNames(tester), hasLength(3));
  });

  testWidgets('should_show_no_one_waiting_when_empty', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(16)
      ..toReady();

    await h.pump();

    expect(inPanel(find.text('No one waiting')), findsOneWidget);
  });

  testWidgets('should_not_press_entries_while_clock_runs', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();

    await h.pump();

    final item = tester.widget<WaitlistPanelItem>(
      find.byType(WaitlistPanelItem).first,
    );
    expect(item.onTap, isNull);
  });

  testWidgets('should_show_live_hint_while_clock_runs', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();

    await h.pump();

    expect(inPanel(find.text('Courts change at the next round')), findsOne);
  });

  testWidgets('should_select_entry_and_show_placing_hint_when_ready', (
    tester,
  ) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toReady();
    final first = h.gameData.waitlistOrder.first;
    await h.pump();

    await h.tap(find.byKey(Key('waitlist-item-${first.id}')));

    expect(
      inPanel(find.text('Placing ${first.name()} — tap a court slot')),
      findsOneWidget,
    );
  });

  testWidgets('should_scroll_list_and_keep_header_with_many_waiting', (
    tester,
  ) async {
    final h = CourtsHarness(tester);
    h.gameData.setSessionCapacity(40);
    h
      ..checkIn(36)
      ..toReady();
    await h.pump();
    final last = h.gameData.waitlistOrder.last;

    await tester.scrollUntilVisible(
      find.byKey(Key('waitlist-item-${last.id}')),
      100,
      scrollable: find.descendant(
        of: find.descendant(
          of: find.byType(WaitlistPanel),
          matching: find.byType(ListView),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.byKey(Key('waitlist-item-${last.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('waitlist-item-${last.id}')).hitTestable(), findsOne);
    expect(inPanel(find.text('SEARCH WAITLIST')).hitTestable(), findsOne);
  });
}
