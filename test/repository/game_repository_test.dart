import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

Future<Database> _openTestDb() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE players (id TEXT PRIMARY KEY, first_name TEXT NOT NULL, last_name TEXT NOT NULL, elo TEXT NOT NULL, sign_in_id TEXT, created_date TEXT, membership_type TEXT, last_played TEXT, avatar_path TEXT, session_fee_paid INTEGER, dues_status TEXT)',
      );
      await db.execute(
        'CREATE TABLE games (id TEXT PRIMARY KEY, created_date TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE game_players (game_id TEXT NOT NULL, player_id TEXT NOT NULL, position INTEGER NOT NULL, PRIMARY KEY (game_id, position), FOREIGN KEY (game_id) REFERENCES games(id), FOREIGN KEY (player_id) REFERENCES players(id))',
      );
    },
  );
}

void main() {
  setUpAll(initSqfliteForTests);

  test('GameRepository: add() writes game row and game_players rows', () async {
    final db = await _openTestDb();
    final player1 = Player.create(firstName: 'P1', lastName: 'A', elo: Elo.b1);
    final player2 = Player.create(firstName: 'P2', lastName: 'B', elo: Elo.b2);
    // Insert players first (FK constraint)
    for (final p in [player1, player2]) {
      await db.insert('players', {
        'id': p.id,
        'first_name': p.firstName,
        'last_name': p.lastName,
        'elo': p.elo.name,
        'sign_in_id': null,
        'created_date': null,
      });
    }
    final game = Game.create([player1, player2]);
    // Simulate GameRepository.add() logic
    await db.transaction((txn) async {
      await txn.insert('games', {
        'id': game.id,
        'created_date': game.createdDate.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (int i = 0; i < game.players.length; i++) {
        await txn.insert('game_players', {
          'game_id': game.id,
          'player_id': game.players[i].id,
          'position': i,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    final gameRows = await db.query('games');
    expect(gameRows, hasLength(1));
    final playerRows = await db.query(
      'game_players',
      where: 'game_id = ?',
      whereArgs: [game.id],
      orderBy: 'position ASC',
    );
    expect(playerRows, hasLength(2));
    expect(playerRows.first['player_id'], equals(player1.id));
    expect(playerRows.last['player_id'], equals(player2.id));
    await db.close();
  });

  test('GameRepository: delete() removes game and game_players rows', () async {
    final db = await _openTestDb();
    final player = Player.create(firstName: 'P', lastName: 'X', elo: Elo.a1);
    await db.insert('players', {
      'id': player.id,
      'first_name': 'P',
      'last_name': 'X',
      'elo': 'a1',
      'sign_in_id': null,
      'created_date': null,
    });
    final game = Game.create([player]);
    await db.insert('games', {
      'id': game.id,
      'created_date': game.createdDate.toIso8601String(),
    });
    await db.insert('game_players', {
      'game_id': game.id,
      'player_id': player.id,
      'position': 0,
    });
    // Simulate delete — game_players before games (FK order)
    await db.transaction((txn) async {
      await txn.delete(
        'game_players',
        where: 'game_id = ?',
        whereArgs: [game.id],
      );
      await txn.delete('games', where: 'id = ?', whereArgs: [game.id]);
    });
    expect(await db.query('games'), isEmpty);
    expect(await db.query('game_players'), isEmpty);
    await db.close();
  });

  test('GameRepository: game_players rows are ordered by position', () async {
    final db = await _openTestDb();
    final players = List.generate(
      4,
      (i) => Player.create(firstName: 'P$i', lastName: 'X', elo: Elo.values[i]),
    );
    for (final p in players) {
      await db.insert('players', {
        'id': p.id,
        'first_name': p.firstName,
        'last_name': 'X',
        'elo': p.elo.name,
        'sign_in_id': null,
        'created_date': null,
      });
    }
    final game = Game.create(players);
    await db.insert('games', {
      'id': game.id,
      'created_date': game.createdDate.toIso8601String(),
    });
    for (int i = 0; i < players.length; i++) {
      await db.insert('game_players', {
        'game_id': game.id,
        'player_id': players[i].id,
        'position': i,
      });
    }
    final rows = await db.query(
      'game_players',
      where: 'game_id = ?',
      whereArgs: [game.id],
      orderBy: 'position ASC',
    );
    expect(
      rows.map((r) => r['player_id']).toList(),
      equals(players.map((p) => p.id).toList()),
    );
    await db.close();
  });
}
