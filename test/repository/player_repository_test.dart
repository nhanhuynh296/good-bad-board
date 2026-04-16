import 'package:good_bad_board/model/player.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

Future<Database> _openTestDb() async {
  return openDatabase(
    inMemoryDatabasePath,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE players (
          id TEXT PRIMARY KEY, first_name TEXT NOT NULL, last_name TEXT NOT NULL,
          elo TEXT NOT NULL, sign_in_id TEXT, created_date TEXT,
          membership_type TEXT, last_played TEXT, avatar_path TEXT,
          session_fee_paid INTEGER, dues_status TEXT
        )
      ''');
    },
  );
}

void main() {
  setUpAll(initSqfliteForTests);

  test('PlayerRepository: _playerToMap produces correct column keys', () async {
    final db = await _openTestDb();
    final player = Player.create(
      firstName: 'Alice',
      lastName: 'Smith',
      elo: Elo.b1,
    );
    final map = {
      'id': player.id,
      'first_name': player.firstName,
      'last_name': player.lastName,
      'elo': player.elo.name,
      'sign_in_id': player.signInId,
      'created_date': player.createdDate?.toIso8601String(),
    };
    await db.insert(
      'players',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final rows = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [player.id],
    );
    expect(rows, hasLength(1));
    expect(rows.first['first_name'], equals('Alice'));
    expect(rows.first['last_name'], equals('Smith'));
    expect(rows.first['elo'], equals('b1'));
    await db.close();
  });

  test('PlayerRepository: insert and query round-trip', () async {
    final db = await _openTestDb();
    final player = Player.create(
      firstName: 'Bob',
      lastName: 'Jones',
      elo: Elo.c2,
    );
    final map = {
      'id': player.id,
      'first_name': player.firstName,
      'last_name': player.lastName,
      'elo': player.elo.name,
      'sign_in_id': null,
      'created_date': player.createdDate?.toIso8601String(),
    };
    await db.insert(
      'players',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final rows = await db.query('players');
    expect(rows, hasLength(1));
    final row = rows.first;
    final recovered = Player(
      id: row['id'] as String,
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      elo: Elo.values.firstWhere((e) => e.name == row['elo']),
      signInId: row['sign_in_id'] as String?,
      createdDate: row['created_date'] != null
          ? DateTime.parse(row['created_date'] as String)
          : null,
    );
    expect(recovered.firstName, equals('Bob'));
    expect(recovered.elo, equals(Elo.c2));
    await db.close();
  });

  test('PlayerRepository: delete removes row from SQLite', () async {
    final db = await _openTestDb();
    final player = Player.create(
      firstName: 'Carol',
      lastName: 'Lee',
      elo: Elo.a1,
    );
    final map = {
      'id': player.id,
      'first_name': 'Carol',
      'last_name': 'Lee',
      'elo': 'a1',
      'sign_in_id': null,
      'created_date': null,
    };
    await db.insert('players', map);
    await db.delete('players', where: 'id = ?', whereArgs: [player.id]);
    final rows = await db.query('players');
    expect(rows, isEmpty);
    await db.close();
  });

  test('PlayerRepository: update changes row values', () async {
    final db = await _openTestDb();
    final player = Player.create(
      firstName: 'Dave',
      lastName: 'Wu',
      elo: Elo.c1,
    );
    await db.insert('players', {
      'id': player.id,
      'first_name': 'Dave',
      'last_name': 'Wu',
      'elo': 'c1',
      'sign_in_id': null,
      'created_date': null,
    });
    await db.update(
      'players',
      {
        'first_name': 'David',
        'last_name': 'Wu',
        'elo': 'b2',
        'sign_in_id': null,
        'created_date': null,
      },
      where: 'id = ?',
      whereArgs: [player.id],
    );
    final rows = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [player.id],
    );
    expect(rows.first['first_name'], equals('David'));
    expect(rows.first['elo'], equals('b2'));
    await db.close();
  });
}
