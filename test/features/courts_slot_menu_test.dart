import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';

import '../support/courts_harness.dart';

/// Court cards, slots and the slot "⋯" menu on the desktop Courts tab
/// (IMPLEMENTATION 8.5.4; UAT COURT-01, COURT-10, COURT-14 … COURT-16;
/// F06, F11, F17, F27, R11-Q4).
void main() {
  setUpCourtsSandbox('courts_slot_menu_test');

  Future<void> openMenu(CourtsHarness h, int court, int slot) async {
    await h.tap(slotMoreFinder(court, slot));
    await h.tester.pumpAndSettle();
  }

  group('Slot menu items (COURT-15)', () {
    testWidgets('should_offer_move_and_check_out_when_ready', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();

      await openMenu(h, 0, 0);

      expect(find.text('Move to waitlist'), findsOneWidget);
      expect(find.text('Check out'), findsOneWidget);
    });

    testWidgets('should_offer_check_out_only_when_running', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await openMenu(h, 0, 0);

      expect(find.text('Move to waitlist'), findsNothing);
      expect(find.text('Check out'), findsOneWidget);
    });

    testWidgets('should_offer_check_out_only_in_changeover', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();
      await h.pump();

      await openMenu(h, 0, 0);

      expect(find.text('Move to waitlist'), findsNothing);
      expect(find.text('Check out'), findsOneWidget);
    });

    testWidgets('should_offer_full_menu_in_paused_changeover', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();
      h.gameData.pause();
      await h.pump();

      await openMenu(h, 0, 0);

      expect(find.text('Move to waitlist'), findsOneWidget);
    });

    testWidgets('should_offer_full_menu_in_running_edit_mode', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();
      await h.pump();

      await openMenu(h, 0, 0);

      expect(find.text('Move to waitlist'), findsOneWidget);
    });

    testWidgets('should_hide_menu_for_checked_out_player_on_running_court', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      h.gameData.checkOutPlayer(h.gameData.visibleMatches[0].players[0]);

      await h.pump();

      expect(slotMoreFinder(0, 0), findsNothing);
      expect(slotMoreFinder(0, 1), findsOneWidget);
    });

    testWidgets('should_have_no_menu_on_open_slot', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(16)
        ..toReady();
      h.gameData.checkOutPlayer(h.gameData.visibleMatches[3].players[3]);

      await h.pump();

      expect(find.text('Open slot'), findsOneWidget);
      expect(slotMoreFinder(3, 3), findsNothing);
    });

    testWidgets('should_move_player_to_waitlist_when_move_selected', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      final player = h.gameData.visibleMatches[0].players[0];
      await h.pump();
      await openMenu(h, 0, 0);

      await h.tapText('Move to waitlist');
      await tester.pumpAndSettle();

      expect(h.gameData.waitlistOrder, contains(player));
    });

    testWidgets('should_check_out_player_when_check_out_selected', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();
      await openMenu(h, 0, 0);

      await h.tapText('Check out');
      await tester.pumpAndSettle();

      expect(h.gameData.checkedInCount, 19);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should_close_menu_when_escape_pressed', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();
      await openMenu(h, 0, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Move to waitlist'), findsNothing);
    });

    testWidgets('should_return_focus_to_more_button_when_menu_closes', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();
      await openMenu(h, 0, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      final focused = FocusManager.instance.primaryFocus!.context!;
      final inMore = find.descendant(
        of: slotMoreFinder(0, 0),
        matching: find.byElementPredicate((element) => element == focused),
        matchRoot: true,
      );
      expect(inMore, findsOneWidget);
    });

    testWidgets('should_give_more_button_forty_pixel_hit_area', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();

      await h.pump();

      final size = tester.getSize(slotMoreFinder(0, 0));
      expect(size.width >= 40 && size.height >= 40, isTrue);
    });

    testWidgets('should_show_more_button_on_hover', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(slotFinder(0, 0)));
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: slotMoreFinder(0, 0), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('should_hide_more_button_without_hover_or_focus', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();

      await h.pump();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: slotMoreFinder(0, 0), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0);
    });

    testWidgets('should_show_more_button_on_keyboard_focus', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();

      final more = tester.widget<IconButton>(
        find.descendant(
          of: slotMoreFinder(0, 0),
          matching: find.byType(IconButton),
          matchRoot: true,
        ),
      );
      more.focusNode!.requestFocus();
      await tester.pumpAndSettle();

      final opacity = tester.widget<Opacity>(
        find.ancestor(of: slotMoreFinder(0, 0), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 1);
    });
  });

  group('Re-roll and slot tap (COURT-10, COURT-14)', () {
    testWidgets('should_hide_reroll_on_live_court_while_running', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      expect(find.text('Re-roll'), findsNothing);
    });

    testWidgets('should_hide_reroll_in_changeover', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toChangeover();

      await h.pump();

      expect(find.text('Re-roll'), findsNothing);
    });

    testWidgets('should_show_reroll_on_every_court_when_paused', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();

      await h.pump();

      expect(find.text('Re-roll'), findsNWidgets(4));
    });

    testWidgets('should_show_reroll_in_edit_mode', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toEditing();

      await h.pump();

      expect(find.text('Re-roll'), findsNWidgets(4));
    });

    testWidgets('should_not_select_slot_when_running', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();
      await h.pump();

      await h.tap(slotFinder(0, 0));

      final slot = tester.widget<DesktopPlayerSlot>(slotFinder(0, 0));
      expect(slot.isSelected, isFalse);
    });

    testWidgets('should_not_mark_slot_as_button_when_running', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toRunning();

      await h.pump();

      final semantics = tester.getSemantics(slotFinder(0, 0));
      expect(semantics.flagsCollection.isButton, isFalse);
    });

    testWidgets('should_select_slot_when_tapped_in_ready', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();

      await h.tap(slotFinder(0, 0));

      final slot = tester.widget<DesktopPlayerSlot>(slotFinder(0, 0));
      expect(slot.isSelected, isTrue);
    });

    testWidgets('should_clear_selection_when_same_slot_tapped_again', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump();
      await h.tap(slotFinder(0, 0));

      await h.tap(slotFinder(0, 0));

      final slot = tester.widget<DesktopPlayerSlot>(slotFinder(0, 0));
      expect(slot.isSelected, isFalse);
    });

    testWidgets('should_show_court_title_and_tier_name', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();

      await h.pump();

      expect(find.text('Court 1'), findsOneWidget);
      expect(find.text('B1'), findsNothing);
    });
  });
}
