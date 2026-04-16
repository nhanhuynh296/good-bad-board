import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:good_bad_board/repository/game_repository.dart'
    show GameDatabase;
import 'package:good_bad_board/repository/player_repository.dart'
    show PlayerDatabase;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MigrationRunner {
  static const _playerFile = 'players.json';
  static const _gameFile = 'games.json';

  /// Runs the one-time JSON → SQLite migration.
  ///
  /// - Idempotent: skips if the players table already has rows.
  /// - Transactional: rolls back completely on any error.
  /// - No-op: returns immediately if neither JSON file exists.
  /// - Throws on failure so AppLoader.loading() can surface an error state.
  static Future<void> run(String rootPath, Database db) async {
    final playerFile = File(p.join(rootPath, _playerFile));
    final gameFile = File(p.join(rootPath, _gameFile));

    final hasPlayers = await playerFile.exists();
    final hasGames = await gameFile.exists();

    if (!hasPlayers && !hasGames) {
      log('MigrationRunner: no JSON files found, nothing to migrate');
      return;
    }

    // Idempotency guard: skip if SQLite already has player data
    final countRows = await db.rawQuery('SELECT COUNT(*) FROM players');
    final existingCount = (countRows.first.values.first as int?) ?? 0;
    if (existingCount > 0) {
      log(
        'MigrationRunner: SQLite already has $existingCount players, '
        'skipping migration',
      );
      return;
    }

    log('MigrationRunner: starting JSON → SQLite migration');

    // All inserts in a single transaction — rolls back atomically on any error
    await db.transaction((txn) async {
      if (hasPlayers) {
        final json = await playerFile.readAsString();
        final dto = PlayerDatabase.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        int count = 0;
        for (final player in dto.players) {
          await txn.insert('players', {
            'id': player.id,
            'first_name': player.firstName,
            'last_name': player.lastName,
            'elo': player.elo.name,
            'sign_in_id': player.signInId,
            'created_date': player.createdDate?.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          count++;
        }
        log('MigrationRunner: migrated $count players');
      }

      if (hasGames) {
        final json = await gameFile.readAsString();
        final dto = GameDatabase.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
        int gameCount = 0;
        for (final gameDto in dto.games) {
          await txn.insert('games', {
            'id': gameDto.id,
            'created_date': gameDto.createdDate.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          int position = 0;
          for (final playerDto in gameDto.playerDto) {
            await txn.insert('game_players', {
              'game_id': gameDto.id,
              'player_id': playerDto.id,
              'position': position++,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          gameCount++;
        }
        log('MigrationRunner: migrated $gameCount games');
      }
    });
    // On any exception, sqflite auto-rolls back the transaction.
    // Exception propagates to AppLoader.loading() → FutureBuilder.hasError.

    log('MigrationRunner: migration complete');
    // JSON files are intentionally left in place as a natural backup.
    // The idempotency guard prevents re-migration on subsequent launches.
  }
}
