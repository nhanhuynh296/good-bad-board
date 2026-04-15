# Testing

**Analysis Date:** 2026-04-16

## Test Structure

**Location:**
- All tests live in `test/` at the project root (flat — no subdirectory nesting)
- Two test files exist:
  - `test/game_data_test.dart` — unit tests for `GameData` state logic
  - `test/widget_test.dart` — smoke widget test for the root `AppLoader` widget

**Organization:**
- Tests are not co-located with source files; they live exclusively in `test/`
- No `test/helpers/`, `test/fixtures/`, or `test/mocks/` subdirectories exist
- Each test file corresponds to a specific class or concern, not a directory mirror of `lib/`

## Test Types

**Unit Tests (`test/game_data_test.dart`):**
- Use `package:test/test.dart` (the standalone Dart test package, not `flutter_test`)
- Test the `GameData` `ChangeNotifier` class in isolation — no widget tree involved
- Cover: adding players, generating matches, swapping players, staging match state
- 5 test cases total

**Widget Tests (`test/widget_test.dart`):**
- Use `package:flutter_test/flutter_test.dart`
- One smoke test: pumps `AppLoader` and asserts no unexpected text is rendered
- Does not mock any dependencies; relies on `AppLoader` completing its async `loading()` (which touches `RepositoryService`, `PersistentSetting`, `PlayerRepository`, `GameRepository`)

**Integration / E2E Tests:**
- Not present

## Coverage

**What is tested:**
- `GameData.addFullPricedPlayer` — players are added to the internal map
- `GameData.addFractionalPricedPlayer` — fractional players are added
- `GameData.makeGame` — staging matches are generated from 4 players and 1 court
- `GameData.swapPlayer` — inactive player replaces an active player in staging matches
- Guard: `makeGame` throws when no players are present

**What is NOT tested (significant gaps):**
- `GameData.saveCurrentGame` / `saveSingleGame` — file persistence not tested
- `GameData.makeSingleCourt` — single-court refresh not tested
- `GameData.onUpdatePlayer` / `deletePlayer` / `removePlayer` — mutation paths not tested
- All `Repository` classes (`GameRepository`, `PlayerRepository`) — zero coverage
- `PersistentSetting` — SharedPreferences logic not tested
- All widgets and pages — only the root smoke test exists
- `core/` extensions (`IterableExtension`, `ImmutabilListExtension`, `ThemeX`, `ShowToast`) — not tested
- `core/organizer.dart`, `core/random.dart`, `core/importer.dart` — not tested
- Routing (`lib/routes.dart`) — not tested

**Coverage tooling:**
- No coverage threshold is configured in CI or `pubspec.yaml`
- `flutter test --coverage` can generate LCOV data but is not run in CI

## Test Utilities

**Mocks / Fakes:**
- None. No mocking library is present in `dev_dependencies` (`mockito`, `mocktail`, etc. are absent)
- The unit tests instantiate `GameData()` and `Player.create(...)` directly — no fakes for repositories or `SharedPreferences`

**Fixtures / Factories:**
- Inline within `game_data_test.dart`: a `List<Player>` of 4 players is generated at the top of `main()` using `List.generate`, shared across all tests via closure capture
- No dedicated factory or fixture helpers

**Test helpers:**
- None beyond what `package:test` and `package:flutter_test` provide natively
- `getPlayerFromGames` (defined in `lib/state/game_data.dart`) is called directly from the test — it is a public top-level function, not a test-only helper

## Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/game_data_test.dart

# Run with coverage (generates coverage/lcov.info)
flutter test --coverage

# Watch mode (not natively supported; use flutter_test with a file watcher externally)
```

**Note:** `test/widget_test.dart` currently pumps `AppLoader`, which calls `RepositoryService.instance.initialize()` and `SharedPreferencesWithCache.create(...)`. This will likely fail or hang in a headless CI environment without proper platform channel mocking. The test passes in CI because `flutter test` provides default platform channel stubs for `path_provider` and `shared_preferences`.

## CI Integration

**Workflow file:** `.github/workflows/dart.yml`

**Trigger:**
- `push` to `main` branch
- `pull_request` targeting `main` branch

**Test step in CI:**
```yaml
- name: Run tests
  run: flutter test
```

**CI pipeline order:**
1. Checkout repository
2. Set up Flutter (stable channel, with cache)
3. `flutter pub get`
4. `dart format --output=none --set-exit-if-changed .` — formatting check (fails fast)
5. `dart run build_runner build --delete-conflicting-outputs` — code generation
6. `flutter analyze --fatal-infos --no-pub` — static analysis (infos are fatal)
7. `flutter test` — runs all tests

**Separate artifact workflow:** `.github/workflows/artifact.yml` runs only on push to `main` and does NOT run tests — it only builds the Windows release artifact and creates a GitHub release.

**No coverage enforcement** in CI. No SonarQube gate on test coverage despite `sonar-project.properties` being present in the root.

---

*Testing analysis: 2026-04-16*
