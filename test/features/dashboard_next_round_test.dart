import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/repository_sandbox.dart';
import '../support/prefs_sandbox.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// RND-10 on the Dashboard: the pre-made next round is shown on the courts,
/// and the two rotation-bar panels choose which round the grid renders.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({'gameType': 'timeBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_next_round_test');
  });

  tearDown(() => sandbox.tearDown());

  Widget wrap(GameData gameData, TimerData timerData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<TimerData>.value(value: timerData),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DashboardPage()),
    ),
  );

  /// A [GameData] with [total] checked-in players across one court, so there
  /// are always spare players on the waitlist.
  GameData seed(int total) {
    final gameData = GameData()..setNumberOfCourt(1);
    for (var i = 0; i < total; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    return gameData;
  }

  /// Widens the test surface so the dashboard renders its desktop layout.
  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// The names rendered in the court grid.
  Set<String> courtNames(WidgetTester tester) => tester
      .widgetList<CourtCard>(find.byType(CourtCard))
      .expand((card) => card.players)
      .map((p) => p.name())
      .toSet();

  /// The names rendered in the waitlist sidebar.
  Set<String> sidebarNames(WidgetTester tester) => tester
      .widget<WaitlistSidebar>(find.byType(WaitlistSidebar))
      .players
      .map((p) => p.name())
      .toSet();

  testWidgets('should_show_the_live_round_before_anything_is_staged', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    final live = gameData.stagingMatches
        .expand((g) => g.players)
        .map((p) => p.name())
        .toSet();

    await tester.pumpWidget(wrap(gameData, TimerData()));

    expect(courtNames(tester), equals(live));
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_show_the_staged_lineup_on_the_courts_when_staged', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    final staged = gameData.stagedLineup!
        .expand((g) => g.players)
        .map((p) => p.name())
        .toSet();
    expect(courtNames(tester), equals(staged));
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_say_placed_in_the_staged_round_summary', (tester) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    expect(find.text('4 players placed across 1 court'), findsOneWidget);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_show_the_waitlist_for_the_round_on_screen', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    // No player may be both on a staged court and on the sidebar — that is
    // how a player gets booked twice, or dropped.
    expect(courtNames(tester).intersection(sidebarNames(tester)), isEmpty);
    expect(
      courtNames(tester).union(sidebarNames(tester)),
      equals(gameData.checkedInPlayers.values.map((p) => p.name()).toSet()),
    );
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_return_to_the_live_round_when_current_panel_tapped', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    final live = gameData.stagingMatches
        .expand((g) => g.players)
        .map((p) => p.name())
        .toSet();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    await tester.tap(find.byKey(RoundRotationBar.currentPanelKey));
    await tester.pump();

    expect(gameData.roundView, equals(RoundView.current));
    expect(courtNames(tester), equals(live));
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_show_the_staged_round_again_when_next_panel_tapped', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();
    await tester.tap(find.byKey(RoundRotationBar.currentPanelKey));
    await tester.pump();

    await tester.tap(find.byKey(RoundRotationBar.nextPanelKey));
    await tester.pump();

    expect(gameData.roundView, equals(RoundView.next));
    final staged = gameData.stagedLineup!
        .expand((g) => g.players)
        .map((p) => p.name())
        .toSet();
    expect(courtNames(tester), equals(staged));
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_mark_the_courts_as_next_round_while_planning', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    expect(
      tester
          .widgetList<CourtCard>(find.byType(CourtCard))
          .every((card) => card.isNextRound),
      isTrue,
    );
    expect(find.text('NEXT'), findsWidgets);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_hide_the_global_save_while_planning_the_next_round', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    expect(find.byKey(const Key('dashboard-save-all')), findsOneWidget);

    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    expect(find.byKey(const Key('dashboard-save-all')), findsNothing);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_place_a_waitlisted_player_onto_the_staged_court', (
    tester,
  ) async {
    useDesktopSurface(tester);
    final gameData = seed(8);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    await tester.tap(find.text('Pre-make next round'));
    await tester.pump();

    final liveBefore = gameData.stagingMatches
        .expand((g) => g.players)
        .map((p) => p.id)
        .toSet();
    final spare = gameData.visibleWaitlistedPlayers.first;

    // Pick the player off the sidebar, then drop them into the first slot.
    await tester.tap(find.text(spare.name()));
    await tester.pump();
    await tester.tap(find.byType(PlayerSlot).first);
    await tester.pump();

    expect(gameData.stagedLineup![0].players.first.id, equals(spare.id));
    // The live round is untouched — this is a plan, not a substitution.
    expect(
      gameData.stagingMatches.expand((g) => g.players).map((p) => p.id).toSet(),
      equals(liveBefore),
    );
    tester.binding.delayed(const Duration(seconds: 1));
  });
}
