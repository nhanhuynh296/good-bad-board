import 'dart:convert';
import 'dart:io';

import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:test/test.dart';

/// Data files in the layout the released build on `main` writes. A player
/// row has no `membership` and no `deletedDate` key. The new build must
/// load these files with no loss.
const _mainPlayers = {
  'players': [
    {
      'firstName': 'Ava',
      'lastName': 'Chen',
      'elo': 'a2',
      'id': 'p1',
      'signInId': 'BC-101',
      'createdDate': '2025-08-09T19:15:04.268904',
    },
    {
      'firstName': 'Liam',
      'lastName': 'Ortiz',
      'elo': 'c1',
      'id': 'p2',
      'signInId': null,
      'createdDate': null,
    },
  ],
};

const _mainGames = {
  'games': [
    {
      'playerDto': [
        {'id': 'p1'},
        {'id': 'p2'},
      ],
      'id': 'g1',
      'createdDate': '2025-08-09T19:20:00.000',
    },
  ],
};

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('main_format_compat_test');
    File(
      '${tempDir.path}/${PlayerRepository.databaseFilename}',
    ).writeAsStringSync(jsonEncode(_mainPlayers));
    File(
      '${tempDir.path}/${GameRepository.databaseFilename}',
    ).writeAsStringSync(jsonEncode(_mainGames));
    PlayerRepository.instance = await PlayerRepository.initialize(
      rootDir: tempDir.path,
    );
    GameRepository.instance = await GameRepository.initialize(
      rootDir: tempDir.path,
    );
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('should_list_every_player_saved_by_main', () {
    expect(
      PlayerRepository.instance.listedPlayers().map((p) => p.id),
      unorderedEquals(['p1', 'p2']),
    );
  });

  test('should_keep_player_fields_saved_by_main', () {
    final ava = PlayerRepository.instance.byId('p1')!;
    expect(
      [ava.firstName, ava.lastName, ava.elo, ava.signInId, ava.createdDate],
      [
        'Ava',
        'Chen',
        Elo.a2,
        'BC-101',
        DateTime(2025, 8, 9, 19, 15, 4, 268, 904),
      ],
    );
  });

  test('should_give_main_players_member_status', () {
    expect(
      PlayerRepository.instance.listedPlayers().map((p) => p.membership),
      everyElement(MembershipStatus.member),
    );
  });

  test('should_resolve_game_roster_saved_by_main', () {
    final game = GameRepository.instance.getAll().single;
    expect(game.players.map((p) => p.id), ['p1', 'p2']);
  });

  test('should_keep_main_games_when_a_new_game_is_saved', () async {
    final roster = PlayerRepository.instance.listedPlayers().toList();
    final newGame = Game.create(roster);
    await GameRepository.instance.add(newGame);

    final reloaded = await GameRepository.initialize(rootDir: tempDir.path);
    expect(
      reloaded.getAll().map((g) => g.id),
      unorderedEquals(['g1', newGame.id]),
    );
  });
}
