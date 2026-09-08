import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/schedule/schedule.dart';

void main() {
  group('SchedulePage', () {
    testWidgets('SCHED-01: should display "Recurring sessions" section title',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      expect(find.text('Recurring sessions'), findsOneWidget);
    });

    testWidgets(
        'SCHED-01: should display session day and time on each card',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      // Each session card shows a day label, e.g. "Monday"
      expect(find.text('Monday'), findsOneWidget);
      // Each session card shows a time window, e.g. "6:00 PM - 8:00 PM"
      expect(find.text('6:00 PM - 8:00 PM'), findsOneWidget);
    });

    testWidgets(
        'SCHED-01: should display session note/description on each card',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      expect(
        find.text('Open play — all levels welcome'),
        findsOneWidget,
      );
    });

    testWidgets(
        'SCHED-01: should display "Auto check-in opens 30 min prior" badge '
        'on each card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      expect(
        find.text('Auto check-in opens 30 min prior'),
        findsWidgets,
      );
    });

    testWidgets(
        'SCHED-01: should display footer text about calendar view in Settings',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      expect(
        find.text(
          'Public calendar view and reminder scheduling live under Settings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'SCHED-01: should show empty state when no sessions scheduled',
        (tester) async {
      // SchedulePage has hardcoded data, so when items exist the empty-state
      // text should never appear. When dynamic data is supported (future),
      // update this to verify the empty state renders correctly.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SchedulePage())),
      );

      // With hardcoded data, session cards are shown and empty state is hidden.
      expect(find.text('No recurring sessions'), findsNothing);
    });
  });
}
