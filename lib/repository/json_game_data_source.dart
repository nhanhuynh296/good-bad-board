import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/data_source.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/repository_interface.dart';

class JsonGameDataSource implements DataSource<Game> {
  final String filePath;
  final InMemoryRepository<Player> playerRepository;

  JsonGameDataSource({
    required this.filePath,
    required this.playerRepository,
  });

  @override
  Future<Iterable<Game>> loadAll() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const Iterable.empty();
    }
    final json = await file.readAsString();
    final dto = GameDatabase.fromJson(jsonDecode(json));
    final games = await Future.wait(
      dto.games.map((gameDto) async {
        final maybePlayers = await Future.wait(
          gameDto.playerDto.map(
            (playerDto) => playerRepository.get(playerDto.id),
          ),
        );
        return Game(
          players: maybePlayers.nonNulls.toList(growable: true),
          id: gameDto.id,
          createdDate: gameDto.createdDate,
        );
      }),
    );
    return games;
  }

  @override
  Future<void> saveAll(Iterable<Game> data) async {
    final file = File(filePath);
    await file.create(recursive: true);
    final dto = GameDatabase(data.map(GameDto.fromGame));
    await file.writeAsString(jsonEncode(dto.toJson()));
    log('JsonGameDataSource saved at $file');
  }
}
