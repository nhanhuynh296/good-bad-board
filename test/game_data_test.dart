import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';

void main() {
  final List<Player> players = List.generate(
    4,
    (i) => Player.create(
      firstName: 'Player',
      lastName: i.toString(),
      elo: Elo.values[i % Elo.values.length],
    ),
  );

  final waitlistedPlayer = Player.create(
    firstName: 'Inactive',
    lastName: 'Player',
    elo: Elo.values[0],
  );

  late RepositorySandbox sandbox;

  setUp(() async {
    sandbox = await RepositorySandbox.setUp('game_data_test');
    await PlayerRepository.instance.addAll([...players, waitlistedPlayer]);
  });

  tearDown(() => sandbox.tearDown());

  test('Can add a full price player', () {
    final gameData = GameData();
    expect(gameData.checkedInPlayers, isEmpty);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.checkedInPlayers, hasLength(players.length));
  });

  test('Can not make game if not enough player', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    expectLater(gameData.makeGame, throwsException);
    players.forEach(gameData.addFullPricedPlayer);
  });

  test('Can not make game if not enough players', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.checkedInPlayers, hasLength(4));
    expect(gameData.stagingMatches, isEmpty);
    await gameData.makeGame();
    expect(gameData.stagingMatches, isNotEmpty);
  });

  test('Can swap player', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    players.forEach(gameData.addFullPricedPlayer);
    expect(gameData.checkedInPlayers, hasLength(4));
    expect(gameData.stagingMatches, isEmpty);
    await gameData.makeGame();
    expect(gameData.stagingMatches, isNotEmpty);

    gameData.addFullPricedPlayer(waitlistedPlayer);
    expect(gameData.checkedInPlayers, hasLength(5));
    expect(
      getPlayerFromGames(gameData.stagingMatches).contains(waitlistedPlayer),
      isFalse,
    );
    final playerToReplace = players.first;
    gameData.swapPlayer(playerToReplace, waitlistedPlayer);
    // inactive player should be in the game now
    expect(
      getPlayerFromGames(gameData.stagingMatches),
      contains(waitlistedPlayer),
    );
    // and played swaped out player should not be in the game
    expect(
      getPlayerFromGames(gameData.stagingMatches).contains(playerToReplace),
      isFalse,
    );
  });
}
