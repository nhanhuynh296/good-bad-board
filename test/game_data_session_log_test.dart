import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:test/test.dart';

import 'support/repository_sandbox.dart';
import 'support/prefs_sandbox.dart';

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('session_log_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<List<Player>> fourPlayers() async {
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    await PlayerRepository.instance.addAll(players);
    return players;
  }

  // ---------------------------------------------------------------------
  // Re-roll counter
  // ---------------------------------------------------------------------

  test(
    'reroll counter starts at zero and increments on makeSingleCourt',
    () async {
      final gameData = GameData()..setNumberOfCourt(1);
      (await fourPlayers()).forEach(gameData.addFullPricedPlayer);
      // A fifth player gives the re-roll someone to rotate in (COURT-03).
      gameData.addFullPricedPlayer(
        Player.create(firstName: 'Spare', lastName: 'One', elo: Elo.c2),
      );
      await gameData.makeGame();

      expect(gameData.sessionRerollCount, 0);

      gameData.makeSingleCourt(0);

      expect(gameData.sessionRerollCount, 1);
    },
  );

  test(
    'reroll counter does not increment on a no-op reroll (4 or fewer players)',
    () async {
      final gameData = GameData()..setNumberOfCourt(1);
      final players = await fourPlayers();
      players.forEach(gameData.addFullPricedPlayer);
      await gameData.makeGame();

      // Exactly 4 players: nobody to rotate in, so the reroll does nothing.
      gameData.makeSingleCourt(0);

      expect(gameData.sessionRerollCount, 0);
    },
  );

  // ---------------------------------------------------------------------
  // Session log snapshot on save
  // ---------------------------------------------------------------------

  test(
    'saveCurrentGame persists a SessionLog snapshot matching live state',
    () async {
      final gameData = GameData()..setNumberOfCourt(1);
      final players = await fourPlayers();
      players.forEach(gameData.addFullPricedPlayer);
      players.forEach(gameData.checkInPlayer);
      await gameData.makeGame();

      // One extra checked-in, waitlisted player.
      final waitlisted = Player.create(
        firstName: 'Wait',
        lastName: 'Lister',
        elo: Elo.c2,
      );
      gameData.addFullPricedPlayer(waitlisted);
      gameData.checkInPlayer(waitlisted);

      gameData.makeSingleCourt(0);
      expect(gameData.sessionRerollCount, 1);

      await gameData.saveCurrentGame();

      final logs = SessionLogRepository.instance.getAll();
      expect(logs, hasLength(1));
      final log = logs.first;

      expect(log.capacity, gameData.sessionCapacity);
      expect(log.checkedInCount, 5);
      expect(log.waitlistCount, 1);
      expect(log.rerollCount, 1);
      expect(log.courtCount, 1);
      expect(log.courtLevelGaps, hasLength(1));

      // Re-roll counter resets after a logged save.
      expect(gameData.sessionRerollCount, 0);
    },
  );

  test(
    'saveSingleGame persists a SessionLog snapshot and resets reroll count',
    () async {
      final gameData = GameData()..setNumberOfCourt(1);
      final players = await fourPlayers();
      players.forEach(gameData.addFullPricedPlayer);
      await gameData.makeGame();
      gameData.makeSingleCourt(0);

      final game = gameData.stagingMatches.first;
      await gameData.saveSingleGame(game);

      final logs = SessionLogRepository.instance.getAll();
      expect(logs, hasLength(1));
      expect(gameData.sessionRerollCount, 0);
    },
  );

  test('SessionLog round-trips through JSON', () {
    final log = SessionLog.create(
      capacity: 20,
      checkedInCount: 8,
      waitlistCount: 2,
      rerollCount: 3,
      courtLevelGaps: [0, 1],
      courtCount: 2,
    );

    final json = log.toJson();
    final decoded = SessionLog.fromJson(json);

    expect(decoded.id, log.id);
    expect(decoded.capacity, 20);
    expect(decoded.checkedInCount, 8);
    expect(decoded.waitlistCount, 2);
    expect(decoded.rerollCount, 3);
    expect(decoded.courtLevelGaps, [0, 1]);
    expect(decoded.courtCount, 2);
  });

  test('SessionLog derived getters compute correctly', () {
    final log = SessionLog.create(
      capacity: 20,
      checkedInCount: 6,
      waitlistCount: 2,
      rerollCount: 0,
      courtLevelGaps: [0, 2],
      courtCount: 2,
    );

    // 6 checked-in / (2 courts * 4) = 0.75
    expect(log.fillRate, closeTo(0.75, 0.0001));
    expect(log.averageLevelGap, closeTo(1.0, 0.0001));
    expect(log.idleCourtSlots, 2);
  });
}
