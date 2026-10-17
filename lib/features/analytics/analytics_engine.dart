import 'dart:math';

import 'package:collection/collection.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
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
///
/// Functions that produce user-visible text (labels, notes, short dates)
/// take an [AppLocalizations] — the widget passes
/// `AppLocalizations.of(context)!`, tests pass
/// `lookupAppLocalizations(const Locale('en'))` — so the engine stays free of
/// any BuildContext.

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

/// Elo steps per [SkillTier]. A [SessionLog] stores each court's level gap
/// in [Elo] index steps (8-step scale); the UAT wants tier-gap (4 tiers), so
/// a stored gap is divided by this. It is an approximation: the log keeps
/// no player tiers, so a 1-step gap may or may not cross a tier boundary.
final double _eloStepsPerTier = Elo.values.length / SkillTier.values.length;

double _tierGap(num eloIndexGap) => eloIndexGap / _eloStepsPerTier;

/// One day of play, folded from the [SessionLog]s saved that day.
class _Session {
  const _Session({
    required this.date,
    required this.capacity,
    required this.checkedIn,
    required this.waitlist,
    required this.rerolls,
    required this.courtCount,
    required this.courtTierGaps,
  });

  final DateTime date;
  final int capacity;
  final int checkedIn;
  final int waitlist;
  final int rerolls;
  final int courtCount;

  /// Tier-gap of each court that held a game, in the order the log lists
  /// them. The log has no court number, so position is the only identity.
  final List<double> courtTierGaps;

  /// Checked-in players over the session capacity (ANA-03).
  double get attendanceRate =>
      capacity <= 0 ? 0 : (checkedIn / capacity).clamp(0, 1).toDouble();

  /// Checked-in players over court slots (courts x 4) (ANA-07).
  double get fillRate {
    final slots = courtCount * Game.playerPerCourt;
    return slots <= 0 ? 0 : (checkedIn / slots).clamp(0, 1).toDouble();
  }

  /// Courts that held a game when the session was saved.
  int get usedCourts => min(courtTierGaps.length, courtCount);

  int get idleCourts => max(courtCount - courtTierGaps.length, 0);

  double get averageTierGap =>
      courtTierGaps.isEmpty ? 0 : courtTierGaps.average;
}

/// Groups [logs] by calendar day (one "session" per day). Several saves on
/// the same day fold into one session: peak checked-in count, average
/// waitlist, summed re-rolls, and each court position's gap averaged over
/// the saves that list it.
List<_Session> _sessionsByDay(Iterable<SessionLog> logs, DateRange range) {
  final inRange = logs.where((l) => range.contains(l.loggedAt));
  final byDay = groupBy(inRange, (SessionLog l) => _dateOnly(l.loggedAt));
  return byDay.entries
      .map((entry) {
        final dayLogs = entry.value.sortedBy((l) => l.loggedAt);
        final last = dayLogs.last;
        final courts = dayLogs.map((l) => l.courtLevelGaps.length).max;
        return _Session(
          date: entry.key,
          capacity: last.capacity,
          checkedIn: dayLogs.map((l) => l.checkedInCount).max,
          waitlist: dayLogs.map((l) => l.waitlistCount).average.round(),
          rerolls: dayLogs.fold<int>(0, (sum, l) => sum + l.rerollCount),
          courtCount: dayLogs.map((l) => l.courtCount).max,
          courtTierGaps: [
            for (var i = 0; i < courts; i++)
              _tierGap(
                dayLogs
                    .where((l) => l.courtLevelGaps.length > i)
                    .map((l) => l.courtLevelGaps[i])
                    .average,
              ),
          ],
        );
      })
      .sortedBy((s) => s.date);
}

/// A single bar-chart data point.
class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
    this.valueLabel,
    this.caption,
  });

  /// X-axis label (e.g. a short date).
  final String label;

  /// The raw value this point represents (not yet normalized to 0..1).
  final double value;

  /// Optional pre-formatted display text for the bar's top label.
  final String? valueLabel;

  /// Optional small text under the label in a [HorizontalBarList] (e.g. a
  /// player's mixing tag).
  final String? caption;
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

/// Retention is always measured over 4 weeks, whatever range is selected.
const _retentionWeeks = 4;

List<KpiEntry> computeKpis(
  List<Game> games,
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final current = _sessionsByDay(sessionLogs, range);
  final prior = _sessionsByDay(sessionLogs, range.priorPeriod);

  double mean(List<_Session> sessions, double Function(_Session) pick) =>
      sessions.isEmpty ? 0 : sessions.map(pick).average;

  final playersInRange = _playerIdsInRange(games, range).length;
  final playersInPrior = _playerIdsInRange(games, range.priorPeriod).length;
  final retention = _retentionPct(games, range.end);
  final priorRetention = _retentionPct(games, range.start);

  /// Shown instead of a delta when there is nothing to compare with.
  const noDelta = '—';

  String delta(double curr, double? prev, String suffix, [int digits = 1]) {
    if (prev == null) return noDelta;
    final d = curr - prev;
    final sign = d >= 0 ? '+' : '';
    return l10n.analytics_delta_vs_prior(
      '$sign${d.toStringAsFixed(digits)}$suffix',
    );
  }

  // A session average is only a fair comparison when both periods have
  // sessions. Otherwise the empty one reads as 0 and gives a fake delta.
  final comparable = current.isNotEmpty && prior.isNotEmpty;
  double? priorIfComparable(double value) => comparable ? value : null;

  final currAttendance = mean(current, (s) => s.attendanceRate * 100);
  final priorAttendance = mean(prior, (s) => s.attendanceRate * 100);
  final currWaitlist = mean(current, (s) => s.waitlist.toDouble());
  final priorWaitlist = mean(prior, (s) => s.waitlist.toDouble());
  final currRerolls = mean(current, (s) => s.rerolls.toDouble());
  final priorRerolls = mean(prior, (s) => s.rerolls.toDouble());
  final currUtil = mean(current, (s) => s.fillRate * 100);
  final priorUtil = mean(prior, (s) => s.fillRate * 100);

  final entries = [
    KpiEntry(
      label: l10n.analytics_kpi_active_players,
      value: '$playersInRange',
      contextLine: delta(
        playersInRange.toDouble(),
        playersInPrior == 0 ? null : playersInPrior.toDouble(),
        '',
        0,
      ),
      deltaPositive: playersInRange >= playersInPrior,
    ),
    KpiEntry(
      label: l10n.analytics_kpi_avg_attendance,
      value: '${currAttendance.toStringAsFixed(0)}%',
      contextLine: delta(
        currAttendance,
        priorIfComparable(priorAttendance),
        '%',
      ),
      deltaPositive: currAttendance >= priorAttendance,
    ),
    KpiEntry(
      label: l10n.analytics_kpi_retention(_retentionWeeks),
      value: retention == null ? noDelta : '${retention.toStringAsFixed(0)}%',
      contextLine: retention == null || priorRetention == null
          ? noDelta
          : delta(retention, priorRetention, '%'),
      deltaPositive: (retention ?? 0) >= (priorRetention ?? 0),
    ),
    KpiEntry(
      label: l10n.analytics_court_utilization,
      value: '${currUtil.toStringAsFixed(0)}%',
      contextLine: delta(currUtil, priorIfComparable(priorUtil), '%'),
      deltaPositive: currUtil >= priorUtil,
    ),
    KpiEntry(
      label: l10n.analytics_kpi_avg_waitlist,
      value: currWaitlist.toStringAsFixed(1),
      contextLine: delta(currWaitlist, priorIfComparable(priorWaitlist), ''),
      deltaPositive: currWaitlist <= priorWaitlist,
    ),
    KpiEntry(
      label: l10n.analytics_kpi_rerolls_per_session,
      value: currRerolls.toStringAsFixed(1),
      contextLine: delta(currRerolls, priorIfComparable(priorRerolls), ''),
      deltaPositive: currRerolls <= priorRerolls,
    ),
  ];

  // A dash is neutral: it is neither a good nor a bad change.
  return [
    for (final e in entries)
      e.contextLine == noDelta
          ? KpiEntry(label: e.label, value: e.value, contextLine: noDelta)
          : e,
  ];
}

/// The games that the KPI and level cards can read for [range]: the range,
/// its prior period, and the two retention windows before its start. Older
/// games cannot change those results, so the page drops them first.
List<Game> gamesForRange(List<Game> games, DateRange range) {
  const retentionLookBack = Duration(days: _retentionWeeks * 7 * 2);
  final priorStart = range.priorPeriod.start;
  final retentionStart = range.start.subtract(retentionLookBack);
  final from = priorStart.isBefore(retentionStart)
      ? priorStart
      : retentionStart;
  return games.where((g) => !g.createdDate.isBefore(from)).toList();
}

Set<String> _playerIdsInRange(Iterable<Game> games, DateRange range) => games
    .where((g) => range.contains(g.createdDate))
    .expand((g) => g.playerIds)
    .toSet();

/// Share of the players seen in the 4 weeks before the 4 weeks ending at
/// [asOf] who were seen again in those last 4 weeks.
double? _retentionPct(List<Game> games, DateTime asOf) {
  const window = Duration(days: _retentionWeeks * 7);
  final recent = DateRange(asOf.subtract(window), asOf);
  final before = DateRange(recent.start.subtract(window), recent.start);
  final base = _playerIdsInRange(games, before);
  if (base.isEmpty) return null;
  final returned = base.intersection(_playerIdsInRange(games, recent));
  return returned.length / base.length * 100;
}

// ── ANA-03: Attendance trend ───────────────────────────────────────

class TrendResult {
  const TrendResult({required this.points, required this.note});
  final List<ChartPoint> points;
  final String note;
}

TrendResult computeAttendanceTrend(
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final points = _sessionsByDay(sessionLogs, range)
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.date, l10n),
          value: s.attendanceRate,
          valueLabel: '${(s.attendanceRate * 100).round()}%',
        ),
      )
      .toList();

  // Month over month: the last 4 weeks against the 4 weeks before them. The
  // earlier month can lie outside [range], so it reads every log.
  const month = Duration(days: 28);
  final recentMonth = DateRange(range.end.subtract(month), range.end);
  final previousMonth = DateRange(
    recentMonth.start.subtract(month),
    recentMonth.start,
  );
  final recent = _sessionsByDay(sessionLogs, recentMonth);
  final previous = _sessionsByDay(sessionLogs, previousMonth);
  if (recent.isEmpty || previous.isEmpty) {
    return TrendResult(
      points: points,
      note: l10n.analytics_not_enough_sessions,
    );
  }
  final recentAvg = recent.map((s) => s.attendanceRate).average;
  final previousAvg = previous.map((s) => s.attendanceRate).average;
  final growth = previousAvg == 0
      ? 0.0
      : (recentAvg - previousAvg) / previousAvg * 100;
  final sign = growth >= 0 ? '+' : '';
  return TrendResult(
    points: points,
    note: l10n.analytics_attendance_change('$sign${growth.toStringAsFixed(0)}'),
  );
}

// ── ANA-04: Waitlist pressure ──────────────────────────────────────

TrendResult computeWaitlistPressure(
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.date, l10n),
          value: s.waitlist.toDouble(),
          valueLabel: '${s.waitlist}',
        ),
      )
      .toList();
  if (points.isEmpty) {
    return TrendResult(
      points: points,
      note: l10n.analytics_not_enough_sessions,
    );
  }
  final avg = points.map((p) => p.value).average;
  final avgLabel = avg.toStringAsFixed(1);
  final note = avg >= 2.5
      ? l10n.analytics_waitlist_high(avgLabel)
      : l10n.analytics_waitlist_low(avgLabel);
  return TrendResult(points: points, note: note);
}

// ── ANA-05/06: Matchmaking fairness ────────────────────────────────

/// Per-session average of the courts' tier-gap. The log keeps no court
/// number, so this is the mean over the courts that held a game that day.
TrendResult computeLevelGapTrend(
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.date, l10n),
          value: s.averageTierGap,
          valueLabel: s.averageTierGap.toStringAsFixed(1),
        ),
      )
      .toList();
  if (points.length < 2) {
    return TrendResult(
      points: points,
      note: l10n.analytics_not_enough_sessions,
    );
  }
  final half = points.length ~/ 2;
  final firstHalf = points.take(half).map((p) => p.value).average;
  final secondHalf = points.skip(half).map((p) => p.value).average;
  return TrendResult(
    points: points,
    note: secondHalf < firstHalf
        ? l10n.analytics_level_gap_down
        : l10n.analytics_level_gap_up,
  );
}

class CourtGapSummary {
  const CourtGapSummary({
    required this.courtNumber,
    required this.averageGap,
    required this.isOverflowAbsorber,
  });
  final int courtNumber;

  /// Average tier-gap of this court over the range.
  final double averageGap;
  final bool isOverflowAbsorber;
}

/// A court is flagged only when it ran a wider gap on at least this many
/// sessions, so one odd night cannot flag it.
const _minSessionsToFlagCourt = 3;

/// ...and its average is above the club-wide average by this factor...
const _overflowGapFactor = 1.25;

/// ...and it was wider than its own session's average on at least this
/// share of the sessions it appeared in.
const _overflowConsistency = 0.6;

List<CourtGapSummary> computeCourtGapComparison(
  List<SessionLog> sessionLogs,
  DateRange range,
) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final gapsByCourt = <int, List<double>>{};
  final widerThanSession = <int, int>{};
  for (final s in sessions) {
    for (var i = 0; i < s.courtTierGaps.length; i++) {
      (gapsByCourt[i] ??= []).add(s.courtTierGaps[i]);
      if (s.courtTierGaps[i] > s.averageTierGap) {
        widerThanSession[i] = (widerThanSession[i] ?? 0) + 1;
      }
    }
  }
  if (gapsByCourt.isEmpty) return [];
  final overallAvg = gapsByCourt.values.expand((v) => v).average;
  return gapsByCourt.entries.sortedBy((e) => e.key).map((e) {
    final nights = e.value.length;
    final consistent =
        nights >= _minSessionsToFlagCourt &&
        (widerThanSession[e.key] ?? 0) / nights >= _overflowConsistency;
    final avg = e.value.average;
    return CourtGapSummary(
      courtNumber: e.key + 1,
      averageGap: avg,
      isOverflowAbsorber: consistent && avg > overallAvg * _overflowGapFactor,
    );
  }).toList();
}

// ── ANA-07: Court utilization ──────────────────────────────────────

class CourtUtilizationResult {
  const CourtUtilizationResult({
    required this.courts,
    required this.fullFillRatePct,
    required this.avgIdleCourtsPerSession,
  });

  /// One point per court: the share of sessions in which that court held a
  /// game when the session was saved.
  final List<ChartPoint> courts;

  /// Share of sessions where every court could be full-4 (checked-in
  /// players >= courts x 4).
  final double fullFillRatePct;

  /// Average courts without a game per session. This is a count, not a time:
  /// the log has no court start and end times.
  final double avgIdleCourtsPerSession;
}

CourtUtilizationResult computeCourtUtilization(
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final sessions = _sessionsByDay(sessionLogs, range);
  final courtTotal = sessions.map((s) => s.courtCount).maxOrNull ?? 0;
  // The log has no court number: court N is the Nth court that held a game.
  final courts = [
    for (var i = 0; i < courtTotal; i++)
      () {
        final existing = sessions.where((s) => s.courtCount > i);
        final rate =
            existing.where((s) => s.usedCourts > i).length / existing.length;
        return ChartPoint(
          label: l10n.court_n(i + 1),
          value: rate,
          valueLabel: '${(rate * 100).round()}%',
        );
      }(),
  ];
  final fullFillRate = sessions.isEmpty
      ? 0.0
      : sessions.where((s) => s.fillRate >= 1.0).length / sessions.length * 100;
  final avgIdle = sessions.isEmpty
      ? 0.0
      : sessions.map((s) => s.idleCourts.toDouble()).average;
  return CourtUtilizationResult(
    courts: courts,
    fullFillRatePct: fullFillRate,
    avgIdleCourtsPerSession: avgIdle,
  );
}

// ── ANA-08: Re-rolls per session ───────────────────────────────────

TrendResult computeRerollsPerSession(
  List<SessionLog> sessionLogs,
  DateRange range, {
  required AppLocalizations l10n,
}) {
  final sessions = _sessionsByDay(sessionLogs, range);
  if (sessions.isEmpty) {
    return TrendResult(
      points: const [],
      note: l10n.analytics_not_enough_sessions,
    );
  }
  final points = sessions
      .map(
        (s) => ChartPoint(
          label: _shortDate(s.date, l10n),
          value: s.rerolls.toDouble(),
          valueLabel: '${s.rerolls}',
        ),
      )
      .toList();
  // A spike is a night with more re-rolls than average. It counts as
  // high-attendance or high-spread when it is above the average too.
  final avgRerolls = sessions.map((s) => s.rerolls).average;
  final avgAttendance = sessions.map((s) => s.attendanceRate).average;
  final avgGap = sessions.map((s) => s.averageTierGap).average;
  final spikes = sessions.where((s) => s.rerolls > avgRerolls).toList();
  final highAttendance = spikes.any((s) => s.attendanceRate > avgAttendance);
  final highSpread = spikes.any((s) => s.averageTierGap > avgGap);
  final note = switch ((highAttendance, highSpread)) {
    (true, true) => l10n.analytics_reroll_spikes_both,
    (true, false) => l10n.analytics_reroll_spikes_attendance,
    (false, true) => l10n.analytics_reroll_spikes,
    (false, false) => l10n.analytics_reroll_steady,
  };
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
    required this.trendNote,
    required this.stagnationNote,
  });
  final List<ChartPoint> points;
  final String medianTierLabel;

  /// Whether the active players skew to higher or lower tiers than in the
  /// prior period. Null when either period has no games.
  final String? trendNote;
  final String? stagnationNote;
}

/// Sessions a player must attend in the range to be called stagnant.
const _stagnationSessions = 6;

/// Change in the mean tier index of the active players that counts as a
/// trend rather than steady.
const _tierTrendThreshold = 0.1;

LevelDistributionResult computeLevelDistribution(
  List<Player> allPlayers,
  List<Game> games,
  DateRange range, {
  required Player? Function(String id) resolvePlayer,
  required AppLocalizations l10n,
}) {
  final points = SkillTier.values
      .map(
        (tier) => ChartPoint(
          label: tier.localizedLabel(l10n),
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
    medianLabel = SkillTier.values[mid].localizedLabel(l10n);
  }

  // Trend: the club keeps no tier history (a Game stores player ids only,
  // ADR-0001), so progress cannot be measured. The closest honest signal is
  // who plays: the mean current tier of the players active in this range
  // against the prior range.
  double? meanTier(DateRange window) {
    final tiers = _playerIdsInRange(
      games,
      window,
    ).map(resolvePlayer).nonNulls.map((p) => p.elo.skillTier.index);
    return tiers.isEmpty ? null : tiers.average;
  }

  final current = meanTier(range);
  final before = meanTier(range.priorPeriod);
  String? trendNote;
  if (current != null && before != null) {
    final change = current - before;
    trendNote = change > _tierTrendThreshold
        ? l10n.analytics_level_trend_up
        : change < -_tierTrendThreshold
        ? l10n.analytics_level_trend_down
        : l10n.analytics_level_trend_flat;
  }

  // Stagnation: players with 6+ sessions (days) in the range. With no tier
  // history, "tier unchanged" cannot be checked, so a tier change is not
  // detected.
  // A day is an int key (yyyymmdd): cheaper to hash than a DateTime.
  final sessionsByPlayer = <String, Set<int>>{};
  for (final g in games.where((g) => range.contains(g.createdDate))) {
    final d = g.createdDate;
    final day = d.year * 10000 + d.month * 100 + d.day;
    for (final id in g.playerIds) {
      (sessionsByPlayer[id] ??= {}).add(day);
    }
  }
  sessionsByPlayer.removeWhere((id, _) => resolvePlayer(id) == null);
  final stagnantCount = sessionsByPlayer.values
      .where((days) => days.length >= _stagnationSessions)
      .length;

  return LevelDistributionResult(
    points: points,
    medianTierLabel: medianLabel,
    trendNote: trendNote,
    stagnationNote: stagnantCount > 0
        ? l10n.analytics_stagnation(stagnantCount)
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
    // One visit per session day: two games on one day count once.
    final dates =
        byPlayerId[player.id]
            ?.map((r) => _dateOnly(r.$2))
            .toSet()
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

enum MixingTag { connector, clique, isolated }

class MixingEntry {
  const MixingEntry({
    required this.name,
    required this.score,
    required this.tag,
  });
  final String name;
  final double score;
  final MixingTag? tag;
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
    MixingTag? tag;
    if (score >= 0.7) {
      tag = MixingTag.connector;
    } else if (score <= 0.2) {
      tag = MixingTag.isolated;
    } else if (score <= 0.4) {
      tag = MixingTag.clique;
    }
    result.add(MixingEntry(name: nameOf(player), score: score, tag: tag));
  }
  return result.sortedBy<num>((e) => -e.score);
}

/// The players the mixing card lists. [sorted] is highest score first. Over
/// [size] players, it keeps the top and bottom halves, so the isolated
/// players are not cut off.
List<MixingEntry> sampleMixing(List<MixingEntry> sorted, {int size = 10}) {
  if (sorted.length <= size) return sorted;
  final half = size ~/ 2;
  return [...sorted.take(half), ...sorted.skip(sorted.length - half)];
}

// ── ANA-13: New player integration ─────────────────────────────────

/// A player counts as "new" for this many days after joining. There is no
/// setting for it yet (UAT: "the configured new window").
const kNewPlayerWindowDays = 60;

/// A player is a "regular" at this many logged games.
const _regularGameCount = 8;

class NewPlayerEntry {
  const NewPlayerEntry({
    required this.name,
    required this.joinDate,
    required this.sessionsAttended,
    required this.pctWithRegulars,
  });
  final String name;
  final DateTime joinDate;

  /// Distinct days the player played in the range.
  final int sessionsAttended;
  final double pctWithRegulars;
  bool get isFavorable => pctWithRegulars >= 50;

  /// A player with no games in the range has no mix to judge.
  bool get needsAttention => sessionsAttended > 0 && !isFavorable;
}

/// New players are those who joined in the [newWindowDays] before
/// [range] ends. Their sessions and mix are measured on games in [range];
/// regulars are found from all [games].
List<NewPlayerEntry> computeNewPlayerIntegration(
  List<Game> games,
  List<Player> allPlayers, {
  required DateRange range,
  int newWindowDays = kNewPlayerWindowDays,
}) {
  final regularIds = _regularPlayerIds(games);

  final newPlayers = allPlayers.where(
    (p) =>
        p.createdDate != null &&
        range.end.difference(p.createdDate!).inDays <= newWindowDays,
  );

  // Index games by player once. A scan of all games for each new player
  // costs players × games (PERSISTENCE.md §3.2).
  final newIds = {for (final p in newPlayers) p.id};
  final gamesByPlayerId = <String, List<Game>>{};
  for (final g in games.where((g) => range.contains(g.createdDate))) {
    for (final id in g.playerIds.toSet()) {
      if (newIds.contains(id)) (gamesByPlayerId[id] ??= <Game>[]).add(g);
    }
  }

  return newPlayers
      .map((player) {
        final playerGames = gamesByPlayerId[player.id] ?? const <Game>[];
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
          sessionsAttended: playerGames
              .map((g) => _dateOnly(g.createdDate))
              .toSet()
              .length,
          pctWithRegulars: pct,
        );
      })
      .sortedBy((e) => e.joinDate)
      .toList();
}

/// Players who appear in at least [_regularGameCount] logged games are
/// "regulars" for new-player integration (ANA-13).
Set<String> _regularPlayerIds(List<Game> games) {
  final counts = <String, int>{};
  for (final g in games) {
    for (final id in g.playerIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts.entries
      .where((e) => e.value >= _regularGameCount)
      .map((e) => e.key)
      .toSet();
}

String _shortDate(DateTime d, AppLocalizations l10n) =>
    l10n.analytics_short_date(d.month, d.day);
