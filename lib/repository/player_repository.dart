import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:good_bad_board/repository/repository_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  late Map<String, Player> _cache;

  Future<void> initialize() async {
    final db = RepositoryService.instance.db;
    final rows = await db.query('players');
    _cache = Map.fromEntries(
      rows.map((row) => MapEntry(row['id'] as String, _mapToPlayer(row))),
    );
    log('PlayerRepository loaded ${_cache.length} players from SQLite');
  }

  Iterable<Player> getAllCachedPlayers() {
    return _cache.values.toSet();
  }

  @override
  Future<void> add(Player player) async {
    await RepositoryService.instance.db.insert(
      'players',
      _playerToMap(player),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cache[player.id] = player;
  }

  Future<void> addAll(Iterable<Player> players) async {
    final db = RepositoryService.instance.db;
    await db.transaction((txn) async {
      for (final player in players) {
        await txn.insert(
          'players',
          _playerToMap(player),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    _cache.addAll(Map.fromEntries(players.map((e) => MapEntry(e.id, e))));
  }

  @override
  Future<void> delete(String id) async {
    await RepositoryService.instance.db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
    _cache.remove(id);
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
    await RepositoryService.instance.db.update(
      'players',
      _playerToMap(value),
      where: 'id = ?',
      whereArgs: [id],
    );
    _cache[id] = value;
  }

  Map<String, dynamic> _playerToMap(Player p) => {
    'id': p.id,
    'first_name': p.firstName,
    'last_name': p.lastName,
    'elo': p.elo.name,
    'sign_in_id': p.signInId,
    'created_date': p.createdDate?.toIso8601String(),
  };

  Player _mapToPlayer(Map<String, dynamic> row) => Player(
    id: row['id'] as String,
    firstName: row['first_name'] as String,
    lastName: row['last_name'] as String,
    elo: Elo.values.firstWhere((e) => e.name == row['elo']),
    signInId: row['sign_in_id'] as String?,
    createdDate: row['created_date'] != null
        ? DateTime.parse(row['created_date'] as String)
        : null,
  );
}
