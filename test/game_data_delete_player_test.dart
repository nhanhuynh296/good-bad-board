import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';

/// PLY-07 / ADR-0001: deleting a Player anonymises rather than removes them,
/// so a Game they played keeps its full roster.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async => sandbox = await RepositorySandbox.setUp('delete_player'));

  tearDown(() => sandbox.tearDown());

  Player alice() =>
      Player.create(firstName: 'Alice', lastName: 'Smith', elo: Elo.b2);

  test(
    'deletePlayer empties the name and sign-in id, keeps id, elo and created date',
    () async {
      final player = alice().copyWith(signInId: 'ALICE01');
      await PlayerRepository.instance.add(player);
      final gameData = GameData();
      gameData.addFullPricedPlayer(player);

      await gameData.deletePlayer(player);

      final stored = PlayerRepository.instance.byId(player.id);
      expect(stored, isNotNull);
      expect(stored!.firstName, isEmpty);
      expect(stored.lastName, isEmpty);
      expect(stored.signInId, isNull);
      expect(stored.id, player.id);
      expect(stored.elo, player.elo);
      expect(stored.createdDate, player.createdDate);
      expect(stored.isAnonymised, isTrue);
    },
  );

  test('deletePlayer leaves every historical roster intact on disk', () async {
    final player = alice();
    await PlayerRepository.instance.add(player);
    await GameRepository.instance.add(
      Game.create([player, player, player, player]),
    );
    final gameData = GameData();
    gameData.addFullPricedPlayer(player);

    await gameData.deletePlayer(player);

    final games = GameRepository.instance.getAll();
    expect(games, hasLength(1));
    expect(games.first.players.map((p) => p.id), [
      player.id,
      player.id,
      player.id,
      player.id,
    ]);
  });

  test('an anonymised player is absent from the listed player list but still '
      'resolves for a historical game', () async {
    final player = alice();
    await PlayerRepository.instance.add(player);
    await GameRepository.instance.add(
      Game.create([player, player, player, player]),
    );
    final gameData = GameData();
    gameData.addFullPricedPlayer(player);
    await gameData.deletePlayer(player);

    expect(
      PlayerRepository.instance.listedPlayers().map((p) => p.id),
      isNot(contains(player.id)),
    );
    final resolved = GameRepository.instance.getAll().first.players;
    expect(resolved, hasLength(4));
    expect(resolved.every((p) => p.isAnonymised), isTrue);
  });

  test('deletePlayer removes the player from the live session', () async {
    final player = alice();
    await PlayerRepository.instance.add(player);
    final gameData = GameData();
    gameData.addFullPricedPlayer(player);
    gameData.checkInPlayer(player);

    await gameData.deletePlayer(player);

    expect(gameData.checkedInPlayers.containsKey(player.id), isFalse);
    expect(gameData.isPlayerCheckedIn(player), isFalse);
  });
}
