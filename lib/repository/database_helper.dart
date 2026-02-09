import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:good_bad_board/model/player.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseFilename = 'good_bad_board.db';
  static const int databaseVersion = 1;

  static const String playersTable = 'players';
  static const String gamesTable = 'games';
  static const String gamePlayersTable = 'game_players';

  static const String playersJsonFilename = 'players.json';
  static const String gamesJsonFilename = 'games.json';

  static dynamic sqlLiteDateTimeSerializer(DateTime? dateTime) =>
      dateTime?.millisecondsSinceEpoch;

  Database? _database;

  Future<void> initialize() async {
    await database;
    await _migrateFromJsonIfNeeded();
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await _databasePath();
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    if (isDesktop) {
      sqfliteFfiInit();
      return databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: databaseVersion,
          onConfigure: _configureDatabase,
          onCreate: _createTables,
        ),
      );
    }

    return openDatabase(
      dbPath,
      version: databaseVersion,
      onConfigure: _configureDatabase,
      onCreate: _createTables,
    );
  }

  Future<String> _databasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, databaseFilename);
  }

  Future<void> _configureDatabase(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
CREATE TABLE $playersTable (
  id TEXT PRIMARY KEY,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  elo INTEGER NOT NULL,
  signInId TEXT,
  createdDate INTEGER
)
''');

    await db.execute('''
CREATE TABLE $gamesTable (
  id TEXT PRIMARY KEY,
  createdDate INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE $gamePlayersTable (
  gameId TEXT NOT NULL,
  playerId TEXT NOT NULL,
  playerOrder INTEGER NOT NULL,
  PRIMARY KEY (gameId, playerId),
  FOREIGN KEY (gameId) REFERENCES $gamesTable(id) ON DELETE CASCADE,
  FOREIGN KEY (playerId) REFERENCES $playersTable(id) ON DELETE CASCADE
)
''');
  }

  Future<void> _migrateFromJsonIfNeeded() async {
    final db = await database;
    final playerCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $playersTable'),
        ) ??
        0;
    final gameCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $gamesTable'),
        ) ??
        0;

    if (playerCount > 0 || gameCount > 0) return;

    final directory = await getApplicationDocumentsDirectory();
    final playersFile = File(path.join(directory.path, playersJsonFilename));
    final gamesFile = File(path.join(directory.path, gamesJsonFilename));

    if (!await playersFile.exists() && !await gamesFile.exists()) return;
    final players = await _loadPlayersFromJson(playersFile);
    final games = await _loadGamesFromJson(gamesFile);

    if (players.isEmpty && games.isEmpty) return;

    await db.transaction((txn) async {
      for (final player in players) {
        await txn.insert(
          playersTable,
          _playerToRow(player),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final game in games) {
        await txn.insert(
          gamesTable,
          _gameToRow(game),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (var i = 0; i < game.playerIds.length; i++) {
          await txn.insert(gamePlayersTable, {
            'gameId': game.id,
            'playerId': game.playerIds[i],
            'playerOrder': i,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    log(
      'Migrated ${players.length} players and ${games.length} games from JSON',
    );
  }

  Future<List<Player>> _loadPlayersFromJson(File playersFile) async {
    if (!await playersFile.exists()) return [];
    final jsonMap =
        jsonDecode(await playersFile.readAsString()) as Map<String, dynamic>;
    final playersJson = jsonMap['players'] as List<dynamic>? ?? [];
    return playersJson
        .map((entry) => Player.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<List<_GameMigration>> _loadGamesFromJson(File gamesFile) async {
    if (!await gamesFile.exists()) return [];
    final jsonMap =
        jsonDecode(await gamesFile.readAsString()) as Map<String, dynamic>;
    final gamesJson = jsonMap['games'] as List<dynamic>? ?? [];
    return gamesJson.map((entry) {
      final gameMap = entry as Map<String, dynamic>;
      final playerDto = gameMap['playerDto'] as List<dynamic>? ?? [];
      final playerIds = playerDto
          .map((dto) => (dto as Map<String, dynamic>)['id'] as String)
          .toList();
      return _GameMigration(
        id: gameMap['id'] as String,
        createdDate: DateTime.parse(gameMap['createdDate'] as String),
        playerIds: playerIds,
      );
    }).toList();
  }

  Map<String, Object?> _playerToRow(Player player) => {
    'id': player.id,
    'firstName': player.firstName,
    'lastName': player.lastName,
    'elo': player.elo.index,
    'signInId': player.signInId,
    'createdDate': player.createdDate?.millisecondsSinceEpoch,
  };

  Map<String, Object?> _gameToRow(_GameMigration game) => {
    'id': game.id,
    'createdDate': game.createdDate.millisecondsSinceEpoch,
  };
}

class _GameMigration {
  const _GameMigration({
    required this.id,
    required this.createdDate,
    required this.playerIds,
  });

  final String id;
  final DateTime createdDate;
  final List<String> playerIds;
}
