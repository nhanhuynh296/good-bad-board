import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

/// Layout breakpoints follow the viewport width, not the width left after the
/// shell padding (UAT NAV-06, NAV-07). The page is wrapped in the same
/// padding the shell adds, so a content-width bug shows at the boundaries.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({'gameType': 'timeBased'});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('dashboard_breakpoints_test');
  });

  tearDown(() => sandbox.tearDown());

  double shellPadding(double width) => isDesktop(width)
      ? 24
      : isTablet(width)
      ? 20
      : 14;

  Future<void> pumpDashboard(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final gameData = GameData()..setNumberOfCourt(4);
    for (var i = 0; i < 18; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameData>.value(value: gameData),
          ChangeNotifierProvider<TimerData>.value(value: TimerData()),
          ChangeNotifierProvider<PersistentSetting>.value(
            value: PersistentSetting.instance,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(shellPadding(width)),
              child: const DashboardPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The number of stat cells on each distinct row, top to bottom.
  List<int> statRows(WidgetTester tester) {
    final tops = <double, int>{};
    for (final e in find.byType(AppStatCell).evaluate()) {
      final dy = tester.getTopLeft(find.byWidget(e.widget)).dy;
      tops[dy] = (tops[dy] ?? 0) + 1;
    }
    final keys = tops.keys.toList()..sort();
    return [for (final k in keys) tops[k]!];
  }

  int courtColumns(WidgetTester tester) => {
    for (final e in find.byType(CourtCard).evaluate())
      tester.getTopLeft(find.byWidget(e.widget)).dx,
  }.length;

  group('NAV-06 stat strip arrangement', () {
    for (final entry in {
      719.0: [2, 2],
      720.0: [3, 3],
      1079.0: [3, 3],
    }.entries) {
      testWidgets(
        'should_arrange_stats_as_${entry.value.join("x")}_at_${entry.key.toInt()}px',
        (tester) async {
          await pumpDashboard(tester, entry.key);

          expect(statRows(tester), entry.value);
        },
      );
    }

    // The desktop Courts tab has no stat strip: the round bar replaces it
    // (IMPLEMENTATION 8.5.1, 8.2.2).
    for (final width in [1080.0, 1127.0]) {
      testWidgets('should_show_no_stat_strip_at_${width.toInt()}px', (
        tester,
      ) async {
        await pumpDashboard(tester, width);

        expect(find.byType(AppStatCell), findsNothing);
      });
    }
  });

  group('NAV-07 dashboard arrangement', () {
    for (final width in [1080.0, 1127.0]) {
      testWidgets(
        'should_place_waitlist_panel_right_of_courts_at_${width.toInt()}px',
        (tester) async {
          await pumpDashboard(tester, width);

          final sidebarLeft = tester.getTopLeft(find.byType(WaitlistPanel)).dx;
          final courtsRight = tester
              .getTopRight(find.byType(DesktopCourtCard).first)
              .dx;
          expect(sidebarLeft, greaterThan(courtsRight));
          expect(find.byType(WaitlistChips), findsNothing);
        },
      );
    }

    for (final entry in {1079.0: 2, 720.0: 2, 719.0: 1}.entries) {
      testWidgets(
        'should_stack_courts_in_${entry.value}_columns_at_${entry.key.toInt()}px',
        (tester) async {
          await pumpDashboard(tester, entry.key);

          expect(courtColumns(tester), entry.value);
        },
      );
    }

    testWidgets('should_put_waitlist_chips_above_courts_at_1079px', (
      tester,
    ) async {
      await pumpDashboard(tester, 1079);

      final chipsBottom = tester.getBottomLeft(find.byType(WaitlistChips)).dy;
      final courtsTop = tester.getTopLeft(find.byType(CourtCard).first).dy;
      expect(chipsBottom, lessThanOrEqualTo(courtsTop));
      expect(find.byType(WaitlistSidebar), findsNothing);
    });
  });
}
