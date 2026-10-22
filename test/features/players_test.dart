import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('shows the accent bar when the player is checked in', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.byKey(const Key('player-row-bar')), findsOneWidget);
    });

    testWidgets('fires onToggleProfile when More tapped', (tester) async {
      var toggled = false;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      await tester.tap(find.text('More'));
      expect(toggled, isTrue);
    });

    testWidgets('fires onCycleMembership when membership pill tapped', (
      tester,
    ) async {
      var cycled = false;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('fires onToggleCheckin when the row is tapped', (tester) async {
      var toggled = false;
      final player = _testPlayer('Alice', Elo.b2);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlayerRow(
              player: player,
              isExpanded: false,
              membership: MembershipStatus.member,
              isCheckedIn: false,
              onToggleCheckin: () => toggled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alice Test'));
      expect(toggled, isTrue);
    });

    Future<void> pumpRow(
      WidgetTester tester, {
      bool isExpanded = false,
      VoidCallback? onToggleProfile,
      VoidCallback? onToggleCheckin,
      VoidCallback? onLevelUp,
    }) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayerRow(
            player: _testPlayer('Alice', Elo.b2),
            isExpanded: isExpanded,
            membership: MembershipStatus.member,
            isCheckedIn: false,
            onToggleProfile: onToggleProfile,
            onToggleCheckin: onToggleCheckin,
            onLevelUp: onLevelUp,
          ),
        ),
      ),
    );

    testWidgets('should_toggle_check_in_when_the_row_is_tapped', (
      tester,
    ) async {
      var toggled = false;
      await pumpRow(tester, onToggleCheckin: () => toggled = true);

      // The sign-in ID is part of the row but not the name.
      await tester.tap(find.text('—'));

      expect(toggled, isTrue);
    });

    testWidgets('should_not_toggle_the_profile_when_the_row_is_tapped', (
      tester,
    ) async {
      var opened = false;
      await pumpRow(tester, onToggleProfile: () => opened = true);

      await tester.tap(find.text('Alice Test'));

      expect(opened, isFalse);
    });

    testWidgets('should_not_toggle_check_in_when_a_control_is_tapped', (
      tester,
    ) async {
      var toggled = false;
      await pumpRow(
        tester,
        onToggleCheckin: () => toggled = true,
        onToggleProfile: () {},
        onLevelUp: () {},
      );

      await tester.tap(find.text('+'));
      await tester.tap(find.text('More'));

      expect(toggled, isFalse);
    });

    testWidgets('should_show_the_expand_arrow_when_the_profile_is_hidden', (
      tester,
    ) async {
      await pumpRow(tester);

      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('should_show_the_collapse_arrow_when_the_profile_is_shown', (
      tester,
    ) async {
      await pumpRow(tester, isExpanded: true);

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    });
  });

  group('PlayerProfileCard', () {
    testWidgets('displays stat trio — level, matches, diversity', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 42,
        diversityPercent: 15,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: 'Attended 5 of 10 sessions',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      expect(find.text('15%'), findsOneWidget); // Diversity
    });

    testWidgets('displays attendance summary', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        diversityPercent: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: 'Attended 5 of 10 sessions',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
        diversityPercent: 5,
        levelHistory: [],
        topPartners: [
          PartnerEntry('Bob Test', 8),
          PartnerEntry('Carol Test', 5),
        ],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('hides the level progression block even when history exists', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        diversityPercent: 5,
        levelHistory: [Elo.c2, Elo.c1, Elo.b2, Elo.b1],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerProfileCard(player: player, stats: stats),
            ),
          ),
        ),
      );
      expect(find.text('LEVEL PROGRESSION'), findsNothing);
    });

    testWidgets('hides level progression when no history', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      const stats = PlayerProfileStats(
        matchCount: 10,
        diversityPercent: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
        diversityPercent: 5,
        levelHistory: [],
        topPartners: [],
        attendanceSummary: '',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

    /// Taps the "More" button of the row that shows [name].
    Future<void> tapMore(WidgetTester tester, String name) => tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text(name),
          matching: find.byType(PlayerRow),
        ),
        matching: find.text('More'),
      ),
    );

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: gameData,
              child: const PlayersPage(),
            ),
          ),
        ),
      );
    }

    testWidgets('should_use_wide_row_layout_when_viewport_is_740_wide', (
      tester,
    ) async {
      // Arrange — header shows at 740 px; the row must match it (NAV-08).
      tester.view.physicalSize = const Size(740, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpPlayersPage(
        tester,
        initialPlayers: [_testPlayer('Alice', Elo.b1)],
      );

      // Act
      final levelColumn = find
          .ancestor(
            of: find.byType(LevelAdjuster),
            matching: find.byType(SizedBox),
          )
          .first;

      // Assert
      expect(tester.getSize(levelColumn).width, 155);
    });

    testWidgets('should_show_the_open_row_and_its_profile_in_one_panel', (
      tester,
    ) async {
      await pumpPlayersPage(
        tester,
        initialPlayers: [_testPlayer('Alice', Elo.b1)],
      );

      await tapMore(tester, 'Alice Test');
      await tester.pumpAndSettle();

      final panel = find.ancestor(
        of: find.byType(PlayerRow),
        matching: find.byKey(const Key('player-accordion-panel')),
      );
      expect(
        find.descendant(of: panel, matching: find.byType(PlayerProfileCard)),
        findsOneWidget,
      );
    });

    testWidgets('should_not_draw_a_separate_card_for_the_profile', (
      tester,
    ) async {
      await pumpPlayersPage(
        tester,
        initialPlayers: [_testPlayer('Alice', Elo.b1)],
      );

      await tapMore(tester, 'Alice Test');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(PlayerProfileCard),
          matching: find.byType(AppCard),
        ),
        findsNothing,
      );
    });

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

    testWidgets('CHK-02: tapping the row checks the player in', (tester) async {
      final player = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [player]);

      // Initially not checked in
      expect(gameData.isPlayerCheckedIn(player), isFalse);

      // Find and tap the "check-in" control in PlayerRow
      // PlayerRow renders either "In" or "Out" pill depending on check-in state
      expect(find.byKey(const Key('player-row-bar')), findsNothing);
      await tester.tap(find.text('Alice Test'));
      await tester.pumpAndSettle();

      // Player is now checked in
      expect(gameData.isPlayerCheckedIn(player), isTrue);
      expect(find.byKey(const Key('player-row-bar')), findsOneWidget);
    });

    testWidgets(
      'CHK-03: tapping the row at capacity is refused (no state change)',
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

        // Tap Carol's row — refused.
        await tester.tap(find.text('Carol Test'));
        await tester.pump();
        expect(
          find.text('Session at capacity — cannot check in'),
          findsOneWidget,
        );

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
        find.text('Session at capacity — new check-ins are blocked.'),
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
        find.text('Session at capacity — new check-ins are blocked.'),
        findsOneWidget,
      );
    });

    testWidgets('CHK-05: tapping a checked-in row checks the player out', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [player]);

      // Check in
      gameData.checkInPlayer(player);
      await tester.pumpAndSettle();
      expect(gameData.isPlayerCheckedIn(player), isTrue);
      expect(find.byKey(const Key('player-row-bar')), findsOneWidget);

      // Tap again to check out
      await tester.tap(find.text('Alice Test'));
      await tester.pumpAndSettle();

      // Player is now checked out
      expect(gameData.isPlayerCheckedIn(player), isFalse);
      expect(find.byKey(const Key('player-row-bar')), findsNothing);
    });

    testWidgets('CHK-06: tapping a disabled player row does nothing', (
      tester,
    ) async {
      final player = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [player]);

      // Disable the player's membership
      gameData.setMembership(player, MembershipStatus.disabled);
      await flushPendingWrites(tester);
      await tester.pumpAndSettle();

      // Row is now disabled — tapping does not check them in
      await tester.tap(find.text('Alice Test'));
      await tester.pumpAndSettle();
      expect(gameData.isPlayerCheckedIn(player), isFalse);
      expect(gameData.checkedInCount, 0);
    });

    testWidgets('PLY-04: search matches the name or the sign-in ID', (
      tester,
    ) async {
      final alice = _testPlayer('Alice', Elo.b1).copyWith(signInId: 'ZED99');
      final bob = _testPlayer('Bob', Elo.a2);
      await pumpPlayersPage(tester, initialPlayers: [alice, bob]);

      await tester.enterText(find.byType(TextField), 'zed');
      await tester.pumpAndSettle();
      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('Bob Test'), findsNothing);

      // The level is not searched.
      await tester.enterText(find.byType(TextField), 'a2');
      await tester.pumpAndSettle();
      expect(find.text('Bob Test'), findsNothing);
    });

    testWidgets('PLY-04: search is a case-insensitive substring match', (
      tester,
    ) async {
      await pumpPlayersPage(
        tester,
        initialPlayers: [
          _testPlayer('Alice', Elo.b1),
          _testPlayer('Bob', Elo.a2),
        ],
      );

      await tester.enterText(find.byType(TextField), 'LIC');
      await tester.pumpAndSettle();

      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('Bob Test'), findsNothing);
    });

    testWidgets('PLY-04: clearing the search shows every player again', (
      tester,
    ) async {
      await pumpPlayersPage(
        tester,
        initialPlayers: [
          _testPlayer('Alice', Elo.b1),
          _testPlayer('Bob', Elo.a2),
        ],
      );
      await tester.enterText(find.byType(TextField), 'lic');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Bob Test'), findsOneWidget);
    });

    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
    }

    testWidgets('PLY-07: delete shows a confirmation dialog', (tester) async {
      await pumpPlayersPage(
        tester,
        initialPlayers: [_testPlayer('Alice', Elo.b1)],
      );

      await openDeleteDialog(tester);

      expect(find.text('Delete player?'), findsOneWidget);
    });

    testWidgets('PLY-07: cancel keeps the player unchanged', (tester) async {
      final alice = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [alice]);
      await openDeleteDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete player?'), findsNothing);
      expect(find.text('Alice Test'), findsOneWidget);
      expect(PlayerRepository.instance.byId(alice.id)!.isAnonymised, isFalse);
    });

    testWidgets('PLY-07: confirm anonymises the player and removes the row', (
      tester,
    ) async {
      final alice = _testPlayer('Alice', Elo.b1);
      await pumpPlayersPage(tester, initialPlayers: [alice]);
      await openDeleteDialog(tester);

      await tester.runAsync(() async {
        await tester.tap(find.text('Delete'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(PlayerRepository.instance.byId(alice.id)!.isAnonymised, isTrue);
      expect(find.text('Alice Test'), findsNothing);
    });

    testWidgets('PLY-12: profile stats come from persisted games and logs', (
      tester,
    ) async {
      final alice = _testPlayer('Alice', Elo.b1);
      final others = [
        _testPlayer('Bob', Elo.a2),
        _testPlayer('Cat', Elo.b1),
        _testPlayer('Dan', Elo.b1),
      ];
      await tester.runAsync(() async {
        await PlayerRepository.instance.addAll([alice, ...others]);
        await GameRepository.instance.add(Game.create([alice, ...others]));
        await SessionLogRepository.instance.add(
          SessionLog.create(
            capacity: 20,
            checkedInCount: 4,
            waitlistCount: 0,
            rerollCount: 0,
            courtLevelGaps: const [1],
            courtCount: 1,
          ),
        );
      });
      gameData = GameData();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: gameData,
              child: const PlayersPage(),
            ),
          ),
        ),
      );

      await tapMore(tester, 'Alice Test');
      await tester.pumpAndSettle();

      // 1 match; 3 of 3 possible partners = 100%.
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Attended 1 of 1 session'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlayerProfileCard),
          matching: find.text('Bob Test'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'PLY-12: profile shows empty text before any session is saved',
      (tester) async {
        await pumpPlayersPage(
          tester,
          initialPlayers: [_testPlayer('Alice', Elo.b1)],
        );

        await tapMore(tester, 'Alice Test');
        await tester.pumpAndSettle();

        expect(find.text('No sessions logged yet'), findsOneWidget);
      },
    );

    testWidgets('PLY-12: profile updates when a game is saved to the store', (
      tester,
    ) async {
      final alice = _testPlayer('Alice', Elo.b1);
      final others = [
        _testPlayer('Bob', Elo.a2),
        _testPlayer('Cat', Elo.b1),
        _testPlayer('Dan', Elo.b1),
      ];
      await pumpPlayersPage(tester, initialPlayers: [alice, ...others]);
      await tapMore(tester, 'Alice Test');
      await tester.pumpAndSettle();
      expect(find.text('No sessions logged yet'), findsOneWidget);

      await tester.runAsync(() async {
        await GameRepository.instance.add(Game.create([alice, ...others]));
        await SessionLogRepository.instance.add(
          SessionLog.create(
            capacity: 20,
            checkedInCount: 4,
            waitlistCount: 0,
            rerollCount: 0,
            courtLevelGaps: const [1],
            courtCount: 1,
          ),
        );
      });
      await tester.pumpAndSettle();

      expect(find.text('Attended 1 of 1 session'), findsOneWidget);
    });
  });
}
