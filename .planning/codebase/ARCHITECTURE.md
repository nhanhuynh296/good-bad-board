# Architecture

**Analysis Date:** 2026-04-16

## Pattern

**Overall:** Layered architecture with Provider-based state management, loosely following a Repository pattern. Not a strict MVC/MVVM — the `state/` layer combines ViewModel-like business logic with ChangeNotifier, while views consume state directly via `context.select` / `Provider.of`.

**Key Characteristics:**
- No BLoC, no Riverpod — pure `provider` package (`ChangeNotifier` + `MultiProvider`)
- Singletons used for repositories and services (all via `ClassName._()` private constructor + `static final instance`)
- In-memory caching in repositories backed by local JSON files on disk
- Code generation via `freezed` + `json_serializable` for immutable models and DTOs
- Navigation managed declaratively via `go_router`

## Layer Structure

**Models (`lib/model/`):**
- Purpose: Pure data classes. Immutable value objects using `freezed`.
- Contains: `Player`, `Game` — domain entities with factory constructors and business helpers (`eloGap()`, `isPlayable()`)
- Depends on: `freezed_annotation`, `uuid`, `collection`
- Used by: state, repository, view layers

**Repository (`lib/repository/`):**
- Purpose: Persistence layer. Reads/writes JSON files to the device's application documents directory.
- Contains: `InMemoryRepository<V>` interface; `PlayerRepository`, `GameRepository` (singleton implementations); DTO classes (`PlayerDto`, `GameDto`, `PlayerDatabase`, `GameDatabase`); `RepositoryService` (resolves root storage path); `Serializer` (file picker helper)
- Pattern: Each repository holds a `Map<String, V> _cache` that is the single source of truth at runtime. All mutations write through to a JSON file immediately.
- Depends on: `path_provider`, `dart:io`, `freezed_annotation`, `json_serializable`
- Used by: state layer, directly by some view widgets (e.g., `SignInPage` calls `PlayerRepository.instance.add()`)

**State (`lib/state/`):**
- Purpose: Application state and business logic. Acts as the ViewModel layer.
- Contains:
  - `GameData` (`ChangeNotifier`) — active session state: current players, staging matches, history, court count. Houses core game-generation algorithm (`makeGame`, `_improveEloSpread`).
  - `PersistentSetting` (`ChangeNotifier`, singleton) — user preferences backed by `SharedPreferences` (game type, duration, language, background, auto-make).
  - `TimerData` (`ChangeNotifier`) — tracks elapsed countdown timer duration across page navigations.
- Depends on: model, repository layers
- Used by: view layer via `Provider.of<T>` / `context.select<T>`

**View (`lib/view/`):**
- Purpose: UI layer. All Flutter widgets and pages.
- Pages: `LandingPage`, `SignInPage`, `GameMakerPage`, `PlayerStatisticPage`
- Components (`lib/view/component/`): Reusable widgets — `Button`, `Court`, `GameEditor`, `InactivePlayer`, `ListRenderer`, `Overlay`, `PlayerComponent`, `Timer`, `SettingPage`, `ShadedContainer`; dialogs (`AddPlayer`, `EditPlayer`, `Toasts`)
- Depends on: state layer, model, core utilities
- Used by: router

**Core (`lib/core/`):**
- Purpose: Pure utilities and extensions. No Flutter-framework dependencies except `BuildContext` extension.
- Contains:
  - `build_context_extension.dart` — `ThemeX` extension (`theme`, `textTheme`, `colorScheme` shortcuts)
  - `duration_extension.dart` — Duration helpers
  - `iterable_extension.dart` — Collection helpers (`shuffled`, `choices`, `mostPopular`, etc.)
  - `random.dart` — Shared `Random` instance
  - `importer.dart` — CSV import logic (file picker + parsing)
  - `organizer.dart` — Empty file (reserved/unused)

**Application root (`lib/`):**
- `main.dart` — App bootstrap: initialises repositories sequentially, wraps app in `MultiProvider`
- `routes.dart` — `GoRouter` configuration with named routes
- `global.dart` — App-wide constants (`appName`, `navigatorKey`, `version`, `goldenRatio`)
- `theme.dart` — `lightTheme` / `darkTheme` definitions, `AppColors`, shared border/shape constants
- `spacing.dart` — Spacing constants (`space8`, `space16`, `spacePageX`, etc.)

## State Management

**Package:** `provider` ^6.1.2

**Providers registered in `main.dart`:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: PersistentSetting.instance), // singleton
    ChangeNotifierProvider(create: (_) => GameData()),               // session-scoped
    ChangeNotifierProvider(create: (_) => TimerData()),              // session-scoped
  ],
  ...
)
```

**Consumption patterns:**
- `context.select<T, R>((T t) => t.field)` — granular rebuild, preferred in pages
- `Provider.of<T>(context)` — full widget rebuild on any change, used in components
- `Provider.of<T>(context, listen: false)` — one-time read without subscribing
- `PersistentSetting.instance` accessed directly (as singleton) in some places, bypassing the provider tree

**State boundaries:**
- `GameData` is the session object; it is NOT persisted across app restarts. History is reloaded from `GameRepository` on the `PlayerStatisticPage` when needed.
- `PersistentSetting` wraps `SharedPreferences`; it is persisted and survives restarts.
- `TimerData` is in-memory only; saves elapsed time so the timer can resume across page transitions within a session.

## Data Flow

**Player registration flow:**
1. `SignInPage` renders the list from `PlayerRepository.instance.getAllCachedPlayers()`
2. User taps a player → `GameData.addFullPricedPlayer(player)` → `notifyListeners()`
3. `GameMakerPage` rebuilds via `context.select((GameData d) => d.players)`

**Game generation flow:**
1. User taps "Generate" on `GameMakerPage`
2. `GameData.makeGame()` → weighted random player selection → `_improveEloSpread()` (greedy swap optimisation) → `stagingMatches` updated → `notifyListeners()`
3. `GameMakerPage` rebuilds to show new staging matches

**Game save flow:**
1. User taps "Save" → `GameData.saveCurrentGame()` or `saveSingleGame(game)`
2. `GameRepository.instance.addAll(stagingMatches)` → writes to `games.json`
3. `stagingMatches` cleared → `history` appended → `notifyListeners()`

**Settings persistence flow:**
1. User changes a setting in `SettingPage` → `PersistentSetting.instance.setX(value)`
2. Internally calls `sharedPreference.setX(...)` then `notifyListeners()`
3. `MyApp` rebuilds (`locale` selector) or affected widgets rebuild

**Startup initialisation sequence (order-dependent):**
```
RepositoryService.initialize()          // resolves file system root path
PersistentSetting.initialize()          // loads SharedPreferences cache
PlayerRepository.initialize()           // reads players.json into memory
GameRepository.initialize()             // reads games.json; requires PlayerRepository
```

## Key Design Decisions

**Singleton repositories:** `PlayerRepository.instance`, `GameRepository.instance`, `RepositoryService.instance`, `PersistentSetting.instance` are all private-constructor singletons. This avoids dependency injection but couples call sites directly to concrete types — some views call `PlayerRepository.instance` outside the provider tree.

**Freezed for models and DTOs:** `Player`, `Game`, `PlayerDto`, `GameDto`, `PlayerDatabase`, `GameDatabase` all use `freezed`. Models have `equal: false` and `makeCollectionsUnmodifiable: false` on `Game` to allow mutable player lists during in-game editing.

**JSON file storage (no SQLite):** Each entity type has a single JSON file (`players.json`, `games.json`) written in full on every mutation. Simple but not efficient for large datasets.

**DTO indirection for game serialization:** `GameDto` stores `PlayerDto` (id reference only) instead of full player data. `GameRepository.initialize()` resolves player references from `PlayerRepository` at load time. This keeps players deduplicated but creates an initialization order dependency.

**ELO-based greedy optimisation:** `GameData._improveEloSpread` iterates pairwise player swaps across courts to minimise ELO spread (weighted by average and max spread). Capped at `maxIteration = 1000`.

**Weighted random player selection:** `GameData._choosePlayer` uses exponential decay weighting so players who have played fewer games are statistically more likely to be selected.

**GoRouter for navigation:** Declarative routing via `lib/routes.dart`. Navigator key (`navigatorKey` from `global.dart`) is passed to `GoRouter` to allow imperative navigation outside the widget tree.

## Module Boundaries

There are no separate Dart packages or feature modules. The app is a single package (`good_bad_board`) divided by technical layer:

| Directory | Role |
|---|---|
| `lib/model/` | Domain entities |
| `lib/repository/` | Data persistence (JSON files, SharedPreferences) |
| `lib/state/` | App state / business logic (ChangeNotifier) |
| `lib/view/` | Screens and UI components |
| `lib/core/` | Pure utilities and Dart extensions |
| `lib/l10n/` | Internationalisation (ARB files + generated `.dart`) |

No strict feature-first organisation — all pages live flat in `lib/view/`, not grouped by feature. Components are shared across all pages in `lib/view/component/`.

---

*Architecture analysis: 2026-04-16*
