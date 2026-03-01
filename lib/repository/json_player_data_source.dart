import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/data_source.dart';
import 'package:good_bad_board/repository/player_repository.dart';

class JsonPlayerDataSource implements DataSource<Player> {
  final String filePath;

  JsonPlayerDataSource({required this.filePath});

  @override
  Future<Iterable<Player>> loadAll() async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const Iterable.empty();
    }
    final json = await file.readAsString();
    final dto = PlayerDatabase.fromJson(jsonDecode(json));
    return dto.players;
  }

  @override
  Future<void> saveAll(Iterable<Player> data) async {
    final file = File(filePath);
    await file.create(recursive: true);
    final dto = PlayerDatabase(data);
    await file.writeAsString(jsonEncode(dto.toJson()));
    log('JsonPlayerDataSource saved at $file');
  }
}
