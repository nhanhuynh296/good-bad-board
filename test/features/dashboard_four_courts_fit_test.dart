import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/shell/top_nav_bar.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

/// NAV-07 / S3: the client runs 4 courts on a Windows desktop window. All 4
/// courts must be on screen at once, with the stat strip, action bar, round
/// rotation bar and waitlist sidebar shown, and the grid must not scroll.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_four_courts_fit_test');
  });

  tearDown(() => sandbox.tearDown());

  /// The desktop shell around the Dashboard: nav bar, then the page inside
  /// the desktop padding (see `ResponsiveShell`).
  Widget wrap(GameData gameData, TimerData timerData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<TimerData>.value(value: timerData),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopNavBar(
              tabs: [
                for (final label in [
                  'Dashboard',
                  'Players',
                  'Sessions',
                  'Analytics',
                  'Settings',
                ])
                  TopNavTab(label: label, onTap: () {}),
              ],
            ),
            const Expanded(
              child: Padding(
                padding: AppSpacing.desktopPadding,
                child: DashboardPage(),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// [total] checked-in players over the default courts (20: 16 play, 4 wait).
  Future<GameData> fullSession(int total) async {
    final gameData = GameData();
    for (var i = 0; i < total; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '${i + 1}',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  const sizes = [
    Size(1280, 720),
    Size(1366, 768),
    Size(1440, 900),
    Size(1920, 1080),
  ];

  test('should_default_to_four_courts', () {
    expect(GameData().numberOfCourt, 4);
  });

  for (final size in sizes) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';

    Future<GameData> pumpDashboard(
      WidgetTester tester, {
      int players = 20,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final gameData = await fullSession(players);
      await tester.pumpWidget(wrap(gameData, TimerData()));
      return gameData;
    }

    testWidgets('should_show_all_four_courts_on_screen_at_$name', (
      tester,
    ) async {
      await pumpDashboard(tester);

      final viewport = Offset.zero & size;
      final cards = find.byType(CourtCard);
      expect(cards, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(
          viewport.contains(tester.getBottomRight(cards.at(i))) &&
              viewport.contains(tester.getTopLeft(cards.at(i))),
          isTrue,
          reason: 'court ${i + 1} is outside the $name window',
        );
      }
    });

    testWidgets('should_not_scroll_the_court_grid_at_$name', (tester) async {
      await pumpDashboard(tester);

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, 0);
    });

    testWidgets('should_not_overflow_any_court_at_$name', (tester) async {
      await pumpDashboard(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_not_overflow_a_court_with_remove_buttons_at_$name', (
      tester,
    ) async {
      // 14 players: the fourth court holds 2, so its slots show remove buttons.
      await pumpDashboard(tester, players: 14);

      expect(tester.takeException(), isNull);
    });

    testWidgets('should_not_cut_player_names_at_$name', (tester) async {
      await pumpDashboard(tester);

      final names = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(PlayerSlot),
          matching: find.textContaining('Player'),
        ),
      );
      expect(names.where((p) => p.didExceedMaxLines), isEmpty);
    });
  }
}
