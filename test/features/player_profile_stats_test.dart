import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';

Player _p(String name, [Elo elo = Elo.b1]) =>
    Player(firstName: name, lastName: 'T', elo: elo, id: name);

Game _game(List<Player> players, DateTime at) => Game(
  playerIds: players.map((p) => p.id).toList(),
  id: '${players.map((p) => p.id).join()}$at',
  createdDate: at,
);

SessionLog _log(DateTime at) => SessionLog(
  id: 'log$at',
  loggedAt: at,
  capacity: 20,
  checkedInCount: 8,
  waitlistCount: 0,
  rerollCount: 0,
  courtLevelGaps: const [0],
  courtCount: 2,
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final me = _p('Me');
  final others = [for (final n in 'ABCDEFGHI'.split('')) _p(n)];
  final roster = [me, ...others]; // 9 possible partners

  PlayerProfileStats compute(List<Game> games, List<SessionLog> logs) =>
      computePlayerProfileStats(
        player: me,
        games: games,
        logs: logs,
        roster: roster,
        l10n: l10n,
      );

  final day1 = DateTime(2026, 10, 1, 19);
  final day2 = DateTime(2026, 10, 8, 19);

  test('should_return_zero_stats_when_no_persisted_games', () {
    final stats = compute([], []);

    expect(stats.matchCount, 0);
    expect(stats.diversityPercent, 0);
    expect(stats.topPartners, isEmpty);
    expect(stats.attendanceSummary, 'No sessions logged yet');
  });

  test('should_count_only_games_the_player_is_in', () {
    final stats = compute(
      [
        _game([me, others[0], others[1], others[2]], day1),
        _game([others[3], others[4], others[5], others[6]], day1),
      ],
      [_log(day1)],
    );

    expect(stats.matchCount, 1);
  });

  test(
    'should_define_diversity_as_distinct_partners_over_possible_partners',
    () {
      // Partners A, B, C, D = 4 distinct of 9 possible -> 44%.
      final stats = compute(
        [
          _game([me, others[0], others[1], others[2]], day1),
          _game([me, others[0], others[1], others[3]], day2),
        ],
        [_log(day1), _log(day2)],
      );

      expect(stats.diversityPercent, 44);
    },
  );

  test('should_reach_100_percent_when_player_met_every_other_player', () {
    final stats = computePlayerProfileStats(
      player: me,
      games: [
        _game([me, others[0], others[1], others[2]], day1),
      ],
      logs: [_log(day1)],
      roster: [me, others[0], others[1], others[2]],
      l10n: l10n,
    );

    expect(stats.diversityPercent, 100);
  });

  test('should_list_at_most_three_top_partners_most_frequent_first', () {
    final stats = compute(
      [
        _game([me, others[0], others[1], others[2]], day1),
        _game([me, others[0], others[1], others[3]], day1),
        _game([me, others[0], others[4], others[5]], day2),
      ],
      [_log(day1), _log(day2)],
    );

    expect(stats.topPartners, hasLength(3));
    expect(stats.topPartners.first.name, 'A T');
    expect(stats.topPartners.first.count, 3);
    expect(stats.topPartners[1].name, 'B T');
  });

  test('should_summarise_attendance_as_days_played_over_days_logged', () {
    final stats = compute(
      [
        _game([me, others[0], others[1], others[2]], day1),
        _game([others[3], others[4], others[5], others[6]], day2),
      ],
      [_log(day1), _log(day2)],
    );

    expect(stats.attendanceSummary, 'Attended 1 of 2 sessions');
  });

  test('should_fold_two_logs_on_one_day_into_one_session', () {
    final stats = compute(
      [
        _game([me, others[0], others[1], others[2]], day1),
      ],
      [_log(day1), _log(day1.add(const Duration(hours: 1)))],
    );

    expect(stats.attendanceSummary, 'Attended 1 of 1 session');
  });

  test('should_have_one_level_history_entry_per_game', () {
    final stats = compute(
      [
        _game([me, others[0], others[1], others[2]], day2),
        _game([me, others[0], others[1], others[2]], day1),
      ],
      [_log(day1), _log(day2)],
    );

    expect(stats.levelHistory, hasLength(2));
  });
}
