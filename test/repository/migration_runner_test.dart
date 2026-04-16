import 'package:test/test.dart';

import '../helpers/sqflite_test_helper.dart';

void main() {
  setUpAll(initSqfliteForTests);

  test(
    'MigrationRunner.run() inserts all JSON players and games into SQLite',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 03 (01-03-PLAN.md)',
  );

  test(
    'MigrationRunner.run() is idempotent: running twice does not duplicate data',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 03 (01-03-PLAN.md)',
  );

  test(
    'MigrationRunner.run() rolls back transaction on error — SQLite remains empty',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 03 (01-03-PLAN.md)',
  );

  test(
    'MigrationRunner.run() is a no-op when no JSON files exist',
    () async {},
    skip: 'Wave 0 stub — implemented in Plan 03 (01-03-PLAN.md)',
  );
}
