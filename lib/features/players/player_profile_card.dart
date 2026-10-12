import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';

/// Summary statistics for a player's expandable profile card.
///
/// Callers compute these from persisted history (see
/// `computePlayerProfileStats`) and pass them in as a snapshot — the profile card itself is a pure presentational widget.
class PlayerProfileStats {
  const PlayerProfileStats({
    required this.matchCount,
    required this.diversityPercent,
    required this.levelHistory,
    required this.topPartners,
    required this.attendanceSummary,
  });

  /// Total number of games the player has participated in.
  final int matchCount;

  /// Distinct partners played with, as a whole percent of the other players
  /// on the roster (0–100).
  final int diversityPercent;

  /// Recent level trend ordered chronologically (oldest first). Each entry
  /// is the [Elo] value the player held at that point.
  final List<Elo> levelHistory;

  /// Up to 3 most frequent partners, sorted by count descending.
  final List<PartnerEntry> topPartners;

  /// Human-readable attendance summary, e.g. "Attended 12 of last 20 sessions".
  final String attendanceSummary;
}

/// A single partner name + game-count pair for the profile card.
class PartnerEntry {
  const PartnerEntry(this.name, this.count);
  final String name;
  final int count;
}

/// Expandable profile card displayed below a [PlayerRow].
///
/// Shows:
/// - Membership label + close button
/// - Stat trio: Current Level | Matches | Diversity
/// - Level progression sparkline
/// - Most frequent partners list
/// - Attendance history text
///
/// Has no card chrome of its own: the Players page shows it inside the same
/// rounded panel as its [PlayerRow], so the row and the profile read as one
/// accordion item.
class PlayerProfileCard extends StatelessWidget {
  const PlayerProfileCard({
    super.key,
    required this.player,
    required this.stats,
    this.membership = MembershipStatus.member,
    this.onClose,
    this.onDelete,
  });

  final Player player;
  final PlayerProfileStats stats;
  final MembershipStatus membership;
  final VoidCallback? onClose;

  /// Called when the delete ("remove from club") action is tapped.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────
          Row(
            children: [
              // Membership badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: switch (membership) {
                    MembershipStatus.member => AppColors.pillBg,
                    MembershipStatus.casual => AppColors.warningBg,
                    MembershipStatus.disabled => AppColors.toggleOff,
                  },
                  borderRadius: AppRadii.fullRadius,
                ),
                child: Text(
                  membership.localizedLabel(l10n),
                  style: AppTypography.chip.copyWith(
                    color: switch (membership) {
                      MembershipStatus.member => AppColors.success,
                      MembershipStatus.casual => AppColors.warningText,
                      MembershipStatus.disabled => AppColors.toggleOffText,
                    },
                  ),
                ),
              ),
              const Spacer(),
              // Delete button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: AppRadii.smRadius,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              // Close button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: AppRadii.smRadius,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Stat Trio ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_current_level,
                  value: player.elo.toDisplayName(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_matches,
                  value: '${stats.matchCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTrioCell(
                  label: l10n.players_diversity,
                  value: '${stats.diversityPercent}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Level Progression Sparkline ─────────────────
          if (stats.levelHistory.isNotEmpty) ...[
            _SectionLabel(l10n.players_level_progression),
            const SizedBox(height: AppSpacing.sm),
            _LevelSparkline(history: stats.levelHistory),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Partners + Attendance ───────────────────────
          if (stats.topPartners.isNotEmpty) ...[
            _SectionLabel(l10n.players_most_frequent_partners),
            const SizedBox(height: AppSpacing.sm),
            ...stats.topPartners.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name, style: AppTypography.body)),
                    Text('${p.count}', style: AppTypography.helperBold),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Attendance ───────────────────────────────────
          if (stats.attendanceSummary.isNotEmpty) ...[
            _SectionLabel(l10n.players_attendance),
            const SizedBox(height: AppSpacing.sm),
            Text(stats.attendanceSummary, style: AppTypography.body),
          ],
        ],
      ),
    );
  }
}

/// A label/value pair within the stat trio section of [PlayerProfileCard].
///
/// Value: 18–20px, 800. Label: 10px, 700, uppercase, muted.
class _StatTrioCell extends StatelessWidget {
  const _StatTrioCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

/// Horizontal sparkline showing recent Elo level trend as coloured bars.
///
/// Each bar represents one historical data point; the bar colour indicates the
/// Elo tier using [AppColors.accentPrimary] luminance variants.
class _LevelSparkline extends StatelessWidget {
  const _LevelSparkline({required this.history});

  final List<Elo> history;

  /// Map the 8 Elo tiers to progressively darker accent shades.
  static final List<Color> _tierColors = [
    // c2 (lowest) → lightest
    AppColors.barTertiary,
    const Color(0xFFFDC4A0),
    const Color(0xFFFDA876),
    const Color(0xFFFD8D4D),
    AppColors.accentPrimary,
    const Color(0xFFCC5522),
    const Color(0xFF994019),
    // s1 (highest) → darkest
    AppColors.headerBg,
  ];

  @override
  Widget build(BuildContext context) {
    // Show at most the last 20 data points
    final subset = history.length > 20
        ? history.sublist(history.length - 20)
        : history;
    final maxIndex = Elo.values.length - 1;
    if (maxIndex <= 0) return const SizedBox(height: 40);

    return SizedBox(
      height: 40,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          values: subset.map((e) => e.index / maxIndex).toList(),
          colors: subset
              .map((e) => _tierColors[e.index.clamp(0, _tierColors.length - 1)])
              .toList(),
        ),
      ),
    );
  }
}

/// Paints a small bar chart with a connecting polyline overlay.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.colors});

  final List<double> values; // 0.0 – 1.0
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final barWidth = ((size.width / values.length) - 2).clamp(0.0, size.width);
    const barRadius = 3.0;
    final maxBarHeight = size.height * 0.8;

    for (var i = 0; i < values.length; i++) {
      final barHeight = (values[i] * 0.6 + 0.4) * maxBarHeight;
      final x = i * (barWidth + 2) + 1;
      final y = size.height - barHeight;

      final paint = Paint()..color = colors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(barRadius),
        ),
        paint,
      );
    }

    // Connecting polyline
    if (values.length < 2) return;

    final linePaint = Paint()
      ..color = AppColors.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final barHeight = (values[i] * 0.6 + 0.4) * maxBarHeight;
      final x = i * (barWidth + 2) + 1 + barWidth / 2;
      final y = size.height - barHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Endpoint dot
    if (values.isNotEmpty) {
      final lastBarHeight = (values.last * 0.6 + 0.4) * maxBarHeight;
      final lastX = (values.length - 1) * (barWidth + 2) + 1 + barWidth / 2;
      final lastY = size.height - lastBarHeight;

      canvas.drawCircle(
        Offset(lastX, lastY),
        3.5,
        Paint()..color = AppColors.accentPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      !listEquals(oldDelegate.values, values) ||
      !listEquals(oldDelegate.colors, colors);
}

/// Small uppercase section label used within [PlayerProfileCard].
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTypography.statLabel);
  }
}
