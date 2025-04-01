import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:good_bad_board/dto/player.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:path_provider/path_provider.dart';

class Serializer {
  Serializer._();

  static final Serializer instance = Serializer._();

  late final Directory appDir;
  static const String playerFilename = 'players.json';

  Future<void> initialize() async {
    appDir = await getApplicationDocumentsDirectory();
    debugPrint("initialized, app dir: ${appDir.path}");
  }

  Future<List<Player>> loadPlayers() async {
    final selectedFile = File('${appDir.path}/$playerFilename');
    if (!await selectedFile.exists()) return [];
    final json = await selectedFile.readAsString();
    final dto = PlayerDto.fromJson(jsonDecode(json));
    return dto.players.toList();
  }

  Future<void> savePlayers(List<Player> players) async {
    final selectedFile = File(appDir.path + playerFilename);
    final dto = PlayerDto(players: players);
    await selectedFile.writeAsString(jsonEncode(dto.toJson()));
  }

  Future<File?> pickJsonFile() async {
    final downloadDir = await getDownloadsDirectory();
    final pickerResult = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select saved data file',
      initialDirectory: downloadDir?.path,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return (pickerResult?.files.firstOrNull?.path != null)
        ? File(pickerResult!.files.firstOrNull!.path!)
        : null;
  }
}
