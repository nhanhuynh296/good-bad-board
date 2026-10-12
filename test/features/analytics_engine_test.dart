import 'package:flutter/widgets.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';
import 'package:test/test.dart';

Player _p(String name, Elo elo, {DateTime? createdDate}) => Player.create(
  firstName: name,
  lastName: 'T',
  elo: elo,
).copyWith(createdDate: createdDate ?? DateTime(2026, 1, 1));

Game _game(List<Player> players, DateTime date) => Game(
  playerIds: players.map((p) => p.id).toList(),
  id: '${date.toIso8601String()}-${players.hashCode}',
  createdDate: date,
);

/// A `resolvePlayer` callback backed by an in-memory map — the pure-Dart
/// stand-in for `PlayerRepository.byId` these tests use instead of touching
/// the real repository.
Player? Function(String id) _resolverFor(List<Player> players) {
  final byId = {for (final p in players) p.id: p};
  return (id) => byId[id];
}

SessionLog _log({
  required DateTime loggedAt,
  int capacity = 20,
  int checkedInCount = 8,
  int waitlistCount = 0,
  int rerollCount = 0,
  List<int> courtLevelGaps = const [0, 1],
  int courtCount = 2,
}) => SessionLog(
  id: loggedAt.toIso8601String(),
  loggedAt: loggedAt,
  capacity: capacity,
  checkedInCount: checkedInCount,
  waitlistCount: waitlistCount,
  rerollCount: rerollCount,
  courtLevelGaps: courtLevelGaps,
  courtCount: courtCount,
);

void main() {
  // The engine builds user-visible text through AppLocalizations; English
  // keeps these label and note expectations unchanged.
  final l10n = lookupAppLocalizations(const Locale('en'));
  final now = DateTime(2026, 8, 14);
  final range = DateRange(now.subtract(const Duration(days: 84)), now);

  group('ANA-01: DateRange', () {
    test('lastWeeks builds the correct window', () {
      final r = DateRange.lastWeeks(12, now: now);
      expect(r.end, now);
      expect(r.start, now.subtract(const Duration(days: 84)));
    });

    test('priorPeriod is the equal-length preceding window', () {
      final r = DateRange(DateTime(2026, 6, 1), DateTime(2026, 7, 1));
      final prior = r.priorPeriod;
      expect(prior.end, r.start);
      expect(prior.start, DateTime(2026, 5, 2));
    });
  });

  group('ANA-02: KPI strip', () {
    test('should_compute_6_kpi_entries', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 7)),
          checkedInCount: 16,
          waitlistCount: 2,
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          checkedInCount: 20,
          waitlistCount: 4,
        ),
      ];
      final kpis = computeKpis([], logs, range, l10n: l10n);
      expect(kpis, hasLength(6));
    });

    test('should_label_first_tile_active_players', () {
      final a = _p('A', Elo.c2);
      final b = _p('B', Elo.c2);
      final games = [
        _game([a, b], now.subtract(const Duration(days: 3))),
        _game([a], now.subtract(const Duration(days: 2))),
      ];
      final kpis = computeKpis(games, [], range, l10n: l10n);
      expect(kpis.first.label, 'Active players');
      expect(kpis.first.value, '2');
    });

    test('should_show_active_players_delta_vs_prior_period', () {
      final a = _p('A', Elo.c2);
      final b = _p('B', Elo.c2);
      final games = [
        _game([a, b], now.subtract(const Duration(days: 3))),
        _game([a], now.subtract(const Duration(days: 100))),
      ];
      final kpis = computeKpis(games, [], range, l10n: l10n);
      expect(kpis.first.contextLine, '+1 vs prior period');
      expect(kpis.first.deltaPositive, isTrue);
    });

    test('should_keep_retention_label_at_4wk_for_any_range', () {
      final wideRange = DateRange.lastWeeks(26, now: now);
      final kpis = computeKpis([], [], wideRange, l10n: l10n);
      final retention = kpis.firstWhere((k) => k.label.startsWith('Retention'));
      expect(retention.label, 'Retention (4wk)');
    });

    test('should_compute_retention_as_share_of_previous_4wk_who_returned', () {
      final a = _p('A', Elo.c2);
      final b = _p('B', Elo.c2);
      final games = [
        _game([a, b], now.subtract(const Duration(days: 40))),
        _game([a], now.subtract(const Duration(days: 5))),
      ];
      final kpis = computeKpis(games, [], range, l10n: l10n);
      final retention = kpis.firstWhere((k) => k.label.startsWith('Retention'));
      expect(retention.value, '50%');
    });

    test('should_compare_retention_with_the_prior_period', () {
      final kpis = computeKpis([], [], range, l10n: l10n);
      final retention = kpis.firstWhere((k) => k.label.startsWith('Retention'));
      expect(retention.contextLine, '+0.0% vs prior period');
    });
  });

  group('ANA-03: Attendance trend', () {
    test('should_use_checked_in_over_capacity_as_bar_value', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          capacity: 20,
          checkedInCount: 10,
          courtCount: 2,
        ),
      ];
      final result = computeAttendanceTrend(logs, range, l10n: l10n);
      expect(result.points.single.value, 0.5);
      expect(result.points.single.valueLabel, '50%');
    });

    test('should_report_month_over_month_growth', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 35)),
          checkedInCount: 10,
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 5)),
          checkedInCount: 15,
        ),
      ];
      final result = computeAttendanceTrend(logs, range, l10n: l10n);
      expect(result.note, '+50% month over month');
    });

    test('should_report_decline_with_a_minus_sign', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 35)),
          checkedInCount: 20,
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 5)),
          checkedInCount: 10,
        ),
      ];
      final result = computeAttendanceTrend(logs, range, l10n: l10n);
      expect(result.note, '-50% month over month');
    });

    test('should_say_not_enough_sessions_without_a_previous_month', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 5)),
          checkedInCount: 10,
        ),
      ];
      final result = computeAttendanceTrend(logs, range, l10n: l10n);
      expect(result.note, l10n.analytics_not_enough_sessions);
    });
  });

  group('ANA-04: Waitlist pressure', () {
    test('flags high waitlist pressure at >= 2.5 average', () {
      final logs = [
        _log(loggedAt: now.subtract(const Duration(days: 2)), waitlistCount: 3),
        _log(loggedAt: now.subtract(const Duration(days: 1)), waitlistCount: 3),
      ];
      final result = computeWaitlistPressure(logs, range, l10n: l10n);
      expect(result.note, contains('high'));
    });

    test('reassures when waitlist pressure is low', () {
      final logs = [
        _log(loggedAt: now.subtract(const Duration(days: 1)), waitlistCount: 0),
      ];
      final result = computeWaitlistPressure(logs, range, l10n: l10n);
      expect(result.note, contains('low'));
    });
  });

  group('ANA-05: Level-gap trend', () {
    test('should_express_gap_as_tier_gap_not_elo_steps', () {
      // Two Elo steps are one tier.
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          courtLevelGaps: [2, 2],
        ),
      ];
      final result = computeLevelGapTrend(logs, range, l10n: l10n);
      expect(result.points.single.value, 1.0);
      expect(result.points.single.valueLabel, '1.0');
    });

    test('should_say_improving_when_gap_shrinks', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 20)),
          courtLevelGaps: [3, 3],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 10)),
          courtLevelGaps: [2, 2],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          courtLevelGaps: [0, 0],
        ),
      ];
      final result = computeLevelGapTrend(logs, range, l10n: l10n);
      expect(result.note, l10n.analytics_level_gap_down);
    });

    test('should_say_not_improving_when_gap_grows', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 20)),
          courtLevelGaps: [0, 0],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          courtLevelGaps: [4, 4],
        ),
      ];
      final result = computeLevelGapTrend(logs, range, l10n: l10n);
      expect(result.note, l10n.analytics_level_gap_up);
    });

    test('should_say_not_improving_when_gap_is_flat', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 20)),
          courtLevelGaps: [2, 2],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          courtLevelGaps: [2, 2],
        ),
      ];
      final result = computeLevelGapTrend(logs, range, l10n: l10n);
      expect(result.note, l10n.analytics_level_gap_up);
    });

    test('should_say_not_enough_sessions_with_one_session', () {
      final logs = [_log(loggedAt: now.subtract(const Duration(days: 1)))];
      final result = computeLevelGapTrend(logs, range, l10n: l10n);
      expect(result.note, l10n.analytics_not_enough_sessions);
    });
  });

  group('ANA-06: Per-court comparison', () {
    List<SessionLog> nights(List<List<int>> gapsPerNight) => [
      for (var i = 0; i < gapsPerNight.length; i++)
        _log(
          loggedAt: now.subtract(Duration(days: 20 - i)),
          courtLevelGaps: gapsPerNight[i],
        ),
    ];

    test('should_flag_a_court_that_is_wider_on_most_nights', () {
      final courts = computeCourtGapComparison(
        nights([
          [0, 4],
          [0, 4],
          [0, 4],
        ]),
        range,
      );
      expect(courts.last.isOverflowAbsorber, isTrue);
      expect(courts.first.isOverflowAbsorber, isFalse);
    });

    test('should_not_flag_a_court_with_a_single_outlier_night', () {
      final courts = computeCourtGapComparison(
        nights([
          [0, 0],
          [0, 0],
          [0, 8],
        ]),
        range,
      );
      expect(courts.last.isOverflowAbsorber, isFalse);
    });

    test('should_not_flag_a_court_seen_on_fewer_than_3_nights', () {
      final courts = computeCourtGapComparison(
        nights([
          [0, 4],
          [0, 4],
        ]),
        range,
      );
      expect(courts.last.isOverflowAbsorber, isFalse);
    });

    test('should_report_average_gap_in_tiers', () {
      final courts = computeCourtGapComparison(
        nights([
          [0, 4],
        ]),
        range,
      );
      expect(courts.last.averageGap, 2.0);
    });

    test('should_fold_multiple_same_day_saves_into_one_session', () {
      // Two saves on one night list the same courts; they must not become
      // extra courts.
      final sameNight = now.subtract(const Duration(days: 1));
      final logs = [
        _log(loggedAt: sameNight, courtLevelGaps: [2]),
        _log(
          loggedAt: sameNight.add(const Duration(minutes: 5)),
          courtLevelGaps: [4],
        ),
      ];
      final courts = computeCourtGapComparison(logs, range);
      expect(courts, hasLength(1));
      expect(courts.single.averageGap, 1.5);
    });
  });

  group('ANA-07: Court utilization', () {
    final nightOne = now.subtract(const Duration(days: 5));
    final nightTwo = now.subtract(const Duration(days: 1));

    test('should_report_a_fill_rate_per_court', () {
      final logs = [
        _log(
          loggedAt: nightOne,
          checkedInCount: 8,
          courtLevelGaps: [0, 0],
          courtCount: 2,
        ),
        _log(
          loggedAt: nightTwo,
          checkedInCount: 4,
          courtLevelGaps: [0],
          courtCount: 2,
        ),
      ];
      final result = computeCourtUtilization(logs, range, l10n: l10n);
      expect(result.courts.map((c) => c.label), ['Court 1', 'Court 2']);
      expect(result.courts.map((c) => c.valueLabel), ['100%', '50%']);
    });

    test('should_report_full_4_fill_rate_over_sessions', () {
      final logs = [
        _log(loggedAt: nightOne, checkedInCount: 8, courtCount: 2),
        _log(loggedAt: nightTwo, checkedInCount: 4, courtCount: 2),
      ];
      final result = computeCourtUtilization(logs, range, l10n: l10n);
      expect(result.fullFillRatePct, 50);
    });

    test('should_report_average_idle_courts_per_session', () {
      final logs = [
        _log(loggedAt: nightOne, courtLevelGaps: [0, 0], courtCount: 2),
        _log(loggedAt: nightTwo, courtLevelGaps: [0], courtCount: 2),
      ];
      final result = computeCourtUtilization(logs, range, l10n: l10n);
      expect(result.avgIdleCourtsPerSession, 0.5);
    });

    test('should_return_no_courts_when_no_sessions', () {
      final result = computeCourtUtilization([], range, l10n: l10n);
      expect(result.courts, isEmpty);
    });
  });

  group('ANA-08: Re-rolls per session', () {
    // Two nights; the second has more re-rolls than the first.
    String noteFor({
      required int firstCheckedIn,
      required int secondCheckedIn,
      required int firstGap,
      required int secondGap,
      int firstRerolls = 0,
      int secondRerolls = 6,
    }) {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 5)),
          checkedInCount: firstCheckedIn,
          rerollCount: firstRerolls,
          courtLevelGaps: [firstGap, firstGap],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          checkedInCount: secondCheckedIn,
          rerollCount: secondRerolls,
          courtLevelGaps: [secondGap, secondGap],
        ),
      ];
      return computeRerollsPerSession(logs, range, l10n: l10n).note;
    }

    test('should_link_spikes_to_high_attendance_nights', () {
      expect(
        noteFor(
          firstCheckedIn: 4,
          secondCheckedIn: 20,
          firstGap: 2,
          secondGap: 2,
        ),
        l10n.analytics_reroll_spikes_attendance,
      );
    });

    test('should_link_spikes_to_high_level_spread_nights', () {
      expect(
        noteFor(
          firstCheckedIn: 10,
          secondCheckedIn: 10,
          firstGap: 0,
          secondGap: 4,
        ),
        l10n.analytics_reroll_spikes,
      );
    });

    test('should_link_spikes_to_both_attendance_and_spread', () {
      expect(
        noteFor(
          firstCheckedIn: 4,
          secondCheckedIn: 20,
          firstGap: 0,
          secondGap: 4,
        ),
        l10n.analytics_reroll_spikes_both,
      );
    });

    test('should_say_steady_when_re_rolls_do_not_spike', () {
      expect(
        noteFor(
          firstCheckedIn: 4,
          secondCheckedIn: 20,
          firstGap: 0,
          secondGap: 4,
          secondRerolls: 0,
        ),
        l10n.analytics_reroll_steady,
      );
    });

    test('should_say_not_enough_sessions_when_none_logged', () {
      final result = computeRerollsPerSession([], range, l10n: l10n);
      expect(result.note, l10n.analytics_not_enough_sessions);
    });
  });

  group('ANA-09: Level distribution', () {
    LevelDistributionResult distribution(
      List<Player> players,
      List<Game> games,
    ) => computeLevelDistribution(
      players,
      games,
      range,
      resolvePlayer: _resolverFor(players),
      l10n: l10n,
    );

    test(
      'should_bucket_players_into_the_4_named_tiers_and_compute_the_median',
      () {
        final players = [_p('A', Elo.c2), _p('B', Elo.c1), _p('C', Elo.s1)];
        final result = distribution(players, []);
        expect(result.points.map((p) => p.label), [
          'Amateur',
          'Intermediate',
          'Advanced',
          'Professional',
        ]);
        expect(result.medianTierLabel, 'Amateur');
      },
    );

    test('should_flag_a_player_with_6_sessions_in_range', () {
      final player = _p('Stuck', Elo.c2);
      final games = List.generate(
        6,
        (i) => _game([player], now.subtract(Duration(days: 6 - i))),
      );
      final result = distribution([player], games);
      expect(result.stagnationNote, l10n.analytics_stagnation(1));
    });

    test('should_count_sessions_not_games_for_stagnation', () {
      // Six games on one night are one session.
      final player = _p('Busy', Elo.c2);
      final night = now.subtract(const Duration(days: 2));
      final games = List.generate(6, (_) => _game([player], night));
      final result = distribution([player], games);
      expect(result.stagnationNote, isNull);
    });

    test('should_ignore_sessions_outside_the_range_for_stagnation', () {
      final player = _p('Stuck', Elo.c2);
      final games = List.generate(
        6,
        (i) => _game([player], DateTime(2000, 1, 1 + i)),
      );
      final result = distribution([player], games);
      expect(result.stagnationNote, isNull);
    });

    test('should_report_trend_up_when_active_players_skew_higher', () {
      final low = _p('Low', Elo.c2);
      final high = _p('High', Elo.s1);
      final games = [
        _game([low], now.subtract(const Duration(days: 100))),
        _game([high], now.subtract(const Duration(days: 3))),
      ];
      final result = distribution([low, high], games);
      expect(result.trendNote, l10n.analytics_level_trend_up);
    });

    test('should_report_trend_down_when_active_players_skew_lower', () {
      final low = _p('Low', Elo.c2);
      final high = _p('High', Elo.s1);
      final games = [
        _game([high], now.subtract(const Duration(days: 100))),
        _game([low], now.subtract(const Duration(days: 3))),
      ];
      final result = distribution([low, high], games);
      expect(result.trendNote, l10n.analytics_level_trend_down);
    });

    test('should_report_trend_flat_when_the_mix_does_not_change', () {
      final player = _p('Same', Elo.b2);
      final games = [
        _game([player], now.subtract(const Duration(days: 100))),
        _game([player], now.subtract(const Duration(days: 3))),
      ];
      final result = distribution([player], games);
      expect(result.trendNote, l10n.analytics_level_trend_flat);
    });

    test('should_give_no_trend_without_games_in_both_windows', () {
      final player = _p('Only', Elo.b2);
      final games = [
        _game([player], now.subtract(const Duration(days: 3))),
      ];
      final result = distribution([player], games);
      expect(result.trendNote, isNull);
    });
  });

  group('ANA-11: At-risk players', () {
    test('flags a regular attendee who has not been seen in 3+ weeks', () {
      final regular = _p('Regular', Elo.c2);
      final games = List.generate(
        8,
        (i) => _game([regular], now.subtract(Duration(days: 40 + i * 4))),
      );
      final result = computeAtRiskPlayers(games, [regular], now: now);
      expect(result.lapsedCount, 1);
      expect(result.entries.first.weeksSinceLastSeen, greaterThanOrEqualTo(3));
    });
  });

  group('ANA-12: Player mixing', () {
    test('should_tag_a_wide_partner_player_as_connector', () {
      final hub = _p('Hub', Elo.c2);
      final partners = List.generate(5, (i) => _p('P$i', Elo.c1));
      final games = List.generate(
        5,
        (i) => _game([hub, partners[i]], DateTime(2026, 1, 1 + i)),
      );
      final mixing = computePlayerMixing(
        games,
        resolvePlayer: _resolverFor([hub, ...partners]),
      );
      final hubEntry = mixing.firstWhere((m) => m.name == hub.name());
      expect(hubEntry.tag, MixingTag.connector);
    });

    test('should_tag_a_narrow_circle_player_as_clique', () {
      // 3 distinct partners over 10 games: score 0.3.
      final a = _p('A', Elo.c2);
      final others = List.generate(3, (i) => _p('O$i', Elo.c1));
      final games = List.generate(
        10,
        (i) => _game([a, others[i % 3]], DateTime(2026, 1, 1 + i)),
      );
      final mixing = computePlayerMixing(
        games,
        resolvePlayer: _resolverFor([a, ...others]),
      );
      expect(
        mixing.firstWhere((m) => m.name == a.name()).tag,
        MixingTag.clique,
      );
    });

    test('should_tag_a_one_partner_player_as_isolated', () {
      final a = _p('A', Elo.c2);
      final b = _p('B', Elo.c1);
      final games = List.generate(
        10,
        (i) => _game([a, b], DateTime(2026, 1, 1 + i)),
      );
      final mixing = computePlayerMixing(
        games,
        resolvePlayer: _resolverFor([a, b]),
      );
      expect(mixing.first.tag, MixingTag.isolated);
    });

    test('should_use_the_supplied_name_for_a_deleted_player', () {
      final deleted = _p(
        'Ghost',
        Elo.c2,
      ).copyWith(deletedDate: DateTime(2026, 1, 2));
      final p0 = _p('P0', Elo.c1);
      final games = [
        _game([deleted, p0], DateTime(2026, 1, 1)),
      ];
      final mixing = computePlayerMixing(
        games,
        resolvePlayer: _resolverFor([deleted, p0]),
        nameOf: (p) => p.isAnonymised ? 'Deleted player' : p.name(),
      );
      expect(mixing.map((m) => m.name), contains('Deleted player'));
    });

    MixingEntry entry(int i, double score, [MixingTag? tag]) =>
        MixingEntry(name: 'E$i', score: score, tag: tag);

    test('should_sample_the_top_and_bottom_scores_when_over_10_players', () {
      final entries = [
        for (var i = 0; i < 12; i++)
          entry(i, 1 - i / 12, i == 11 ? MixingTag.isolated : null),
      ];
      final sample = sampleMixing(entries);
      expect(sample, hasLength(10));
      expect(sample.map((e) => e.name), containsAll(['E0', 'E4', 'E7', 'E11']));
    });

    test('should_keep_every_player_when_10_or_fewer', () {
      final entries = [for (var i = 0; i < 10; i++) entry(i, 1 - i / 10)];
      expect(sampleMixing(entries), entries);
    });
  });

  group('ANA-13: New player integration', () {
    final regular = _p('Reg', Elo.c2, createdDate: DateTime(2020, 1, 1));
    final regularGames = List.generate(
      8,
      (i) => _game([regular, _p('X$i', Elo.c1)], DateTime(2026, 1, 1 + i)),
    );
    final other = _p('Y', Elo.c1);

    List<NewPlayerEntry> integration(List<Game> extra, List<Player> players) =>
        computeNewPlayerIntegration(
          [...regularGames, ...extra],
          [regular, ...players],
          range: range,
        );

    Player newcomer({int joinedDaysAgo = 5}) => _p(
      'Newbie',
      Elo.c2,
      createdDate: now.subtract(Duration(days: joinedDaysAgo)),
    );

    test('should_compute_the_share_of_games_played_with_regulars', () {
      final newbie = newcomer();
      final result = integration(
        [
          _game([newbie, regular], now.subtract(const Duration(days: 1))),
        ],
        [newbie],
      );
      expect(result.single.name, 'Newbie T');
      expect(result.single.pctWithRegulars, 100);
      expect(result.single.isFavorable, isTrue);
    });

    test('should_count_sessions_attended_as_distinct_days', () {
      final newbie = newcomer();
      final night = now.subtract(const Duration(days: 1));
      final result = integration(
        [
          _game([newbie, regular], night),
          _game([newbie, other], night),
          _game([newbie, regular], night.subtract(const Duration(days: 2))),
        ],
        [newbie],
      );
      expect(result.single.sessionsAttended, 2);
    });

    test('should_mark_below_50_percent_as_needing_attention', () {
      final newbie = newcomer();
      final result = integration(
        [
          _game([newbie, regular], now.subtract(const Duration(days: 1))),
          _game([newbie, other], now.subtract(const Duration(days: 2))),
          _game([newbie, other], now.subtract(const Duration(days: 3))),
        ],
        [newbie],
      );
      expect(result.single.isFavorable, isFalse);
    });

    test('should_treat_exactly_50_percent_as_favorable', () {
      final newbie = newcomer();
      final result = integration(
        [
          _game([newbie, regular], now.subtract(const Duration(days: 1))),
          _game([newbie, other], now.subtract(const Duration(days: 2))),
        ],
        [newbie],
      );
      expect(result.single.isFavorable, isTrue);
    });

    test('should_exclude_players_who_joined_before_the_new_window', () {
      final old = newcomer(joinedDaysAgo: kNewPlayerWindowDays + 1);
      final edge = newcomer(joinedDaysAgo: kNewPlayerWindowDays);
      final result = integration([], [old, edge]);
      expect(result.map((e) => e.name), ['Newbie T']);
      expect(result.single.joinDate, edge.createdDate);
    });

    test('should_only_count_games_inside_the_selected_range', () {
      final newbie = newcomer(joinedDaysAgo: 50);
      final result = computeNewPlayerIntegration(
        [
          ...regularGames,
          _game([newbie, regular], now.subtract(const Duration(days: 3))),
          _game([newbie, regular], now.subtract(const Duration(days: 40))),
        ],
        [regular, newbie],
        range: DateRange.lastWeeks(2, now: now),
      );
      expect(result.single.sessionsAttended, 1);
    });
  });
}
