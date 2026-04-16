import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

void main() {
  late Database db;

  setUpAll(initSqfliteForTests);

  setUp(() async {
    // Use in-memory database for fast, isolated tests
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Replicate the schema from RepositoryService._migrateV1
        await db.execute('''
          CREATE TABLE players (
            id               TEXT PRIMARY KEY,
            first_name       TEXT NOT NULL,
            last_name        TEXT NOT NULL,
            elo              TEXT NOT NULL,
            sign_in_id       TEXT,
            created_date     TEXT,
            membership_type  TEXT,
            last_played      TEXT,
            avatar_path      TEXT,
            session_fee_paid INTEGER,
            dues_status      TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE games (
            id            TEXT PRIMARY KEY,
            created_date  TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE game_players (
            game_id    TEXT NOT NULL,
            player_id  TEXT NOT NULL,
            position   INTEGER NOT NULL,
            PRIMARY KEY (game_id, position),
            FOREIGN KEY (game_id)   REFERENCES games(id),
            FOREIGN KEY (player_id) REFERENCES players(id)
          )
        ''');
      },
    );
  });

  tearDown(() async => db.close());

  test('players table exists with all required columns', () async {
    final result = await db.rawQuery("PRAGMA table_info('players')");
    final columns = result.map((row) => row['name'] as String).toSet();
    expect(
      columns,
      containsAll([
        'id',
        'first_name',
        'last_name',
        'elo',
        'sign_in_id',
        'created_date',
      ]),
    );
  });

  test(
    'players table has all Phase 3 forward-ready nullable columns (D-01)',
    () async {
      final result = await db.rawQuery("PRAGMA table_info('players')");
      final columns = result.map((row) => row['name'] as String).toSet();
      expect(
        columns,
        containsAll([
          'membership_type',
          'last_played',
          'avatar_path',
          'session_fee_paid',
          'dues_status',
        ]),
      );
    },
  );

  test('games table exists with required columns', () async {
    final result = await db.rawQuery("PRAGMA table_info('games')");
    final columns = result.map((row) => row['name'] as String).toSet();
    expect(columns, containsAll(['id', 'created_date']));
  });

  test('game_players table exists with required columns', () async {
    final result = await db.rawQuery("PRAGMA table_info('game_players')");
    final columns = result.map((row) => row['name'] as String).toSet();
    expect(columns, containsAll(['game_id', 'player_id', 'position']));
  });
}
