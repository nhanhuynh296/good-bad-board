import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:test/test.dart';

// Note: _improveEloSpreadIsolate is a top-level function in game_data.dart.
// It is private (prefixed with _) so we test it indirectly via observable behavior,
// or we test its logic by calling makeGame() end-to-end.

void main() {
  test(
    'makeGame() with 4 players completes and populates stagingMatches',
    () async {
      final players = List.generate(
        4,
        (i) => Player.create(
          firstName: 'Player',
          lastName: i.toString(),
          elo: Elo.values[i % Elo.values.length],
        ),
      );
      final gameData = GameData()..setNumberOfCourt(1);
      players.forEach(gameData.addFullPricedPlayer);
      await gameData.makeGame();
      expect(gameData.stagingMatches, isNotEmpty);
      expect(gameData.stagingMatches.first.players, hasLength(4));
    },
  );

  test('makeGame() with varied ELO players completes without error', () async {
    // 8 players with spread-out ELOs across 2 courts
    final players = [
      Player.create(firstName: 'A', lastName: '1', elo: Elo.s1),
      Player.create(firstName: 'B', lastName: '2', elo: Elo.c2),
      Player.create(firstName: 'C', lastName: '3', elo: Elo.a1),
      Player.create(firstName: 'D', lastName: '4', elo: Elo.c1),
      Player.create(firstName: 'E', lastName: '5', elo: Elo.s2),
      Player.create(firstName: 'F', lastName: '6', elo: Elo.b1),
      Player.create(firstName: 'G', lastName: '7', elo: Elo.b2),
      Player.create(firstName: 'H', lastName: '8', elo: Elo.a2),
    ];
    final gameData = GameData()..setNumberOfCourt(2);
    players.forEach(gameData.addFullPricedPlayer);
    // Should not throw, should complete, courts should have players
    await gameData.makeGame();
    expect(gameData.stagingMatches, hasLength(greaterThanOrEqualTo(1)));
  });

  test(
    'makeGame() result has no more total players than input players',
    () async {
      final players = List.generate(
        8,
        (i) => Player.create(
          firstName: 'P',
          lastName: i.toString(),
          elo: Elo.values[i % Elo.values.length],
        ),
      );
      final gameData = GameData()..setNumberOfCourt(2);
      players.forEach(gameData.addFullPricedPlayer);
      await gameData.makeGame();
      final totalOnCourt = gameData.stagingMatches
          .expand((g) => g.players)
          .length;
      expect(totalOnCourt, lessThanOrEqualTo(players.length));
    },
  );
}
