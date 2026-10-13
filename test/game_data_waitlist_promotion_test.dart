import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

/// WL-03: a freed court slot is refilled from the waitlist, and only that
/// court is touched. Other open courts stay open, and a PLAYING court is
/// never refilled.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('waitlist_promotion');
  });

  tearDown(() => sandbox.tearDown());

  Future<void> flushPendingWrites() =>
      PlayerRepository.instance.addAll(const []);

  /// [total] players checked in, [courts] courts, round generated.
  Future<GameData> generated(int total, int courts) async {
    final players = [
      for (var i = 0; i < total; i++)
        Player.create(firstName: 'P$i', lastName: 'X', elo: Elo.b2),
    ];
    await PlayerRepository.instance.addAll(players);
    final gameData = GameData()..setNumberOfCourt(courts);
    players.forEach(gameData.checkInPlayer);
    await gameData.makeGame();
    return gameData;
  }

  List<int> courtSizes(GameData g) => [
    for (final game in g.stagingMatches) game.playerIds.length,
  ];

  Player playerOn(GameData g, int court) =>
      g.stagingMatches[court].players.first;

  test('should_fill_only_freed_court_when_player_checks_out', () async {
    // Arrange — 10 players, 3 courts: 4 + 4 + 0, two waiting.
    final gameData = await generated(10, 3);
    expect(courtSizes(gameData), [4, 4, 0]);

    // Act
    gameData.checkOutPlayer(playerOn(gameData, 0));

    // Assert
    expect(courtSizes(gameData), [4, 4, 0]);
  });

  test('should_keep_rest_of_waitlist_when_one_slot_is_freed', () async {
    final gameData = await generated(10, 3);

    gameData.checkOutPlayer(playerOn(gameData, 0));

    expect(gameData.waitlistedPlayers, hasLength(1));
  });

  test('should_fill_only_freed_court_when_player_is_deleted', () async {
    final gameData = await generated(10, 3);

    await gameData.deletePlayer(playerOn(gameData, 1));

    expect(courtSizes(gameData), [4, 4, 0]);
  });

  test('should_fill_only_freed_court_when_player_is_disabled', () async {
    final gameData = await generated(10, 3);
    final leaving = playerOn(gameData, 1);

    gameData.setMembership(leaving, MembershipStatus.disabled);
    await flushPendingWrites();

    expect(courtSizes(gameData), [4, 4, 0]);
  });

  test('should_promote_highest_level_first_into_freed_court', () async {
    // Arrange — 4 on court, 2 waiting with different levels.
    final low = Player.create(firstName: 'Low', lastName: 'X', elo: Elo.c2);
    final high = Player.create(firstName: 'High', lastName: 'X', elo: Elo.a1);
    final four = [
      for (var i = 0; i < 4; i++)
        Player.create(firstName: 'C$i', lastName: 'X', elo: Elo.b2),
    ];
    await PlayerRepository.instance.addAll([...four, low, high]);
    final gameData = GameData()..setNumberOfCourt(1);
    four.forEach(gameData.checkInPlayer);
    await gameData.makeGame();
    gameData.checkInPlayer(low);
    gameData.checkInPlayer(high);

    // Act
    gameData.checkOutPlayer(four.first);

    // Assert
    expect(gameData.stagingMatches[0].playerIds, contains(high.id));
  });

  test('should_not_refill_playing_court_when_its_player_checks_out', () async {
    // Arrange — game-based, 14 players, 3 courts, court 1 saved (PLAYING).
    await PersistentSetting.instance.setGameType(GameType.gameBased);
    final gameData = await generated(14, 3);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);
    expect(gameData.isCourtPlaying(0), isTrue);
    expect(gameData.waitlistedPlayers, hasLength(2));

    // Act
    gameData.checkOutPlayer(playerOn(gameData, 0));

    // Assert
    expect(courtSizes(gameData), [3, 4, 4]);
    expect(gameData.waitlistedPlayers, hasLength(2));
  });

  test('should_fill_non_playing_court_when_another_court_is_playing', () async {
    await PersistentSetting.instance.setGameType(GameType.gameBased);
    final gameData = await generated(14, 3);
    await gameData.saveSingleGame(gameData.stagingMatches[0]);

    gameData.checkOutPlayer(playerOn(gameData, 1));

    expect(courtSizes(gameData), [4, 4, 4]);
    expect(gameData.waitlistedPlayers, hasLength(1));
  });
}
