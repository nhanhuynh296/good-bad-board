import 'dart:math';

import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// COURT-02 / COURT-03: a re-roll picks the lowest level gap among several
/// random combinations, and does nothing when nobody can be rotated in.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('reroll_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<List<Player>> playersWith(List<Elo> levels) async {
    final players = [
      for (var i = 0; i < levels.length; i++)
        Player.create(firstName: 'P', lastName: '$i', elo: levels[i]),
    ];
    await PlayerRepository.instance.addAll(players);
    return players;
  }

  Future<GameData> oneCourt(List<Player> players, {int seed = 1}) async {
    final gameData = GameData(random: Random(seed))..setNumberOfCourt(1);
    for (final player in players) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    return gameData;
  }

  int tierGap(Iterable<Player> players) {
    final tiers = players.map((p) => p.elo.skillTier.index);
    return tiers.reduce(max) - tiers.reduce(min);
  }

  test(
    'should_pick_lowest_level_gap_when_pool_has_many_combinations',
    () async {
      // Arrange — four amateurs and two professionals: only one 4-player
      // combination has a tier gap of zero.
      final players = await playersWith([
        Elo.c2,
        Elo.c2,
        Elo.c1,
        Elo.c1,
        Elo.s2,
        Elo.s1,
      ]);

      for (var seed = 0; seed < 5; seed++) {
        final gameData = await oneCourt(players, seed: seed);

        // Act
        gameData.makeSingleCourt(0);

        // Assert
        expect(
          tierGap(gameData.stagingMatches[0].players),
          0,
          reason: 'seed $seed',
        );
      }
    },
  );

  test('should_return_other_pool_players_to_waitlist_when_rerolled', () async {
    // Arrange
    final players = await playersWith(List.filled(6, Elo.b2));
    final gameData = await oneCourt(players);

    // Act
    gameData.makeSingleCourt(0);

    // Assert
    expect(gameData.waitlistedPlayers, hasLength(2));
  });

  test('should_not_change_court_when_pool_is_exactly_four', () async {
    // Arrange
    final players = await playersWith(List.filled(4, Elo.b2));
    final gameData = await oneCourt(players);
    final before = [...gameData.stagingMatches[0].playerIds];

    // Act
    gameData.makeSingleCourt(0);

    // Assert
    expect(gameData.stagingMatches[0].playerIds, before);
  });

  test('should_not_count_reroll_when_pool_is_exactly_four', () async {
    // Arrange
    final players = await playersWith(List.filled(4, Elo.b2));
    final gameData = await oneCourt(players);

    // Act
    gameData.makeSingleCourt(0);

    // Assert
    expect(gameData.sessionRerollCount, 0);
  });

  test('should_not_throw_or_count_when_pool_is_below_four', () async {
    // Arrange
    final players = await playersWith(List.filled(4, Elo.b2));
    final gameData = await oneCourt(players);
    gameData.removePlayer(players.first);

    // Act
    gameData.makeSingleCourt(0);

    // Assert
    expect(gameData.sessionRerollCount, 0);
  });

  test('should_report_cannot_reroll_when_pool_is_four_or_fewer', () async {
    // Arrange
    final players = await playersWith(List.filled(4, Elo.b2));
    final gameData = await oneCourt(players);

    // Act + Assert
    expect(gameData.canRerollCourt(0), isFalse);
  });

  test('should_report_can_reroll_when_pool_is_above_four', () async {
    // Arrange
    final players = await playersWith(List.filled(5, Elo.b2));
    final gameData = await oneCourt(players);

    // Act + Assert
    expect(gameData.canRerollCourt(0), isTrue);
  });

  test('should_fill_an_empty_court_when_four_players_wait', () async {
    // Arrange — court 0 full, court 1 emptied so its 4 players wait.
    final players = await playersWith(List.filled(8, Elo.b2));
    final gameData = GameData(random: Random(1))..setNumberOfCourt(2);
    for (final player in players) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    for (final id in gameData.stagingMatches[1].playerIds.toList()) {
      gameData.removePlayerFromCourt(players.firstWhere((p) => p.id == id));
    }

    // Act
    gameData.makeSingleCourt(1);

    // Assert
    expect(gameData.stagingMatches[1].playerIds, hasLength(4));
  });

  test('should_report_can_reroll_when_a_part_full_court_can_fill', () async {
    // Arrange — court 1 keeps 2 players, the other 2 wait.
    final players = await playersWith(List.filled(8, Elo.b2));
    final gameData = GameData(random: Random(1))..setNumberOfCourt(2);
    for (final player in players) {
      gameData.checkInPlayer(player);
    }
    await gameData.makeGame();
    for (final id in gameData.stagingMatches[1].playerIds.take(2).toList()) {
      gameData.removePlayerFromCourt(players.firstWhere((p) => p.id == id));
    }

    // Act + Assert
    expect(gameData.canRerollCourt(1), isTrue);
  });
}
