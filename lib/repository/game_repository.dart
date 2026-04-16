import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:good_bad_board/repository/repository_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  late Map<String, Game> _cache;

  late PlayerRepository _playerRepository;

  Future<void> initialize() async {
    _playerRepository = PlayerRepository.instance;
    final db = RepositoryService.instance.db;

    final gameRows = await db.query('games');
    final games = await Future.wait(
      gameRows.map((row) async {
        final playerRows = await db.query(
          'game_players',
          where: 'game_id = ?',
          whereArgs: [row['id']],
          orderBy: 'position ASC',
        );
        final maybePlayers = await Future.wait(
          playerRows.map(
            (pr) => _playerRepository.get(pr['player_id'] as String),
          ),
        );
        return Game(
          players: maybePlayers.nonNulls.toList(growable: true),
          id: row['id'] as String,
          createdDate: DateTime.parse(row['created_date'] as String),
        );
      }),
    );
    _cache = Map.fromEntries(games.map((g) => MapEntry(g.id, g)));
    log('GameRepository loaded ${_cache.length} games from SQLite');
  }

  @override
  Future<void> add(Game game) async {
    final db = RepositoryService.instance.db;
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
    _cache[game.id] = game;
  }

  Future<void> addAll(Iterable<Game> games) async {
    for (final game in games) {
      await add(game);
    }
  }

  @override
  Future<void> delete(String id) async {
    final db = RepositoryService.instance.db;
    await db.transaction((txn) async {
      await txn.delete('game_players', where: 'game_id = ?', whereArgs: [id]);
      await txn.delete('games', where: 'id = ?', whereArgs: [id]);
    });
    _cache.remove(id);
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
    final db = RepositoryService.instance.db;
    await db.transaction((txn) async {
      await txn.update(
        'games',
        {'created_date': value.createdDate.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.delete('game_players', where: 'game_id = ?', whereArgs: [id]);
      for (int i = 0; i < value.players.length; i++) {
        await txn.insert('game_players', {
          'game_id': id,
          'player_id': value.players[i].id,
          'position': i,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    _cache[id] = value;
  }
}
