import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:good_bad_board/dto/repository_service.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player.g.dart';

@JsonSerializable()
class PlayerDto {
  final Iterable<Player> players;

  PlayerDto({required this.players});

  factory PlayerDto.fromJson(Map<String, dynamic> json) =>
      _$PlayerDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerDtoToJson(this);
}

class PlayerRepository {
  PlayerRepository._();

  static final PlayerRepository instance = PlayerRepository._();

  static const String playerFilename = 'players.json';

  late final Set<Player> _players;

  Future<void> initialize() async {
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$playerFilename',
    );
    if (!await selectedFile.exists()) {
      _players = {};
      return;
    }
    final json = await selectedFile.readAsString();
    final dto = PlayerDto.fromJson(jsonDecode(json));
    _players = dto.players.toSet();
  }

  Set<Player> getAllPlayers() {
    return Set.of(_players);
  }

  Future<void> createPlayer(Player player) async {
    _players.add(player);
    return await _save(_players);
  }

  Future<Player?> getPlayer(String id) async {
    return _players.singleWhereOrNull((p) => p.id == id);
  }

  Future<void> deletePlayer(String id) async {
    _players.removeWhere((p) => p.id == id);
    return await _save(_players);
  }

  Future<void> updatePlayer(Player player) async {
    final savedPlayer = _players.singleWhereOrNull((p) => p.id == player.id);
    if (savedPlayer == null) return;
    _players.removeWhere((p) => p.id == player.id);
    _players.add(player);
    return await _save(_players);
  }

  Future<void> _save(Iterable<Player> players) async {
    final selectedFile = File(
      '${RepositoryService.instance.rootPath}/$playerFilename',
    );
    final dto = PlayerDto(players: players);
    await selectedFile.writeAsString(jsonEncode(dto.toJson()));
  }
}
