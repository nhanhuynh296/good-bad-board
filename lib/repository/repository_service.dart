import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RepositoryService {
  RepositoryService._();

  static final RepositoryService instance = RepositoryService._();

  late final String rootPath;
  late final Database db;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    rootPath = appDir.path;
    log('Application root path: $rootPath');

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    db = await openDatabase(
      p.join(rootPath, 'good_bad_board.db'),
      version: 1,
      onCreate: (db, version) async {
        await _migrateV1(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) await _migrateV1(db);
      },
    );
    log('SQLite database opened at ${p.join(rootPath, 'good_bad_board.db')}');
  }

  Future<void> _migrateV1(Database db) async {
    // Players table — forward-ready with Phase 3 nullable columns (D-01)
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

    // Games table — minimal per D-02 (Analytics columns added in Phase 5)
    await db.execute('''
      CREATE TABLE games (
        id            TEXT PRIMARY KEY,
        created_date  TEXT NOT NULL
      )
    ''');

    // Junction table for game-player relationships with ordered positions
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
  }
}
