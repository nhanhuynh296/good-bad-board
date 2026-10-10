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
    test('computes 6 KPI entries', () {
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
      final kpis = computeKpis([], logs, [_p('A', Elo.c2)], range, l10n: l10n);
      expect(kpis, hasLength(6));
      expect(kpis.map((k) => k.label), contains('Registered players'));
      expect(kpis.first.value, '1');
    });

    test(
      'retention label reflects the selected range, not a hardcoded 4wk',
      () {
        final wideRange = DateRange.lastWeeks(26, now: now);
        final kpis = computeKpis([], [], [], wideRange, l10n: l10n);
        final retention = kpis.firstWhere(
          (k) => k.label.startsWith('Retention'),
        );
        expect(retention.label, 'Retention (26wk)');
      },
    );
  });

  group('ANA-03: Attendance trend', () {
    test('produces one point per logged day with a growth note', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 14)),
          checkedInCount: 4,
          courtCount: 2,
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          checkedInCount: 8,
          courtCount: 2,
        ),
      ];
      final result = computeAttendanceTrend(logs, range, l10n: l10n);
      expect(result.points, hasLength(2));
      expect(result.note, contains('%'));
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

  group('ANA-05/06: Matchmaking fairness', () {
    test('level gap trend improving note when gap shrinks', () {
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
      expect(result.note, contains('improving'));
    });

    test('per-court comparison flags an overflow-absorbing court', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          courtLevelGaps: [0, 5],
        ),
      ];
      final courts = computeCourtGapComparison(logs, range);
      expect(courts, hasLength(2));
      expect(courts.last.isOverflowAbsorber, isTrue);
      expect(courts.first.isOverflowAbsorber, isFalse);
    });

    test(
      'per-court comparison folds multiple same-day saves into one session',
      () {
        // Two courts saved individually (saveSingleGame) on the same night
        // must not be double-counted as two separate sessions.
        final sameNight = now.subtract(const Duration(days: 1));
        final logs = [
          _log(loggedAt: sameNight, courtLevelGaps: [2]),
          _log(
            loggedAt: sameNight.add(const Duration(minutes: 5)),
            courtLevelGaps: [4],
          ),
        ];
        final courts = computeCourtGapComparison(logs, range);
        // Folded into a single day-bucket with concatenated court gaps.
        expect(courts, hasLength(2));
        expect(courts.map((c) => c.averageGap), containsAll([2.0, 4.0]));
      },
    );
  });

  group('ANA-07: Court utilization', () {
    test('reports full-fill rate and idle courts', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          checkedInCount: 8,
          courtCount: 2,
        ),
      ];
      final result = computeCourtUtilization(logs, range, l10n: l10n);
      expect(result.fullFillRatePct, 100);
      expect(result.avgIdleCourtsPerSession, 0);
    });
  });

  group('ANA-08: Re-rolls per session', () {
    test('connects re-roll spikes to high level-spread nights', () {
      final logs = [
        _log(
          loggedAt: now.subtract(const Duration(days: 5)),
          rerollCount: 0,
          courtLevelGaps: [0, 0],
        ),
        _log(
          loggedAt: now.subtract(const Duration(days: 1)),
          rerollCount: 6,
          courtLevelGaps: [3, 3],
        ),
      ];
      final result = computeRerollsPerSession(logs, range, l10n: l10n);
      expect(result.note, contains('spike'));
    });
  });

  group('ANA-09: Level distribution', () {
    test(
      'buckets players into the 4 named tiers, not raw elo, and computes median',
      () {
        final players = [_p('A', Elo.c2), _p('B', Elo.c1), _p('C', Elo.s1)];
        final result = computeLevelDistribution(
          players,
          [],
          range,
          resolvePlayer: _resolverFor(players),
          l10n: l10n,
        );
        expect(result.points, hasLength(4));
        expect(result.points.map((p) => p.label), [
          'Amateur',
          'Intermediate',
          'Advanced',
          'Professional',
        ]);
        expect(result.medianTierLabel, 'Amateur');
      },
    );

    test('flags stagnant players with 6+ flat sessions within the range', () {
      final player = _p('Stuck', Elo.c2);
      final games = List.generate(
        6,
        (i) => _game([player], now.subtract(Duration(days: 6 - i))),
      );
      final result = computeLevelDistribution(
        [player],
        games,
        range,
        resolvePlayer: _resolverFor([player]),
        l10n: l10n,
      );
      expect(result.stagnationNote, contains('1 players'));
    });

    test('stagnation ignores games outside the selected range', () {
      final player = _p('Stuck', Elo.c2);
      final games = List.generate(
        6,
        (i) => _game([player], DateTime(2000, 1, 1 + i)),
      );
      final result = computeLevelDistribution(
        [player],
        games,
        range,
        resolvePlayer: _resolverFor([player]),
        l10n: l10n,
      );
      expect(result.stagnationNote, isNull);
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
    test('tags a wide-partner player as connector', () {
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
      expect(hubEntry.tag, 'connector');
    });

    test('uses the supplied nameOf — a deleted player shows a placeholder', () {
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
  });

  group('ANA-13: New player integration', () {
    test('computes % of games played with regulars', () {
      final regular = _p('Reg', Elo.c2, createdDate: DateTime(2020, 1, 1));
      final regularGames = List.generate(
        8,
        (i) => _game([regular, _p('X$i', Elo.c1)], DateTime(2025, 1, 1 + i)),
      );
      final newbie = _p(
        'Newbie',
        Elo.c2,
        createdDate: now.subtract(const Duration(days: 5)),
      );
      final newbieGame = _game([
        newbie,
        regular,
      ], now.subtract(const Duration(days: 1)));
      final result = computeNewPlayerIntegration(
        [...regularGames, newbieGame],
        [regular, newbie],
        now: now,
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Newbie T');
      expect(result.first.pctWithRegulars, 100);
      expect(result.first.isFavorable, isTrue);
    });
  });
}
