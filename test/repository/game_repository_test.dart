import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

void main() {
  setUpAll(initSqfliteForTests);

  test(
    'GameRepository.add() persists game and player positions to SQLite',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'GameRepository.initialize() reconstructs games with players from SQLite JOIN',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );

  test(
    'GameRepository.delete() removes game and game_players rows',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 02 (01-02-PLAN.md)',
  );
}
