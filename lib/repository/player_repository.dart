import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/database_helper.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:sqflite/sqflite.dart';

part 'player_repository.freezed.dart';
part 'player_repository.g.dart';

/// How player is referenced in other dto class
@freezed
abstract class PlayerDto with _$PlayerDto {
  const factory PlayerDto(String id) = _PlayerDto;

  factory PlayerDto.fromJson(Map<String, dynamic> json) =>
      _$PlayerDtoFromJson(json);

  factory PlayerDto.fromPlayer(Player player) => PlayerDto(player.id);
}

@freezed
abstract class PlayerDatabase with _$PlayerDatabase {
  const factory PlayerDatabase(Iterable<Player> players) = _PlayerDatabase;

  factory PlayerDatabase.fromJson(Map<String, dynamic> json) =>
      _$PlayerDatabaseFromJson(json);
}

class PlayerRepository extends InMemoryRepository<Player> {
  PlayerRepository._();

  static final PlayerRepository instance = PlayerRepository._();

  static const String databaseFilename = 'players.json';

  late final Database _db;

  late final Map<String, Player> _cache;

  Future<void> initialize() async {
    _db = await DatabaseHelper.instance.database;
    final rows = await _db.query(DatabaseHelper.playersTable);
    final players = rows.map(Player.fromSqliteRow);
    _cache = Map.fromEntries(
      players.map((player) => MapEntry(player.id, player)),
    );
  }

  Iterable<Player> getAllCachedPlayers() {
    return _cache.values.toSet();
  }

  @override
  Future<void> add(Player player) async {
    _cache[player.id] = player;
    await _db.insert(
      DatabaseHelper.playersTable,
      player.toSqliteRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> addAll(Iterable<Player> players) async {
    _cache.addAll(Map.fromEntries(players.map((e) => MapEntry(e.id, e))));
    await _db.transaction((txn) async {
      for (final player in players) {
        await txn.insert(
          DatabaseHelper.playersTable,
          player.toSqliteRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    notifyListeners();
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
    await _db.delete(
      DatabaseHelper.playersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Player?> get(String id) async {
    return _cache[id];
  }

  @override
  Future<Iterable<Player>> getAll({int? count, int? offset}) async {
    final skippedEntries = _cache.values.skip(offset ?? 0);
    if (count != null) {
      return skippedEntries.take(count);
    }
    return skippedEntries;
  }

  Future<Player?> getPlayerFromDto(PlayerDto dto) async {
    return _cache[dto.id];
  }

  @override
  Future<void> update(String id, Player value) async {
    _cache.update(id, (_) => value);
    await _db.update(
      DatabaseHelper.playersTable,
      value.toSqliteRow(),
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<void> save() async {
    await _db.transaction((txn) async {
      await txn.delete(DatabaseHelper.playersTable);
      for (final player in _cache.values) {
        await txn.insert(
          DatabaseHelper.playersTable,
          player.toSqliteRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    log('${runtimeType.toString()} saved to sqlite');
  }
}
