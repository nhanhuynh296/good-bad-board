import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/repository/player_repository.dart';
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
    sandbox = await RepositorySandbox.setUp('stage5_test');
  });

  tearDown(() => sandbox.tearDown());
  // ---------------------------------------------------------------------------
  // CHK-01: checkedInCount and remainingCapacity
  // ---------------------------------------------------------------------------

  test('CHK-01: should report zero checkedInCount when no players', () {
    final gameData = GameData();

    expect(gameData.checkedInCount, 0);
  });

  test('CHK-01: should increment checkedInCount when player checks in', () {
    final gameData = GameData();
    final player = Player.create(
      firstName: 'Alice',
      lastName: 'Smith',
      elo: Elo.c2,
    );
    gameData.addFullPricedPlayer(player);

    final result = gameData.checkInPlayer(player);

    expect(result, CheckInResult.checkedIn);
    expect(gameData.checkedInCount, 1);
  });

  test('CHK-01: should report remainingCapacity correctly', () {
    final gameData = GameData();
    expect(gameData.sessionCapacity, GameData.defaultSessionCapacity);
    // Default 20 minus 0 checked-in
    expect(gameData.remainingCapacity, GameData.defaultSessionCapacity);

    // Add and check in a player
    final player = Player.create(
      firstName: 'Bob',
      lastName: 'Jones',
      elo: Elo.b2,
    );
    gameData.addFullPricedPlayer(player);
    gameData.checkInPlayer(player);

    expect(gameData.remainingCapacity, GameData.defaultSessionCapacity - 1);
  });

  // ---------------------------------------------------------------------------
  // CHK-02: Court placement on check-in
  // ---------------------------------------------------------------------------

  test('CHK-02: should place checked-in player on first non-full court '
      'when court has space', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    // Create 1 court with 4 players via makeGame
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    await PlayerRepository.instance.addAll(players);
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame(); // 1 full court, 4 players

    // Free up one slot on the court
    final displacedPlayer = players.first;
    gameData.removePlayerFromCourt(displacedPlayer);

    // Add and check in a new player — should fill the open slot
    final newPlayer = Player.create(
      firstName: 'New',
      lastName: 'Guy',
      elo: Elo.c2,
    );
    await PlayerRepository.instance.add(newPlayer);
    gameData.addFullPricedPlayer(newPlayer);
    final result = gameData.checkInPlayer(newPlayer);

    expect(result, CheckInResult.checkedIn);
    final court = gameData.gameContainingPlayer(newPlayer);
    expect(court, isNotNull);
    expect(court!.players, contains(newPlayer));
  });

  test('CHK-02: should place checked-in player on waitlist when all courts '
      'are full', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame(); // 1 full court

    // Add and check in a 5th player — court is full, so waitlisted
    final extraPlayer = Player.create(
      firstName: 'Extra',
      lastName: 'Player',
      elo: Elo.s1,
    );
    gameData.addFullPricedPlayer(extraPlayer);
    final result = gameData.checkInPlayer(extraPlayer);

    expect(result, CheckInResult.checkedIn);
    expect(gameData.gameContainingPlayer(extraPlayer), isNull);
    expect(gameData.waitlistedPlayers, contains(extraPlayer));
  });

  // ---------------------------------------------------------------------------
  // CHK-03: Capacity gating
  // ---------------------------------------------------------------------------

  test('CHK-03: should refuse check-in when at capacity', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    gameData.setSessionCapacity(4);

    // Add 4 players, make a full court, and check them all in
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame();
    players.forEach(gameData.checkInPlayer);

    expect(gameData.isAtCapacity, isTrue);
    expect(gameData.checkedInCount, 4);

    // 5th player — should be rejected
    final extraPlayer = Player.create(
      firstName: 'Extra',
      lastName: 'Guy',
      elo: Elo.s1,
    );
    gameData.addFullPricedPlayer(extraPlayer);

    final result = gameData.checkInPlayer(extraPlayer);

    expect(result, CheckInResult.sessionFull);
    expect(gameData.checkedInCount, 4); // unchanged
    expect(gameData.isPlayerCheckedIn(extraPlayer), isFalse);
  });

  test('CHK-03: should allow check-in when below capacity', () {
    final gameData = GameData();
    gameData.setSessionCapacity(10);

    final player = Player.create(
      firstName: 'Charlie',
      lastName: 'Brown',
      elo: Elo.a2,
    );
    gameData.addFullPricedPlayer(player);

    final result = gameData.checkInPlayer(player);

    expect(result, CheckInResult.checkedIn);
    expect(gameData.isPlayerCheckedIn(player), isTrue);
  });

  // ---------------------------------------------------------------------------
  // CHK-04: isAtCapacity
  // ---------------------------------------------------------------------------

  test('CHK-04: should report isAtCapacity true when checkedIn equals '
      'capacity', () {
    final gameData = GameData();
    gameData.setSessionCapacity(4);

    final p1 = Player.create(firstName: 'P1', lastName: 'A', elo: Elo.c2);
    final p2 = Player.create(firstName: 'P2', lastName: 'B', elo: Elo.c1);
    final p3 = Player.create(firstName: 'P3', lastName: 'C', elo: Elo.b2);
    final p4 = Player.create(firstName: 'P4', lastName: 'D', elo: Elo.a2);
    gameData.addFullPricedPlayer(p1);
    gameData.addFullPricedPlayer(p2);
    gameData.addFullPricedPlayer(p3);
    gameData.addFullPricedPlayer(p4);
    gameData.checkInPlayer(p1);
    gameData.checkInPlayer(p2);
    gameData.checkInPlayer(p3);
    gameData.checkInPlayer(p4);

    expect(gameData.checkedInCount, 4);
    expect(gameData.isAtCapacity, isTrue);
  });

  test('CHK-04: should report isAtCapacity false when below capacity', () {
    final gameData = GameData();
    gameData.setSessionCapacity(10);

    final p1 = Player.create(firstName: 'P1', lastName: 'A', elo: Elo.c2);
    gameData.addFullPricedPlayer(p1);
    gameData.checkInPlayer(p1);

    expect(gameData.checkedInCount, 1);
    expect(gameData.isAtCapacity, isFalse);
  });

  // ---------------------------------------------------------------------------
  // CHK-05: Check-out removes player from court
  // ---------------------------------------------------------------------------

  test('CHK-05: should remove player from court on check-out', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame();
    players.forEach(gameData.checkInPlayer);

    final playerToCheckOut = players.first;
    gameData.checkOutPlayer(playerToCheckOut);

    expect(gameData.isPlayerCheckedIn(playerToCheckOut), isFalse);
    expect(gameData.gameContainingPlayer(playerToCheckOut), isNull);
  });

  // ---------------------------------------------------------------------------
  // CHK-05 + WL-02: Auto-promote waitlisted player on check-out
  // ---------------------------------------------------------------------------

  test('CHK-05+WL-02: should auto-promote waitlisted player to fill open '
      'court slot on check-out', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final players = List.generate(
      4,
      (i) =>
          Player.create(firstName: 'Court', lastName: '$i', elo: Elo.values[i]),
    );
    await PlayerRepository.instance.addAll(players);
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame(); // 1 full court
    players.forEach(gameData.checkInPlayer);

    // Add and check in a waitlisted player (court is full)
    final waitlisted = Player.create(
      firstName: 'Wait',
      lastName: 'Listed',
      elo: Elo.s1,
    );
    await PlayerRepository.instance.add(waitlisted);
    gameData.addFullPricedPlayer(waitlisted);
    gameData.checkInPlayer(waitlisted);
    expect(gameData.gameContainingPlayer(waitlisted), isNull);

    // Check out a court player — waitlisted should get promoted
    final courtPlayer = players.first;
    gameData.checkOutPlayer(courtPlayer);

    expect(gameData.isPlayerCheckedIn(courtPlayer), isFalse);
    // The waitlisted player should now occupy the freed slot
    final promotedCourt = gameData.gameContainingPlayer(waitlisted);
    expect(promotedCourt, isNotNull);
    expect(promotedCourt!.players, contains(waitlisted));
  });

  // ---------------------------------------------------------------------------
  // CHK-06: checkedInPlayers excludes inactive (non-session) players
  // ---------------------------------------------------------------------------

  test('CHK-06: checkedInPlayers lists only players who checked in', () {
    final gameData = GameData();
    final checkedInPlayer = Player.create(
      firstName: 'Active',
      lastName: 'One',
      elo: Elo.a1,
    );
    gameData.checkInPlayer(checkedInPlayer);

    // This player never checked in
    final outsider = Player.create(
      firstName: 'Ghost',
      lastName: 'Player',
      elo: Elo.s2,
    );

    expect(gameData.checkedInPlayers.values, contains(checkedInPlayer));
    expect(gameData.checkedInPlayers.values, isNot(contains(outsider)));
  });

  // ---------------------------------------------------------------------------
  // SESS-03: Session capacity constraints
  // ---------------------------------------------------------------------------

  test('SESS-03: should clamp session capacity up to the minimum of 4', () {
    final gameData = GameData();

    gameData.setSessionCapacity(3);

    // Clamped to the minimum — not raised back to the default of 20, which
    // would give the organizer a bigger session than they asked for.
    expect(gameData.sessionCapacity, GameData.minSessionCapacity);
  });

  test('SESS-03: should keep a session capacity at or above the minimum', () {
    final gameData = GameData();

    gameData.setSessionCapacity(4);
    expect(gameData.sessionCapacity, 4);

    gameData.setSessionCapacity(12);
    expect(gameData.sessionCapacity, 12);
  });

  test('SESS-03: should clamp a zero or negative capacity to the minimum', () {
    final gameData = GameData();

    gameData.setSessionCapacity(0);
    expect(gameData.sessionCapacity, GameData.minSessionCapacity);

    gameData.setSessionCapacity(-5);
    expect(gameData.sessionCapacity, GameData.minSessionCapacity);
  });

  test('SESS-06: should clamp a template capacity below the minimum', () {
    final gameData = GameData();

    gameData.loadTemplate(
      const SessionTemplate(
        id: 'tiny',
        name: 'Tiny',
        gameType: GameType.timeBased,
        durationMinutes: 20,
        durationSeconds: 0,
        capacity: 2,
        courts: 1,
      ),
    );

    expect(gameData.sessionCapacity, GameData.minSessionCapacity);
  });

  test(
    'SESS-03: should not bump checked-in players when capacity is lowered',
    () {
      final gameData = GameData();
      // Default capacity is 20
      final players = List.generate(
        10,
        (i) => Player.create(
          firstName: 'Player',
          lastName: '$i',
          elo: Elo.values[i % Elo.values.length],
        ),
      );
      players.forEach(gameData.addFullPricedPlayer);
      players.forEach(gameData.checkInPlayer);
      expect(gameData.checkedInCount, 10);

      // Lower capacity below current checked-in count
      gameData.setSessionCapacity(5);

      // Checked-in players should remain — they are not evicted
      expect(gameData.checkedInCount, 10);
    },
  );

  // ---------------------------------------------------------------------------
  // SESS-04: checkedInCount after multiple check-ins
  // ---------------------------------------------------------------------------

  test('SESS-04: should return correct checkedInCount after checking in '
      'multiple players', () {
    final gameData = GameData();
    final players = List.generate(
      8,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      ),
    );
    // Check in first 5
    for (var i = 0; i < 5; i++) {
      final result = gameData.checkInPlayer(players[i]);
      expect(result, CheckInResult.checkedIn);
    }

    expect(gameData.checkedInCount, 5);
    expect(gameData.remainingCapacity, 20 - 5);
  });

  // ---------------------------------------------------------------------------
  // SESS-05: Session templates — save
  // ---------------------------------------------------------------------------

  test('SESS-05: should add template to list when saved with non-blank '
      'name', () async {
    final gameData = GameData();

    await gameData.saveTemplate(
      'Tuesday Night',
      GameType.gameBased,
      const Duration(minutes: 60),
      12,
      3,
    );

    expect(gameData.templates, hasLength(1));
    expect(gameData.templates.first.name, 'Tuesday Night');
  });

  test('SESS-05: should not add template when saved with blank or whitespace '
      'name', () {
    final gameData = GameData();

    gameData.saveTemplate(
      '',
      GameType.gameBased,
      const Duration(minutes: 60),
      12,
      3,
    );

    expect(gameData.templates, isEmpty);

    gameData.saveTemplate(
      '   ',
      GameType.gameBased,
      const Duration(minutes: 60),
      12,
      3,
    );

    expect(gameData.templates, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // SESS-06: Session templates — load / apply
  // ---------------------------------------------------------------------------

  test('SESS-06: should apply template settings on load', () {
    final gameData = GameData();
    const template = SessionTemplate(
      id: 'weekend',
      name: 'Weekend Bash',
      gameType: GameType.timeBased,
      durationMinutes: 90,
      capacity: 16,
      courts: 4,
    );

    gameData.loadTemplate(template);

    expect(gameData.sessionCapacity, 16);
    expect(gameData.numberOfCourt, 4);
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------

  test('should check in a player not previously added via addFullPricedPlayer '
      '(check-in is self-sufficient)', () {
    final gameData = GameData();
    final outsider = Player.create(
      firstName: 'Outsider',
      lastName: 'Player',
      elo: Elo.s2,
    );
    // Player was never added via addFullPricedPlayer

    final result = gameData.checkInPlayer(outsider);

    expect(result, CheckInResult.checkedIn);
    expect(gameData.checkedInCount, 1);
    expect(gameData.checkedInPlayers, containsPair(outsider.id, outsider));
  });

  test('should return correct checkedInPlayers list', () {
    final gameData = GameData();
    final p1 = Player.create(firstName: 'Alpha', lastName: 'One', elo: Elo.a2);
    final p2 = Player.create(firstName: 'Beta', lastName: 'Two', elo: Elo.b1);
    final p3 = Player.create(
      firstName: 'Gamma',
      lastName: 'Three',
      elo: Elo.c2,
    );

    gameData.checkInPlayer(p1);
    gameData.checkInPlayer(p2);
    // p3 NOT checked in

    final checkedIn = gameData.checkedInPlayers.values;
    expect(checkedIn, hasLength(2));
    expect(checkedIn, containsAll([p1, p2]));
    expect(checkedIn, isNot(contains(p3)));
  });

  test('should be able to check in player again after check-out', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame();
    players.forEach(gameData.checkInPlayer);

    final player = players.first;
    expect(gameData.isPlayerCheckedIn(player), isTrue);

    gameData.checkOutPlayer(player);
    expect(gameData.isPlayerCheckedIn(player), isFalse);

    // Re-check-in
    final result = gameData.checkInPlayer(player);
    expect(result, CheckInResult.checkedIn);
    expect(gameData.isPlayerCheckedIn(player), isTrue);
    expect(gameData.checkedInCount, 4);
  });

  test('should handle checking out a waitlisted player', () async {
    final gameData = GameData()..setNumberOfCourt(1);
    final players = List.generate(
      4,
      (i) => Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i],
      ),
    );
    players.forEach(gameData.addFullPricedPlayer);
    await gameData.makeGame(); // 1 full court
    players.forEach(gameData.checkInPlayer);

    // Waitlisted player
    final waitlisted = Player.create(
      firstName: 'Wait',
      lastName: 'Listed',
      elo: Elo.s1,
    );
    gameData.addFullPricedPlayer(waitlisted);
    gameData.checkInPlayer(waitlisted);

    expect(gameData.gameContainingPlayer(waitlisted), isNull);

    gameData.checkOutPlayer(waitlisted);

    expect(gameData.isPlayerCheckedIn(waitlisted), isFalse);
    expect(gameData.checkedInCount, 4); // back to 4
  });

  test('should delete template at given index', () async {
    final gameData = GameData();

    await gameData.saveTemplate(
      'Template 1',
      GameType.gameBased,
      const Duration(minutes: 30),
      8,
      2,
    );
    await gameData.saveTemplate(
      'Template 2',
      GameType.timeBased,
      const Duration(minutes: 60),
      12,
      3,
    );
    await gameData.saveTemplate(
      'Template 3',
      GameType.gameBased,
      const Duration(minutes: 45),
      10,
      2,
    );

    expect(gameData.templates, hasLength(3));

    await gameData.deleteTemplate(1);

    expect(gameData.templates, hasLength(2));
    expect(gameData.templates[0].name, 'Template 1');
    expect(gameData.templates[1].name, 'Template 3');
  });
}
