import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/database_helper.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:sqflite/sqflite.dart';

part 'game_repository.freezed.dart';
part 'game_repository.g.dart';

@freezed
abstract class GameDto with _$GameDto {
  const factory GameDto(
    Iterable<PlayerDto> playerDto,
    String id,
    DateTime createdDate,
  ) = _GameDto;

  factory GameDto.fromJson(Map<String, dynamic> json) =>
      _$GameDtoFromJson(json);

  factory GameDto.fromGame(Game game) => GameDto(
    game.players.map(PlayerDto.fromPlayer),
    game.id,
    game.createdDate,
  );
}

@freezed
abstract class GameDatabase with _$GameDatabase {
  const factory GameDatabase(Iterable<GameDto> games) = _GameDatabase;

  factory GameDatabase.fromJson(Map<String, dynamic> json) =>
      _$GameDatabaseFromJson(json);
}

class GameRepository extends InMemoryRepository<Game> {
  GameRepository._();

  static final GameRepository instance = GameRepository._();

  static const String databaseFilename = 'games.json';

  late final Database _db;

  late final Map<String, Game> _cache;

  late final PlayerRepository _playerRepository;

  Future<void> initialize() async {
    _playerRepository = PlayerRepository.instance;
    _db = await DatabaseHelper.instance.database;

    final rows = await _db.query(
      DatabaseHelper.gamesTable,
      orderBy: 'createdDate ASC',
    );
    final games = <Game>[];
    for (final row in rows) {
      final gameId = row['id'] as String;
      final playerRows = await _db.query(
        DatabaseHelper.gamePlayersTable,
        columns: ['playerId'],
        where: 'gameId = ?',
        whereArgs: [gameId],
        orderBy: 'playerOrder ASC',
      );
      final playerIds = playerRows.map((playerRow) {
        return playerRow['playerId'] as String;
      });
      final maybePlayers = await Future.wait(
        playerIds.map(_playerRepository.get),
      );
      games.add(
        Game(
          players: maybePlayers.nonNulls.toList(growable: true),
          id: gameId,
          createdDate: DateTime.fromMillisecondsSinceEpoch(
            row['createdDate'] as int,
          ),
        ),
      );
    }

    _cache = Map.fromEntries(games.map((e) => MapEntry(e.id, e)));
  }

  @override
  Future<void> add(Game game) async {
    _cache[game.id] = game;
    await _db.transaction((txn) async {
      await _upsertGame(txn, game);
    });
    notifyListeners();
  }

  Future<void> addAll(Iterable<Game> games) async {
    _cache.addAll(Map.fromEntries(games.map((e) => MapEntry(e.id, e))));
    await _db.transaction((txn) async {
      for (final game in games) {
        await _upsertGame(txn, game);
      }
    });
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
    await _db.delete(
      DatabaseHelper.gamesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  @override
  Future<Game?> get(String id) async {
    return _cache[id];
  }

  @override
  Future<Iterable<Game>> getAll({int? count, int? offset}) async {
    final skippedEntries = _cache.values.skip(offset ?? 0);
    if (count != null) {
      return skippedEntries.take(count);
    }
    return skippedEntries;
  }

  @override
  Future<void> update(String id, Game value) async {
    _cache.update(id, (_) => value);
    await _db.transaction((txn) async {
      await _upsertGame(txn, value);
    });
    notifyListeners();
  }

  Future<void> save() async {
    await _db.transaction((txn) async {
      await txn.delete(DatabaseHelper.gamePlayersTable);
      await txn.delete(DatabaseHelper.gamesTable);
      for (final game in _cache.values) {
        await _upsertGame(txn, game);
      }
    });
    log('${runtimeType.toString()} saved to sqlite');
  }

  Map<String, Object?> _gameToRow(Game game) => {
    'id': game.id,
    'createdDate': game.createdDate.millisecondsSinceEpoch,
  };

  Future<void> _upsertGame(DatabaseExecutor txn, Game game) async {
    await txn.insert(
      DatabaseHelper.gamesTable,
      _gameToRow(game),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await txn.delete(
      DatabaseHelper.gamePlayersTable,
      where: 'gameId = ?',
      whereArgs: [game.id],
    );
    for (var i = 0; i < game.players.length; i++) {
      await txn.insert(
        DatabaseHelper.gamePlayersTable,
        {'gameId': game.id, 'playerId': game.players[i].id, 'playerOrder': i},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
