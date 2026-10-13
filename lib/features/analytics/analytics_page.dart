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
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';
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
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedWeeks = 12;
  late DateRange _range;
  List<Game> _games = [];
  List<SessionLog> _sessionLogs = [];
  List<Player> _allPlayers = [];

  // Results that need the resolved roster or an O(players × games) pass —
  // computePlayerMixing in particular. They follow the selected range, so
  // they are recomputed when the data reloads or the range changes, not on
  // every rebuild.
  AtRiskResult _atRisk = const AtRiskResult(entries: []);
  List<MixingEntry> _mixing = const [];
  List<NewPlayerEntry> _newPlayers = const [];

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
    _recompute();
  }

  @override
  void dispose() {
    _persistedDataChanges.removeListener(_reload);
    super.dispose();
  }

  void _reload() => setState(_recompute);

  void _selectRange(int weeks) => setState(() {
    _selectedWeeks = weeks;
    _recompute();
  });

  /// Reads are synchronous map lookups, so this can run directly from
  /// [didChangeDependencies] — no loading spinner is ever needed.
  void _recompute() {
    final playableGames = GameRepository.instance
        .getAll()
        .where((g) => g.playerIds.isNotEmpty)
        .toList();
    final logs = SessionLogRepository.instance.getAll().toList();
    final allPlayers = PlayerRepository.instance.listedPlayers().toList();
    final l10n = AppLocalizations.of(context)!;
    _games = playableGames;
    _sessionLogs = logs;
    _allPlayers = allPlayers;
    _range = DateRange.lastWeeks(_selectedWeeks);
    final gamesInRange = playableGames
        .where((g) => _range.contains(g.createdDate))
        .toList();
    _atRisk = computeAtRiskPlayers(gamesInRange, allPlayers, now: _range.end);
    _mixing = computePlayerMixing(
      gamesInRange,
      resolvePlayer: PlayerRepository.instance.byId,
      nameOf: (p) => playerDisplayName(p, l10n),
    );
    _newPlayers = computeNewPlayerIntegration(
      playableGames,
      allPlayers,
      range: _range,
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    final l10n = AppLocalizations.of(context)!;

    final kpis = computeKpis(_games, _sessionLogs, range, l10n: l10n);
    final attendance = computeAttendanceTrend(_sessionLogs, range, l10n: l10n);
    final waitlist = computeWaitlistPressure(_sessionLogs, range, l10n: l10n);
    final levelGapTrend = computeLevelGapTrend(_sessionLogs, range, l10n: l10n);
    final courtGaps = computeCourtGapComparison(_sessionLogs, range);
    final courtUtilization = computeCourtUtilization(
      _sessionLogs,
      range,
      l10n: l10n,
    );
    final rerolls = computeRerollsPerSession(_sessionLogs, range, l10n: l10n);
    final levelDistribution = computeLevelDistribution(
      _allPlayers,
      _games,
      range,
      resolvePlayer: PlayerRepository.instance.byId,
      l10n: l10n,
    );
    final gamesInRange = _games
        .where((g) => range.contains(g.createdDate))
        .toList();

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
          KpiStrip(kpis: kpis),
          const SizedBox(height: AppSpacing.lg),

          // ── Row 1: Attendance + Waitlist (ANA-03/04) ─────────
          _ChartRow(
            children: [
              AttendanceChart(result: attendance),
              WaitlistPressureChart(result: waitlist),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Row 2: Level gap trend + court fairness (ANA-05/06) ─
          _ChartRow(
            children: [
              LevelGapTrendChart(result: levelGapTrend),
              CourtGapComparisonCard(courts: courtGaps),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Row 3: Court utilization + re-rolls (ANA-07/08) ──
          _ChartRow(
            children: [
              CourtUtilizationCard(result: courtUtilization),
              RerollChart(result: rerolls),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Row 4: Level distribution + at-risk (ANA-09/11) ──
          _ChartRow(
            children: [
              LevelDistributionCard(result: levelDistribution),
              AtRiskPlayersCard(result: _atRisk),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Row 5: Player mixing + new-player integration (ANA-12/13) ─
          _ChartRow(
            children: [
              PlayerMixingCard(entries: _mixing),
              NewPlayerIntegrationCard(entries: _newPlayers),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Session history: per-game drill-down ─────────────
          SessionHistoryList(games: gamesInRange),
        ],
      ),
    );
  }
}

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
