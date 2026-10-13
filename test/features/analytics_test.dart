import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
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

  group('ANA-01: every card recomputes on range change', () {
    Future<void> seedGames(WidgetTester tester) async {
      await tester.runAsync(() async {
        await PlayerRepository.instance.addAll([
          Player.create(
            firstName: 'Cy',
            lastName: 'C',
            elo: Elo.b2,
          ).copyWith(id: 'p3'),
          Player.create(
            firstName: 'Di',
            lastName: 'D',
            elo: Elo.b2,
          ).copyWith(id: 'p4'),
        ]);
        await GameRepository.instance.addAll([
          // Recent game: Ann and Ben only.
          Game(
            playerIds: ['p1', 'p2', 'p1', 'p2'],
            id: 'recent',
            createdDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          // 8 weeks ago: inside 12 wks, outside 4 wks.
          Game(
            playerIds: ['p3', 'p4', 'p3', 'p4'],
            id: 'older',
            createdDate: DateTime.now().subtract(const Duration(days: 56)),
          ),
        ]);
      });
    }

    testWidgets('should_drop_a_player_from_the_mixing_card_on_4_wks', (
      tester,
    ) async {
      await seedGames(tester);
      await tester.pumpWidget(wrap(const AnalyticsPage()));
      await tester.pumpAndSettle();
      final inMixingCard = find.descendant(
        of: find.byType(PlayerMixingCard),
        matching: find.text('Cy C'),
      );
      expect(inMixingCard, findsOneWidget);

      await tester.tap(find.text('4 wks'));
      await tester.pumpAndSettle();

      expect(inMixingCard, findsNothing);
    });

    testWidgets('should_change_the_active_players_value_on_4_wks', (
      tester,
    ) async {
      await seedGames(tester);
      await tester.pumpWidget(wrap(const AnalyticsPage()));
      await tester.pumpAndSettle();
      final active = find.widgetWithText(AppKpiCard, '4');
      expect(active, findsOneWidget);

      await tester.tap(find.text('4 wks'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppKpiCard, '2'), findsOneWidget);
    });
  });

  group('ANA-14: responsive reflow', () {
    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        wrap(const AnalyticsPage(), size: Size(width, 2400)),
      );
      await tester.pumpAndSettle();
    }

    int kpiColumns(WidgetTester tester) => tester
        .widgetList(find.byType(AppKpiCard))
        .map((w) => tester.getTopLeft(find.byWidget(w)).dx)
        .toSet()
        .length;

    double leftOf(WidgetTester tester, Type type) =>
        tester.getTopLeft(find.byType(type)).dx;

    testWidgets('should_show_6_kpi_columns_on_desktop', (tester) async {
      await pumpAt(tester, 1280);
      expect(kpiColumns(tester), 6);
    });

    testWidgets('should_show_3_kpi_columns_on_tablet', (tester) async {
      await pumpAt(tester, 800);
      expect(kpiColumns(tester), 3);
    });

    testWidgets('should_show_1_kpi_column_on_phone', (tester) async {
      await pumpAt(tester, 390);
      expect(kpiColumns(tester), 1);
    });

    testWidgets('should_place_chart_cards_side_by_side_on_desktop', (
      tester,
    ) async {
      await pumpAt(tester, 1280);
      expect(
        leftOf(tester, WaitlistPressureChart),
        greaterThan(leftOf(tester, AttendanceChart)),
      );
    });

    testWidgets('should_stack_chart_cards_on_tablet', (tester) async {
      await pumpAt(tester, 800);
      expect(
        leftOf(tester, WaitlistPressureChart),
        leftOf(tester, AttendanceChart),
      );
    });

    testWidgets('should_stack_chart_cards_on_phone', (tester) async {
      await pumpAt(tester, 390);
      expect(
        leftOf(tester, WaitlistPressureChart),
        leftOf(tester, AttendanceChart),
      );
    });
  });

  group('ANA-14: breakpoints use the window width, not the padded width', () {
    // The shell pads the page (24 px desktop, 20 px tablet). The layout must
    // still switch on the window width.
    Future<void> pumpPadded(
      WidgetTester tester,
      double width,
      double pad,
    ) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        wrap(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: const AnalyticsPage(),
          ),
          size: Size(width, 2400),
        ),
      );
      await tester.pumpAndSettle();
    }

    int kpiColumns(WidgetTester tester) => tester
        .widgetList(find.byType(AppKpiCard))
        .map((w) => tester.getTopLeft(find.byWidget(w)).dx)
        .toSet()
        .length;

    double leftOf(WidgetTester tester, Type type) =>
        tester.getTopLeft(find.byType(type)).dx;

    testWidgets('should_show_6_kpi_columns_at_window_width_1100', (
      tester,
    ) async {
      await pumpPadded(tester, 1100, 24);
      expect(kpiColumns(tester), 6);
    });

    testWidgets('should_place_charts_side_by_side_at_window_width_1100', (
      tester,
    ) async {
      await pumpPadded(tester, 1100, 24);
      expect(
        leftOf(tester, WaitlistPressureChart),
        greaterThan(leftOf(tester, AttendanceChart)),
      );
    });

    testWidgets('should_show_3_kpi_columns_at_window_width_740', (
      tester,
    ) async {
      await pumpPadded(tester, 740, 20);
      expect(kpiColumns(tester), 3);
    });

    testWidgets('should_stack_charts_at_window_width_740', (tester) async {
      await pumpPadded(tester, 740, 20);
      expect(
        leftOf(tester, WaitlistPressureChart),
        leftOf(tester, AttendanceChart),
      );
    });
  });

  group('ANA-12/13: card details', () {
    testWidgets('should_show_the_mixing_tag_under_each_tagged_player', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PlayerMixingCard(
            entries: [
              MixingEntry(name: 'Hub', score: 0.9, tag: MixingTag.connector),
              MixingEntry(name: 'Duo', score: 0.1, tag: MixingTag.isolated),
            ],
          ),
        ),
      );

      expect(find.text('connector'), findsOneWidget);
      expect(find.text('isolated'), findsOneWidget);
    });

    testWidgets('should_count_cliques_in_the_mixing_summary', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PlayerMixingCard(
            entries: [
              MixingEntry(name: 'Cliq', score: 0.3, tag: MixingTag.clique),
            ],
          ),
        ),
      );

      expect(find.textContaining('1 player in a clique'), findsOneWidget);
    });

    NewPlayerEntry newcomer(double pct) => NewPlayerEntry(
      name: 'Newbie',
      joinDate: DateTime(2026, 8, 1),
      sessionsAttended: 2,
      pctWithRegulars: pct,
    );

    Color? badgeColor(WidgetTester tester) {
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.textContaining('% with regulars'),
              matching: find.byType(Container),
            )
            .first,
      );
      return (badge.decoration as BoxDecoration).color;
    }

    testWidgets('should_style_50_percent_or_more_as_favorable', (tester) async {
      await tester.pumpWidget(
        wrap(NewPlayerIntegrationCard(entries: [newcomer(50)])),
      );

      expect(badgeColor(tester), AppColors.successBg);
    });

    testWidgets('should_style_under_50_percent_as_needing_attention', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(NewPlayerIntegrationCard(entries: [newcomer(49)])),
      );

      expect(badgeColor(tester), AppColors.warningBg);
    });

    testWidgets('should_show_a_note_when_a_new_player_needs_attention', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(NewPlayerIntegrationCard(entries: [newcomer(10)])),
      );

      expect(
        find.textContaining('1 new player mostly plays away from regulars'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_a_reassuring_note_when_all_mix_with_regulars', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(NewPlayerIntegrationCard(entries: [newcomer(80)])),
      );

      expect(
        find.text('New players are playing alongside regulars.'),
        findsOneWidget,
      );
    });
  });
}
