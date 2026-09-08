import 'package:collection/collection.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';

/// Pure, presentation-free computations backing the Analytics tab (ANA-01…13).
///
/// Every function here takes plain data (persisted [Game]s, [SessionLog]s,
/// and the full [Player] roster) and a time window, and returns simple
/// value objects the widget layer renders directly. No raw ELO numbers are
/// ever exposed — only [Elo] tier display names and tier-index gaps, matching
/// the convention already used by CourtCard/SpreadPill (see UAT.md §1).

/// Default `nameOf` for [computePlayerMixing] — the caller supplies a
/// localised one (see `playerDisplayName`) so an anonymised Player
/// (ADR-0001) shows a placeholder instead of a blank name.
String _defaultName(Player player) => player.name();

/// An inclusive-start, exclusive-end date window.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// The equal-length window immediately preceding this one, for
  /// "vs. prior period" deltas.
  DateRange get priorPeriod {
    final length = end.difference(start);
    return DateRange(start.subtract(length), start);
  }

  factory DateRange.lastWeeks(int weeks, {DateTime? now}) {
    final end = now ?? DateTime.now();
    return DateRange(end.subtract(Duration(days: weeks * 7)), end);
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Groups [logs] by calendar day (one "session" per day). Multiple saved
/// rounds on the same day are folded into a single representative snapshot:
/// peak checked-in count, average waitlist, summed re-rolls, and all courts'
/// level gaps concatenated.
List<SessionLog> _sessionsByDay(Iterable<SessionLog> logs, DateRange range) {
  final inRange = logs.where((l) => range.contains(l.loggedAt));
  final byDay = groupBy(inRange, (SessionLog l) => _dateOnly(l.loggedAt));
  final result = byDay.entries
      .map((entry) {
        final dayLogs = entry.value;
        final checkedIn = dayLogs.map((l) => l.checkedInCount).max;
        final waitlist = dayLogs.map((l) => l.waitlistCount).average;
        final rerolls = dayLogs.fold<int>(0, (sum, l) => sum + l.rerollCount);
        final gaps = dayLogs.expand((l) => l.courtLevelGaps).toList();
        final last = dayLogs.last;
        return SessionLog(
          id: last.id,
          loggedAt: entry.key,
          capacity: last.capacity,
          checkedInCount: checkedIn,
          waitlistCount: waitlist.round(),
          rerollCount: rerolls,
          courtLevelGaps: gaps,
          courtCount: last.courtCount,
        );
      })
      .sortedBy((l) => l.loggedAt);
  return result;
}

/// A single bar-chart data point.
class ChartPoint {
  const ChartPoint({required this.label, required this.value, this.valueLabel});

  /// X-axis label (e.g. a short date).
  final String label;

  /// The raw value this point represents (not yet normalized to 0..1).
  final double value;

  /// Optional pre-formatted display text for the bar's top label.
  final String? valueLabel;
}

/// A single KPI tile.
class KpiEntry {
  const KpiEntry({
    required this.label,
    required this.value,
    required this.contextLine,
    this.deltaPositive,
  });

  final String label;
  final String value;

  /// Delta / context line vs. the prior period, e.g. "+4.2% vs prior 12 wks".
  final String contextLine;

  /// Whether the delta is a "good" direction (green) — null for neutral.
  final bool? deltaPositive;
}

// ── ANA-02: KPI strip ──────────────────────────────────────────────

List<KpiEntry> computeKpis(
  List<Game> games,
  List<SessionLog> sessionLogs,
  List<Player> allPlayers,
  DateRange range,
) {
  final current = _sessionsByDay(sessionLogs, range);
  final prior = _sessionsByDay(sessionLogs, range.priorPeriod);

  double avgAttendancePct(List<SessionLog> logs) =>
      logs.isEmpty ? 0 : logs.map((l) => l.fillRate * 100).average;

  double avgWaitlist(List<SessionLog> logs) =>
      logs.isEmpty ? 0 : logs.map((l) => l.waitlistCount.toDouble()).average;

  double avgRerolls(List<SessionLog> logs) =>
      logs.isEmpty ? 0 : logs.map((l) => l.rerollCount.toDouble()).average;

  double courtUtilPct(List<SessionLog> logs) =>
      logs.isEmpty ? 0 : logs.map((l) => l.fillRate * 100).average;

  final registeredPlayers = allPlayers.length;
  final playersInRange = _playerIdsInGames(
    games.where((g) => range.contains(g.createdDate)),
  ).length;
  final playersInPrior = _playerIdsInGames(
    games.where((g) => range.priorPeriod.contains(g.createdDate)),
  ).length;
  final retentionPct = playersInPrior == 0
      ? 0.0
      : (playersInRange / playersInPrior * 100).clamp(0, 100);

  String delta(double curr, double prev, String suffix) {
    final d = curr - prev;
    final sign = d >= 0 ? '+' : '';
    return '$sign${d.toStringAsFixed(1)}$suffix vs prior period';
  }

  final currAttendance = avgAttendancePct(current);
  final priorAttendance = avgAttendancePct(prior);
  final currWaitlist = avgWaitlist(current);
  final priorWaitlist = avgWaitlist(prior);
  final currRerolls = avgRerolls(current);
  final priorRerolls = avgRerolls(prior);
  final currUtil = courtUtilPct(current);
  final priorUtil = courtUtilPct(prior);

  return [
    KpiEntry(
      label: 'Registered players',
      value: '$registeredPlayers',
      contextLine: 'across the club',
    ),
    KpiEntry(
      label: 'Avg attendance',
      value: '${currAttendance.toStringAsFixed(0)}%',
      contextLine: delta(currAttendance, priorAttendance, '%'),
      deltaPositive: currAttendance >= priorAttendance,
    ),
    KpiEntry(
      label: 'Retention (${_weeksInRange(range)}wk)',
      value: '${retentionPct.toStringAsFixed(0)}%',
      contextLine: 'players returning from prior period',
    ),
    KpiEntry(
      label: 'Court utilization',
      value: '${currUtil.toStringAsFixed(0)}%',
      contextLine: delta(currUtil, priorUtil, '%'),
      deltaPositive: currUtil >= priorUtil,
    ),
    KpiEntry(
      label: 'Avg waitlist',
      value: currWaitlist.toStringAsFixed(1),
      contextLine: delta(currWaitlist, priorWaitlist, ''),
      deltaPositive: currWaitlist <= priorWaitlist,
    ),
    KpiEntry(
      label: 'Re-rolls / session',
      value: currRerolls.toStringAsFixed(1),
      contextLine: delta(currRerolls, priorRerolls, ''),
      deltaPositive: currRerolls <= priorRerolls,
    ),
  ];
}

Set<String> _playerIdsInGames(Iterable<Game> games) =>
    games.expand((g) => g.playerIds).toSet();

int _weeksInRange(DateRange range) =>
    (range.end.difference(range.start).inDays / 7).round();

// ── ANA-03: Attendance trend ───────────────────────────────────────

class TrendResult {
  const TrendResult({required this.points, required this.note});
  final List<ChartPoint> points;
  final String note;
}

TrendResult computeAttendanceTrend(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.loggedAt),
          value: s.fillRate,
          valueLabel: '${(s.fillRate * 100).round()}%',
        ),
      )
      .toList();

  if (points.length < 2) {
    return TrendResult(points: points, note: 'Not enough sessions logged yet.');
  }
  final firstHalf = points.take(points.length ~/ 2).map((p) => p.value).average;
  final secondHalf = points
      .skip(points.length ~/ 2)
      .map((p) => p.value)
      .average;
  final growth = firstHalf == 0
      ? 0.0
      : (secondHalf - firstHalf) / firstHalf * 100;
  final sign = growth >= 0 ? '+' : '';
  return TrendResult(
    points: points,
    note: '$sign${growth.toStringAsFixed(0)}% change over the period',
  );
}

// ── ANA-04: Waitlist pressure ──────────────────────────────────────

TrendResult computeWaitlistPressure(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.loggedAt),
          value: s.waitlistCount.toDouble(),
          valueLabel: '${s.waitlistCount}',
        ),
      )
      .toList();
  final avg = points.isEmpty ? 0.0 : points.map((p) => p.value).average;
  final note = avg >= 2.5
      ? 'Average waitlist is high (${avg.toStringAsFixed(1)}/session) — consider adding capacity or another court.'
      : 'Waitlist pressure is low (${avg.toStringAsFixed(1)}/session).';
  return TrendResult(points: points, note: note);
}

// ── ANA-05/06: Matchmaking fairness ────────────────────────────────

TrendResult computeLevelGapTrend(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.loggedAt),
          value: s.averageLevelGap,
          valueLabel: s.averageLevelGap.toStringAsFixed(1),
        ),
      )
      .toList();
  String note = 'Not enough sessions logged yet.';
  if (points.length >= 2) {
    final firstHalf = points
        .take(points.length ~/ 2)
        .map((p) => p.value)
        .average;
    final secondHalf = points
        .skip(points.length ~/ 2)
        .map((p) => p.value)
        .average;
    note = secondHalf <= firstHalf
        ? 'Level gap is trending down — matchmaking is improving.'
        : 'Level gap is trending up — matchmaking fairness is slipping.';
  }
  return TrendResult(points: points, note: note);
}

class CourtGapSummary {
  const CourtGapSummary({
    required this.courtNumber,
    required this.averageGap,
    required this.isOverflowAbsorber,
  });
  final int courtNumber;
  final double averageGap;
  final bool isOverflowAbsorber;
}

List<CourtGapSummary> computeCourtGapComparison(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final byCourtIndex = <int, List<int>>{};
  for (final s in sessions) {
    for (var i = 0; i < s.courtLevelGaps.length; i++) {
      (byCourtIndex[i] ??= []).add(s.courtLevelGaps[i]);
    }
  }
  if (byCourtIndex.isEmpty) return [];
  final overallAvg = byCourtIndex.values
      .expand((v) => v)
      .map((v) => v.toDouble())
      .average;
  return byCourtIndex.entries.sortedBy((e) => e.key).map((e) {
    final avg = e.value.map((v) => v.toDouble()).average;
    return CourtGapSummary(
      courtNumber: e.key + 1,
      averageGap: avg,
      isOverflowAbsorber: avg > overallAvg * 1.25,
    );
  }).toList();
}

// ── ANA-07: Court utilization ──────────────────────────────────────

class CourtUtilizationResult {
  const CourtUtilizationResult({
    required this.points,
    required this.fullFillRatePct,
    required this.avgIdleCourtsPerSession,
  });
  final List<ChartPoint> points;
  final double fullFillRatePct;
  final double avgIdleCourtsPerSession;
}

CourtUtilizationResult computeCourtUtilization(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.loggedAt),
          value: s.fillRate,
          valueLabel: '${(s.fillRate * 100).round()}%',
        ),
      )
      .toList();
  final fullFillRate = sessions.isEmpty
      ? 0.0
      : sessions.where((s) => s.fillRate >= 1.0).length / sessions.length * 100;
  final avgIdle = sessions.isEmpty
      ? 0.0
      : sessions.map((s) => s.idleCourtSlots / Game.playerPerCourt).average;
  return CourtUtilizationResult(
    points: points,
    fullFillRatePct: fullFillRate,
    avgIdleCourtsPerSession: avgIdle,
  );
}

// ── ANA-08: Re-rolls per session ───────────────────────────────────

TrendResult computeRerollsPerSession(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.loggedAt),
          value: s.rerollCount.toDouble(),
          valueLabel: '${s.rerollCount}',
        ),
      )
      .toList();
  if (points.isEmpty) {
    return const TrendResult(
      points: [],
      note: 'Not enough sessions logged yet.',
    );
  }
  final avgRerolls = points.map((p) => p.value).average;
  final highSpreadDays = sessions.where(
    (s) => s.rerollCount > avgRerolls && s.averageLevelGap > 1.0,
  );
  final note = highSpreadDays.isNotEmpty
      ? 'Re-roll spikes tend to line up with high level-spread nights.'
      : 'Re-roll counts stay steady regardless of level spread.';
  return TrendResult(points: points, note: note);
}

// ── ANA-09: Level distribution ─────────────────────────────────────
//
// [SkillTier] and the Elo↔SkillTier mapping live in lib/model/elo.dart so
// they can be shared with the self-registration feature (REG-01…07).

class LevelDistributionResult {
  const LevelDistributionResult({
    required this.points,
    required this.medianTierLabel,
    required this.stagnationNote,
  });
  final List<ChartPoint> points;
  final String medianTierLabel;
  final String? stagnationNote;
}

LevelDistributionResult computeLevelDistribution(
  List<Player> allPlayers,
  List<Game> games,
  DateRange range, {
  required Player? Function(String id) resolvePlayer,
}) {
  final points = SkillTier.values
      .map(
        (tier) => ChartPoint(
          label: tier.label,
          value: allPlayers
              .where((p) => p.elo.skillTier == tier)
              .length
              .toDouble(),
        ),
      )
      .toList();

  String medianLabel = '—';
  if (allPlayers.isNotEmpty) {
    final sortedTiers = allPlayers
        .map((p) => p.elo.skillTier.index)
        .sorted((a, b) => a.compareTo(b));
    final mid = sortedTiers[sortedTiers.length ~/ 2];
    medianLabel = SkillTier.values[mid].label;
  }

  // Stagnation: players whose tier hasn't changed across their last 6 games
  // logged within the selected time range.
  final gamesInRange = games.where((g) => range.contains(g.createdDate));
  final byPlayer = groupBy(
    gamesInRange.expand(
      (g) => g.playerIds
          .map(resolvePlayer)
          .nonNulls
          .map((p) => (p, g.createdDate)),
    ),
    (record) => record.$1.id,
  );
  var stagnantCount = 0;
  for (final entry in byPlayer.entries) {
    final sortedGames = entry.value.sortedBy((r) => r.$2);
    if (sortedGames.length < 6) continue;
    final last6 = sortedGames.sublist(sortedGames.length - 6);
    final tiers = last6.map((r) => r.$1.elo.skillTier).toSet();
    if (tiers.length == 1) stagnantCount++;
  }

  return LevelDistributionResult(
    points: points,
    medianTierLabel: medianLabel,
    stagnationNote: stagnantCount > 0
        ? '$stagnantCount players flat 6+ sessions'
        : null,
  );
}

// ── ANA-11: At-risk players ────────────────────────────────────────

class AtRiskEntry {
  const AtRiskEntry({
    required this.name,
    required this.usualFrequencyPerMonth,
    required this.weeksSinceLastSeen,
  });
  final String name;
  final double usualFrequencyPerMonth;
  final int weeksSinceLastSeen;
}

class AtRiskResult {
  const AtRiskResult({required this.entries});
  final List<AtRiskEntry> entries;
  int get lapsedCount => entries.length;
}

AtRiskResult computeAtRiskPlayers(
  List<Game> games,
  List<Player> allPlayers, {
  DateTime? now,
}) {
  final asOf = now ?? DateTime.now();
  final byPlayerId = groupBy(
    games.expand((g) => g.playerIds.map((id) => (id, g.createdDate))),
    (record) => record.$1,
  );

  final entries = <AtRiskEntry>[];
  for (final player in allPlayers) {
    final dates =
        byPlayerId[player.id]
            ?.map((r) => r.$2)
            .sorted((a, b) => a.compareTo(b)) ??
        <DateTime>[];
    if (dates.isEmpty) continue;
    final span = asOf.difference(dates.first).inDays;
    final monthsSpan = (span / 30).clamp(1, double.infinity);
    final frequency = dates.length / monthsSpan;
    final lastSeen = dates.last;
    final weeksSince = asOf.difference(lastSeen).inDays ~/ 7;
    if (frequency >= 2 && weeksSince >= 3) {
      entries.add(
        AtRiskEntry(
          name: player.name(),
          usualFrequencyPerMonth: frequency,
          weeksSinceLastSeen: weeksSince,
        ),
      );
    }
  }
  entries.sort((a, b) => b.weeksSinceLastSeen.compareTo(a.weeksSinceLastSeen));
  return AtRiskResult(entries: entries);
}

// ── ANA-12: Player mixing ──────────────────────────────────────────

class MixingEntry {
  const MixingEntry({
    required this.name,
    required this.score,
    required this.tag,
  });
  final String name;
  final double score;
  final String? tag;
}

List<MixingEntry> computePlayerMixing(
  List<Game> games, {
  required Player? Function(String id) resolvePlayer,
  String Function(Player) nameOf = _defaultName,
}) {
  final gamesByPlayerId = <String, List<Game>>{};
  for (final g in games) {
    for (final id in g.playerIds) {
      (gamesByPlayerId[id] ??= <Game>[]).add(g);
    }
  }
  final result = <MixingEntry>[];
  for (final entry in gamesByPlayerId.entries) {
    final player = resolvePlayer(entry.key);
    if (player == null) continue;
    final playerGames = entry.value;
    final partnerIds = <String>{
      for (final g in playerGames)
        for (final id in g.playerIds)
          if (id != entry.key) id,
    };
    final score = (partnerIds.length / playerGames.length)
        .clamp(0, 1)
        .toDouble();
    String? tag;
    if (score >= 0.7) {
      tag = 'connector';
    } else if (score <= 0.2) {
      tag = 'isolated';
    } else if (score <= 0.4) {
      tag = 'clique';
    }
    result.add(MixingEntry(name: nameOf(player), score: score, tag: tag));
  }
  return result.sortedBy<num>((e) => -e.score);
}

// ── ANA-13: New player integration ─────────────────────────────────

class NewPlayerEntry {
  const NewPlayerEntry({
    required this.name,
    required this.joinDate,
    required this.sessionsAttended,
    required this.pctWithRegulars,
  });
  final String name;
  final DateTime joinDate;
  final int sessionsAttended;
  final double pctWithRegulars;
  bool get isFavorable => pctWithRegulars >= 50;
}

List<NewPlayerEntry> computeNewPlayerIntegration(
  List<Game> games,
  List<Player> allPlayers, {
  int newWindowDays = 60,
  DateTime? now,
}) {
  final asOf = now ?? DateTime.now();
  final regularIds = _regularPlayerIds(games);

  final newPlayers = allPlayers.where(
    (p) =>
        p.createdDate != null &&
        asOf.difference(p.createdDate!).inDays <= newWindowDays,
  );

  return newPlayers
      .map((player) {
        final playerGames = games
            .where((g) => g.playerIds.contains(player.id))
            .toList();
        final gamesWithRegulars = playerGames.where(
          (g) => g.playerIds.any(
            (id) => id != player.id && regularIds.contains(id),
          ),
        );
        final pct = playerGames.isEmpty
            ? 0.0
            : gamesWithRegulars.length / playerGames.length * 100;
        return NewPlayerEntry(
          name: player.name(),
          joinDate: player.createdDate!,
          sessionsAttended: playerGames.length,
          pctWithRegulars: pct,
        );
      })
      .sortedBy((e) => e.joinDate)
      .toList();
}

/// Players who appear in at least 8 logged games are considered "regulars"
/// for the purpose of new-player integration (ANA-13).
Set<String> _regularPlayerIds(List<Game> games) {
  final counts = <String, int>{};
  for (final g in games) {
    for (final id in g.playerIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts.entries.where((e) => e.value >= 8).map((e) => e.key).toSet();
}

String _shortDate(DateTime d) => '${d.month}/${d.day}';
