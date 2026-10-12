import 'package:collection/collection.dart';
import 'package:good_bad_board/features/players/player_profile_card.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';

/// Most frequent partners shown in the profile (PLY-09).
const int maxTopPartners = 3;

/// Builds the [PlayerProfileStats] of [player] from persisted history only
/// (PLY-12): [games] from `GameRepository` and [logs] from
/// `SessionLogRepository`. The live court state is never read, so a re-roll
/// or check-in changes nothing here until the round is saved.
///
/// - Matches: persisted games that hold the player.
/// - Diversity %: distinct other players met in those games, divided by the
///   number of other players in [roster], rounded. 0 when the roster has no
///   other player.
/// - Top partners: up to [maxTopPartners] others met most often. Every other
///   player in a game counts, as a game does not record who partnered whom.
/// - Attendance: a session is one calendar day with a saved log, as on the
///   Analytics tab. The player attended a session when a saved game of that
///   day holds them.
/// - Level history: the player's current level for each game, oldest game
///   first (no per-game level is stored).
PlayerProfileStats computePlayerProfileStats({
  required Player player,
  required Iterable<Game> games,
  required Iterable<SessionLog> logs,
  required Iterable<Player> roster,
  required AppLocalizations l10n,
}) {
  final others = {
    for (final p in roster)
      if (p.id != player.id) p.id: p,
  };
  final played = games
      .where((g) => g.playerIds.contains(player.id))
      .sortedBy((g) => g.createdDate)
      .toList();

  final partnerCounts = <String, int>{};
  for (final game in played) {
    for (final id in game.playerIds) {
      if (others.containsKey(id)) {
        partnerCounts[id] = (partnerCounts[id] ?? 0) + 1;
      }
    }
  }
  final diversityPercent = others.isEmpty
      ? 0
      : (partnerCounts.length * 100 / others.length).round();
  final topPartners = partnerCounts.entries
      .sortedBy<num>((e) => -e.value)
      .take(maxTopPartners)
      .map((e) => PartnerEntry(others[e.key]!.name(), e.value))
      .toList();

  final sessionDays = logs.map((l) => _day(l.loggedAt)).toSet();
  final attendedDays = played
      .map((g) => _day(g.createdDate))
      .where(sessionDays.contains)
      .toSet();

  return PlayerProfileStats(
    matchCount: played.length,
    diversityPercent: diversityPercent,
    levelHistory: [for (final _ in played) player.elo],
    topPartners: topPartners,
    attendanceSummary: sessionDays.isEmpty
        ? l10n.players_no_session_data
        : l10n.players_attended_sessions(
            attendedDays.length,
            sessionDays.length,
          ),
  );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
