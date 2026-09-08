import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

import '../support/repository_sandbox.dart';

Player _testPlayer(String name, Elo elo) =>
    Player(firstName: name, lastName: 'Test', elo: elo, id: name);

void main() {
  group('LevelAdjuster', () {
    testWidgets('displays current ELO level', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.b1,
              onDecrease: () {},
              onIncrease: () {},
            ),
          ),
        ),
      );
      expect(find.text('B1'), findsOneWidget);
    });

    testWidgets('minus button calls onDecrease', (tester) async {
      var decreased = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.b1,
              onDecrease: () => decreased = true,
              onIncrease: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('−'));
      expect(decreased, isTrue);
    });

    testWidgets('plus button calls onIncrease', (tester) async {
      var increased = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.b1,
              onDecrease: () {},
              onIncrease: () => increased = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('+'));
      expect(increased, isTrue);
    });

    testWidgets('minus button is disabled at lowest tier', (tester) async {
      var decreased = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.c2, // Lowest tier
              onDecrease: () => decreased = true,
              onIncrease: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('−'));
      expect(decreased, isFalse);
    });

    testWidgets('plus button is disabled at highest tier', (tester) async {
      var increased = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.s1, // Highest tier
              onDecrease: () {},
              onIncrease: () => increased = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('+'));
      expect(increased, isFalse);
    });

    testWidgets('disabled buttons render with reduced opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelAdjuster(
              currentLevel: Elo.c2,
              onDecrease: () {},
              onIncrease: () {},
            ),
          ),
        ),
      );
      // The minus button should have an Opacity wrapper with 0.35
      final opacityFinder = find.byWidgetPredicate(
        (w) => w is Opacity && w.opacity == 0.35,
      );
      expect(opacityFinder, findsOneWidget); // Only minus is disabled
    });
  });

  group('PlayerRow', () {
    testWidgets('displays player name and sign-in ID', (tester) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
            ),
          ),
        ),
      );
      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('—'), findsOneWidget); // No sign-in ID
    });

    testWidgets('displays sign-in ID when set', (tester) async {
      final player = Player(
        firstName: 'Bob',
        lastName: 'Smith',
        elo: Elo.a1,
        id: 'bob-id',
        signInId: 'BS001',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: true,
            ),
          ),
        ),
      );
      expect(find.text('BS001'), findsOneWidget);
    });

    testWidgets('shows Member label for member status', (tester) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
            ),
          ),
        ),
      );
      expect(find.text('Member'), findsOneWidget);
    });

    testWidgets('shows Disabled label for disabled status', (tester) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.disabled,
              isCheckedIn: false,
            ),
          ),
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('shows Member/Casual based on membership', (tester) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.casual,
              isCheckedIn: false,
            ),
          ),
        ),
      );
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Member'), findsNothing);
    });

    testWidgets('shows In/Out based on check-in status', (tester) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: true,
            ),
          ),
        ),
      );
      expect(find.text('In'), findsOneWidget);
    });

    testWidgets('fires onToggleProfile when name tapped', (tester) async {
      var toggled = false;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
              onToggleProfile: () => toggled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alice Test'));
      expect(toggled, isTrue);
    });

    testWidgets('fires onCycleMembership when membership pill tapped', (
      tester,
    ) async {
      var cycled = false;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
              onCycleMembership: () => cycled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Member'));
      expect(cycled, isTrue);
    });

    testWidgets('fires onToggleCheckin with correct value', (tester) async {
      bool? newValue;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
              onToggleCheckin: (v) => newValue = v,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Out'));
      expect(newValue, isTrue);
    });
  });

  group('PlayerProfileCard', () {
    testWidgets('displays stat trio — level, matches, diversity', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 42,
        uniquePartnerCount: 15,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: 'Attended 5 of 10 sessions',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      expect(find.text('B1'), findsOneWidget); // Current Level value
      expect(find.text('Current Level'), findsOneWidget);
      expect(find.text('42'), findsOneWidget); // Matches
      expect(find.text('15'), findsOneWidget); // Diversity
    });

    testWidgets('displays attendance summary', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        uniquePartnerCount: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: 'Attended 5 of 10 sessions',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      expect(find.text('Attended 5 of 10 sessions'), findsOneWidget);
    });

    testWidgets('displays top partners when provided', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        uniquePartnerCount: 5,
        levelHistory: [],
        topPartners: [
          PartnerEntry('Bob Test', 8),
          PartnerEntry('Carol Test', 5),
        ],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      // 5 appears both as diversity value and as Carol's count
      expect(find.text('Bob Test'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Carol Test'), findsOneWidget);
    });

    testWidgets('shows level progression section when history available', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        uniquePartnerCount: 5,
        levelHistory: [Elo.c2, Elo.c1, Elo.b2, Elo.b1],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      expect(find.text('LEVEL PROGRESSION'), findsOneWidget);
    });

    testWidgets('hides level progression when no history', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        uniquePartnerCount: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      expect(find.text('LEVEL PROGRESSION'), findsNothing);
    });

    testWidgets('fires onClose when close button tapped', (tester) async {
      var closed = false;
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        uniquePartnerCount: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(
                player: player,
                stats: stats,
                onClose: () => closed = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });
  });

  group('PendingRegistrationCard', () {
    testWidgets('shows count in title', (tester) async {
      final registrations = [
        PendingRegistration.create(
          name: 'New Player',
          contact: 'new@example.com',
          tier: SkillTier.intermediate,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(pendingRegistrations: registrations),
          ),
        ),
      );
      expect(find.text('Pending self-registrations (1)'), findsOneWidget);
    });

    testWidgets('shows registration details', (tester) async {
      final registrations = [
        PendingRegistration.create(
          name: 'Jane Doe',
          contact: 'jane@example.com',
          tier: SkillTier.advanced,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(pendingRegistrations: registrations),
          ),
        ),
      );
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.textContaining('Advanced'), findsOneWidget);
      expect(find.textContaining('jane@example.com'), findsOneWidget);
    });

    testWidgets('shows approve and reject buttons', (tester) async {
      final registrations = [
        PendingRegistration.create(
          name: 'Jane Doe',
          contact: 'jane@example.com',
          tier: SkillTier.intermediate,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(pendingRegistrations: registrations),
          ),
        ),
      );
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('fires onApprove with correct index', (tester) async {
      int? approvedIndex;
      final registrations = [
        PendingRegistration.create(
          name: 'Player A',
          contact: 'a@test.com',
          tier: SkillTier.amateur,
        ),
        PendingRegistration.create(
          name: 'Player B',
          contact: 'b@test.com',
          tier: SkillTier.advanced,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(
              pendingRegistrations: registrations,
              onApprove: (i) => approvedIndex = i,
            ),
          ),
        ),
      );
      // Tap the first Approve button
      await tester.tap(find.text('Approve').first);
      expect(approvedIndex, 0);
    });

    testWidgets('fires onReject with correct index', (tester) async {
      int? rejectedIndex;
      final registrations = [
        PendingRegistration.create(
          name: 'Player A',
          contact: 'a@test.com',
          tier: SkillTier.amateur,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(
              pendingRegistrations: registrations,
              onReject: (i) => rejectedIndex = i,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Reject'));
      expect(rejectedIndex, 0);
    });

    testWidgets('shows nothing when list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PendingRegistrationCard(pendingRegistrations: []),
          ),
        ),
      );
      expect(find.text('Pending self-registrations (0)'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });
  });

  group('PlayersPage', () {
    late GameData gameData;
    late RepositorySandbox sandbox;

    setUp(() async {
      sandbox = await RepositorySandbox.setUp('players_page_test');
    });

    tearDown(() => sandbox.tearDown());

    /// setMembership persists via GameData.onUpdatePlayer, a fire-and-forget
    /// `async` method — advance the (fake) test clock so its pending file
    /// write completes before the test ends. A raw `Future.delayed` would
    /// hang forever here since widget tests run in a paused FakeAsync zone.
    Future<void> flushPendingWrites(WidgetTester tester) =>
        tester.pump(const Duration(milliseconds: 50));

    /// Helper to create a test fixture with real GameData + PlayerRepository.
    Future<void> pumpPlayersPage(
      WidgetTester tester, {
      required List<Player> initialPlayers,
      int sessionCapacity = 20,
      int numberOfCourts = 4,
    }) async {
      // Seeds via the real repository — real disk I/O, so run it for real
      // instead of inside the paused fake-async testWidgets zone.
      await tester.runAsync(
        () => PlayerRepository.instance.addAll(initialPlayers),
      );

      // Create GameData with matching session params
      gameData = GameData()
        ..setSessionCapacity(sessionCapacity)
        ..setNumberOfCourt(numberOfCourts);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: gameData,
              child: const PlayersPage(),
            ),
          ),
        ),
      );
    }

    testWidgets('CHK-01: capacity bar shows checked-in count and remaining', (
      tester,
    ) async {
      final players = [
        _testPlayer('Alice', Elo.b1),
        _testPlayer('Bob', Elo.a2),
        _testPlayer('Carol', Elo.b1),
      ];
      await pumpPlayersPage(tester, initialPlayers: players);

      // Initially no one checked in
      expect(find.text('0 / 20 · 20 left'), findsOneWidget);

      // Check in Alice
      gameData.checkInPlayer(players[0]);
      await tester.pumpAndSettle();

      // Capacity bar updates
      expect(find.text('1 / 20 · 19 left'), findsOneWidget);
    });

    testWidgets('CHK-02: tapping check-in control checks the player in', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [player]);

      // Initially not checked in
      expect(gameData.isPlayerCheckedIn(player), isFalse);

      // Find and tap the "check-in" control in PlayerRow
      // PlayerRow renders either "In" or "Out" pill depending on check-in state
      expect(find.text('Out'), findsOneWidget);
      await tester.tap(find.text('Out'));
      await tester.pumpAndSettle();

      // Player is now checked in
      expect(gameData.isPlayerCheckedIn(player), isTrue);
      expect(find.text('In'), findsOneWidget);
    });

    testWidgets(
      'CHK-03: at capacity, check-in control is refused (no state change)',
      (tester) async {
        // Capacity 4 — the smallest a session can be — plus a 5th player.
        final atCapacity = [
          _testPlayer('Alice', Elo.b1),
          _testPlayer('Bob', Elo.a2),
          _testPlayer('Dave', Elo.c1),
          _testPlayer('Erin', Elo.s1),
        ];
        final carol = _testPlayer('Carol', Elo.b1);

        await pumpPlayersPage(
          tester,
          initialPlayers: [...atCapacity, carol],
          sessionCapacity: GameData.minSessionCapacity,
        );

        for (final player in atCapacity) {
          gameData.checkInPlayer(player);
        }
        await tester.pumpAndSettle();

        expect(gameData.checkedInCount, 4);
        expect(gameData.isAtCapacity, isTrue);

        // Directly try to check in Carol via GameData (should fail)
        final success = gameData.checkInPlayer(carol);
        expect(success, isFalse);

        // Carol is still not checked in
        expect(gameData.isPlayerCheckedIn(carol), isFalse);
        expect(gameData.checkedInCount, 4); // No state change
      },
    );

    testWidgets('CHK-04: at-capacity banner appears when at capacity', (
      tester,
    ) async {
      final players = [
        _testPlayer('Alice', Elo.b1),
        _testPlayer('Bob', Elo.a2),
        _testPlayer('Dave', Elo.c1),
        _testPlayer('Erin', Elo.s1),
      ];
      await pumpPlayersPage(
        tester,
        initialPlayers: players,
        sessionCapacity: GameData.minSessionCapacity,
      );

      // Initially no banner
      expect(
        find.text('Session at capacity — new check-ins will join the waitlist'),
        findsNothing,
      );

      // Check in every player
      for (final player in players) {
        gameData.checkInPlayer(player);
      }
      await tester.pumpAndSettle();

      // Capacity bar should show "4 / 4"
      expect(find.text('4 / 4 · 0 left'), findsOneWidget);

      // Banner now appears
      expect(
        find.text('Session at capacity — new check-ins will join the waitlist'),
        findsOneWidget,
      );
    });

    testWidgets('CHK-05: tapping again on checked-in player checks them out', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [player]);

      // Check in
      gameData.checkInPlayer(player);
      await tester.pumpAndSettle();
      expect(gameData.isPlayerCheckedIn(player), isTrue);
      expect(find.text('In'), findsOneWidget);

      // Tap again to check out
      await tester.tap(find.text('In'));
      await tester.pumpAndSettle();

      // Player is now checked out
      expect(gameData.isPlayerCheckedIn(player), isFalse);
      expect(find.text('Out'), findsOneWidget);
    });

    testWidgets(
      'CHK-06: disabled players do not have an enabled check-in control',
      (tester) async {
        final player = _testPlayer('Alice', Elo.b1);
        await pumpPlayersPage(tester, initialPlayers: [player]);

        // Initially Member — check-in control is enabled
        expect(find.text('Out'), findsOneWidget);

        // Disable the player's membership
        gameData.setMembership(player, MembershipStatus.disabled);
        await flushPendingWrites(tester);
        await tester.pumpAndSettle();

        // Control is now disabled — tapping does not check them in
        expect(find.text('Out'), findsOneWidget);
        await tester.tap(find.text('Out'));
        await tester.pumpAndSettle();
        expect(gameData.isPlayerCheckedIn(player), isFalse);
        expect(gameData.checkedInCount, 0);
      },
    );
  });
}
