import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/player_display.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:good_bad_board/model/game.dart';

/// A read-only list of individual logged games (most recent first) within
/// the selected time range — the per-session drill-down that the old
/// PlayerStatisticPage used to provide before the Analytics tab replaced it.
class SessionHistoryList extends StatelessWidget {
  const SessionHistoryList({super.key, required this.games, this.limit = 30});

  /// Games to display, in any order — sorted descending internally.
  final List<Game> games;

  /// Maximum number of most-recent games to render.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final sorted = games.sortedBy((g) => g.createdDate).reversed.take(limit);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(title: l10n.analytics_session_history),
          const SizedBox(height: AppSpacing.md),
          if (sorted.isEmpty)
            Text(
              l10n.analytics_no_sessions_logged,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSubtle,
              ),
            )
          else
            for (final game in sorted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(game.createdDate, l10n.localeName),
                      style: AppTypography.helperBold,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.players
                          .map((p) => playerDisplayName(p, l10n))
                          .join(', '),
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d, String locale) =>
      '${DateFormat.yMd(locale).format(d)} · ${DateFormat.Hm(locale).format(d)}';
}
