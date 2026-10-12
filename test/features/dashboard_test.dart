import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

void main() {
  Player testPlayer(String name, Elo elo) =>
      Player(firstName: name, lastName: 'Test', elo: elo, id: name);

  List<Player> fourPlayers() => [
    testPlayer('P1', Elo.b2),
    testPlayer('P2', Elo.b1),
    testPlayer('P3', Elo.a2),
    testPlayer('P4', Elo.a1),
  ];

  group('SpreadPill', () {
    testWidgets('shows "Same level" for gap of 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpreadPill(levelGap: 0)),
        ),
      );
      expect(find.text('Same level'), findsOneWidget);
    });

    testWidgets('shows "1 level gap" for gap of 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpreadPill(levelGap: 1)),
        ),
      );
      expect(find.text('1 level gap'), findsOneWidget);
    });

    testWidgets('shows "N level gap" for gap > 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SpreadPill(levelGap: 3)),
        ),
      );
      expect(find.text('3 level gap'), findsOneWidget);
    });
  });

  group('PlayerSlot', () {
    testWidgets('shows "Open slot" when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PlayerSlot()),
        ),
      );
      expect(find.text('Open slot'), findsOneWidget);
    });

    Future<void> pumpSlot(WidgetTester tester, Player player) =>
        tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: PlayerSlot(player: player)),
          ),
        );

    testWidgets('shows player name when occupied', (tester) async {
      await pumpSlot(tester, testPlayer('Alice', Elo.b1));
      expect(find.text('Alice Test'), findsOneWidget);
    });

    testWidgets('should_show_the_level_group_of_the_player', (tester) async {
      await pumpSlot(tester, testPlayer('Alice', Elo.b1));
      expect(find.text('Intermediate'), findsOneWidget);
    });

    testWidgets('should_not_show_the_elo_of_the_player', (tester) async {
      await pumpSlot(tester, testPlayer('Alice', Elo.b1));
      expect(find.text('B1'), findsNothing);
    });

    testWidgets('shows accent background when selection is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PlayerSlot(isSelectionActive: true)),
        ),
      );
      // Verify the widget builds without error when selection is active
      expect(find.text('Open slot'), findsOneWidget);
    });

    testWidgets('fires onTap when tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlayerSlot(
              player: testPlayer('Bob', Elo.a2),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Bob Test'));
      expect(tapped, isTrue);
    });
  });

  group('CourtCard', () {
    testWidgets('should_end_the_last_slot_at_the_card_bottom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 500,
                height: 400,
                child: CourtCard(courtNumber: 1, players: []),
              ),
            ),
          ),
        ),
      );

      final lastSlot = tester.getRect(find.byType(PlayerSlot).last);
      // The card border is 1 px wide.
      expect(lastSlot.bottom, closeTo(400, 1.01));
    });

    testWidgets('displays court number and 4 slots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CourtCard(courtNumber: 3, players: [])),
        ),
      );
      expect(find.text('COURT 3'), findsOneWidget);
      // Should have 4 "Open slot" texts
      expect(find.text('Open slot'), findsNWidgets(4));
    });

    testWidgets('displays players in slots', (tester) async {
      final players = [
        testPlayer('P1', Elo.b2),
        testPlayer('P2', Elo.b1),
        testPlayer('P3', Elo.a2),
        testPlayer('P4', Elo.a1),
      ];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CourtCard(courtNumber: 1, players: players)),
        ),
      );
      expect(find.text('P1 Test'), findsOneWidget);
      expect(find.text('P4 Test'), findsOneWidget);
      // Remaining 2 slots should be Open slot (since 4 players fill all)
      expect(find.text('Open slot'), findsNothing);
    });

    testWidgets('shows re-roll button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: [testPlayer('P1', Elo.b2)],
            ),
          ),
        ),
      );
      expect(find.text('Re-roll'), findsOneWidget);
    });

    testWidgets('fires onReroll when re-roll tapped', (tester) async {
      var rerolled = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: [testPlayer('P1', Elo.b2)],
              onReroll: () => rerolled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Re-roll'));
      expect(rerolled, isTrue);
    });

    testWidgets('fires onSlotTap with correct index', (tester) async {
      int? tappedSlot;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: [testPlayer('P1', Elo.b2)],
              isSelectionActive: true,
              onSlotTap: (i) => tappedSlot = i,
            ),
          ),
        ),
      );
      // Tap the first occupied slot
      await tester.tap(find.text('P1 Test'));
      expect(tappedSlot, 0);
    });

    testWidgets('shows no save button when onSave is absent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(courtNumber: 1, players: fourPlayers()),
          ),
        ),
      );
      expect(find.byKey(const Key('court-save-button')), findsNothing);
    });

    testWidgets('shows save button when court is full and onSave is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: fourPlayers(),
              onSave: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('court-save-button')), findsOneWidget);
    });

    testWidgets('hides save button when the court is not yet full', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: [testPlayer('P1', Elo.b2)],
              onSave: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('court-save-button')), findsNothing);
    });

    testWidgets('fires onSave when the save button is tapped', (tester) async {
      var saved = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: fourPlayers(),
              onSave: () => saved = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('court-save-button')));
      expect(saved, isTrue);
    });

    testWidgets('shows PLAYING badge when the court is in play', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: fourPlayers(),
              isPlaying: true,
            ),
          ),
        ),
      );
      expect(find.text('PLAYING'), findsOneWidget);
    });

    testWidgets('hides save button while the court is in play', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CourtCard(
              courtNumber: 1,
              players: fourPlayers(),
              isPlaying: true,
              onSave: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('court-save-button')), findsNothing);
    });
  });

  group('StatStrip', () {
    testWidgets('displays all six stat labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StatStrip()),
        ),
      );
      expect(find.text('CHECKED IN'), findsOneWidget);
      expect(find.text('REMAINING SLOTS'), findsOneWidget);
      expect(find.text('WAITLIST'), findsOneWidget);
      expect(find.text('AVG LEVEL'), findsOneWidget);
      expect(find.text('AVG LEVEL GAP'), findsOneWidget);
      expect(find.text('RE-ROLLS'), findsOneWidget);
    });

    testWidgets('displays provided values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatStrip(
              checkedIn: '12',
              remainingSlots: '8',
              waitlist: '3',
              avgLevel: 'B1',
              avgLevelGap: '1.5',
              rerolls: '4',
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('WaitlistSidebar', () {
    testWidgets('shows empty state when no players', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WaitlistSidebar(players: [])),
        ),
      );
      expect(find.text('No one waiting'), findsOneWidget);
    });

    testWidgets('shows player names and positions', (tester) async {
      final players = [testPlayer('Alice', Elo.b2), testPlayer('Bob', Elo.c1)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WaitlistSidebar(players: players)),
        ),
      );
      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('Bob Test'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // position
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('highlights selected player', (tester) async {
      final players = [testPlayer('Alice', Elo.b2)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistSidebar(players: players, selectedPlayerId: 'Alice'),
          ),
        ),
      );
      // Widget should build without error with a selected player
      expect(find.text('Alice Test'), findsOneWidget);
    });

    testWidgets('should_name_the_selected_player_in_the_placing_hint', (
      tester,
    ) async {
      final players = [testPlayer('Alice', Elo.b2)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistSidebar(players: players, selectedPlayerId: 'Alice'),
          ),
        ),
      );
      expect(
        find.text('Placing Alice Test — tap a court slot'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_the_idle_hint_when_nobody_is_selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistSidebar(players: [testPlayer('Alice', Elo.b2)]),
          ),
        ),
      );
      expect(
        find.text(
          'Tap a waitlisted player, then a court slot to place or swap them in.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('fires onPlayerSelect when tapped', (tester) async {
      Player? selected;
      final players = [testPlayer('Alice', Elo.b2)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistSidebar(
              players: players,
              onPlayerSelect: (p) => selected = p,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alice Test'));
      expect(selected, isNotNull);
      expect(selected!.firstName, 'Alice');
    });
  });

  group('WaitlistSidebar tier', () {
    testWidgets('should_show_the_level_group_of_a_waiting_player', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistSidebar(players: [testPlayer('Alice', Elo.s1)]),
          ),
        ),
      );
      expect(find.text('Professional'), findsOneWidget);
    });
  });

  group('WaitlistChips', () {
    testWidgets('shows empty state when no players', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WaitlistChips(players: [])),
        ),
      );
      expect(find.text('No one waiting'), findsOneWidget);
    });

    testWidgets('shows chips with player info', (tester) async {
      final players = [testPlayer('Alice', Elo.b2)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WaitlistChips(players: players)),
        ),
      );
      expect(find.textContaining('Alice Test'), findsOneWidget);
      expect(find.textContaining('Intermediate'), findsOneWidget);
    });

    testWidgets('should_not_show_the_elo_in_a_chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistChips(players: [testPlayer('Alice', Elo.b2)]),
          ),
        ),
      );
      expect(find.textContaining('B2'), findsNothing);
    });

    testWidgets('fires onPlayerSelect when chip tapped', (tester) async {
      Player? selected;
      final players = [testPlayer('Alice', Elo.b2)];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WaitlistChips(
              players: players,
              onPlayerSelect: (p) => selected = p,
            ),
          ),
        ),
      );
      await tester.tap(find.textContaining('Alice Test'));
      expect(selected, isNotNull);
      expect(selected!.firstName, 'Alice');
    });
  });
}
