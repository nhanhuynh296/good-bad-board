import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

void main() {
  setUpAll(initSqfliteForTests);

  test(
    'PlayerRepository.add() persists player to SQLite',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'PlayerRepository.getAll() returns all persisted players',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'PlayerRepository.delete() removes player from SQLite and cache',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'PlayerRepository.update() persists changes to SQLite',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'PlayerRepository.initialize() populates cache from SQLite',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );
}
