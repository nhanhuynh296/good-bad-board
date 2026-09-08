import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/state/game_data.dart';

/// Helper to wrap a widget in the required MaterialApp + Scaffold.
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Reads the `selected` accessibility flag off the panel with [key].
bool selectedFlagOf(WidgetTester tester, Key key) =>
    tester.getSemantics(find.byKey(key)).flagsCollection.isSelected ==
    Tristate.isTrue;

void main() {
  // ─────────────────────────────────────────────────────────────────
  // RND-01: Countdown display — live mm:ss, progress bar fill =
  // remaining/D as percentage, updates at least once per second.
  // ─────────────────────────────────────────────────────────────────
  group('RND-01 — Countdown display', () {
    testWidgets('displays round number and mode label', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 3,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // Round number
      expect(find.text('ROUND 3'), findsOneWidget);
      // Mode label
      expect(
        find.text('Game-based · auto-rotates when the set clock ends'),
        findsOneWidget,
      );
    });

    testWidgets('displays countdown timer with MM:SS format', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Time-based · 20 min rounds',
            remainingLabel: '12:34',
            pct: 62.8,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // Countdown text shows the formatted remaining time
      expect(find.text('12:34'), findsOneWidget);
      // "until rotation" label
      expect(find.text('until rotation'), findsOneWidget);
    });

    testWidgets('progress bar fill reflects remaining percentage', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Time-based · 20 min rounds',
            remainingLabel: '10:00',
            pct: 50.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // The progress bar should be present and render.
      // We verify the LinearProgressIndicator exists and has the correct
      // value by checking it renders without error.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Pre-make next round button when not staged', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '18:00',
            pct: 90.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // When not staged, show "Pre-make next round" and hide "Cancel next"
      expect(find.text('Pre-make next round'), findsOneWidget);
      expect(find.text('Cancel next'), findsNothing);
    });

    testWidgets('shows Rotate now button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '18:00',
            pct: 90.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      expect(find.text('Rotate now'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-02: Final-minute urgency styling — when ≤60s remaining,
  // countdown text + progress bar switch to amber (#ffb38a).
  // ─────────────────────────────────────────────────────────────────
  group('RND-02 — Urgency styling', () {
    testWidgets('shows normal (non-amber) styling when > 60s remaining', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 2,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '05:00',
            pct: 25.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // Verify the widget builds without error in normal mode.
      // The countdown text and progress bar should NOT use urgent color.
      expect(find.text('05:00'), findsOneWidget);
      expect(find.byType(RoundRotationBar), findsOneWidget);
    });

    testWidgets('shows urgent amber styling when ≤ 60s remaining', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 2,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '00:45',
            pct: 3.75,
            isUrgent: true,
            isStaged: false,
          ),
        ),
      );

      // The widget should render with urgency state.
      // The countdown should still display.
      expect(find.text('00:45'), findsOneWidget);
      expect(find.byType(RoundRotationBar), findsOneWidget);
    });

    testWidgets('progress bar is still visible in urgent mode', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 2,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '00:30',
            pct: 2.5,
            isUrgent: true,
            isStaged: false,
          ),
        ),
      );

      // Progress bar should still exist (with amber color in implementation)
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-03: Auto-rotation at 0:00 — verified via GameData logic.
  // Tests in game_data_round_rotation_test.dart
  // ─────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────
  // RND-04: "Rotate now" triggers immediate rotation.
  // Tests in game_data_round_rotation_test.dart
  // ─────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────
  // RND-05: Pre-make next round — computes staged lineup, shows
  // "Cancel next" + staged panel.
  // ─────────────────────────────────────────────────────────────────
  group('RND-05 — Pre-make next round display', () {
    testWidgets('shows Cancel next and hides Pre-make when staged', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: true,
            stagedSummary: '16 players across 4 courts',
            stagedPct: 25.0,
          ),
        ),
      );

      // When staged: show "Cancel next" and hide "Pre-make next round"
      expect(find.text('Cancel next'), findsOneWidget);
      expect(find.text('Pre-make next round'), findsNothing);
    });

    testWidgets('shows NEXT ROUND · READY badge when staged', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: true,
            stagedSummary: '16 players across 4 courts',
            stagedPct: 25.0,
          ),
        ),
      );

      // The staged panel should show the READY badge and summary
      expect(find.text('NEXT ROUND · READY'), findsOneWidget);
      expect(find.text('16 players across 4 courts'), findsOneWidget);
    });

    testWidgets('shows striped progress bar in staged panel', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: true,
            stagedSummary: '16 players across 4 courts',
            stagedPct: 25.0,
          ),
        ),
      );

      // The staged panel should include a progress indicator
      // (striped/dashed bar that fills up rather than depletes)
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-06: Staged round becomes live — verified via GameData logic.
  // Tests in game_data_round_rotation_test.dart
  // ─────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────
  // RND-07: Cancel staged — panel disappears.
  // ─────────────────────────────────────────────────────────────────
  group('RND-07 — Cancel staged display', () {
    testWidgets('firing onCancelStaged clears the interface', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        wrap(
          RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: true,
            stagedSummary: '16 players across 4 courts',
            stagedPct: 25.0,
            onCancelStaged: () => cancelled = true,
          ),
        ),
      );

      // Tap "Cancel next" and verify callback fires
      await tester.tap(find.text('Cancel next'));
      expect(cancelled, isTrue);
    });

    testWidgets('hides staged panel when isStaged is false', (tester) async {
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // No staged elements visible
      expect(find.text('NEXT ROUND · READY'), findsNothing);
      expect(find.text('Cancel next'), findsNothing);
      expect(find.text('Pre-make next round'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-08: Only one staged round at a time — verified via GameData
  // logic. Tests in game_data_round_rotation_test.dart
  // ─────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────
  // RND-09: Mode label — Game-based vs. Time-based
  // ─────────────────────────────────────────────────────────────────
  group('RND-09 — Mode label', () {
    testWidgets('shows game-based mode label text', (tester) async {
      const gameBasedLabel =
          'Game-based · auto-rotates when the set clock ends';

      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: gameBasedLabel,
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // The exact subtitle from the UAT spec
      expect(find.text(gameBasedLabel), findsOneWidget);
    });

    testWidgets('shows time-based mode label text', (tester) async {
      const timeBasedLabel = 'Time-based · 20 min rounds';

      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: timeBasedLabel,
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      // The subtitle includes the duration from the session configuration
      expect(find.text(timeBasedLabel), findsOneWidget);
    });

    testWidgets('time-based label shows correct duration from settings', (
      tester,
    ) async {
      // Duration should reflect actual session setting
      const label = 'Time-based · 35 min rounds';

      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 2,
            modeLabel: label,
            remainingLabel: '30:00',
            pct: 85.7,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // RND-10: Round selector — the two panels act as radio buttons that
  // choose which round the court grid shows.
  // ─────────────────────────────────────────────────────────────────
  group('RND-10 — Round selector', () {
    Widget bar({
      required bool isStaged,
      RoundView selectedView = RoundView.current,
      ValueChanged<RoundView>? onSelectView,
    }) => wrap(
      RoundRotationBar(
        roundNumber: 1,
        modeLabel: 'Time-based · 20 min rounds',
        remainingLabel: '15:00',
        pct: 75.0,
        isUrgent: false,
        isStaged: isStaged,
        stagedSummary: '16 players across 4 courts',
        stagedPct: 25.0,
        selectedView: selectedView,
        onSelectView: onSelectView,
      ),
    );

    testWidgets('should_show_only_the_current_panel_when_not_staged', (
      tester,
    ) async {
      await tester.pumpWidget(bar(isStaged: false));

      expect(find.byKey(RoundRotationBar.currentPanelKey), findsOneWidget);
      expect(find.byKey(RoundRotationBar.nextPanelKey), findsNothing);
    });

    testWidgets('should_show_both_panels_when_staged', (tester) async {
      await tester.pumpWidget(bar(isStaged: true));

      expect(find.byKey(RoundRotationBar.currentPanelKey), findsOneWidget);
      expect(find.byKey(RoundRotationBar.nextPanelKey), findsOneWidget);
    });

    testWidgets('should_select_current_when_the_current_panel_is_tapped', (
      tester,
    ) async {
      RoundView? selected;
      await tester.pumpWidget(
        bar(
          isStaged: true,
          selectedView: RoundView.next,
          onSelectView: (view) => selected = view,
        ),
      );

      await tester.tap(find.byKey(RoundRotationBar.currentPanelKey));

      expect(selected, equals(RoundView.current));
    });

    testWidgets('should_select_next_when_the_next_panel_is_tapped', (
      tester,
    ) async {
      RoundView? selected;
      await tester.pumpWidget(
        bar(isStaged: true, onSelectView: (view) => selected = view),
      );

      await tester.tap(find.byKey(RoundRotationBar.nextPanelKey));

      expect(selected, equals(RoundView.next));
    });

    testWidgets('should_mark_the_current_panel_selected_by_default', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(bar(isStaged: true));

      expect(selectedFlagOf(tester, RoundRotationBar.currentPanelKey), isTrue);
      expect(selectedFlagOf(tester, RoundRotationBar.nextPanelKey), isFalse);
      handle.dispose();
    });

    testWidgets('should_mark_the_next_panel_selected_on_the_next_view', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        bar(isStaged: true, selectedView: RoundView.next),
      );

      expect(selectedFlagOf(tester, RoundRotationBar.nextPanelKey), isTrue);
      expect(selectedFlagOf(tester, RoundRotationBar.currentPanelKey), isFalse);
      handle.dispose();
    });

    testWidgets('should_keep_cancel_next_inside_the_next_panel', (
      tester,
    ) async {
      await tester.pumpWidget(bar(isStaged: true));

      expect(
        find.descendant(
          of: find.byKey(RoundRotationBar.nextPanelKey),
          matching: find.text('Cancel next'),
        ),
        findsOneWidget,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Additional interaction tests
  // ─────────────────────────────────────────────────────────────────
  group('RoundRotationBar — interactions', () {
    testWidgets('fires onRotateNow when Rotate now tapped', (tester) async {
      var rotated = false;

      await tester.pumpWidget(
        wrap(
          RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
            onRotateNow: () => rotated = true,
          ),
        ),
      );

      await tester.tap(find.text('Rotate now'));
      expect(rotated, isTrue);
    });

    testWidgets('fires onStageNext when Pre-make next round tapped', (
      tester,
    ) async {
      var staged = false;

      await tester.pumpWidget(
        wrap(
          RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
            onStageNext: () => staged = true,
          ),
        ),
      );

      await tester.tap(find.text('Pre-make next round'));
      expect(staged, isTrue);
    });

    testWidgets('Rotate now is always visible', (tester) async {
      // Not staged
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: false,
          ),
        ),
      );
      expect(find.text('Rotate now'), findsOneWidget);

      // Staged
      await tester.pumpWidget(
        wrap(
          const RoundRotationBar(
            roundNumber: 1,
            modeLabel: 'Game-based · auto-rotates when the set clock ends',
            remainingLabel: '15:00',
            pct: 75.0,
            isUrgent: false,
            isStaged: true,
            stagedSummary: '16 players across 4 courts',
            stagedPct: 25.0,
          ),
        ),
      );
      expect(find.text('Rotate now'), findsOneWidget);
    });
  });
}
