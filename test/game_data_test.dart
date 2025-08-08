import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:test/test.dart';

void main() {
  final List<Player> players = List.generate(
    4,
    (i) => Player.create(
      firstName: 'Player',
      lastName: i.toString(),
      elo: Elo.values[i % Elo.values.length],
    ),
  );

  final inactivePlayer = Player.create(
    firstName: 'Inactive',
    lastName: 'Player',
    elo: Elo.values[0],
  );

  test('Can add a full price player', () {
    final gameData = GameData();
    expect(gameData.players, isEmpty);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.players, hasLength(players.length));
  });

  test('Can add a partial price player', () {
    final gameData = GameData();
    expect(gameData.players, isEmpty);
    players.forEach(gameData.addFractionalPricedPlayer);
    expect(gameData.players, hasLength(4));
  });

  test('Can not make game if not enough player', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final error = await gameData.makeGame();
    expect(error, isNotNull);
    players.forEach(gameData.addFullPricedPlayer);
  });

  test('Can not make game if not enough players', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.players, hasLength(4));
    expect(gameData.stagingMatches, isEmpty);
    final error = await gameData.makeGame();
    expect(error, isNull);
    expect(gameData.stagingMatches, isNotEmpty);
  });

  test('Can swap player', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.players, hasLength(4));
    expect(gameData.stagingMatches, isEmpty);
    final error = await gameData.makeGame();
    expect(error, isNull);
    expect(gameData.stagingMatches, isNotEmpty);

    gameData.addFullPricedPlayer(inactivePlayer);
    expect(gameData.players, hasLength(5));
    expect(
      getPlayerFromGames(gameData.stagingMatches).contains(inactivePlayer),
      isFalse,
    );
    final playerToReplace = players.first;
    gameData.swapPlayer(playerToReplace, inactivePlayer);
    // inactive player should be in the game now
    expect(
      getPlayerFromGames(gameData.stagingMatches),
      contains(inactivePlayer),
    );
    // and played swaped out player should not be in the game
    expect(
      getPlayerFromGames(gameData.stagingMatches).contains(playerToReplace),
      isFalse,
    );
  });
}
