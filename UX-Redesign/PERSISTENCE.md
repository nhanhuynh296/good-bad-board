# PERSISTENCE.md — Data Layer: State, Findings, and Plan

> **Status:** investigation complete, implementation not started.
> **Date of investigation:** 2026-08-18. **Branch:** `refactor/deepseek-oneshot` (at `b2fc864`).
> **Purpose:** this file is the handoff for the data-layer work. It records what was measured,
> what was decided and why, and exactly what to change. Read sections 1 to 5 before writing code.

---

## 0. How to use this file

The investigation started from a request to replace JSON persistence with a database, on the
assumption that JSON is inefficient at scale. **That assumption was measured and did not hold.**
The plan changed as a result. Section 4 has the numbers, section 5 has the decision, section 6 is
the work.

**Corrections applied 2026-08-28.** Mechanism B in §3.1 was wrong — it read the domain backwards and
its fix would have destroyed data. §3.1, phase 1b and phase 1c are corrected. The domain decisions
behind those corrections now live in [`../CONTEXT.md`](../CONTEXT.md) and
[`../docs/adr/`](../docs/adr/). Read the ADRs before section 6.

If you are picking this up cold:

1. Read section 3 (findings) — there is a live data-loss bug, and it is the reason this work exists.
2. Read section 4 (benchmarks) — do not re-litigate the JSON-versus-SQLite question without
   re-running them. The reproduction code is in appendix A.
3. Work through section 6 in order. Phase 1 and phase 2 are the ones that matter.
4. Section 7 is the verification protocol. Section 8 lists the docs to update when done.

**Project conventions that apply** (from root `CLAUDE.md`): TDD, tests written and failing before
implementation, AAA pattern, behaviour-describing test names. Run `just generate` after touching
any `@freezed` or JSON-serializable model. Run `just lint` and `just test` before claiming done.

---

## 1. Current data layer

### 1.1 Shape

Four singleton repositories, each an in-memory `Map<String, T>` cache over one JSON file. No
database, no DI container, no Riverpod. Every repository is reached as `XRepository.instance`.
State management is `provider` / `ChangeNotifier`.

| Class | File | On-disk file | Root JSON key |
|---|---|---|---|
| `PlayerRepository` | `lib/repository/player_repository.dart:32` | `players.json` | `{"players": [...]}` |
| `GameRepository` | `lib/repository/game_repository.dart:40` | `games.json` | `{"games": [...]}` |
| `SessionLogRepository` | `lib/repository/session_log_repository.dart:22` | `session_logs.json` | `{"logs": [...]}` |
| `PendingRegistrationRepository` | `lib/repository/pending_registration_repository.dart:23` | `pending_registrations.json` | `{"registrations": [...]}` |

Supporting pieces:

- `lib/repository/repository_interface.dart:1` — `InMemoryRepository<V>`, the only storage
  abstraction. CRUD only: `add`, `delete`, `get`, `getAll({count, offset})`, `update`.
- `lib/repository/repository_service.dart:6` — singleton holding `rootPath`, resolved from
  `getApplicationDocumentsDirectory()`. `initialize()` is idempotent (`:17-22`);
  `initializeForTesting(path)` (`:24-28`) is the test seam.
- `lib/state/persistent_setting.dart:31` — SharedPreferences wrapper for settings and session
  templates.
- `lib/repository/serializer.dart` and `GameData.saveGame` (`lib/state/game_data.dart:996`) are
  **dead code** — no caller anywhere in `lib/`. `saveGame` returns a `File` handle and never
  writes to it.

Every repository builds its path by string interpolation, duplicated in both `initialize()` and
`save()`:

```dart
File('${RepositoryService.instance.rootPath}/$databaseFilename')
```

Note the hardcoded `/` separator rather than `p.join`, despite Windows being the target platform.

### 1.2 Persisted models

All `@freezed` + `json_serializable` except `SessionTemplate`, which is hand-written.

| Model | File | Fields |
|---|---|---|
| `Player` | `lib/model/player.dart:42` | `firstName`, `lastName`, `elo: Elo`, `id`, `signInId?`, `createdDate?`, `membership: MembershipStatus` |
| `Game` | `lib/model/game.dart:16` | `players: List<Player>`, `id`, `createdDate`. Constants `playerPerCourt = 4`, `singlePlayerPerCourt = 2` |
| `SessionLog` | `lib/model/session_log.dart:10` | `id`, `loggedAt`, `capacity`, `checkedInCount`, `waitlistCount`, `rerollCount`, `courtLevelGaps: List<int>`, `courtCount` |
| `PendingRegistration` | `lib/model/pending_registration.dart:11` | `id`, `name` (single field), `contact`, `tier: SkillTier`, `submittedAt` |
| `SessionTemplate` | `lib/model/session_template.dart` | `id`, `name`, `modeIndex`, `durationMinutes`, `durationSeconds`, `capacity`, `courts`. **Not freezed.** Stored in `session_templates.json` (was SharedPreferences) |

Enums: `Elo` (`player.dart:7`) has 8 values `c2,c1,b2,b1,a2,a1,s2,s1`. `MembershipStatus`
(`player.dart:24`) is `member,casual,disabled`. `SkillTier` (`lib/model/elo.dart:7`) has 4 values
and bridges to `Elo` via `Elo.skillTier` (`:21`) and `SkillTier.lowerBoundElo` (`:30`).

### 1.3 The DTO layer

`games.json` does **not** store `Game.toJson`. It stores a separate DTO shape:

- `PlayerDto(String id)` — `player_repository.dart:14`. A player reference by id.
- `GameDto(Iterable<PlayerDto> playerDto, String id, DateTime createdDate)` —
  `game_repository.dart:14`.

`PlayerDto` is the **only cross-file foreign key in the whole app**, and it is unenforced.

### 1.4 What is NOT persisted

These exist as domain concepts but have no durable representation. Important context for anyone
extending the schema.

- **Round / rotation** — `_roundNumber`, `_stagedLineup`, `_roundView` are RAM only
  (`game_data.dart:175-226`). Rounds are only implied by a batch of `GameDto` rows sharing a
  timestamp.
- **Session** — no session entity. `SessionLog` is an anonymous per-round snapshot keyed only by
  `loggedAt`. Analytics reconstructs "a session" by grouping logs by calendar day
  (`analytics_engine.dart`, `_dateOnly`).
- **Check-in / attendance** — `_checkedInPlayerIds: Set<String>` (`game_data.dart:72`) is RAM only.
  Restarting mid-session loses every check-in. Only the count survives, inside
  `SessionLog.checkedInCount`.
- **Per-player stats and Elo history** — nothing stored. Analytics derives everything by replaying
  `games.json`.
- **Match result, score, winner** — no field exists anywhere. `Game` records who played, never who
  won.

### 1.5 Lifecycle

Startup is `lib/main.dart:30-41`, driven by `_AppLoaderState` plus a `FutureBuilder`:

```dart
await Future.wait([RepositoryService.instance.initialize(),
                   PersistentSetting.instance.initialize()]);
await PlayerRepository.instance.initialize();
await GameRepository.instance.initialize();   // ordered: needs PlayerRepository
await SessionLogRepository.instance.initialize();
await PendingRegistrationRepository.instance.initialize();
```

All four files are read and parsed eagerly on the main isolate. No `compute`, no streaming, no lazy
load.

Writes are **whole-file rewrites on every mutation**. Every `add`/`addAll`/`delete`/`update` calls
`save()`, and `save()` does:

```dart
await selectedFile.create(recursive: true);
await selectedFile.writeAsString(jsonEncode(dto.toJson()));   // ENTIRE collection
```

No atomic temp-then-rename, no `flush: true`, no write lock. An interrupted or concurrent write
truncates the file. `_logRound` (`game_data.dart:525-532`) does two full-file rewrites back to
back.

Complete list of write triggers:

| Call site | Effect |
|---|---|
| `game_data.dart:361` `onUpdatePlayer` | `PlayerRepository.update` — fire-and-forget, **not awaited** |
| `game_data.dart:394` `deletePlayer` | `PlayerRepository.delete` |
| `game_data.dart:527` `_logRound` | `GameRepository.addAll` |
| `game_data.dart:548` `saveSingleGame` | `GameRepository.add` |
| `game_data.dart:571` `_logSessionSnapshot` | `SessionLogRepository.add` |
| `game_data.dart:900` `saveTemplate` | `PersistentSetting.persistTemplate` |
| `players_page.dart:397` | add player |
| `players_page.dart:459` | CSV bulk import |
| `players_page.dart:506-507` | approve registration — add Player, delete pending |
| `players_page.dart:534` | reject registration |
| `registration_page.dart:48` | public `/register` submit |

### 1.6 Cache-invalidation signalling

Repositories are not `ChangeNotifier`s and emit no streams, so pages poll two monotonic counters.
This exists because `StatefulShellRoute.indexedStack` keeps every tab's `State` alive.

- `GameData._saveVersion` (`game_data.dart:161-170`) — `AnalyticsPage` compares it in `build()` and
  re-runs `_load()` (`analytics_page.dart:83-89`).
- `PendingRegistrationRepository._version` (`pending_registration_repository.dart:34-39`) —
  `PlayersPage` polls it in `build()` (`players_page.dart:61,228,518,538`).

### 1.7 Live data snapshot (2026-08-18)

Location on the dev machine:
`~/Library/Containers/nz.nathanHuynh.goodBadBoard/Data/Documents/`

| File | Bytes | Rows |
|---|---|---|
| `players.json` | 42,002 | 245 players |
| `games.json` | 41,149 | 385 game (court) rows |
| `session_logs.json` | 7,383 | 39 session logs (all dated 2026-08-16) |
| `pending_registrations.json` | 20 | 0 |

A backup was taken before any work started:
`~/Library/Containers/nz.nathanHuynh.goodBadBoard/Data/Documents-backup-20260818/`

Elo distribution: `c2` 104, `c1` 55, `b2` 45, `b1` 24, `a2` 12, `a1` 5, `s2`/`s1` 0.
All 245 players are `membership: member`. Every sampled player has `signInId: null` **and
`createdDate: null`** — which matters, because `computeNewPlayerIntegration` and the at-risk logic
key off `createdDate`.

Growth: `games.json` spans 2025-08-09 to 2026-08-16 across 13 distinct play days, averaging ~30
court rows per day. It grows at roughly `courts × rounds` per session and is the fastest-growing
file.

---

## 2. Test setup and isolation

### 2.1 Inventory

`test/` has 24 files, ~5,600 lines, run by `just test` (`flutter test`).
`integration_test/` has 6 files, 904 lines, and is run by **no justfile recipe and no CI job**.

`integration_test/helpers/test_utils.dart` (412 lines) is the shared harness. There is no
`test/helpers/` equivalent — unit tests duplicate their setup per file.

Key harness contents: tab index constants (`dashboardTabIndex` 0, **`playersTabIndex` 1**,
`sessionsTabIndex` 2), size presets, `pumpApp`, `pumpAppWithPlayers`, navigation helpers,
`clearAllPlayers()`, `clearAllGames()`.

### 2.2 How isolation works today, and why it is fragile

Isolation rests entirely on one seam, called by convention:

```dart
RepositoryService.instance.initializeForTesting(_sandboxedRootPath());
```

`test_utils.dart:355-394` creates one per-process temp dir and calls that as the first statement of
`_ensureReposReady()`. Thirteen unit-test files each repeat their own
`Directory.systemTemp.createTempSync(...)` plus `initializeForTesting(tempDir.path)` in `setUp`.

**There is no `path_provider` platform override anywhere in the repo.** No
`PathProviderPlatform.instance = ...`, no mock. Redirecting `rootPath` is sufficient only because
every repository resolves its file lazily from it.

Open gaps:

1. **`test/widget_test.dart` is unsandboxed.** It pumps `const AppLoader()` with no
   `initializeForTesting`. Under `flutter test`, `getApplicationDocumentsDirectory()` normally
   throws `MissingPluginException`, which `AppLoader` swallows via its `snapshot.hasError` branch —
   so it does not currently write. Nothing prevents it from writing.
2. **A new test file that forgets two lines** writes to whatever `rootPath` the previous file in
   the process left behind, or to the real directory.
3. **`integration_test/` never cleans up.** No `tearDown` in any file, so one
   `good_bad_board_test_*` dir leaks per test process.
4. **`late final` caches force workarounds.** `PlayerRepository._cache` (`:39`) and
   `GameRepository._cache` / `_playerRepository` (`:47,49`) are `late final`, so `initialize()` can
   only succeed once per process. `_ensureReposReady()` therefore wraps every init in a bare
   `catch (_)` (`:375-382`), and tests use `resetForTesting`/`initializeForTesting` cache pokes.
   `SessionLogRepository` and `PendingRegistrationRepository` use plain `late`, so those two get a
   clean `initialize()` per test. Net effect: caches survive across tests while the temp dir is
   recreated per test, so in-memory and on-disk state can disagree mid-file.
5. **Code paths that bypass the seam.** `serializer.dart:11` (`getDownloadsDirectory`) and
   `game_data.dart:997` call `path_provider` directly. Neither is exercised by current tests.

### 2.3 The 2026-08-16 incident

`clearAllPlayers()` (`test_utils.dart:399-404`) deletes every player one at a time, each delete
triggering a full `players.json` rewrite. Run against an unsandboxed `rootPath`, it wiped the real
file. `b2fc864` added the sandbox and made `RepositoryService.initialize()` idempotent so
`AppLoader` remounting cannot clobber a test override.

That fix stopped the direct wipe. It did **not** undo the downstream damage — see finding 3.1.

### 2.4 Stubbing patterns

No mocking framework at all (`mockito`, `mocktail` both absent). No Riverpod, so no
`ProviderScope` overrides. Four patterns in use:

1. **Real file IO into a temp dir** — the dominant one. Example:
   `test/repository/pending_registration_repository_test.dart:12-19`.
2. **Cache-only, no file IO** — `initializeForTesting()` just assigns `_cache = {}`. Example:
   `test/features/players_test.dart:572-578`.
3. **Cache reseeding** — `resetForTesting(Map)`, needed because `late final _cache` cannot be
   re-initialized. Example: `test/features/analytics_test.dart:50`.
4. **SharedPreferences in-memory** — `SharedPreferences.setMockInitialValues({})`.

One timing hack worth knowing: `test/features/players_test.dart:590-595` has `flushPendingWrites`
which pumps 50 ms, because `GameData.onUpdatePlayer` is fire-and-forget `async` and widget tests
run in a paused `FakeAsync` zone.

### 2.5 Build and CI

`justfile`: `generate` (pub get, gen-l10n, build_runner), `lint` (`flutter analyze --fatal-infos
--no-pub`, `dart format --set-exit-if-changed`), `test` (`flutter test`). No integration recipe.

`.github/workflows/dart.yml` — `code_analysis` job on push/PR to `main`: pub get, format check,
build_runner, analyze, `flutter test`. **Missing `flutter gen-l10n`** relative to `just generate`.

`.github/workflows/artifact.yml` — Windows release build on push to `main`. No tests.

`sonar-project.properties` — `sonar.sources=lib`, no `sonar.tests`, no coverage path, and no
workflow invokes the scanner.

Environment: Dart SDK constraint `^3.8.1`. Local toolchain Flutter 3.47.0 / Dart 3.13.0. No DB
package present anywhere in `pubspec.yaml` or `pubspec.lock` — no sqflite, drift, isar, hive,
sqlite3, or objectbox, direct or transitive.

---

## 3. Findings

Four defects, ordered by severity. 3.1 is the reason this work exists.

### 3.1 CRITICAL — the design silently destroys game history

**FIXED 2026-08-29.** Phase 1 below is implemented — `JsonCollection`, `GameRepository`'s
ids-holding cache, and anonymise-on-delete. The finding stands as the record of what was
wrong and why; the mechanism it describes no longer runs. The already-lost 379 rows remain
unrecoverable (see below).

**98% of the match history is already gone. 379 of 385 game rows hold `playerDto: []`.**
Only 6 rows carry the expected 4 players, all dated 2026-08-16. There are also 5 dangling player
ids that resolve to nothing.

Two independent mechanisms cause this, both still live in code.

**Mechanism A — cascade erasure on save.** `GameRepository.initialize()` resolves each
`PlayerDto` to a `Player` and drops the ones it cannot find:

```dart
// lib/repository/game_repository.dart:63-76
final maybePlayers = await Future.wait(
  gameDto.playerDto.map(_playerRepository.getPlayerFromDto),
);
return Game(players: maybePlayers.nonNulls.toList(growable: true), ...);
//                                ^^^^^^^^ unresolved ids vanish here
```

The next `save()` re-serializes from that lossy cache (`:121`), writing the shortened roster back
to disk. **One bad load permanently strips players from every historical game.** Deleting a player,
or a CSV re-import that changes ids, is enough to trigger it. Combined with the 2026-08-16 incident
(section 2.3), which deleted all 245 players and then saved, this explains the observed 100%
emptiness on every historical day.

**Mechanism B — ~~empty padded courts are persisted~~.** **CORRECTED 2026-08-28. This was not a
defect. See ADR-0002.**

The original finding said `saveCurrentGame` was wrong to pass the whole `stagingMatches` list to
`_logRound` (`game_data.dart:513`), including the empty `Game.create([])` placeholders that
`_padToCourtCount` (`:270-274`) and `makeGame` (`:459-463`) insert. It named `rotateNow`'s filter
(`:314-317`) as the correct pattern to copy.

That reads the domain backwards. The app has two game types (`GameType`, `persistent_setting.dart:21`):

| Game type | Button | Path | Scope |
|---|---|---|---|
| Time Based | one Save for the round (`dashboard_page:285`) | `saveCurrentGame()` | every court |
| Game Based | one Save per court card (`dashboard_page:517`) | `saveSingleGame(court)` | one court |

In a Time Based session a **round** is every court at one moment, and an idle court is part of that
round. `saveCurrentGame` is right to keep it. `rotateNow` is the inconsistent one: it logs the same
thing — one Time Based round — and drops the idle courts, so the two paths write two different
shapes to disk. The fix runs the other way: **`rotateNow` must keep the empty courts.**

What remains true is the ambiguity. An empty row means either "a court was idle in this round"
(correct) or "mechanism A destroyed the roster" (corruption), and nothing on disk distinguishes
them. ADR-0002 resolves this by putting a round id on the game row.

Mechanism B contributed an unknown share of the empty rows. Mechanism A alone explains the observed
100% emptiness, so the recovery position in this section does not change.

**Consequence:** every player-level analytic — `computePlayerMixing`, `computeTopMovers`,
`computeAtRiskPlayers`, `computeNewPlayerIntegration` — is computing over 6 usable games and
silently reporting near-empty results. `analytics_page.dart:69` filters
`g.players.isNotEmpty`, so the tab renders 6 games out of 385 rows with no error shown.

**The lost rosters are not recoverable.** No other copy exists on disk. Accept the loss, stop the
bleeding, and keep the archived JSON.

### 3.2 HIGH — Analytics tab freezes for ~1 second at year-3 volume

**FIXED.** `computePlayerMixing` and `computeNewPlayerIntegration` index games by player id once.

Follow-up (2026-10-14), measured in debug mode with 245 players, 2 sessions a week, 90 games a
session (one test-only benchmark, not in the repo):

| Card computations, 26-week range | 1 year (9,360) | 5 years (46,800) |
|---|---|---|
| Before | 147 ms | 398 ms |
| After | 72 ms | 147 ms |

The changes: the Analytics page computes once per data, range or language change, and not while its
tab is hidden (a Rotate now on the Dashboard no longer recomputes it); `gamesForRange` drops games
that no card window reads; the level-distribution stagnation count keys days as ints. Release (AOT)
builds were not measured.

`computePlayerMixing` (`analytics_engine.dart:584-612`) re-scans every game for every player:

```dart
// line 589 — O(players × games)
final playerGames = games.where((g) => g.players.any((p) => p.id == player.id));
```

At 245 players and 28,080 games that is 27.5 million id comparisons. Measured 891 ms — 87% of the
whole tab's cost. It also takes the **entire** history and ignores the date range, so it cannot be
reduced by narrowing the range.

`computeNewPlayerIntegration` (`:647`) repeats the pattern, bounded to players whose `createdDate`
is within 60 days. It is currently free only because every live player has `createdDate: null`. It
will start costing as soon as that field is populated.

This is an algorithmic defect, not a storage one. See section 4.2.

### 3.3 MEDIUM — no atomic writes

**FIXED.** `JsonCollection` writes a temp file, flushes it, renames it over the target, and coalesces concurrent writes. Dart's `File.rename` on Windows is expected to replace an existing target. Not yet checked on a Windows machine.

`save()` does `create(recursive: true)` then `writeAsString(...)` directly over the live file, with
no temp-then-rename, no `flush`, and no lock. A crash or power loss mid-write leaves a truncated,
unparseable file. `_logRound` performs two such writes in sequence.

### 3.4 LOW — session templates never reload

**FIXED.** `GameData.restoreTemplates()` runs at startup, and `deleteTemplate` writes the shorter list.

`loadTemplates()` (`persistent_setting.dart:173-184`) is called **only from inside
`persistTemplate` itself** (`:162`) and from tests. Nothing rehydrates `GameData._templates` at
startup, so saved templates never reappear after a restart. `GameData.deleteTemplate`
(`game_data.dart:918-924`) also removes only from the RAM list, never from SharedPreferences.

UAT gap that let this through: SESS-05 and SESS-06 cover saving and loading a template, but no case
covers surviving a restart.

### 3.5 INFORMATIONAL — stale preference keys

**CORRECTED.** The analysis below is wrong for production. The released build on `main` uses `SharedPreferencesWithCache`, which writes **unprefixed** keys. The `flutter.`-prefixed keys come from the legacy API that this branch used for a time, on a development machine only. The app now uses `SharedPreferencesWithCache` again, so the unprefixed keys are the live ones. See `test/persistent_setting_main_format_test.dart`.

The live prefs file holds:

```
autoMakegame => false                        <- invisible to the app
flutter.gameDuration => 200                  <- authoritative
flutter.gameType => "timeBased"              <- authoritative
flutter.locale => "fr"                       <- invisible, no matching Setting
flutter.self_registration_enabled => true    <- dead, key not in source
gameDuration => 2100                         <- invisible to the app
gameType => "timeBased"                      <- invisible to the app
language => ["en"]                           <- invisible to the app
```

**These are not competing values.** `shared_preferences` prefixes every key with `flutter.`
automatically, and the `Setting` enum uses unprefixed names (`gameDuration`, `gameType`,
`language`, `autoMakegame`), so the app reads only the `flutter.`-prefixed entries. The unprefixed
keys and `flutter.locale` are inert leftovers from an older plugin version.
`flutter.self_registration_enabled` matches no name in the source at all.

This is hygiene, not a bug. It affects no behaviour. Fix it only if convenient.

---

## 4. Benchmarks

All figures measured on the dev machine (Apple Silicon, SSD) with release-mode-comparable pure
Dart. **Windows on slower storage should be assumed 1.5 to 2× worse.** Reproduction code is in
appendix A.

Workload model, per the club's stated shape: **4 courts, 15 rounds per session, 3 sessions per
week.** That is 60 game rows per session and 156 sessions per year, so **9,360 game rows per year**
and 2,340 session logs per year.

### 4.1 Write and startup cost (JSON)

| | `games.json` | Save per rotation | Startup parse |
|---|---|---|---|
| Today (385) | 0.10 MB | 9 ms | 9 ms |
| Year 1 (9,360) | 2.54 MB | 25 ms | 26 ms |
| Year 3 (28,080) | 7.61 MB | 70 ms | 68 ms |
| Year 5 (46,800) | 12.68 MB | 116 ms | 116 ms |

Read as: at year 3, pressing "Rotate now" blocks the UI for ~70 ms — about four dropped frames, a
brief stutter. Across 15 rotations that is roughly one second of total jank per whole session.
Startup adds 68 ms. Memory for 28,000 games is under 10 MB.

**Conclusion: JSON write cost does not become a problem within five years at this scale.** The
original premise for moving to a database was wrong.

### 4.2 Analytics cost, and the fix

Measured against the real functions in `analytics_engine.dart`:

| | Today (374) | Year 1 (9,360) | Year 3 (28,080) |
|---|---|---|---|
| `computePlayerMixing` | 13 ms | 222 ms | **891 ms** |
| `computeKpis` | 9 ms | 12 ms | 22 ms |
| `computeLevelDistribution` | 5 ms | 14 ms | 22 ms |
| `computeTopMovers` | 3 ms | 7 ms | 22 ms |
| `computeAtRiskPlayers` | 2 ms | 10 ms | 17 ms |
| `computeAttendanceTrend` | 1 ms | 5 ms | 6 ms |
| `computeNewPlayerIntegration` | 1 ms | 5 ms | 8 ms |
| **Total** | **34 ms** | **277 ms** | **1,018 ms** |

The indexed rewrite of mixing was built and measured:

| Year 3 | Current | Indexed |
|---|---|---|
| mixing | 891 ms | **29 ms** |
| whole tab | 1,018 ms | **156 ms** |

**30× faster from roughly 15 lines, with no storage change.** A database would run the same nested
loop over rows from a different source and would not help.

---

## 5. Decision

**Harden JSON. Do not migrate to SQLite now.**

### 5.1 Rationale

| | Build cost | Ongoing cost | Fixes 3.1? | Fixes 3.2? |
|---|---|---|---|---|
| SQLite (drift) | 8–9 days | Every model change needs a migration + schema test, ~20–30% more work per change | Yes | **No** |
| JSON hardening | ~3 days | Adding a field stays a nullable field plus codegen | Yes | Yes |

Three things drove this:

1. **The performance premise failed** (4.1). JSON is fine for years at this scale.
2. **The worst real performance problem is algorithmic** (4.2). SQLite would not fix it. The
   expensive function ignores the date range, so range-scoped SQL queries — the main analytics
   benefit in the original database plan — would not have touched it.
3. **The data-loss bug does not need a database.** Not dropping unresolved ids is a few lines.
4. **The test-isolation requirement is storage-agnostic.** A compile-enforced injection seam works
   identically over JSON.

There is also an unresolved supply risk on the database path: `sqlite3_flutter_libs` is
end-of-life ("Not used anymore, update to version 3.x of package:sqlite3 instead"), and `sqlite3`
3.5.1 is a plain Dart FFI package rather than a Flutter plugin, so Windows native-library bundling
for `flutter build windows` is unverified. drift 2.34 and `sqlite3` 3.5 also both require Dart
`>=3.10.0`, against the declared `^3.8.1`.

### 5.2 When to revisit

Move to SQLite when any of these becomes true — not before:

- A second device or concurrent writers (two organizers, or a phone check-in companion).
- `games.json` passes roughly 50,000 rows, or save cost passes ~150 ms.
- Queries the warm cache genuinely cannot serve — per-player history pages, arbitrary date-range
  reporting, full-text search.
- A need for durable per-round audit or match results, where partial writes are unacceptable.

### 5.3 The SQLite design, preserved

Kept so a future migration does not restart from nothing. This was fully designed and reviewed
before being deferred; the schema fixes the modelling gaps rather than porting 1:1.

Engine would be `drift` + `sqlite3` (dev: `drift_dev`), reusing the existing `build_runner`
pipeline. Store enums with `textEnum<T>()`, not `intEnum`, so values match the existing JSON
strings (`"elo": "c1"`) and survive enum reordering.

```
players               id PK, first_name, last_name, elo, sign_in_id?, created_date?,
                      membership, deleted_at?
sessions              id PK, started_at, ended_at?, capacity, court_count, mode,
                      rotation_seconds
rounds                id PK, session_id → sessions ON DELETE CASCADE, round_number,
                      started_at, ended_at?          UNIQUE(session_id, round_number)
games                 id PK, round_id? → rounds ON DELETE CASCADE, court_index, created_date
game_players          game_id → games ON DELETE CASCADE,
                      player_id → players ON DELETE RESTRICT,
                      slot_index                     PK(game_id, slot_index)
session_logs          id PK, session_id? → sessions ON DELETE SET NULL, round_id?,
                      logged_at, capacity, checked_in_count, waitlist_count,
                      reroll_count, court_count
session_log_court_gaps  session_log_id → session_logs ON DELETE CASCADE, court_index,
                      level_gap                      PK(session_log_id, court_index)
player_elo_history    id PK, player_id → players ON DELETE CASCADE, elo, changed_at
pending_registrations id PK, name, contact, tier, submitted_at
session_templates     id PK, name, mode_index, duration_minutes, duration_seconds,
                      capacity, courts
```

Indexes: `games(created_date)`, `games(round_id)`, `game_players(player_id)`,
`session_logs(logged_at)`, `rounds(session_id)`, `player_elo_history(player_id, changed_at)`,
`sessions(started_at)`.

Central invariant: `game_players.player_id` is `ON DELETE RESTRICT` and `players` is soft-deleted.
Deleting a player cannot erase history — the database refuses. Enable FKs explicitly in drift's
`beforeOpen` with `PRAGMA foreign_keys = ON`, since SQLite defaults them off.

Session lifecycle, had it been built: a session opens lazily on the first check-in of the day and
closes at midnight or on roster clear. This matches what analytics already assumes by grouping
logs per calendar day. Migrated legacy games would keep `round_id` as `NULL`.

Migration approach: one-time, idempotent, single transaction, run when the DB is absent and JSON
files are present. Dry-run against copies in a scratch directory and report row counts before
touching the real directory. Then rename each `*.json` to `*.json.premigration.backup`.

**Phase 1 of that work must be a spike** on the `sqlite3` 3.x Windows bundling question above,
because it can invalidate the dependency choice. Fall back to `sqlite3_flutter_libs 0.5.42` (last
non-EOL release) if needed.

### 5.4 Moving to a server database (MySQL / PostgreSQL)

The app runs offline today. The JSON files are kept in a shape that maps
one-to-one to SQL tables, so a later move to MySQL or PostgreSQL is an
import, not a redesign.

Rules the JSON layer keeps:

- One file is one table. Each row has a string `id` (UUID v4) as the
  primary key. All five files follow this: `players.json`, `games.json`,
  `session_logs.json`, `pending_registrations.json`,
  `session_templates.json`.
- Field names are camelCase in JSON and snake_case in SQL
  (`createdDate` → `created_date`).
- Enums are stored as their name strings (`"elo": "c1"`). Use `TEXT` /
  `VARCHAR` columns, not integers, so a reorder of a Dart enum cannot
  corrupt data.
- Dates are ISO-8601 local strings. Import them as `TIMESTAMP`
  (PostgreSQL) or `DATETIME` (MySQL).
- A list inside a row is a child table:
  - `games[].playerDto[]` → `game_players(game_id, player_id, slot_index)`.
    `slot_index` is the position in the list.
  - `session_logs[].courtLevelGaps[]` →
    `session_log_court_gaps(session_log_id, court_index, level_gap)`.
- Players are never hard-deleted while games reference them (ADR-0001).
  This matches `game_players.player_id → players ON DELETE RESTRICT`.

The table list in 5.3 is the target schema. For a server, use `UUID`
(PostgreSQL) or `CHAR(36)` (MySQL) for ids, and `VARCHAR` for enum
columns. The tables `sessions`, `rounds` and `player_elo_history` in 5.3
have no JSON source yet; create them empty.

Settings (language, game type, game duration, auto-make-game, court
background) stay in the platform preferences store. They are per-device
settings, not club data, and do not move to the server.

---

## 6. Implementation plan

~3 days total. Phases are ordered by value per hour. Phase 1 and 2 are the ones that matter — if
time runs out, ship those.

Write the failing test first in every phase (root `CLAUDE.md`).

### Phase 1 — Stop the roster loss (~0.5 day) · **highest priority**

**DONE 2026-08-29.** Fixes 3.1. Three independent changes.

**1a. Never write a lossy roster back.** Change `GameRepository` so its cache holds the DTO ids
rather than resolved `Player` objects. Resolve to `Game` on read, not on load.

- `_cache` becomes `Map<String, GameDto>`.
- `initialize()` stops calling `getPlayerFromDto` and stops using `.nonNulls`.
- `save()` writes the cached DTOs straight back, so unresolvable ids survive on disk untouched.
- `get`/`getAll` resolve ids to `Player` at read time and still drop unknowns, so **read behaviour
  and all analytics results are unchanged**. Only the write path changes.

This is the minimal correct fix: reads degrade, writes preserve.

**1b. Anonymise players instead of deleting them.** See **ADR-0001**. Without this, a hard delete
makes ids permanently unresolvable and 1a only preserves bytes, not meaning.

- Add `DateTime? deletedDate` to `Player` (`lib/model/player.dart:46`). Run `just generate`.
  (This section previously said `deletedAt`; `deletedDate` matches the existing `createdDate`.)
- `GameData.deletePlayer` (`game_data.dart:392-396`) sets `deletedDate`, empties `firstName` and
  `lastName`, and clears `signInId`, via `update` instead of calling `PlayerRepository.delete`.
  The id, the `elo` and the `createdDate` stay, so play history stays correct.
- `PlayerRepository.getAllCachedPlayers()` (`:56`) filters `deletedDate == null`.
- Audit the other `getAll`/`get` call sites for the same filter. Historical resolution must still
  see anonymised players, so do **not** filter inside `getPlayerFromDto`.
- Nothing stores the words "deleted player". The UI reads `deletedDate != null` and renders a
  localised label, so `en`, `fr` and `zh` all stay correct.

**1c. ~~Stop persisting empty courts~~ — REMOVED 2026-08-28.** This step was based on the incorrect
mechanism B finding in §3.1 and would have destroyed data. `saveCurrentGame` is right to keep the
empty courts, because in a Time Based session an idle court is part of the round. See ADR-0002.

The change runs the other way, and it is **not part of phase 1**: `rotateNow` (`:314-317`) must stop
filtering, so both Time Based save paths write the same shape. Do it with the round id in ADR-0002,
not before — until a round id exists, an empty row cannot be told apart from a destroyed roster.

`saveSingleGame` (`:540`) needs no change. It guards `game.players.isEmpty` at `:541`, which is
correct: a Game Based court saves on its own and has no round to belong to.

**Tests to write first:**
»
- A game whose roster references an unknown player id keeps that id in `games.json` after an
  unrelated save. *This is the regression guard for the bug that erased 98% of the history.*
- Deleting a player leaves their historical game rosters intact on disk.
- An anonymised player is absent from `getAllCachedPlayers()` but still resolves for a historical
  game.
- Deleting a player empties `firstName`, `lastName` and `signInId`, and keeps `id`, `elo` and
  `createdDate`.
- ~~`saveCurrentGame` with 2 filled courts and 2 empty padded courts persists exactly 2 games.~~
  **REMOVED 2026-08-28** — this asserts the incorrect mechanism B finding. `saveCurrentGame` with 2
  filled and 2 empty padded courts must persist **4** games. See ADR-0002.

### Phase 2 — Index the analytics hot loops (~0.5 day) · **highest value per hour**

Fixes 3.2. Build a player-to-games index once instead of re-scanning per player. Replace the body
of `computePlayerMixing` (`analytics_engine.dart:584-612`). Measured at 891 ms → 29 ms at year-3
volume.

```dart
List<MixingEntry> computePlayerMixing(List<Game> games) {
  final gamesByPlayer = <String, List<Game>>{};
  final playerById = <String, Player>{};
  for (final g in games) {
    for (final p in g.players) {
      (gamesByPlayer[p.id] ??= <Game>[]).add(g);
      playerById[p.id] ??= p;
    }
  }
  final result = <MixingEntry>[];
  for (final entry in gamesByPlayer.entries) {
    final playerGames = entry.value;
    if (playerGames.isEmpty) continue;
    final partnerIds = <String>{};
    for (final g in playerGames) {
      for (final p in g.players) {
        if (p.id != entry.key) partnerIds.add(p.id);
      }
    }
    final score =
        (partnerIds.length / playerGames.length).clamp(0, 1).toDouble();
    String? tag;
    if (score >= 0.7) {
      tag = 'connector';
    } else if (score <= 0.2) {
      tag = 'isolated';
    } else if (score <= 0.4) {
      tag = 'clique';
    }
    result.add(
      MixingEntry(name: playerById[entry.key]!.name(), score: score, tag: tag),
    );
  }
  return result.sortedBy<num>((e) => -e.score);
}
```

Apply the same index to `computeNewPlayerIntegration` (`:629-665`), whose `playerGames` lookup at
`:647` has the identical pattern.

**This must be behaviour-preserving.** The existing suite in
`test/features/analytics_engine_test.dart` (254 lines) is the oracle — it must pass untouched. Add
a case with a known partner-diversity result before rewriting, so equivalence is proven rather than
assumed.

Do **not** add a benchmark to the committed suite; timing tests are flaky in CI. Use appendix A
ad hoc.

### Phase 3 — Atomic and coalesced writes (~0.5 day)

Fixes 3.3.

**3a. Atomic write.** Extract the duplicated save logic — currently copy-pasted across all four
repositories — into one shared helper, for example `lib/repository/json_file_store.dart`:

```
write(target, contents):
  tmp = File('$target.tmp')
  tmp.writeAsString(contents, flush: true)
  tmp.rename(target)        // verify Windows semantics, see caveat
```

**Caveat to verify:** on POSIX, `rename` atomically replaces an existing target. Dart's
`File.rename` on Windows may fail when the target exists. Confirm this before relying on it. If it
does fail, use: write `tmp`, rename `target` → `target.old`, rename `tmp` → `target`, delete
`target.old`. Then on load, if `target` is missing but `target.old` exists, recover from
`target.old`.

While there, replace the hardcoded `'/'` interpolation with `p.join` for the Windows target.

**3b. Coalesce concurrent writes.** Do **not** add a debounce timer — it would break the many tests
that assume `await save()` has landed. Instead track one in-flight write plus at most one pending
write, and have every `save()` call return a Future completing when a write containing its data has
landed. Multiple rapid mutations then collapse into one write without changing `await` semantics,
and two writes can never interleave.

**Tests to write first:**

- A save interrupted before rename leaves the previous file contents intact and parseable.
- Ten rapid `update` calls produce fewer than ten physical writes, and the final file contains all
  ten changes.
- `await save()` guarantees the data is on disk.

### Phase 4 — Compile-enforced test isolation (~1 day) · **the explicit requirement**

**DONE (4a, 4b, 4d in part).** `lib/repository/data_root.dart`. `AppLoader` requires a `DataRoot`; `DataRoot.production()` throws under `flutter test`. Integration tests use a temp directory and an in-memory preferences store. 4f (CI job for integration tests) is not done.

Replaces the convention-based seam in section 2.2 with one the compiler checks.

**4a. Introduce a `DataRoot` value type** in `lib/repository/data_root.dart`, with two named
constructors and no default:

- `DataRoot.production()` — resolves `getApplicationDocumentsDirectory()`. Throws if
  `Platform.environment.containsKey('FLUTTER_TEST')`.
- `DataRoot.temporary()` — creates and owns a temp dir, with a `dispose()` that deletes it.

A test cannot reach production data by forgetting a call. It would have to type `.production()`
deliberately.

**4b. Make it required.** `AppLoader({required this.dataRoot})`, and
`RepositoryService.initialize(DataRoot)`. `main.dart` becomes the only caller of
`DataRoot.production()`. **A test that pumps the app without supplying a root is now a compile
error, not a silent production write.**

**4c. Note the limit honestly.** The `FLUTTER_TEST` guard covers `flutter test` only.
`integration_test` runs as a real app and does not set that variable. That is exactly why 4b —
compile-time — is the primary guard and the environment check is only secondary.

**4d. Convert callers.** Rewrite `test_utils.dart:355-394` to hand in a `DataRoot.temporary()` and
delete the bare `catch (_)`. Convert the 13 unit-test files off `initializeForTesting`. Fix
`test/widget_test.dart`, which currently pumps `AppLoader` unsandboxed. Add the missing
`tearDownAll` so temp dirs stop leaking.

**4e. Relax the caches.** Change `PlayerRepository._cache` (`:39`) and `GameRepository._cache` /
`_playerRepository` (`:47,49`) from `late final` to plain `late`, matching the other two
repositories. Then `initialize()` can run per test and the `resetForTesting` /
`initializeForTesting` pokes can be deleted along with the try/catch dance.

**4f. Run the integration suite.** Add `just test-integration`
(`flutter test integration_test -d macos`) and a CI job in `.github/workflows/dart.yml`. Nothing
runs `integration_test/` today, which is why the incident had no guard — **without this the
isolation guarantee is claimed but never checked.** Also add the missing `flutter gen-l10n` step
that `just generate` has and CI does not.

### Phase 5 — Templates reload (~0.25 day)

**DONE.** See 3.4.

Fixes 3.4. Hydrate `GameData._templates` from `PersistentSetting.loadTemplates()` during startup,
and make `GameData.deleteTemplate` (`game_data.dart:918-924`) write the shortened list back through
a new `PersistentSetting.removeTemplate(name)`.

**Tests to write first:** a saved template is listed after a fresh `GameData` + `initialize()`; a
deleted template is still absent after the same restart.

### Phase 6 — Prefs hygiene (~0.25 day, optional)

Addresses 3.5. **Read 3.5 first — this is not a live bug.** The unprefixed keys are invisible to
the app, so this only removes dead weight. Add a one-time cleanup, version-stamped so it runs once,
that deletes the unprefixed duplicates and `flutter.self_registration_enabled`. Skip this phase if
time is short.

### Phase 7 — Docs (~0.25 day)

See section 8.

### Out of scope, deliberately

- **Persisting check-in state.** `_checkedInPlayerIds` is RAM-only, so a crash mid-session loses
  every check-in. Fixing it is a behaviour change and needs its own UAT cases, not a storage fix.
  Worth filing.
- **Match results / winners.** No field exists. A feature, not a defect.
- **Dead code removal.** `serializer.dart` and `GameData.saveGame` (`:996-1011`) have no callers.
  Safe to delete, but unrelated.

---

## 7. Verification

1. `just generate` — codegen clean (required after the `Player.deletedAt` change).
2. `just lint` — `flutter analyze --fatal-infos --no-pub` and format check both clean.
3. `just test` — all **347** currently-passing tests still pass. That count is the baseline.
4. `just test-integration` — new recipe passes.
5. **Roster-preservation proof (phase 1).** A game referencing an unknown player id still has that
   id in `games.json` after an unrelated save. Then delete a player who appears in a saved game and
   assert the roster is intact. *This is the exact failure that erased 98% of the history.*
6. **Isolation proof (phase 4).** Record `stat` on the four real JSON files. Run both suites.
   Re-`stat` and confirm mtimes are unchanged. Baseline captured 2026-08-18:

   | File | mtime at investigation |
   |---|---|
   | `games.json` | Aug 16 16:50:50 2026 |
   | `pending_registrations.json` | Aug 15 23:40:12 2026 |
   | `players.json` | Aug 17 23:52:31 2026 |
   | `session_logs.json` | Aug 16 16:50:50 2026 |

   Then delete the `dataRoot` argument from one `pumpApp` call and confirm `flutter analyze`
   **errors** rather than the test passing. That is the difference between a guarantee and a
   convention.
7. **Analytics equivalence proof (phase 2).** `test/features/analytics_engine_test.dart` passes
   untouched, and a new fixture with a hand-computed diversity score matches.
8. **Atomicity proof (phase 3).** A save interrupted before rename leaves the old file parseable.
9. **Durability proof (phase 5).** Save a template, restart, confirm it is listed. Delete one,
   restart, confirm it stays gone.
10. `flutter build windows` succeeds — the target platform, and the one where the `rename` and
    `p.join` concerns land.

---

## 8. Doc updates required when done

Per root `CLAUDE.md`, feature and test changes must be reflected back into the UX-Redesign docs.

- **`lib/CLAUDE.md` L15-24** — rewrite "Data Layer: In-Memory Cache + JSON File Persistence" to
  cover the DTO-cache change, soft delete, atomic writes, and the `DataRoot` seam. Two existing
  staleness bugs to fix while there: the section omits `SessionLogRepository` /
  `session_logs.json` and `PendingRegistrationRepository` entirely, and the "Drag-and-Drop System"
  section (L35-37) describes a system replaced by click-to-select in Stage 3.
- **`UX-Redesign/IMPLEMENTATION.md`** — add `## Stage 8 — Data Layer Hardening` after L1028, before
  `## Cross-Cutting Rules` (L1031). Match the existing per-stage template exactly: `### Goal` →
  `### Inputs` → `### Migration Notes` → `### File Manifest` (`| Action | Path | Notes |`) →
  `### Detailed Tasks` (`#### 8.1 — \`Name\`` plus a comment-only ```dart block ending in
  `// Props:`) → `### Acceptance Criteria` (`- [ ] **DATA-01** — …`, opening with a
  `> **UAT mapping:**` blockquote). Add a Stage 8 row to the Stage Overview table after L61 and the
  new files to the File Tree (L1060-1166). Note L1145-1157 of that tree is already stale —
  `session_log_repository.dart` and `model/session_log.dart` are missing despite Stage 6 creating
  them.
- **`UX-Redesign/UAT.md`** — add `## 11. Data persistence` with a new `DATA-01…NN` prefix, in the
  established `**DATA-01** — Title` plus Given/When/Then format. Cover: data survives restart;
  deleting a player preserves their game history; an interrupted write does not corrupt the file; a
  saved session template is still listed after a restart. Add the row to the traceability table
  (L673-684) and update the total at L686 (currently **75**).
- **`UX-Redesign/ARCHITECTURE.md`** — this doc is a pure design-system reference (tokens,
  components, layout) with zero persistence mentions today. Add at most a compact
  `## 7. Data Persistence` section with the entity diagram and the roster-preservation invariant,
  pointing here for detail. Keep it small rather than moving this file's content in.

---

## Appendix A — Benchmark reproduction

Both benchmarks were run ad hoc and then deleted. Neither belongs in the committed suite — timing
assertions are flaky in CI. Recreate them when a measurement is needed.

### A.1 JSON write and parse cost

A standalone Dart script (no Flutter needed). Build `n` maps matching the `GameDto` shape exactly —
`{'playerDto': [{'id': …} × 4], 'id': …, 'createdDate': …}` — wrap them as `{'games': [...]}`, then
time four things separately: `jsonEncode`, `writeAsStringSync`, `readAsStringSync` +
`jsonDecode`, and the O(games × 4) player-resolution pass that `GameRepository.initialize` performs.
Run for `n` in `[385, 9360, 28080, 46800]`. Save cost is encode + write.

### A.2 Analytics cost

A `flutter test` file, because `analytics_engine.dart` transitively imports Flutter through
`model/game.dart` → `state/game_data.dart`. Generate 245 `Player`s with non-null `createdDate`
(the live data has nulls, which makes `computeNewPlayerIntegration` free and hides its cost), and
`n` `Game`s of 4 players each on an 8-minute stride. Then time each `compute*` function separately
with a `Stopwatch` and print the results.

Watch the argument order: `computeLevelDistribution(List<Player>, List<Game>, DateRange)` takes
players first, unlike its neighbours.

Use `n` in `[374, 9360, 28080]` for today / year 1 / year 3.

## Appendix B — Volume model

| Input | Value |
|---|---|
| Courts | 4 |
| Rounds per session | 15 |
| Sessions per week | 3 |
| Game rows per session | 4 × 15 = 60 |
| Sessions per year | 3 × 52 = 156 |
| **Game rows per year** | **9,360** |
| Session logs per year | 15 × 156 = 2,340 |
| Year 3 game rows | 28,080 |
| Year 5 game rows | 46,800 |

Adjust proportionally if the club's shape changes. Court count and rounds per session both scale
game rows linearly, so doubling courts halves the time to any threshold in section 5.2.
