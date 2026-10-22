import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/player_display.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/analytics/analytics_engine.dart';
import 'package:good_bad_board/features/analytics/at_risk_players.dart';
import 'package:good_bad_board/features/analytics/attendance_chart.dart';
import 'package:good_bad_board/features/analytics/court_gap_comparison.dart';
import 'package:good_bad_board/features/analytics/court_utilization.dart';
import 'package:good_bad_board/features/analytics/kpi_strip.dart';
import 'package:good_bad_board/features/analytics/level_distribution.dart';
import 'package:good_bad_board/features/analytics/level_gap_trend.dart';
import 'package:good_bad_board/features/analytics/new_player_integration.dart';
import 'package:good_bad_board/features/analytics/player_mixing.dart';
import 'package:good_bad_board/features/analytics/reroll_chart.dart';
import 'package:good_bad_board/features/analytics/session_history_list.dart';
import 'package:good_bad_board/features/analytics/waitlist_pressure_chart.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';

/// The Analytics tab — KPI strip, time-range switcher, and the full set of
/// attendance / fairness / court / player-health charts (ANA-01…14).
///
/// Sources data from persisted [GameRepository] and [SessionLogRepository]
/// entries (not the in-memory, per-app-run `GameData.history`) so trends
/// survive app restarts.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key, this.showHiddenCards = false});

  /// ANA-06 (court fairness) and ANA-12 (player mixing) are hidden for this
  /// release. The engine and cards stay; tests turn this on.
  final bool showHiddenCards;

  /// How many times any page computed its results. Tests read it.
  @visibleForTesting
  static int debugRecomputeCount = 0;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedWeeks = 12;

  /// Results for the selected range. Null until the tab is first opened.
  _AnalyticsResults? _results;

  /// Whether this tab is on screen. The shell keeps hidden tabs alive and
  /// turns their tickers off.
  bool _tabActive = false;

  /// Whether the data or the language changed since the last recompute.
  bool _stale = true;
  Locale? _locale;

  /// Fires after every write to either repository — persisted games and
  /// session logs are read fresh whenever they change, even though the
  /// Analytics route (a StatefulShellRoute branch) survives tab switches.
  late final Listenable _persistedDataChanges = Listenable.merge([
    GameRepository.instance.listenable,
    SessionLogRepository.instance.listenable,
  ]);

  @override
  void initState() {
    super.initState();
    _persistedDataChanges.addListener(_reload);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not initState: _recompute reads AppLocalizations.of(context), which
    // Flutter forbids before initState has completed.
    _tabActive = TickerMode.valuesOf(context).enabled;
    final locale = Localizations.localeOf(context);
    if (locale != _locale) {
      _locale = locale;
      _stale = true;
    }
    if (_tabActive && _stale) _recompute();
  }

  @override
  void dispose() {
    _persistedDataChanges.removeListener(_reload);
    super.dispose();
  }

  /// A save on another tab (Save, Rotate now) only marks the results stale.
  /// They are recomputed when this tab opens, so the Dashboard does not
  /// wait for the charts.
  void _reload() {
    if (!_tabActive) {
      _stale = true;
      return;
    }
    setState(_recompute);
  }

  void _selectRange(int weeks) => setState(() {
    _selectedWeeks = weeks;
    _recompute();
  });

  /// Computes every card once per data, range or language change, never on
  /// a plain rebuild. Reads are synchronous map lookups, so no loading
  /// spinner is needed.
  void _recompute() {
    AnalyticsPage.debugRecomputeCount++;
    _stale = false;
    final l10n = AppLocalizations.of(context)!;
    final range = DateRange.lastWeeks(_selectedWeeks);
    final playableGames = GameRepository.instance
        .getAll()
        .where((g) => g.playerIds.isNotEmpty)
        .toList();
    // Only the windows the cards read: the range, the prior period and the
    // retention look-back. Older games cannot change the results.
    final games = gamesForRange(playableGames, range);
    final logs = SessionLogRepository.instance.getAll().toList();
    final allPlayers = PlayerRepository.instance.listedPlayers().toList();
    final gamesInRange = games
        .where((g) => range.contains(g.createdDate))
        .toList();
    _results = _AnalyticsResults(
      // The Members tile comes first; it does not follow the range
      // (R13-Q10).
      kpis: [
        computeMembersKpi(allPlayers, l10n: l10n),
        ...computeKpis(games, logs, range, l10n: l10n),
      ],
      attendance: computeAttendanceTrend(logs, range, l10n: l10n),
      waitlist: computeWaitlistPressure(logs, range, l10n: l10n),
      levelGapTrend: computeLevelGapTrend(logs, range, l10n: l10n),
      courtGaps: computeCourtGapComparison(logs, range),
      courtUtilization: computeCourtUtilization(logs, range, l10n: l10n),
      rerolls: computeRerollsPerSession(logs, range, l10n: l10n),
      levelDistribution: computeLevelDistribution(
        allPlayers,
        games,
        range,
        resolvePlayer: PlayerRepository.instance.byId,
        l10n: l10n,
      ),
      atRisk: computeAtRiskPlayers(gamesInRange, allPlayers, now: range.end),
      mixing: widget.showHiddenCards
          ? computePlayerMixing(
              gamesInRange,
              resolvePlayer: PlayerRepository.instance.byId,
              nameOf: (p) => playerDisplayName(p, l10n),
            )
          : const [],
      // "Regular" counts games over the whole history, so this one gets
      // every game.
      newPlayers: computeNewPlayerIntegration(
        playableGames,
        allPlayers,
        range: range,
      ),
      recentGames: gamesInRange
          .sortedBy((g) => g.createdDate)
          .reversed
          .take(SessionHistoryList.defaultLimit)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    // Hidden and never opened: nothing to show yet.
    if (results == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    final cards = <Widget>[
      AttendanceChart(result: results.attendance),
      WaitlistPressureChart(result: results.waitlist),
      LevelGapTrendChart(result: results.levelGapTrend),
      if (widget.showHiddenCards)
        CourtGapComparisonCard(courts: results.courtGaps),
      CourtUtilizationCard(result: results.courtUtilization),
      RerollChart(result: results.rerolls),
      LevelDistributionCard(result: results.levelDistribution),
      AtRiskPlayersCard(result: results.atRisk),
      if (widget.showHiddenCards) PlayerMixingCard(entries: results.mixing),
      NewPlayerIntegrationCard(entries: results.newPlayers),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: title + range switcher (ANA-01) ─────────
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = isPhone(MediaQuery.sizeOf(context).width);
              final title = AppSectionTitle(title: l10n.analytics_title);
              final switcher = AnalyticsRangeSwitcher(
                selectedWeeks: _selectedWeeks,
                onChanged: _selectRange,
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.sm),
                    switcher,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [title, switcher],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── KPI strip (ANA-02) ───────────────────────────────
          KpiStrip(kpis: results.kpis),
          const SizedBox(height: AppSpacing.lg),

          // ── Chart grid: two cards per row (ANA-03…13) ────────
          // Hidden cards are left out, so the rest are chunked in pairs and
          // no row is left with a hole.
          for (final row in _pairs(cards)) ...[
            _ChartRow(children: row),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Session history: per-game drill-down ─────────────
          SessionHistoryList(games: results.recentGames),
        ],
      ),
    );
  }
}

/// Everything the cards show, for one range.
class _AnalyticsResults {
  const _AnalyticsResults({
    required this.kpis,
    required this.attendance,
    required this.waitlist,
    required this.levelGapTrend,
    required this.courtGaps,
    required this.courtUtilization,
    required this.rerolls,
    required this.levelDistribution,
    required this.atRisk,
    required this.mixing,
    required this.newPlayers,
    required this.recentGames,
  });

  final List<KpiEntry> kpis;
  final TrendResult attendance;
  final TrendResult waitlist;
  final TrendResult levelGapTrend;
  final List<CourtGapSummary> courtGaps;
  final CourtUtilizationResult courtUtilization;
  final TrendResult rerolls;
  final LevelDistributionResult levelDistribution;
  final AtRiskResult atRisk;
  final List<MixingEntry> mixing;
  final List<NewPlayerEntry> newPlayers;

  /// The most recent games in the range, newest first.
  final List<Game> recentGames;
}

List<List<Widget>> _pairs(List<Widget> cards) => [
  for (var i = 0; i < cards.length; i += 2)
    cards.sublist(i, i + 2 > cards.length ? cards.length : i + 2),
];

/// A responsive row of chart cards — side by side on desktop, one column on
/// tablet and phone, per ANA-14.
class _ChartRow extends StatelessWidget {
  const _ChartRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isDesktop(MediaQuery.sizeOf(context).width)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1)
                  const SizedBox(width: AppSpacing.lg),
              ],
            ],
          ),
        );
      },
    );
  }
}
