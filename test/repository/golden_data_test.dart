import 'dart:convert';
import 'dart:io';

import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/json_collection.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:test/test.dart';

/// A snapshot of real (name-scrubbed) club data — 245 players and 385
/// games, 5 of which reference player ids no `players.json` row resolves to.
/// Copied once into this fixture directory; never read from the real data
/// directory. See PERSISTENCE.md §2.2, §6 phase 4 and CONTEXT.md.
const _fixtureDir = 'test/fixtures/repository_golden';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('repository_golden_test');
    for (final entry in Directory(_fixtureDir).listSync().whereType<File>()) {
      final name = entry.uri.pathSegments.last;
      entry.copySync('${tempDir.path}/$name');
    }
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test(
    'loading real player data and saving it back with no changes reproduces '
    'the original bytes exactly — evidence the refactor changed nothing',
    () async {
      final collection = JsonCollection<Player>(
        rootDir: tempDir.path,
        fileName: PlayerRepository.databaseFilename,
        collectionKey: 'players',
        fromJson: Player.fromJson,
        toJson: (player) => player.toJson(),
        idOf: (player) => player.id,
      );
      await collection.load();

      // A no-op rewrite: every entry is put back exactly as loaded.
      await collection.upsertAll(collection.all());

      expect(
        File(
          '${tempDir.path}/${PlayerRepository.databaseFilename}',
        ).readAsBytesSync(),
        equals(File('$_fixtureDir/players.json').readAsBytesSync()),
      );
    },
  );

  test(
    'loading real game data and saving it back with no changes reproduces '
    'the original bytes exactly, including the 5 already-dangling player ids',
    () async {
      final collection = JsonCollection<GameDto>(
        rootDir: tempDir.path,
        fileName: GameRepository.databaseFilename,
        collectionKey: 'games',
        fromJson: GameDto.fromJson,
        toJson: (dto) => dto.toJson(),
        idOf: (dto) => dto.id,
      );
      await collection.load();

      await collection.upsertAll(collection.all());

      expect(
        File(
          '${tempDir.path}/${GameRepository.databaseFilename}',
        ).readAsBytesSync(),
        equals(File('$_fixtureDir/games.json').readAsBytesSync()),
      );
    },
  );

  test('a game roster naming an unknown player id keeps that id on disk after '
      'an unrelated save — regression guard for the roster-erasure bug '
      '(PERSISTENCE.md §3.1)', () async {
    PlayerRepository.instance = await PlayerRepository.initialize(
      rootDir: tempDir.path,
    );
    GameRepository.instance = await GameRepository.initialize(
      rootDir: tempDir.path,
    );

    Set<String> idsOnDisk() {
      final games =
          (jsonDecode(
                    File(
                      '${tempDir.path}/${GameRepository.databaseFilename}',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>)['games']
              as List;
      return {
        for (final game in games)
          for (final playerDto in game['playerDto'] as List)
            playerDto['id'] as String,
      };
    }

    final danglingIds = idsOnDisk().where(
      (id) => PlayerRepository.instance.byId(id) == null,
    );
    expect(danglingIds, isNotEmpty);
    final danglingIdsSnapshot = danglingIds.toSet();

    // An unrelated write — logging one brand-new game — must not shrink
    // any other game's roster.
    final newPlayer = Player.create(
      firstName: 'New',
      lastName: 'Player',
      elo: Elo.c2,
    );
    await PlayerRepository.instance.add(newPlayer);
    await GameRepository.instance.add(
      Game.create([newPlayer, newPlayer, newPlayer, newPlayer]),
    );

    expect(idsOnDisk().containsAll(danglingIdsSnapshot), isTrue);
  });
}
