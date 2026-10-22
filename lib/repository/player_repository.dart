import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/json_collection.dart';

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

/// Thin adapter over [JsonCollection] for `players.json`.
class PlayerRepository {
  PlayerRepository._(this._collection);

  static late PlayerRepository instance;

  static const String databaseFilename = 'players.json';

  final JsonCollection<Player> _collection;

  /// Notifies after every successful write.
  Listenable get listenable => _collection;

  static Future<PlayerRepository> initialize({required String rootDir}) async {
    final collection = JsonCollection<Player>(
      rootDir: rootDir,
      fileName: databaseFilename,
      collectionKey: 'players',
      fromJson: Player.fromJson,
      toJson: (player) => player.toJson(),
      idOf: (player) => player.id,
    );
    await collection.load();
    return PlayerRepository._(collection);
  }

  /// Looks up a player by id, anonymised or not — for resolving a
  /// historical Game roster, where an anonymised player must still resolve.
  Player? byId(String id) => _collection.byId(id);

  /// Listed players — excludes anonymised (deleted) rows. What the
  /// organizer picks a player from: the roster list, check-in, matchmaking.
  Iterable<Player> listedPlayers() =>
      _collection.all().where((player) => !player.isAnonymised);

  /// Adds a new player, or overwrites an existing one with the same id.
  Future<void> add(Player player) => _collection.upsert(player);

  Future<void> addAll(Iterable<Player> players) =>
      _collection.upsertAll(players);

  Future<void> delete(String id) => _collection.remove(id);
}
