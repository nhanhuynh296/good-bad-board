# lib/ architecture

### State Management: Provider + ChangeNotifier

Three state objects are registered at the root in `lib/main.dart`:

| Class | Scope | Purpose |
|---|---|---|
| `PersistentSetting` | Singleton | App settings persisted via `SharedPreferencesWithCache` (language, game type, game duration, court background; main's auto-make-game key stays on disk, unread) |
| `GameData` | Per-session | Core game logic: checked-in player roster, matchmaking, Elo optimization, staging/history of games |
| `TimerData` | Per-session | Tracks elapsed time for the countdown timer on the game page |

State changes trigger `notifyListeners()`. Views use `context.select()` or `context.read<T>()` / `Provider.of<T>()` to consume state.

### Data Layer: JsonCollection + thin repository adapters

`lib/repository/json_collection.dart` defines `JsonCollection<V>` — the one module that owns
load, in-memory cache, synchronous reads, durable writes (temp file + rename, flushed, coalesced)
and change notification (it's a `ChangeNotifier`) for a single JSON file. `PlayerRepository`,
`GameRepository`, `SessionLogRepository` and `PendingRegistrationRepository` are thin adapters
over one `JsonCollection` each, supplying a file name and a codec pair.

Each adapter exposes a `static late` `instance` field and a `static Future<X> initialize({required
String rootDir})` constructor — nothing is built eagerly, so an adapter used before construction
throws instead of silently reaching a stale or production directory. `main.dart` constructs all
four once, in dependency order (`PlayerRepository` before `GameRepository`, since `Game.players`
resolves ids against `PlayerRepository.instance` when read). Tests use
`test/support/repository_sandbox.dart`, which does the same against a temp directory.

Reads (`byId`, `all`, `listedPlayers`, `getAll`) are synchronous map lookups. Writes
(`add`, `addAll`, `update`, `delete`, `remove`) are asynchronous and notify listeners after they
land — pages that need to react to a write (e.g. `PlayersPage`'s pending-registration queue,
`AnalyticsPage`'s persisted games/logs) listen to `XRepository.instance.listenable` rather than
polling a revision counter.

`GameRepository`'s cache holds `GameDto` (player ids only), not resolved `Game` objects — a
`Game`'s player list is resolved from `PlayerRepository` only when read, never when saved, so a
player id that no longer resolves survives on disk instead of being dropped (ADR-0001).

Models (`Player`, `Game`, and DTOs) use the **freezed** package with **json_serializable** for immutable data classes with JSON serialization. Run `just generate` after changes.

### Matchmaking Algorithm (`lib/state/game_data.dart`)

The `GameData.makeGame()` method:
1. Uses weighted random selection (`Picker.choices` from `lib/core/random.dart`) — players with fewer past matches get higher probability
2. Groups selected players into courts of 4 (`Game.playerPerCourt`)
3. Runs a greedy hill-climbing optimization (`_improveEloSpread`) that swaps player pairs between courts to minimize Elo spread, using the `trotter` library for combinatorial iteration

### Drag-and-Drop System

Players can be dragged between the inactive player list and court positions. The swap flow (`GameData.swapPlayer`) handles both directions. `DragTarget<Player>` in `InactivePlayerComponent` also supports removing a player from court by dragging them to the inactive area.

### Theme & Styling

Design tokens live in `lib/design/`: colors (`AppColors`), typography (`AppTypography`), spacing (`AppSpacing`), radii (`AppRadii`), breakpoints (`AppBreakpoints`), and the theme factory (`AppTheme`). The app is light only (no dark theme). A consistent outlined border style (`_lightOutlinedBorder`) is applied to all Material components. Text uses one bundled family, Source Sans 3, on a 6-size scale; `AppTheme.light(locale:)` adds the Chinese system font fallback for the locale.
