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

/// The court grid must stay reachable once it is taller than the viewport.
///
/// The grid renders with `shrinkWrap: true` and `NeverScrollableScrollPhysics`,
/// so the layout around it has to provide the scrolling — otherwise the courts
/// below the first row cannot be reached at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({'gameType': 'timeBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_scroll_test');
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

  /// A [GameData] with [total] checked-in players across [courts] courts.
  GameData seed(int total, int courts) {
    final gameData = GameData()..setNumberOfCourt(courts);
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

  /// A surface tall enough for the desktop layout but short enough that four
  /// courts cannot all fit — the situation the operator hit.
  void useShortDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// The scroll view the court grid sits inside, if there is one.
  Finder courtGridScrollable() => find
      .ancestor(
        of: find.byType(CourtCard).first,
        matching: find.byType(Scrollable),
      )
      .first;

  testWidgets('should_put_the_desktop_court_grid_inside_a_scroll_view', (
    tester,
  ) async {
    useShortDesktopSurface(tester);
    final gameData = seed(16, 4);
    await gameData.makeGame();

    await tester.pumpWidget(wrap(gameData, TimerData()));

    // The grid's own physics are NeverScrollable, so without an enclosing
    // scroll view the courts below the first row are unreachable.
    expect(courtGridScrollable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_scroll_the_court_grid_to_reach_the_last_court', (
    tester,
  ) async {
    useShortDesktopSurface(tester);
    final gameData = seed(16, 4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // COURT 4 sits on the second grid row, below the fold.
    final lastCourt = find.text('COURT 4');
    final before = tester.getTopLeft(lastCourt).dy;

    await tester.drag(courtGridScrollable(), const Offset(0, -300));
    await tester.pump();

    // It moved up the screen, so the organizer can reach it.
    expect(tester.getTopLeft(lastCourt).dy, lessThan(before));
    expect(tester.takeException(), isNull);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_still_scroll_on_a_stacked_layout', (tester) async {
    // Tablet width — the stacked layout, which already had its own scroll view.
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final gameData = seed(16, 4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    final lastCourt = find.text('COURT 4');
    final before = tester.getTopLeft(lastCourt).dy;

    await tester.drag(courtGridScrollable(), const Offset(0, -300));
    await tester.pump();

    expect(tester.getTopLeft(lastCourt).dy, lessThan(before));
    expect(tester.takeException(), isNull);
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_scroll_whole_page_to_last_court_on_phone', (
    tester,
  ) async {
    // Arrange — phone: stat strip, bars, chips and courts share one scroll.
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final gameData = seed(20, 4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));
    final statStripTop = tester.getTopLeft(find.byType(StatStrip)).dy;

    // Act
    await tester.dragUntilVisible(
      find.text('COURT 4'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -150),
    );
    await tester.pump();

    // Assert — the last court is on screen and the stat strip scrolled away.
    expect(
      tester.getBottomLeft(find.text('COURT 4')).dy,
      lessThanOrEqualTo(700),
    );
    expect(
      tester.getTopLeft(find.byType(StatStrip)).dy,
      lessThan(statStripTop),
    );
    expect(tester.takeException(), isNull);
    tester.binding.delayed(const Duration(seconds: 1));
  });
}
