import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/state/game_data.dart';

import '../support/courts_harness.dart';

/// NAV-07: the club runs 4 courts on a Windows desktop window. All 4 courts
/// must be on screen at once, under the round bar and the next-round strip,
/// with the waitlist panel at the right, and the grid must not scroll
/// (IMPLEMENTATION 8.5.1).
void main() {
  setUpCourtsSandbox('dashboard_four_courts_fit_test');

  test('should_default_to_four_courts', () {
    expect(GameData().numberOfCourt, 4);
  });

  const sizes = [
    Size(1280, 720),
    Size(1366, 768),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  final phases = <String, void Function(CourtsHarness)>{
    'no_lineup': (_) {},
    'ready': (h) => h.toReady(),
    'running': (h) => h.toRunning(),
    'edit_mode': (h) => h.toEditing(),
    'paused': (h) => h.toPaused(),
    'time_up': (h) => h.toTimeUp(),
    'changeover': (h) => h.toChangeover(),
  };

  for (final size in sizes) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    for (final MapEntry(key: phase, value: arrange) in phases.entries) {
      testWidgets('should_show_all_four_courts_at_${name}_when_$phase', (
        tester,
      ) async {
        final h = CourtsHarness(tester)..checkIn(20);
        arrange(h);
        await h.pump(size: size);

        final viewport = Offset.zero & size;
        final cards = find.byType(DesktopCourtCard);
        expect(cards, findsNWidgets(4));
        for (var i = 0; i < 4; i++) {
          expect(
            viewport.contains(tester.getBottomRight(cards.at(i))) &&
                viewport.contains(tester.getTopLeft(cards.at(i))),
            isTrue,
            reason: 'court ${i + 1} is outside the $name window',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('should_not_cut_player_names_at_$name', (tester) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toReady();
      await h.pump(size: size);

      final names = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(DesktopPlayerSlot),
          matching: find.textContaining('Player'),
        ),
      );
      expect(names.where((p) => p.didExceedMaxLines), isEmpty);
    });
  }

  testWidgets('should_place_round_bar_under_nav_at_full_width', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();

    await h.pump();

    final bar = tester.getRect(find.byType(RoundBar));
    expect(bar, const Rect.fromLTWH(0, 56, 1280, 80));
  });

  testWidgets('should_give_waitlist_panel_280_pixels', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();

    await h.pump();

    expect(tester.getSize(find.byType(WaitlistPanel)).width, 280);
  });

  testWidgets('should_show_no_stat_strip_on_desktop', (tester) async {
    final h = CourtsHarness(tester)
      ..checkIn(20)
      ..toRunning();

    await h.pump();

    expect(find.byType(StatStrip), findsNothing);
  });

  for (final locale in const [Locale('fr'), Locale('zh'), Locale('zh', 'HK')]) {
    testWidgets('should_fit_paused_round_bar_at_1280_in_$locale', (
      tester,
    ) async {
      final h = CourtsHarness(tester)
        ..checkIn(20)
        ..toPaused();

      await h.pump(locale: locale);

      expect(tester.takeException(), isNull);
    });
  }
}
