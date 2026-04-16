# Phase 1: Infrastructure - Research

**Researched:** 2026-04-16
**Domain:** Flutter SQLite migration (sqflite), Dart isolates, repository refactor
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Players table is forward-ready — define all known Phase 3 columns as nullable in Phase 1:
  `membership_type`, `last_played`, `avatar_path`, `session_fee_paid`, `dues_status`. Phase 3 populates
  them without a second migration.
- **D-02:** Games table is minimal — only migrate fields that exist today. Phase 5 (Analytics) will add
  its analytics columns (`session_duration`, `court_game_count`, `paying_snapshot`) via an ALTER TABLE
  migration when that phase runs.
- **D-03:** Preserve the existing `InMemoryRepository<V>` contract where feasible so call sites in views
  and state layers don't change. Make targeted improvements only where obviously needed (e.g., explicit
  `open`/`close` lifecycle, async factory for initialization). Avoid a full async-native redesign.
- **D-04:** SQLite implementation uses `sqflite` — no ORM (drift, floor). Manual SQL.
- **D-05:** Migration is silent and automatic on first launch. Zero data loss is a hard constraint. No
  user interaction required.

### Claude's Discretion

- **Migration failure handling:** Recommend showing an error state rather than silently swallowing
  failures. A partial migration should roll back (SQLite transaction). Surface an error screen so the
  user knows rather than silently losing data.
- **`trotter` dependency removal:** If inlining `Combinations` and `Amalgams` is a small, contained
  change during the isolate refactor, do it opportunistically. If it risks scope creep, leave for a
  cleanup phase.
- **`intl: any` constraint:** Flag if touched during Phase 1 pubspec changes; pin to `^0.19.0` or
  current compatible range.

### Deferred Ideas (OUT OF SCOPE)

- Migration failure handling is decided by Claude's Discretion (see above) — not a user-specified area.
- `trotter` dependency removal is optional opportunistic cleanup, not a hard requirement.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-01 | All player and game data is stored in SQLite (`sqflite`) instead of JSON flat files | Schema design, sqflite API patterns, Windows FFI init, repository replacement |
| INFRA-02 | On first launch after upgrade, the app silently migrates all existing JSON player and game data into SQLite with zero data loss | Migration runner strategy, JSON detection, transaction rollback pattern |
| INFRA-03 | The ELO optimisation algorithm (`_improveEloSpread`) runs in a Dart isolate so the main UI thread remains responsive during game generation | `Isolate.run()` / `compute()`, sendable types analysis for `Player` and `Game` |
</phase_requirements>

---

## Summary

Phase 1 replaces the in-memory JSON repository layer with a SQLite-backed layer using the `sqflite`
package, adds a one-time silent migration runner that converts existing `players.json` and `games.json`
into the new schema, and offloads the greedy ELO optimizer (`_improveEloSpread`) to a background Dart
isolate to eliminate UI freeze.

The existing codebase is well-positioned for this migration. The singleton repository pattern, the
already-async `makeGame()`, and the clear DTO layer all make this a contained infrastructure swap with
no public API changes visible to the view layer. The primary implementation risks are: (1) ensuring the
Windows-desktop FFI init path (`sqfliteFfiInit` + `databaseFactoryFfi`) is applied before any database
open call, and (2) confirming that `Player` and `Game` objects are sendable across isolates before
choosing the isolate approach.

**Primary recommendation:** Add `sqflite` + `sqflite_common_ffi` + `path` to pubspec. Replace the two
JSON repositories with SQLite-backed implementations that preserve the `InMemoryRepository<V>` method
signatures. Run the JSON-to-SQLite migration in a transaction inside `AppLoader.loading()` before the
normal repository initialization. Offload `_improveEloSpread` via `compute()` by extracting it and its
inputs to a top-level function with plain Dart types.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SQLite schema + CRUD | Repository (`lib/repository/`) | — | Existing repository layer is the persistence tier; SQLite replaces JSON file I/O |
| Migration runner (JSON → SQLite) | Repository (`lib/repository/`) | App bootstrap (`lib/main.dart`) | Migration runs at init time, reads JSON from disk, writes to SQLite; belongs in repo layer, triggered from AppLoader |
| ELO optimizer offload | State (`lib/state/game_data.dart`) | — | `makeGame()` already lives in GameData; isolate wrapper goes here; no view layer changes |
| Database path resolution | Repository service (`RepositoryService`) | — | Already owns `rootPath`; add `dbPath` alongside |
| FFI initialization (Windows) | App bootstrap (`lib/main.dart`) | — | `sqfliteFfiInit()` must run before any `openDatabase()` call, which happens in AppLoader.loading() |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `sqflite` | 2.4.2 | SQLite database for Android, iOS, macOS | Official Flutter SQLite package; 5.5k+ pub likes; maintained by tekartik.com |
| `sqflite_common_ffi` | 2.3.7+1 (resolvable) / 2.4.0+2 (latest) | SQLite via FFI for Windows and Linux desktop | Required for Windows target; same API as sqflite; also enables unit tests without emulator |
| `path` | 1.9.1 (already transitive) | Path construction for DB file path | Used instead of `getDatabasesPath()` which has "lame" FFI implementation |

> Note: `path_provider` is already in the project (^2.1.5) and provides `getApplicationDocumentsDirectory()`.
> Use `path_provider` + `path` together to construct the DB file path on all platforms.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter/foundation.dart` (`compute`) | SDK (Flutter 3.35.7) | Run isolate computation from Flutter | Use for `_improveEloSpread` offload — simpler than raw `Isolate.run()`, same effect on native |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `sqflite` (manual SQL) | `drift` ORM | Drift provides type-safe queries and codegen but D-04 locks in sqflite with manual SQL |
| `sqflite` (manual SQL) | `floor` | Same as drift — locked out by D-04 |
| `compute()` | `Isolate.run()` | `Isolate.run()` is equivalent on native; `compute()` is the Flutter idiom and handles web gracefully |

**Installation:**

```bash
flutter pub add sqflite sqflite_common_ffi path
```

**Version verification (run before plan execution):**

```bash
flutter pub add sqflite sqflite_common_ffi path --dry-run 2>/dev/null | grep -E "sqflite|path |sqlite3"
```

Expected output lines (verified 2026-04-16):
- `sqflite 2.4.2` [VERIFIED: pub.dev API]
- `sqflite_common_ffi 2.3.7+1` (constraint `^2.3.0` will resolve; `2.4.0+2` is latest) [VERIFIED: pub.dev API]
- `path 1.9.1` (already transitive, promoted to direct) [VERIFIED: pub.dev API]

---

## Architecture Patterns

### System Architecture Diagram

```
AppLoader.loading()
    │
    ├─ RepositoryService.initialize()    → resolves rootPath, dbPath
    ├─ PersistentSetting.initialize()   → SharedPreferences (unchanged)
    │
    ├─ MigrationRunner.run(rootPath, db) ─────────────────────────────┐
    │   │                                                              │
    │   ├─ File("players.json").exists() → YES → read JSON            │
    │   │   └─ parse PlayerDatabase → INSERT INTO players (tx)        │
    │   │                                                              │
    │   ├─ File("games.json").exists() → YES → read JSON              │
    │   │   └─ parse GameDatabase → INSERT INTO games (tx)            │
    │   │                                                              │
    │   └─ tx.commit() or tx.rollback() on error                      │
    │                                               [MIGRATION DONE]  │
    │                                                                  │
    ├─ PlayerRepository.initialize()    → SELECT * FROM players → cache
    └─ GameRepository.initialize()      → SELECT * FROM games  → cache
                                          (resolve player refs from cache)

User taps "Generate"
    │
    GameData.makeGame()  [async, already on main isolate]
    │
    └─ await compute(_improveEloSpreadIsolate, payload)
         │  [background isolate]
         │  payload = (List<List<int>> eloSlots, int numCourts, ...)
         │  returns optimized slot assignments
         └─ main isolate applies result → notifyListeners()

CRUD mutations (add/update/delete)
    │
    Repository method → SQLite INSERT/UPDATE/DELETE → in-memory _cache update
    (write-through; no full-file rewrite)
```

### Recommended Project Structure

No new directories needed. Changes are within existing structure:

```
lib/
├── repository/
│   ├── player_repository.dart         # Replace JSON impl with SQLite
│   ├── game_repository.dart           # Replace JSON impl with SQLite
│   ├── repository_service.dart        # Add dbPath alongside rootPath
│   ├── migration_runner.dart          # NEW: one-time JSON→SQLite runner
│   ├── repository_interface.dart      # Unchanged
│   └── serializer.dart               # Unchanged
├── state/
│   └── game_data.dart                 # Extract _improveEloSpread to top-level fn; wrap with compute()
└── main.dart                          # Add sqfliteFfiInit() for Windows; call MigrationRunner
```

### Pattern 1: sqflite Database Open with Versioned Schema

**What:** Open the database once at startup with a version number. `onCreate` creates the schema for
fresh installs; `onUpgrade` handles schema evolution for existing users.

**When to use:** Every time the schema changes, increment the version constant and add an `onUpgrade`
branch. `onCreate` should apply all migrations sequentially so fresh installs and upgrades converge.

```dart
// Source: https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md
// Source: https://github.com/tekartik/sqflite/blob/master/sqflite/doc/migration_example.md

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

const int _dbVersion = 1;

Future<Database> openAppDatabase() async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, 'good_bad_board.db');

  return openDatabase(
    dbPath,
    version: _dbVersion,
    onCreate: (db, version) async {
      // Apply all migrations in order so fresh install == upgrade path
      await _migrateV1(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 1) await _migrateV1(db);
      // Future: if (oldVersion < 2) await _migrateV2(db);
    },
  );
}

Future<void> _migrateV1(Database db) async {
  await db.execute('''
    CREATE TABLE players (
      id          TEXT PRIMARY KEY,
      first_name  TEXT NOT NULL,
      last_name   TEXT NOT NULL,
      elo         TEXT NOT NULL,
      sign_in_id  TEXT,
      created_date TEXT,
      -- Phase 3 forward-ready nullable columns (D-01)
      membership_type  TEXT,
      last_played      TEXT,
      avatar_path      TEXT,
      session_fee_paid INTEGER,
      dues_status      TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE games (
      id            TEXT PRIMARY KEY,
      created_date  TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE game_players (
      game_id    TEXT NOT NULL,
      player_id  TEXT NOT NULL,
      position   INTEGER NOT NULL,
      PRIMARY KEY (game_id, position),
      FOREIGN KEY (game_id) REFERENCES games(id),
      FOREIGN KEY (player_id) REFERENCES players(id)
    )
  ''');
}
```

### Pattern 2: Windows FFI Initialization

**What:** `sqflite` does not support Windows directly. `sqflite_common_ffi` replaces the factory.
Must run before any `openDatabase()` call.

**When to use:** In `main()` or `AppLoader.loading()`, guarded by `Platform.isWindows || Platform.isLinux`.

```dart
// Source: https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initSqflite() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // On Android/iOS, databaseFactory is the platform default — no-op.
}
```

**Integration point:** Call `initSqflite()` at the top of `AppLoader.loading()` before `RepositoryService.initialize()`.

### Pattern 3: JSON-to-SQLite One-Time Migration Runner

**What:** Detect presence of legacy JSON files. If found, parse them and INSERT into SQLite in a single
transaction. If the transaction succeeds, the JSON files can be left in place (as backup) or optionally
renamed to `.migrated`. Migration must be idempotent — running it twice must not double-insert records.

**When to use:** Once, during the first launch after upgrade. Detected by checking whether JSON files
exist alongside an empty (or newly created) SQLite database.

```dart
// lib/repository/migration_runner.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:good_bad_board/repository/player_repository.dart' show PlayerDatabase;
import 'package:good_bad_board/repository/game_repository.dart' show GameDatabase;

class MigrationRunner {
  static const _playerFile = 'players.json';
  static const _gameFile = 'games.json';

  /// Runs the migration if legacy JSON files are present.
  /// Wrapped in a SQLite transaction — rolls back on any error.
  /// Throws on failure so AppLoader can surface an error state.
  static Future<void> run(String rootPath, Database db) async {
    final playerFile = File(p.join(rootPath, _playerFile));
    final gameFile = File(p.join(rootPath, _gameFile));

    final hasPlayers = await playerFile.exists();
    final hasGames = await gameFile.exists();

    if (!hasPlayers && !hasGames) return; // Nothing to migrate

    // Check if already migrated (idempotency guard)
    final existingCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM players'),
    ) ?? 0;
    if (existingCount > 0) return; // Already migrated

    await db.transaction((txn) async {
      if (hasPlayers) {
        final json = await playerFile.readAsString();
        final dto = PlayerDatabase.fromJson(jsonDecode(json));
        for (final player in dto.players) {
          await txn.insert(
            'players',
            {
              'id': player.id,
              'first_name': player.firstName,
              'last_name': player.lastName,
              'elo': player.elo.name,
              'sign_in_id': player.signInId,
              'created_date': player.createdDate?.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      if (hasGames) {
        final json = await gameFile.readAsString();
        final dto = GameDatabase.fromJson(jsonDecode(json));
        for (final gameDto in dto.games) {
          await txn.insert(
            'games',
            {
              'id': gameDto.id,
              'created_date': gameDto.createdDate.toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          int position = 0;
          for (final playerDto in gameDto.playerDto) {
            await txn.insert(
              'game_players',
              {
                'game_id': gameDto.id,
                'player_id': playerDto.id,
                'position': position++,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    });
    // On any exception, transaction auto-rolls back; exception propagates to AppLoader.
  }
}
```

### Pattern 4: ELO Optimizer Isolate Offload via compute()

**What:** `compute()` spawns a background isolate, runs the function, returns the result. The input and
output must be sendable (plain Dart objects — no open files, no `ChangeNotifier`, no Flutter widgets).

**Sendability of existing types:** `Player` and `Game` are `@freezed` immutable classes. They contain
only `String`, `DateTime`, `Elo` (enum), and `List<Player>`. None of these reference native resources.
They ARE sendable. [VERIFIED: dart.dev/language/isolates — "majority of objects can be sent across
isolates"; exceptions are native resource holders like Socket]

**The problem with sending mutable Game objects:** The optimizer mutates `game.players[i]` in-place.
Isolates copy data on send, so mutations in the isolate do NOT affect the original list. The solution
is to pass indices/ELO values, compute the optimal permutation, and return the result as a plain
`List<List<int>>` (player indices per court), then apply the result on the main isolate.

```dart
// Extracted top-level function — must be top-level or static for compute()
// Source: https://docs.flutter.dev/perf/isolates
typedef EloPayload = ({List<List<int>> courtElos, int maxIteration});
typedef EloResult = List<List<int>>; // Optimized player index assignments per court

EloResult _improveEloSpreadIsolate(EloPayload payload) {
  // Pure computation on plain int data — no Player/Game objects cross the isolate boundary
  // Returns reordered index lists that main isolate applies to stagingMatches
  // ... (greedy swap logic here, using List<int> elos instead of Player objects)
  return payload.courtElos; // placeholder — actual optimization runs here
}

// In GameData.makeGame():
Future<void> makeGame() async {
  // ... build stagingMatches as before ...

  // Extract ELO indices for isolate (plain ints — fully sendable)
  final payload = (
    courtElos: stagingMatches.map((g) => g.players.map((p) => p.elo.index).toList()).toList(),
    maxIteration: maxIteration,
  );

  final optimizedIndices = await compute(_improveEloSpreadIsolate, payload);
  _applyOptimizedOrder(stagingMatches, optimizedIndices);

  notifyListeners();
}
```

> **Alternative approach (simpler):** Pass the full `List<List<int>>` ELO values and receive back
> a permutation. The optimizer only cares about ELO indices — `Player` objects are not needed for the
> swap logic. This is the recommended approach to keep isolate boundary clean.

### Anti-Patterns to Avoid

- **Calling `getDatabasesPath()` on Windows:** It has a "lame implementation" with FFI and returns
  an incorrect path. Always use `path_provider` + `path` package to construct the DB path.
- **Opening multiple Database instances:** sqflite defaults to `singleInstance: true`. Never open the
  same DB path twice — it causes lock exceptions. Open once in `RepositoryService` and share the
  reference.
- **Wrapping migration callbacks in an extra transaction:** sqflite's `onCreate`/`onUpgrade` callbacks
  are already internally wrapped in a transaction. Do not add a nested `db.transaction()` inside them.
  Use a separate `db.transaction()` only for the external JSON migration runner.
- **Passing `ChangeNotifier` / `BuildContext` objects to compute():** These cannot cross isolate
  boundaries. Extract only plain data (ints, strings, maps) before calling `compute()`.
- **Leaving `intl: any` in pubspec:** If any pubspec change is made, pin it: `intl: ^0.19.0`.
- **Removing JSON files immediately after migration:** Keep them (or rename to `.migrated`) as a
  fallback. They are small and their presence is the zero-cost rollback mechanism if something goes
  wrong before the next launch.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQLite versioned schema migrations | Custom version-check logic | sqflite `openDatabase(version:, onCreate:, onUpgrade:)` | Built-in callbacks handle version tracking atomically; already transaction-wrapped |
| Desktop SQLite support | Bundling your own sqlite3.dll | `sqflite_common_ffi` + `sqlite3` (auto via build hooks) | `sqlite3` v3 uses build hooks to compile and set up `sqlite3.dll` on Windows automatically |
| Background computation | Custom `ReceivePort`/`SendPort` setup | `compute()` | compute() is the Flutter idiom; handles error propagation and isolate lifecycle automatically |
| In-memory + disk write-through | Custom cache invalidation | Keep existing `_cache` pattern, just replace JSON writes with SQLite CRUD | The current write-through pattern is correct for this scale; SQLite ACID handles atomicity |

**Key insight:** sqflite's version migration system is the right tool for schema evolution — do not
replicate it with custom SharedPreferences flags or separate migration tables.

---

## Common Pitfalls

### Pitfall 1: Windows Release Mode Missing sqlite3.dll

**What goes wrong:** App crashes on launch in release mode on Windows with "cannot find sqlite3.dll".

**Why it happens:** `sqflite_common_ffi` with `sqlite3` v3 uses build hooks to compile and include
`sqlite3.dll` during debug builds, but release builds on older configurations may not bundle it
automatically into the `build/windows/x64/runner/Release/` folder.

**How to avoid:** After running `flutter build windows --release`, verify that `sqlite3.dll` is present
alongside the `.exe`. With `sqlite3` v3+ (which `sqflite_common_ffi 2.4.0+2` depends on), this should
be automatic via build hooks. Test a release build before shipping.

**Warning signs:** App launches fine in debug/profile but crashes immediately in release on Windows.

### Pitfall 2: Calling openDatabase Before sqfliteFfiInit

**What goes wrong:** `MissingPluginException` or `Unhandled Exception: sqflite ffi not supported`
on Windows.

**Why it happens:** `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi` must be called
before any `openDatabase()` call. If the DB open happens in `RepositoryService.initialize()` and
`sqfliteFfiInit()` is called after, it fails.

**How to avoid:** Add `sqfliteFfiInit()` as the very first step in `AppLoader.loading()`, before
`RepositoryService.initialize()`.

**Warning signs:** Only fails on Windows/Linux; passes on Android/iOS.

### Pitfall 3: Migration Runs Twice (Non-Idempotent)

**What goes wrong:** On second launch, the JSON files still exist, migration runs again, and
`INSERT OR IGNORE` skips all rows (because of `ConflictAlgorithm.ignore`). This is actually safe
if using `ignore`, but if using `replace`, it could corrupt data.

**How to avoid:** Use `conflictAlgorithm: ConflictAlgorithm.ignore` for all migration inserts, AND
add an upfront guard: `SELECT COUNT(*) FROM players` — if > 0, skip migration entirely.

**Warning signs:** Duplicate entries in SQLite or unexpected data loss on second launch.

### Pitfall 4: Isolate Receives Mutable State That It Cannot Affect

**What goes wrong:** Developer passes `stagingMatches` (a `List<Game>`) to `compute()`, the isolate
mutates `game.players`, but the main isolate's list is unchanged (because isolates copy data). The
game appears not to be optimized.

**Why it happens:** Dart isolates copy message data. Mutations in the isolate are invisible to the
main isolate.

**How to avoid:** Pass ELO indices (plain `List<List<int>>`) into the isolate. Return an optimized
permutation (also `List<List<int>>`). Apply the permutation on the main isolate.

**Warning signs:** `_improveEloSpread` completes (no exception) but `stagingMatches` ELO spread is
unchanged after the `await compute(...)` call.

### Pitfall 5: GameRepository Initialization Requires PlayerRepository

**What goes wrong:** Initialization order is changed (e.g., SQLite open is parallelized with
`Future.wait`), and `GameRepository.initialize()` tries to resolve player references before
`PlayerRepository`'s cache is populated.

**Why it happens:** The current initialization sequence has an explicit documented dependency:
`PlayerRepository` must complete before `GameRepository`. This dependency still exists in SQLite
— `game_players` JOIN `players` requires player records to exist first.

**How to avoid:** Preserve the sequential initialization order from `main.dart`:
```dart
await PlayerRepository.instance.initialize(db);
await GameRepository.instance.initialize(db);
```
Do not use `Future.wait` for these two.

---

## Code Examples

### Opening the database in RepositoryService

```dart
// lib/repository/repository_service.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RepositoryService {
  RepositoryService._();

  static final RepositoryService instance = RepositoryService._();

  late final String rootPath;
  late final Database db;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    rootPath = appDir.path;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    db = await openDatabase(
      p.join(rootPath, 'good_bad_board.db'),
      version: 1,
      onCreate: (db, version) => _migrateV1(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) await _migrateV1(db);
      },
    );
  }
}
```

### SQLite PlayerRepository CRUD pattern

```dart
// Source: sqflite pub.dev documentation — insert/query helpers
@override
Future<void> add(Player player) async {
  await _db.insert(
    'players',
    _playerToMap(player),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  _cache[player.id] = player;
}

@override
Future<Iterable<Player>> getAll({int? count, int? offset}) async {
  // Reads from cache at runtime; initial population in initialize()
  final skipped = _cache.values.skip(offset ?? 0);
  return count != null ? skipped.take(count) : skipped;
}

Map<String, dynamic> _playerToMap(Player p) => {
  'id': p.id,
  'first_name': p.firstName,
  'last_name': p.lastName,
  'elo': p.elo.name,
  'sign_in_id': p.signInId,
  'created_date': p.createdDate?.toIso8601String(),
};

Player _mapToPlayer(Map<String, dynamic> row) => Player(
  id: row['id'] as String,
  firstName: row['first_name'] as String,
  lastName: row['last_name'] as String,
  elo: Elo.values.firstWhere((e) => e.name == row['elo']),
  signInId: row['sign_in_id'] as String?,
  createdDate: row['created_date'] != null
      ? DateTime.parse(row['created_date'] as String)
      : null,
);
```

---

## Runtime State Inventory

> This phase renames/replaces the storage format. Evaluate runtime state explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `players.json` + `games.json` in `getApplicationDocumentsDirectory()` on each user's device | One-time migration READ + SQLite INSERT in MigrationRunner |
| Live service config | None — no external services used | None |
| OS-registered state | None — no OS-registered tasks or services | None |
| Secrets/env vars | None — no secrets reference JSON filenames | None |
| Build artifacts | `lib/repository/*.freezed.dart`, `*.g.dart` — will need regeneration after any model/DTO changes | Run `dart run build_runner build --delete-conflicting-outputs` |

**MigrationRunner data strategy:**
- Read: `players.json` → `PlayerDatabase.fromJson()` (existing freezed DTO — no changes needed)
- Read: `games.json` → `GameDatabase.fromJson()` (existing freezed DTO — no changes needed)
- Write: INSERT INTO `players`, `games`, `game_players` tables inside a single transaction
- On success: files remain in place (natural backup); a subsequent launch detects `COUNT(*) > 0` and skips
- On failure: transaction rolls back; SQLite DB remains empty; next launch retries from JSON (zero data loss)

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual `Isolate.spawn()` + SendPort/ReceivePort | `Isolate.run()` / `compute()` | Dart 2.19 / Flutter 3.7 | Much simpler one-shot isolate; automatic cleanup |
| `sqlite3_flutter_libs` required for Windows | `sqlite3` v3 build hooks (auto) | sqlite3 3.0.0 | No manual DLL management in most cases |
| `getDatabasesPath()` for all platforms | `path_provider` + `path` on desktop | sqflite_common_ffi limitation | Must use path_provider on Windows/Linux |

**Deprecated/outdated:**
- `sqlite3_flutter_libs`: End-of-life (`sqlite3_flutter_libs 0.6.0+eol`). Do NOT add this package. The `sqlite3` package (v3+) handles DLL bundling via build hooks directly. [VERIFIED: pub.dev package page shows "eol" suffix]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Player` and `Game` (freezed classes with String/DateTime/enum/List fields) are sendable across Dart isolates | Architecture Patterns — Pattern 4 | If wrong, cannot pass Player/Game objects to isolate at all; must use pure int payloads (the recommended approach already avoids this) |
| A2 | The `sqlite3` v3 build hooks correctly bundle `sqlite3.dll` in the Windows CI build pipeline | Pitfall 1 | If wrong, release build crashes on launch; mitigation: test release build before shipping |
| A3 | JSON files (`players.json`, `games.json`) live at `getApplicationDocumentsDirectory()` path on all target platforms | Runtime State Inventory | Verified from RepositoryService source: `rootPath = (await getApplicationDocumentsDirectory()).path` — HIGH confidence this is correct |

---

## Open Questions (RESOLVED)

1. **`trotter` inline vs. leave for later**
   - What we know: `Combinations` and `Amalgams` are used in exactly one place (lines 285-291 of `game_data.dart`). The package is low-maintenance (CONCERNS.md). Once `_improveEloSpread` is extracted to a top-level function for isolate use, inlining the two generators is a small additional step.
   - What's unclear: Whether Claude's Discretion in CONTEXT.md permits inlining as part of Plan 01-03 or should be a separate plan.
   - Recommendation: Include `trotter` inline as an optional task in Plan 01-03 (INFRA-03). If it adds more than ~30 lines of Dart, defer to a cleanup phase.
   - RESOLVED: Plan 01-04 (INFRA-03) removes the `trotter` import from `game_data.dart` and replaces `Combinations`/`Amalgams` with equivalent plain double-for-loops in both `_improveEloSpreadIsolate` (new top-level function) and the legacy `_improveEloSpread` method. The `trotter` package entry in `pubspec.yaml` is left in place (pubspec change out of scope for Plan 04).

2. **Migration runner: rename or delete JSON files after success?**
   - What we know: Leaving JSON files in place is the safest strategy (they become a natural backup). The idempotency guard (`COUNT(*) > 0`) prevents re-migration.
   - What's unclear: User expectation was not discussed.
   - Recommendation: Leave JSON files in place. This is the zero-risk strategy and requires no additional cleanup logic.
   - RESOLVED: Plan 01-03 (INFRA-02) leaves JSON files in place after migration. The `MigrationRunner` action block and the `## Open Questions` recommendation both confirm this. Idempotency is guaranteed by the `SELECT COUNT(*) FROM players` guard that skips migration when `existingCount > 0`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All tasks | ✓ | 3.35.7 (channel user-branch) | — |
| Dart SDK | All tasks | ✓ | 3.9.2 | — |
| `dart run build_runner build` | After model/DTO changes | ✓ | build_runner 2.5.4 | — |
| `sqflite` (pub.dev) | INFRA-01 | ✓ (not yet added) | 2.4.2 available | — |
| `sqflite_common_ffi` (pub.dev) | INFRA-01 (Windows) | ✓ (not yet added) | 2.3.7+1 resolvable | — |
| `path` (pub.dev) | INFRA-01 | ✓ (already transitive) | 1.9.1 | — |
| Windows build target | CI artifact | ✓ (CI runs on windows-latest) | GitHub Actions | — |
| `flutter test` | All test runs | ✓ | via flutter_test SDK dep | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

**Note:** `sqflite_common_ffi` resolves to `2.3.7+1` with current constraints; `2.4.0+2` is latest but
requires relaxing constraints. Either version works — the API is identical. [VERIFIED: dry-run]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `test` ^1.25.15 |
| Config file | None — uses flutter default discovery |
| Quick run command | `flutter test test/game_data_test.dart` |
| Full suite command | `flutter test` (or `just test`) |

### Current Test State

There are 5 tests in `test/game_data_test.dart`. 4 pass; 1 fails:

- **Failing:** "Can swap player" — `Unsupported operation: Cannot remove from an unmodifiable list` at `game_data.dart:353`. This is a pre-existing bug (unrelated to Phase 1) but must not regress further.

The `test/widget_test.dart` is effectively a smoke test that does not exercise the repository layer.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFRA-01 | PlayerRepository reads/writes to SQLite | unit | `flutter test test/repository/player_repository_test.dart` | ❌ Wave 0 |
| INFRA-01 | GameRepository reads/writes to SQLite | unit | `flutter test test/repository/game_repository_test.dart` | ❌ Wave 0 |
| INFRA-01 | SQLite schema has all expected columns including Phase 3 nullable cols | unit | `flutter test test/repository/schema_test.dart` | ❌ Wave 0 |
| INFRA-02 | MigrationRunner converts JSON data to SQLite without data loss | unit | `flutter test test/repository/migration_runner_test.dart` | ❌ Wave 0 |
| INFRA-02 | MigrationRunner is idempotent (running twice does not duplicate data) | unit | (same file) | ❌ Wave 0 |
| INFRA-02 | MigrationRunner rolls back on error (SQLite remains empty, JSON intact) | unit | (same file) | ❌ Wave 0 |
| INFRA-03 | makeGame() completes without blocking (ELO runs in isolate) | integration | `flutter test test/state/game_data_isolate_test.dart` | ❌ Wave 0 |
| INFRA-03 | ELO result applied correctly (stagingMatches reflect optimized spread) | unit | (same file) | ❌ Wave 0 |

**Note on testing with sqflite_common_ffi:** Unit tests must initialize the FFI factory before any
`openDatabase()` call. Use `sqflite_common_ffi` in test setup:

```dart
// test/helpers/sqflite_test_helper.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void initSqfliteForTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

Use `inMemoryDatabasePath` for fast, isolated tests: `openDatabase(inMemoryDatabasePath, ...)`.

### Sampling Rate

- **Per task commit:** `flutter test test/repository/ test/state/`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/repository/player_repository_test.dart` — covers INFRA-01 player CRUD
- [ ] `test/repository/game_repository_test.dart` — covers INFRA-01 game CRUD + player reference resolution
- [ ] `test/repository/schema_test.dart` — covers INFRA-01 schema shape (column names, nullable Phase 3 cols)
- [ ] `test/repository/migration_runner_test.dart` — covers INFRA-02 (happy path, idempotency, rollback)
- [ ] `test/state/game_data_isolate_test.dart` — covers INFRA-03 (isolate runs, result applied)
- [ ] `test/helpers/sqflite_test_helper.dart` — shared FFI init fixture

---

## Security Domain

> `security_enforcement` not explicitly set to false in config.json — applying standard checks.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in this phase |
| V3 Session Management | No | Session is in-memory only (GameData), not persisted |
| V4 Access Control | No | Single-device, no multi-user |
| V5 Input Validation | Yes (partial) | JSON deserialization uses freezed `fromJson` — existing validation. SQLite inserts use parameterized queries via sqflite API (never raw string interpolation) |
| V6 Cryptography | No | No encryption of the SQLite database required at this phase |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via player names | Tampering | sqflite's `insert()`/`query()` helpers use parameterized bindings — never use `rawQuery` with string interpolation |
| Corrupt JSON file on migration | Denial of Service | Wrap migration in try/catch; roll back transaction; surface error in AppLoader |
| Truncated SQLite file on first write | Denial of Service | SQLite's WAL mode (or default journal mode) ensures atomic writes; sqflite handles this |

**Key note:** The project stores personal player names (first name, last name) in SQLite. This is
existing data already stored in JSON; no new sensitivity is introduced. No encryption required for
this use case per project scope.

---

## Sources

### Primary (HIGH confidence)

- sqflite 2.4.2 — pub.dev API endpoint [VERIFIED: `curl pub.dev/api/packages/sqflite`]
- sqflite_common_ffi 2.4.0+2 — pub.dev API endpoint [VERIFIED: `curl pub.dev/api/packages/sqflite_common_ffi`]
- sqflite opening_db.md — https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md
- sqflite migration_example.md — https://github.com/tekartik/sqflite/blob/master/sqflite/doc/migration_example.md
- sqflite_common_ffi desktop setup — https://github.com/tekartik/sqflite/blob/master/sqflite_common_ffi/doc/using_ffi_instead_of_sqflite.md
- Flutter isolates docs — https://docs.flutter.dev/perf/isolates
- Dart isolates language guide — https://dart.dev/language/isolates
- `compute()` API — https://api.flutter.dev/flutter/foundation/compute.html
- Project source: `lib/repository/player_repository.dart`, `lib/repository/game_repository.dart`, `lib/main.dart`, `lib/state/game_data.dart`, `lib/model/player.dart`, `lib/model/game.dart`
- Package dry-run output: `flutter pub add sqflite sqflite_common_ffi path --dry-run` [VERIFIED: local execution]
- Flutter SDK: 3.35.7, Dart: 3.9.2 [VERIFIED: local `flutter --version`]

### Secondary (MEDIUM confidence)

- Windows desktop sqflite setup guide — https://dev.to/ayoubzulfiqar/how-to-use-sqflite-on-windows-flutter-ggm (cross-verified with official sqflite_common_ffi docs)
- sqflite migration best practices — https://github.com/kishandonga/flutter-sqflite-onupgrade (cross-verified with sqflite official docs)

### Tertiary (LOW confidence)

- sqlite3_flutter_libs EOL status inferred from `0.6.0+eol` version suffix on pub.dev (consistent with sqflite_common_ffi docs saying sqlite3 v3 handles this automatically)

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — versions verified via pub.dev API and flutter dry-run
- Architecture: HIGH — based on reading all source files directly; no guesswork
- Migration pattern: HIGH — verified against official sqflite docs
- Isolate approach: HIGH — verified against Flutter perf docs and dart.dev isolates guide
- Pitfalls: HIGH — derived from official docs + direct source code analysis

**Research date:** 2026-04-16
**Valid until:** 2026-07-16 (sqflite is stable; Dart isolates API is stable)
