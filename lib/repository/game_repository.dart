import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/repository_interface.dart';
import 'package:good_bad_board/repository/repository_service.dart';

part 'game_repository.freezed.dart';
part 'game_repository.g.dart';

@freezed
abstract class GameDto with _$GameDto {
  const factory GameDto(Iterable<PlayerDto> playerDto, String id) = _GameDto;

  factory GameDto.fromJson(Map<String, dynamic> json) =>
      _$GameDtoFromJson(json);

  factory GameDto.fromGame(Game game) =>
      GameDto(game.players.map(PlayerDto.fromPlayer), game.id);
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

  late final Map<String, Game> _cache;

  late final PlayerRepository _playerRepository;

  Future<void> initialize() async {
    _playerRepository = PlayerRepository.instance;
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$databaseFilename',
    );

    if (!await selectedFile.exists()) {
      _cache = {};
      return;
    }
    final json = await selectedFile.readAsString();
    final dto = GameDatabase.fromJson(jsonDecode(json));
    final games = await Future.wait(
      dto.games.map((gameDto) async {
        final maybePlayers = await Future.wait(
          gameDto.playerDto.map(_playerRepository.getPlayerFromDto),
        );
        return Game(
          players: maybePlayers.nonNulls.toFixedLengthList(),
          id: gameDto.id,
        );
      }),
    );

    _cache = Map.fromEntries(games.map((e) => MapEntry(e.id, e)));
  }

  @override
  Future<void> add(Game game) {
    _cache[game.id] = game;
    return save();
  }

  Future<void> addAll(Iterable<Game> games) async {
    _cache.addAll(Map.fromEntries(games.map((e) => MapEntry(e.id, e))));
    return save();
  }

  @override
  Future<void> delete(id) async {
    _cache.remove(id);
    return save();
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
  Future<void> update(String id, Game value) {
    _cache.update(id, (_) => value);
    return save();
  }

  Future<void> save() async {
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$databaseFilename',
    );
    await selectedFile.create(recursive: true);
    final dto = GameDatabase(_cache.values.map(GameDto.fromGame));
    await selectedFile.writeAsString(jsonEncode(dto.toJson()));
    log('${runtimeType.toString()} saved at $selectedFile');
  }
}
