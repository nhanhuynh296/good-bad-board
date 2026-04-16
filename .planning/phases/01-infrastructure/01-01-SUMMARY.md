---
phase: 01-infrastructure
plan: 01
subsystem: database
tags: [sqflite, sqlite, sqflite_common_ffi, path, flutter, schema, migration]

# Dependency graph
requires: []
provides:
  - sqflite ^2.4.2, sqflite_common_ffi ^2.3.0, path ^1.9.1 declared in pubspec.yaml
  - intl pinned to ^0.20.2 (was unconstrained `any`)
  - RepositoryService.instance.db — open sqflite Database after initialize()
  - SQLite schema v1: players (11 cols), games (2 cols), game_players junction (3 cols)
  - Phase 3 forward-ready nullable columns in players table (D-01)
  - Wave 0 test scaffold: schema_test.dart (4 passing), 5 stub files (15 skipped)
  - test/helpers/sqflite_test_helper.dart with initSqfliteForTests()
affects:
  - 01-02 (PlayerRepository/GameRepository SQLite CRUD)
  - 01-03 (MigrationRunner reads rootPath, writes to db)
  - 01-04 (GameData isolate test stubs filled in)

# Tech tracking
tech-stack:
  added:
    - sqflite ^2.4.2
    - sqflite_common_ffi ^2.3.0
    - path ^1.9.1
  patterns:
    - sqfliteFfiInit() + databaseFactory = databaseFactoryFfi guarded by Platform.isWindows || Platform.isLinux before openDatabase()
    - Schema created via _migrateV1(db) in onCreate/onUpgrade callbacks (no manual transaction — sqflite wraps automatically)
    - In-memory DB (inMemoryDatabasePath) pattern for isolated unit tests
    - initSqfliteForTests() helper in setUpAll() for all repository tests

key-files:
  created:
    - test/helpers/sqflite_test_helper.dart
    - test/repository/schema_test.dart
    - test/repository/player_repository_test.dart
    - test/repository/game_repository_test.dart
    - test/repository/migration_runner_test.dart
    - test/state/game_data_isolate_test.dart
  modified:
    - pubspec.yaml
    - lib/repository/repository_service.dart

key-decisions:
  - "Removed redundant sqflite import: sqflite_common_ffi re-exports all sqflite symbols; importing both causes unnecessary_import info (fatal in CI)"
  - "Pinned intl to ^0.20.2 not ^0.19.0: flutter_localizations SDK pins intl to 0.20.2; ^0.19.0 causes version solving failure"
  - "schema_test.dart replicates _migrateV1 DDL inline (no import of RepositoryService) to keep tests self-contained and avoid platform initialization in schema-only tests"

patterns-established:
  - "Platform guard pattern: sqfliteFfiInit() + databaseFactory = databaseFactoryFfi only on Windows/Linux"
  - "Wave 0 stub pattern: skip: 'Wave 0 stub — implemented in Plan NN (01-NN-PLAN.md)' for tests not yet implemented"
  - "Test helper import: setUpAll(initSqfliteForTests) at top of every repository test file"

requirements-completed:
  - INFRA-01

# Metrics
duration: 6min
completed: 2026-04-16
---

# Phase 01 Plan 01: SQLite Foundation Summary

**sqflite schema (players/games/game_players with Phase 3 D-01 nullable cols) added to RepositoryService, with Wave 0 test scaffold passing 4 schema tests and 15 stubs ready for Plans 02-04**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-16T01:34:33Z
- **Completed:** 2026-04-16T01:39:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- pubspec.yaml updated with sqflite ^2.4.2, sqflite_common_ffi ^2.3.0, path ^1.9.1; intl pinned from `any` to `^0.20.2`
- RepositoryService rewritten to open versioned SQLite DB with full schema (`_migrateV1`), including 5 Phase 3 forward-ready nullable columns per design decision D-01
- Six Wave 0 test scaffold files created; schema_test.dart passes 4 tests; all 15 stub tests skipped cleanly; `flutter test` exits 0

## Task Commits

Each task was committed atomically:

1. **Task 1: Add sqflite dependencies to pubspec.yaml and pin intl** - `a98e35a` (chore)
2. **Task 2: Rewrite RepositoryService with SQLite open and schema creation** - `32406ef` (feat)
3. **Task 3: Create Wave 0 test scaffold files** - `1f792d6` (test)

## Files Created/Modified

- `pubspec.yaml` - Added sqflite ^2.4.2, sqflite_common_ffi ^2.3.0, path ^1.9.1; pinned intl ^0.20.2
- `lib/repository/repository_service.dart` - Complete rewrite: late final Database db, sqfliteFfiInit guard, openDatabase with _migrateV1 schema (players/games/game_players)
- `test/helpers/sqflite_test_helper.dart` - initSqfliteForTests() for use in setUpAll()
- `test/repository/schema_test.dart` - 4 passing tests verifying all table columns including D-01 nullable cols
- `test/repository/player_repository_test.dart` - 5 skipped stubs for Plan 02
- `test/repository/game_repository_test.dart` - 3 skipped stubs for Plan 02
- `test/repository/migration_runner_test.dart` - 4 skipped stubs for Plan 03
- `test/state/game_data_isolate_test.dart` - 3 skipped stubs for Plan 04

## Decisions Made

- **Removed duplicate sqflite import**: `sqflite_common_ffi/sqflite_ffi.dart` re-exports all sqflite symbols; keeping both causes an `unnecessary_import` info lint which is fatal in CI (`--fatal-infos`). Import `sqflite_common_ffi` only.
- **intl pinned to ^0.20.2 not ^0.19.0**: The plan called for `^0.19.0`, but `flutter_localizations` (SDK) pins `intl` to exactly `0.20.2`, causing version solving failure. Corrected to `^0.20.2`.
- **schema_test.dart does not import RepositoryService**: Tests replicate the DDL inline using an in-memory DB. This avoids pulling in `path_provider` and platform plugins, which require Flutter test infrastructure not available in pure `dart test` context.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed intl version constraint incompatible with Flutter SDK**
- **Found during:** Task 1 (Add sqflite dependencies to pubspec.yaml and pin intl)
- **Issue:** Plan specified `intl: ^0.19.0` but `flutter_localizations` from the Flutter SDK pins intl to exactly `0.20.2`, making `^0.19.0` incompatible — `flutter pub get` fails with version solving error
- **Fix:** Changed `intl: ^0.19.0` to `intl: ^0.20.2` which is compatible with SDK's pinned 0.20.2
- **Files modified:** pubspec.yaml
- **Verification:** `flutter pub get` exits 0 and resolves intl 0.20.2
- **Committed in:** a98e35a (Task 1 commit)

**2. [Rule 1 - Bug] Removed redundant sqflite import (fatal lint in CI)**
- **Found during:** Task 2 (Rewrite RepositoryService)
- **Issue:** Plan template included both `import 'package:sqflite/sqflite.dart'` and `import 'package:sqflite_common_ffi/sqflite_ffi.dart'`. The latter re-exports all sqflite symbols, making the former redundant. `flutter analyze --fatal-infos` treats `unnecessary_import` as an error.
- **Fix:** Removed `import 'package:sqflite/sqflite.dart'` from repository_service.dart
- **Files modified:** lib/repository/repository_service.dart
- **Verification:** `flutter analyze lib/repository/repository_service.dart` reports 0 issues
- **Committed in:** 32406ef (Task 2 commit)

**3. [Rule 3 - Blocking] Ran build_runner to generate frozen model files for test compilation**
- **Found during:** Task 3 (Create Wave 0 test scaffold files)
- **Issue:** The worktree was created via `git reset --hard` to the base commit. Generated files (`*.freezed.dart`, `*.g.dart`) are gitignored and were absent from the worktree. Tests importing `player.dart`, `game.dart`, `player_repository.dart`, `game_repository.dart` failed to compile without them.
- **Fix:** Ran `dart run build_runner build --delete-conflicting-outputs`; generated 12 output files
- **Files modified:** (generated — gitignored, not committed)
- **Verification:** `flutter test test/repository/schema_test.dart` exits 0 with 4 passing
- **Committed in:** Not committed (gitignored generated files)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking)
**Impact on plan:** All auto-fixes necessary for correctness. No scope creep.

## Issues Encountered

- `libsqlite3.so` not on default library path (only `libsqlite3.so.0` present). Resolved by creating a symlink in `/tmp/sqlitelib/` and running tests with `LD_LIBRARY_PATH=/tmp/sqlitelib`. This is a CI/dev-environment concern — on Windows (primary target) `sqlite3.dll` is bundled by the sqlite3 Dart package automatically.

## Known Stubs

The following stubs are intentional Wave 0 scaffolding (not blocking plan goals):

| File | Tests | Reason |
|------|-------|--------|
| `test/repository/player_repository_test.dart` | 5 tests | Implemented by Plan 02 |
| `test/repository/game_repository_test.dart` | 3 tests | Implemented by Plan 02 |
| `test/repository/migration_runner_test.dart` | 4 tests | Implemented by Plan 03 |
| `test/state/game_data_isolate_test.dart` | 3 tests | Implemented by Plan 04 |

All stubs use explicit `skip:` markers with plan references — they do not prevent the plan's goal (schema + test scaffold) from being achieved.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns beyond what the plan's threat model covers. `RepositoryService.initialize()` introduces a local SQLite file write at `{rootPath}/good_bad_board.db` — covered by T-01-01 (hardcoded DDL, no injection surface) and T-01-02 (FFI guard mitigated per plan).

## Next Phase Readiness

- `RepositoryService.instance.db` is ready for Plans 02 (repository CRUD) and 03 (MigrationRunner)
- `rootPath` preserved for MigrationRunner JSON file reading
- Wave 0 test stubs in place; Plans 02-04 can fill them in immediately
- No blockers for Plans 02, 03, or 04

---
*Phase: 01-infrastructure*
*Completed: 2026-04-16*

## Self-Check: PASSED

- FOUND: repository_service.dart
- FOUND: sqflite_test_helper.dart
- FOUND: schema_test.dart
- FOUND: player_repository_test.dart
- FOUND: game_repository_test.dart
- FOUND: migration_runner_test.dart
- FOUND: game_data_isolate_test.dart
- FOUND: 01-01-SUMMARY.md
- FOUND commit: a98e35a
- FOUND commit: 32406ef
- FOUND commit: 1f792d6
