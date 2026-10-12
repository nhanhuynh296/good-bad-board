import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/analytics/analytics.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:provider/provider.dart';

import '../support/repository_sandbox.dart';
import '../support/prefs_sandbox.dart';

Widget wrap(
  Widget child, {
  Size size = const Size(1280, 900),
  GameData? gameData,
}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: MaterialApp(
    // AnalyticsPage resolves a deleted player's display name via
    // AppLocalizations.of(context) — needs the real delegates registered.
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ChangeNotifierProvider<GameData>.value(
        value: gameData ?? GameData(),
        child: child,
      ),
    ),
  ),
);

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();

    sandbox = await RepositorySandbox.setUp('analytics_test');
    await PlayerRepository.instance.addAll([
      Player.create(
        firstName: 'Ann',
        lastName: 'A',
        elo: Elo.c2,
      ).copyWith(id: 'p1'),
      Player.create(
        firstName: 'Ben',
        lastName: 'B',
        elo: Elo.b2,
      ).copyWith(id: 'p2'),
    ]);
  });

  tearDown(() => sandbox.tearDown());

  group('ANA-01/02/14: AnalyticsPage', () {
    testWidgets('renders the range switcher and KPI strip on desktop', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AnalyticsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('4 wks'), findsOneWidget);
      expect(find.text('12 wks'), findsOneWidget);
      expect(find.text('26 wks'), findsOneWidget);
      expect(find.text('ACTIVE PLAYERS'), findsOneWidget);
    });

    testWidgets('reflows to a single column on phone width', (tester) async {
      await tester.pumpWidget(
        wrap(const AnalyticsPage(), size: const Size(390, 900)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Attendance trend'), findsOneWidget);
    });

    testWidgets('switching the time range does not throw', (tester) async {
      await tester.pumpWidget(wrap(const AnalyticsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('4 wks'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets(
      'reloads when a game is saved without remounting — the Analytics '
      'route stays alive across tab switches (StatefulShellRoute)',
      (tester) async {
        final gameData = GameData();
        await tester.pumpWidget(
          wrap(const AnalyticsPage(), gameData: gameData),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('No sessions logged yet'), findsOneWidget);

        // Seed a game directly into the repository (bypassing GameData's
        // save flow, which does real disk I/O that doesn't play well
        // inside a fake-async testWidgets zone) to prove the reload wiring
        // — AnalyticsPage listens to GameRepository directly — not the save
        // flow itself, which is covered in test/game_data_session_log_test.dart.
        final player = Player.create(
          firstName: 'New',
          lastName: 'P',
          elo: Elo.c2,
        );
        await tester.runAsync(() async {
          // GameRepository resolves a roster from PlayerRepository on read
          // — the player has to actually be registered to show up.
          await PlayerRepository.instance.add(player);
          await GameRepository.instance.add(
            Game.create([player, player, player, player]),
          );
        });

        await tester.pump();
        await tester.pump();

        expect(find.text('No sessions logged yet'), findsNothing);
      },
    );
  });
}
