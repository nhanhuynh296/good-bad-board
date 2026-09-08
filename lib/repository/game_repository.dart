import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/json_collection.dart';
import 'package:good_bad_board/repository/player_repository.dart';

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

  factory GameDto.fromGame(Game game) =>
      GameDto(game.playerIds.map(PlayerDto.new), game.id, game.createdDate);
}

/// Thin adapter over [JsonCollection] for `games.json`.
///
/// The cache holds the stored player ids ([GameDto]), never resolved
/// [Game.players], so a save can never shrink a roster whose ids no longer
/// resolve (see ADR-0001). [Game.playerIds] is the DTO's ids, unchanged;
/// resolving an id to a [Player] happens lazily in [Game.players], and an id
/// that resolves to nothing simply yields no player there — it still
/// survives on disk.
class GameRepository {
  GameRepository._(this._collection);

  static late GameRepository instance;

  static const String databaseFilename = 'games.json';

  final JsonCollection<GameDto> _collection;

  /// Notifies after every successful write.
  Listenable get listenable => _collection;

  static Future<GameRepository> initialize({required String rootDir}) async {
    final collection = JsonCollection<GameDto>(
      rootDir: rootDir,
      fileName: databaseFilename,
      collectionKey: 'games',
      fromJson: GameDto.fromJson,
      toJson: (dto) => dto.toJson(),
      idOf: (dto) => dto.id,
    );
    await collection.load();
    return GameRepository._(collection);
  }

  Game _resolve(GameDto dto) => Game(
    playerIds: dto.playerDto
        .map((playerDto) => playerDto.id)
        .toList(growable: true),
    id: dto.id,
    createdDate: dto.createdDate,
  );

  Iterable<Game> getAll() => _collection.all().map(_resolve);

  Future<void> add(Game game) => _collection.upsert(GameDto.fromGame(game));

  Future<void> addAll(Iterable<Game> games) =>
      _collection.upsertAll(games.map(GameDto.fromGame));

  Future<void> delete(String id) => _collection.remove(id);
}
