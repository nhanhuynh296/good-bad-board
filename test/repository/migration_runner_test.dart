import 'dart:convert';
import 'dart:io';

import 'package:good_bad_board/repository/migration_runner.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

// Builds the in-memory database with the full schema for migration tests
Future<Database> _openTestDb() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE players ('
        'id TEXT PRIMARY KEY, first_name TEXT NOT NULL, last_name TEXT NOT NULL, '
        'elo TEXT NOT NULL, sign_in_id TEXT, created_date TEXT, membership_type TEXT, '
        'last_played TEXT, avatar_path TEXT, session_fee_paid INTEGER, dues_status TEXT)',
      );
      await db.execute(
        'CREATE TABLE games (id TEXT PRIMARY KEY, created_date TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE game_players ('
        'game_id TEXT NOT NULL, player_id TEXT NOT NULL, position INTEGER NOT NULL, '
        'PRIMARY KEY (game_id, position))',
      );
    },
  );
}

// Creates a players.json fixture in dir
Future<void> _writeTempPlayersJson(Directory dir) async {
  final playersJson = jsonEncode({
    'players': [
      {
        'id': 'player-uuid-1',
        'firstName': 'Alice',
        'lastName': 'Smith',
        'elo': 'b1',
        'signInId': null,
        'createdDate': '2024-01-15T10:00:00.000',
      },
      {
        'id': 'player-uuid-2',
        'firstName': 'Bob',
        'lastName': 'Jones',
        'elo': 'c2',
        'signInId': null,
        'createdDate': '2024-01-16T10:00:00.000',
      },
    ],
  });
  await File(p.join(dir.path, 'players.json')).writeAsString(playersJson);
}

// Creates a games.json fixture in dir
Future<void> _writeTempGamesJson(Directory dir) async {
  final gamesJson = jsonEncode({
    'games': [
      {
        'playerDto': [
          {'id': 'player-uuid-1'},
          {'id': 'player-uuid-2'},
        ],
        'id': 'game-uuid-1',
        'createdDate': '2024-02-01T10:00:00.000',
      },
    ],
  });
  await File(p.join(dir.path, 'games.json')).writeAsString(gamesJson);
}

void main() {
  setUpAll(initSqfliteForTests);

  test('MigrationRunner.run() inserts all JSON players into SQLite', () async {
    final db = await _openTestDb();
    final dir = await Directory.systemTemp.createTemp('migration_test_');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    await _writeTempPlayersJson(dir);

    await MigrationRunner.run(dir.path, db);

    final rows = await db.query('players');
    expect(rows, hasLength(2));
    expect(rows.first['first_name'], equals('Alice'));
    expect(rows.last['first_name'], equals('Bob'));
  });

  test(
    'MigrationRunner.run() inserts games and game_player positions',
    () async {
      final db = await _openTestDb();
      final dir = await Directory.systemTemp.createTemp(
        'migration_test_games_',
      );
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });

      await _writeTempPlayersJson(dir);
      await _writeTempGamesJson(dir);

      await MigrationRunner.run(dir.path, db);

      final gameRows = await db.query('games');
      expect(gameRows, hasLength(1));
      final playerPositionRows = await db.query(
        'game_players',
        orderBy: 'position ASC',
      );
      expect(playerPositionRows, hasLength(2));
      expect(playerPositionRows.first['player_id'], equals('player-uuid-1'));
      expect(playerPositionRows.first['position'], equals(0));
    },
  );

  test(
    'MigrationRunner.run() is idempotent: second run skips if data exists',
    () async {
      final db = await _openTestDb();
      final dir = await Directory.systemTemp.createTemp('migration_test_idem_');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });

      await _writeTempPlayersJson(dir);

      // First run migrates the data
      await MigrationRunner.run(dir.path, db);
      final rowsAfterFirst = await db.rawQuery('SELECT COUNT(*) FROM players');
      final countAfterFirst = (rowsAfterFirst.first.values.first as int?) ?? 0;
      expect(countAfterFirst, equals(2));

      // Second run must be a no-op — idempotency guard fires
      await MigrationRunner.run(dir.path, db);
      final rowsAfterSecond = await db.rawQuery('SELECT COUNT(*) FROM players');
      final countAfterSecond =
          (rowsAfterSecond.first.values.first as int?) ?? 0;
      expect(countAfterSecond, equals(2)); // unchanged
    },
  );

  test('MigrationRunner.run(): no-op when neither JSON file exists', () async {
    final db = await _openTestDb();
    final dir = await Directory.systemTemp.createTemp('migration_test_empty_');
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    // No JSON files written — run() must return without error
    await expectLater(MigrationRunner.run(dir.path, db), completes);

    final rows = await db.query('players');
    expect(rows, isEmpty);
  });

  test(
    'MigrationRunner.run() rolls back on error — SQLite stays empty after malformed JSON',
    () async {
      final db = await _openTestDb();
      final dir = await Directory.systemTemp.createTemp('migration_test_err_');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });

      // Write malformed players.json (invalid JSON content)
      await File(
        p.join(dir.path, 'players.json'),
      ).writeAsString('this is not valid json {{{');

      // run() must throw (propagates the parse/transaction error)
      await expectLater(MigrationRunner.run(dir.path, db), throwsException);

      // SQLite must remain empty — transaction was rolled back
      final rows = await db.query('players');
      expect(rows, isEmpty);
    },
  );
}
