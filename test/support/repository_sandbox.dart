import 'dart:io';

import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/repository/session_template_repository.dart';

/// Points every repository singleton at a fresh temp directory.
///
/// [PlayerRepository.instance] and friends are `late` — unset until this (or
/// [main.dart]'s `loading()`) assigns them — so a test that forgets to call
/// this crashes on first use instead of silently writing to whatever
/// directory an earlier test or app run left behind.
///
/// ```dart
/// late RepositorySandbox sandbox;
/// setUp(() async => sandbox = await RepositorySandbox.setUp());
/// tearDown(() => sandbox.tearDown());
/// ```
class RepositorySandbox {
  RepositorySandbox._(this.tempDir);

  final Directory tempDir;

  static Future<RepositorySandbox> setUp([
    String prefix = 'repository_sandbox',
  ]) async {
    final tempDir = Directory.systemTemp.createTempSync(prefix);
    PlayerRepository.instance = await PlayerRepository.initialize(
      rootDir: tempDir.path,
    );
    GameRepository.instance = await GameRepository.initialize(
      rootDir: tempDir.path,
    );
    SessionLogRepository.instance = await SessionLogRepository.initialize(
      rootDir: tempDir.path,
    );
    PendingRegistrationRepository.instance =
        await PendingRegistrationRepository.initialize(rootDir: tempDir.path);
    SessionTemplateRepository.instance =
        await SessionTemplateRepository.initialize(rootDir: tempDir.path);
    return RepositorySandbox._(tempDir);
  }

  void tearDown() => tempDir.deleteSync(recursive: true);
}

/// Creates [n] evenly Elo-spread test players and registers them in
/// [PlayerRepository.instance] — required since [Game.players] resolves a
/// roster id against the repository, not an embedded value.
Future<List<Player>> createTestPlayers(
  int n, {
  String firstName = 'Player',
}) async {
  final players = List.generate(
    n,
    (i) => Player.create(
      firstName: firstName,
      lastName: '$i',
      elo: Elo.values[i % Elo.values.length],
    ),
  );
  await PlayerRepository.instance.addAll(players);
  return players;
}
