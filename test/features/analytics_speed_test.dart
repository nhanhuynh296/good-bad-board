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

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

// Analytics speed (Nathan, 2026-10-14, "Quick fix").

final _now = DateTime(2026, 10, 14);

Game _game(String id, DateTime date, List<String> ids) =>
    Game(playerIds: ids, id: id, createdDate: date);

/// Two years of games, one a week, mixing 8 players.
List<Game> _history() => [
  for (var w = 0; w < 104; w++)
    _game('g$w', _now.subtract(Duration(days: w * 7 + 1)), [
      'p${w % 8}',
      'p${(w + 1) % 8}',
      'p${(w + 3) % 8}',
      'p${(w + 5) % 8}',
    ]),
];

final _players = [
  for (var i = 0; i < 8; i++)
    Player(firstName: 'P$i', lastName: 'T', elo: Elo.values[i], id: 'p$i'),
];

void main() {
  group('gamesForRange', () {
    final range = DateRange.lastWeeks(12, now: _now);

    test('should_drop_a_game_older_than_every_window_the_page_uses', () {
      final old = _game('old', DateTime(2020, 1, 1), ['p1']);

      expect(gamesForRange([old], range), isEmpty);
    });

    test('should_keep_a_game_at_the_start_of_the_prior_period', () {
      final g = _game('prior', range.priorPeriod.start, ['p1']);

      expect(gamesForRange([g], range), [g]);
    });

    test('should_keep_a_game_in_the_retention_window_before_the_range', () {
      // 4 weeks: the prior period starts 28 days back, retention 56.
      final short = DateRange.lastWeeks(4, now: _now);
      final g = _game(
        'retention',
        short.start.subtract(const Duration(days: 55)),
        ['p1'],
      );

      expect(gamesForRange([g], short), [g]);
    });

    test('should_give_the_same_kpis_as_the_full_history', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final games = _history();
      String text(List<KpiEntry> k) =>
          k.map((e) => '${e.label}|${e.value}|${e.contextLine}').join('\n');

      for (final weeks in [4, 12, 26]) {
        final r = DateRange.lastWeeks(weeks, now: _now);
        expect(
          text(computeKpis(gamesForRange(games, r), const [], r, l10n: l10n)),
          text(computeKpis(games, const [], r, l10n: l10n)),
        );
      }
    });

    test('should_give_the_same_level_trend_as_the_full_history', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final games = _history();
      final byId = {for (final p in _players) p.id: p};

      for (final weeks in [4, 12, 26]) {
        final r = DateRange.lastWeeks(weeks, now: _now);
        LevelDistributionResult run(List<Game> g) => computeLevelDistribution(
          _players,
          g,
          r,
          resolvePlayer: (id) => byId[id],
          l10n: l10n,
        );
        expect(run(gamesForRange(games, r)).trendNote, run(games).trendNote);
      }
    });
  });

  group('AnalyticsPage recompute', () {
    late RepositorySandbox sandbox;

    setUp(() async {
      mockPreferences({});
      await PersistentSetting.instance.initialize();
      sandbox = await RepositorySandbox.setUp('analytics_speed_test');
      await PlayerRepository.instance.addAll(_players);
    });

    tearDown(() => sandbox.tearDown());

    Widget page({required bool visible, Key? key}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<GameData>.value(
          value: GameData(),
          // The shell turns tickers off on a hidden tab.
          child: TickerMode(
            enabled: visible,
            child: AnalyticsPage(key: key),
          ),
        ),
      ),
    );

    Future<void> saveGame(WidgetTester tester, String id) async {
      await tester.runAsync(
        () => GameRepository.instance.add(
          _game(id, DateTime.now(), ['p0', 'p1', 'p2', 'p3']),
        ),
      );
      await tester.pump();
    }

    testWidgets('should_not_recompute_while_the_tab_is_hidden', (tester) async {
      const key = GlobalObjectKey('analytics');
      await tester.pumpWidget(page(visible: false, key: key));
      final before = AnalyticsPage.debugRecomputeCount;

      await saveGame(tester, 'hidden');

      expect(AnalyticsPage.debugRecomputeCount, before);
    });

    testWidgets('should_recompute_once_when_the_hidden_tab_opens', (
      tester,
    ) async {
      const key = GlobalObjectKey('analytics');
      await tester.pumpWidget(page(visible: false, key: key));
      await saveGame(tester, 'a');
      await saveGame(tester, 'b');
      final before = AnalyticsPage.debugRecomputeCount;

      await tester.pumpWidget(page(visible: true, key: key));

      expect(AnalyticsPage.debugRecomputeCount, before + 1);
    });

    testWidgets('should_recompute_when_a_game_is_saved_while_open', (
      tester,
    ) async {
      await tester.pumpWidget(page(visible: true));
      final before = AnalyticsPage.debugRecomputeCount;

      await saveGame(tester, 'open');

      expect(AnalyticsPage.debugRecomputeCount, before + 1);
    });

    testWidgets('should_not_recompute_on_a_plain_rebuild', (tester) async {
      const key = GlobalObjectKey('analytics');
      await tester.pumpWidget(page(visible: true, key: key));
      final before = AnalyticsPage.debugRecomputeCount;

      // A parent rebuild with no data or range change.
      await tester.pumpWidget(page(visible: true, key: key));

      expect(AnalyticsPage.debugRecomputeCount, before);
    });
  });
}
