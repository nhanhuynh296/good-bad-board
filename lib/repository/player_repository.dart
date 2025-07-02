import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:good_bad_board/repository/repository_service.dart';

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

  late final Map<String, Player> _cache;

  Future<void> initialize() async {
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$databaseFilename',
    );
    if (!await selectedFile.exists()) {
      _cache = {};
      return;
    }
    final json = await selectedFile.readAsString();
    final dto = PlayerDatabase.fromJson(jsonDecode(json));
    _cache = Map.fromEntries(
      dto.players.map((player) => MapEntry(player.id, player)),
    );
  }

  Iterable<Player> getAllCachedPlayers() {
    return _cache.values.toSet();
  }

  @override
  Future<void> add(Player player) {
    _cache[player.id] = player;
    return save();
  }

  Future<void> addAll(Iterable<Player> players) async {
    _cache.addAll(Map.fromEntries(players.map((e) => MapEntry(e.id, e))));
    return save();
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
    return save();
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
  Future<void> update(String id, Player value) {
    _cache.update(id, (_) => value);
    return save();
  }

  Future<void> save() async {
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$databaseFilename',
    );

    await selectedFile.create(recursive: true);
    final dto = PlayerDatabase(_cache.values);
    await selectedFile.writeAsString(jsonEncode(dto.toJson()));
    log('${runtimeType.toString()} saved at $selectedFile');
  }
}
