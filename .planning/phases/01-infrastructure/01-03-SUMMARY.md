---
phase: 01-infrastructure
plan: 03
subsystem: database
tags: [sqflite, sqlite, migration, json, transaction, idempotency, flutter]

# Dependency graph
requires:
  - 01-01 (RepositoryService.instance.db, rootPath, sqflite schema, test helper)
  - 01-02 (PlayerDatabase.fromJson, GameDatabase.fromJson freezed DTOs)
provides:
  - MigrationRunner static class: run(rootPath, db) reads players.json/games.json and
    inserts all records into SQLite in a single transaction with idempotency guard
  - AppLoader.loading() updated: sequential RepositoryService → PersistentSetting →
    MigrationRunner → PlayerRepository → GameRepository (no more Future.wait)
  - 5 migration unit tests: happy-path players, happy-path games+positions, idempotency,
    no-op empty dir, rollback on malformed JSON
affects:
  - 01-04 (GameData isolate tests — no dependency, but loading() order is now fixed)
  - app startup: users upgrading from JSON storage see zero-data-loss silent migration

# Tech tracking
tech-stack:
  added: []
  patterns:
    - MigrationRunner pattern: static class, single static run() method, no instance state
    - Idempotency guard: COUNT(*) check before any inserts; ConflictAlgorithm.ignore as secondary guard
    - Transactional migration: db.transaction() wraps all inserts; sqflite auto-rolls back on exception
    - Exception propagation: no catch block in MigrationRunner — errors surface to AppLoader FutureBuilder
    - Inline COUNT extraction: (rawQuery('SELECT COUNT(*)').first.values.first as int?) ?? 0
      (Sqflite.firstIntValue only in sqflite package, not sqflite_common_ffi)

key-files:
  created:
    - lib/repository/migration_runner.dart
  modified:
    - lib/main.dart
    - test/repository/migration_runner_test.dart

key-decisions:
  - "Replaced Sqflite.firstIntValue with inline rawQuery extraction: Sqflite class lives in sqflite package only, not sqflite_common_ffi. Using both causes unnecessary_import lint fatal in CI. Inline (rows.first.values.first as int?) ?? 0 achieves identical semantics."
  - "Future.wait replaced with sequential awaits: RepositoryService must complete before MigrationRunner (needs open db), so parallelising RepositoryService and PersistentSetting is unsafe. Sequential order is explicit and correct."
  - "JSON files left in place after migration: natural backup; idempotency guard (COUNT > 0) prevents re-insertion on subsequent launches."

patterns-established:
  - "MigrationRunner: static-only class (no instantiation) with a single run(rootPath, db) entry point — matches the one-shot nature of migration"
  - "Idempotency via COUNT(*): check player row count before any transaction; if > 0, return immediately — ConflictAlgorithm.ignore is secondary safety net only"

requirements-completed:
  - INFRA-02

# Metrics
duration: 8min
completed: 2026-04-16
---

# Phase 01 Plan 03: MigrationRunner Summary

**One-time JSON-to-SQLite migration via transactional MigrationRunner.run() with idempotency guard, wired into AppLoader.loading() between RepositoryService init and PlayerRepository init**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-16T02:05:00Z
- **Completed:** 2026-04-16T02:13:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `lib/repository/migration_runner.dart`: static `run(rootPath, db)` reads players.json and games.json, inserts all records (players, games, game_players positions) in a single `db.transaction()`, with COUNT(*) idempotency guard and ConflictAlgorithm.ignore on every insert
- Updated `lib/main.dart` `loading()`: removed `Future.wait`, added sequential awaits with MigrationRunner.run() between RepositoryService.initialize() and PlayerRepository.initialize() — enforces correct initialization order
- Replaced 4 Wave 0 stubs in migration_runner_test.dart with 5 real tests (added games+positions test); all pass against in-memory SQLite

## Task Commits

Each task was committed atomically:

1. **Task 1: Create MigrationRunner and implement migration tests** - `6829ef6` (feat)
2. **Task 2: Update AppLoader.loading() to invoke MigrationRunner in correct order** - `bf1573a` (feat)

## Files Created/Modified

- `lib/repository/migration_runner.dart` - New file: static MigrationRunner class with run(rootPath, db); idempotency guard; transactional JSON→SQLite insert for players and games; exceptions propagate to AppLoader
- `lib/main.dart` - Updated loading(): import added; Future.wait replaced with sequential awaits; MigrationRunner.run() inserted at correct position
- `test/repository/migration_runner_test.dart` - Wave 0 stubs replaced with 5 real tests using in-memory SQLite and temp directories

## Decisions Made

- **Replaced Sqflite.firstIntValue with inline extraction**: `Sqflite` class is only in the `sqflite` package, not `sqflite_common_ffi`. Importing both packages causes `unnecessary_import` info lint which is fatal in CI (`--fatal-infos`). Fixed with `(rows.first.values.first as int?) ?? 0` which is equivalent and import-safe.
- **Sequential awaits instead of Future.wait**: RepositoryService must complete before MigrationRunner (provides the open Database), so parallelising RepositoryService and PersistentSetting would create a race condition. Sequential is explicit, correct, and the simplest safe change.
- **JSON files left in place**: Natural backup for users; idempotency guard prevents re-migration. No file deletion logic needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced Sqflite.firstIntValue with inline rawQuery extraction**
- **Found during:** Task 1 (Create MigrationRunner and implement migration tests)
- **Issue:** Plan template used `Sqflite.firstIntValue(await db.rawQuery(...))` but `Sqflite` class is only exported by the `sqflite` package. Both migration_runner.dart and migration_runner_test.dart import only `sqflite_common_ffi` (per Plan 02 decision — importing both causes fatal `unnecessary_import` lint). Compilation failed with "Undefined name 'Sqflite'".
- **Fix:** Replaced with `(rows.first.values.first as int?) ?? 0` in both migration_runner.dart and migration_runner_test.dart
- **Files modified:** lib/repository/migration_runner.dart, test/repository/migration_runner_test.dart
- **Verification:** `flutter test test/repository/migration_runner_test.dart` exits 0 with 5 tests passing
- **Committed in:** 6829ef6 (Task 1 commit)

**2. [Rule 1 - Bug] dart format applied before commit**
- **Found during:** Task 1 verify step
- **Issue:** `dart format --output=none --set-exit-if-changed` exited 1 on both new files
- **Fix:** Ran `dart format lib/repository/migration_runner.dart test/repository/migration_runner_test.dart`
- **Files modified:** lib/repository/migration_runner.dart, test/repository/migration_runner_test.dart
- **Verification:** `dart format --output=none --set-exit-if-changed` exits 0
- **Committed in:** 6829ef6 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correctness and CI compliance. No scope creep.

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None — no external service configuration required.

## Known Stubs

None — all migration tests are fully implemented and passing. The Wave 0 game_data_isolate_test.dart stubs (Plan 04) remain intentional scaffolding.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced. MigrationRunner reads local files from `getApplicationDocumentsDirectory()` — covered by T-03-01 (accept: not user-accessible on mobile). Transactional rollback covers T-03-02. COUNT(*) guard covers T-03-03. Exception propagation to FutureBuilder covers T-03-04.

## Next Phase Readiness

- MigrationRunner is complete and wired into AppLoader — zero-data-loss upgrade path for JSON→SQLite is live
- AppLoader.loading() initialization order is now correct and explicit
- No blockers for Plan 04 (GameData isolate offload) or any subsequent phase
- Full test suite: 25 tests passing, 0 skips remaining in Plans 01-03 scope

---
*Phase: 01-infrastructure*
*Completed: 2026-04-16*

## Self-Check: PASSED

- FOUND: lib/repository/migration_runner.dart
- FOUND: lib/main.dart (contains MigrationRunner.run())
- FOUND: test/repository/migration_runner_test.dart (5 real tests, 0 skips)
- FOUND commit: 6829ef6
- FOUND commit: bf1573a
