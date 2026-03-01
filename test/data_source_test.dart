import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/data_source.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:test/test.dart';

/// In-memory implementation of DataSource for testing purposes.
class InMemoryPlayerDataSource implements DataSource<Player> {
  List<Player> _storage = [];

  @override
  Future<Iterable<Player>> loadAll() async {
    return List.unmodifiable(_storage);
  }

  @override
  Future<void> saveAll(Iterable<Player> data) async {
    _storage = data.toList();
  }
}

void main() {
  late InMemoryPlayerDataSource dataSource;

  setUp(() {
    dataSource = InMemoryPlayerDataSource();
  });

  group('InMemoryPlayerDataSource', () {
    test('loadAll returns empty when no data stored', () async {
      final result = await dataSource.loadAll();
      expect(result, isEmpty);
    });

    test('saveAll and loadAll round-trip', () async {
      final players = [
        Player.create(firstName: 'Alice', lastName: 'A', elo: Elo.c2),
        Player.create(firstName: 'Bob', lastName: 'B', elo: Elo.b1),
      ];

      await dataSource.saveAll(players);
      final loaded = await dataSource.loadAll();
      expect(loaded, hasLength(2));
    });

    test('saveAll replaces all existing data', () async {
      final initialPlayers = [
        Player.create(firstName: 'Alice', lastName: 'A', elo: Elo.c2),
      ];
      await dataSource.saveAll(initialPlayers);

      final newPlayers = [
        Player.create(firstName: 'Bob', lastName: 'B', elo: Elo.b1),
        Player.create(firstName: 'Carol', lastName: 'C', elo: Elo.a1),
      ];
      await dataSource.saveAll(newPlayers);

      final loaded = await dataSource.loadAll();
      expect(loaded, hasLength(2));
    });
  });

  group('PlayerRepository with DataSource', () {
    test('initialize loads data from data source', () async {
      final player = Player.create(
        firstName: 'Alice',
        lastName: 'A',
        elo: Elo.c2,
      );
      await dataSource.saveAll([player]);

      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      final result = await repo.get(player.id);
      expect(result, isNotNull);
      expect(result!.firstName, 'Alice');
    });

    test('add persists to data source', () async {
      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      final player = Player.create(
        firstName: 'Bob',
        lastName: 'B',
        elo: Elo.b1,
      );
      await repo.add(player);

      // Verify data was saved to the data source
      final stored = await dataSource.loadAll();
      expect(stored, hasLength(1));
    });

    test('delete persists to data source', () async {
      final player = Player.create(
        firstName: 'Alice',
        lastName: 'A',
        elo: Elo.c2,
      );
      await dataSource.saveAll([player]);

      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      await repo.delete(player.id);

      final stored = await dataSource.loadAll();
      expect(stored, isEmpty);
    });

    test('update persists to data source', () async {
      final player = Player.create(
        firstName: 'Alice',
        lastName: 'A',
        elo: Elo.c2,
      );
      await dataSource.saveAll([player]);

      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      final updatedPlayer = player.copyWith(elo: Elo.s1);
      await repo.update(player.id, updatedPlayer);

      final stored = (await dataSource.loadAll()).toList();
      expect(stored, hasLength(1));
      expect(stored.first.elo, Elo.s1);
    });

    test('getAll returns all cached players', () async {
      final players = List.generate(
        5,
        (i) => Player.create(
          firstName: 'Player',
          lastName: '$i',
          elo: Elo.values[i % Elo.values.length],
        ),
      );
      await dataSource.saveAll(players);

      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      final result = await repo.getAll();
      expect(result, hasLength(5));
    });

    test('getAll supports pagination', () async {
      final players = List.generate(
        5,
        (i) => Player.create(
          firstName: 'Player',
          lastName: '$i',
          elo: Elo.values[i % Elo.values.length],
        ),
      );
      await dataSource.saveAll(players);

      final repo = PlayerRepository.instance;
      await repo.initialize(dataSource);

      final result = await repo.getAll(count: 2, offset: 1);
      expect(result, hasLength(2));
    });
  });
}
