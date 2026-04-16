<!-- GSD:project-start source:PROJECT.md -->
## Project

**Good Badminton Board**

A Flutter-based court and session organiser for badminton clubs, used by committee members to manage player rotation, court assignments, and ELO-balanced matchmaking during sessions. The app handles the full session lifecycle — from player sign-in through game generation to session history — on a single shared device run by the club committee.

**Core Value:** The committee can run a session end-to-end — sign in players, generate balanced courts, and rotate fairly — with minimal taps and no manual calculation.

### Constraints

- **Tech stack**: Flutter (Dart) — no platform change; target mobile (Android/iOS) first
- **Storage migration**: Must preserve all existing player and game history data when migrating to SQLite; zero data loss
- **UX principle**: Admin-first, minimal taps — avoid features that require continuous input during play (no live scoring, no play-by-play)
- **State management**: Stay on Provider/ChangeNotifier unless SQLite migration creates a clear reason to revisit; avoid scope creep into Riverpod/BLoC refactor
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Language & Runtime
- Dart ^3.8.1 - All application code under `lib/`
- Kotlin - Android platform layer under `android/app/src/main/kotlin/`
- Flutter (stable channel) - cross-platform UI framework targeting Windows desktop (primary artifact), Android, and iOS
## Frameworks & Core Libraries
- `flutter` (sdk) - UI framework
- `flutter_localizations` (sdk) - i18n/l10n support (en, fr, zh locales)
- `go_router` ^16.0.0 - Declarative routing (`lib/routes.dart`)
- `provider` ^6.1.2 - State management via `ChangeNotifier` + `MultiProvider` (`lib/main.dart`)
- `freezed_annotation` ^3.0.0 - Immutable data class code generation for models and repositories
- `json_annotation` ^4.9.0 - JSON serialization annotations for models
## Build & Package Management
- Lockfile: `pubspec.lock` present
- Install: `flutter pub get`
- Code generation: `dart run build_runner build --delete-conflicting-outputs`
- `flutter_lints` ^6.0.0 extended with additional rules in `analysis_options.yaml`
- Base: `package:flutter_lints/flutter.yaml`
- Notable extra rules: `prefer_const_constructors`, `prefer_const_declarations`, `camel_case_types`, `file_names`
## Key Dependencies
| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management — `GameData`, `TimerData`, `PersistentSetting` via `ChangeNotifier` |
| `go_router` | ^16.0.0 | Client-side routing across 4 pages (`/`, `/register`, `/game`, `/stats`) |
| `freezed_annotation` | ^3.0.0 | Immutable model/repository classes (`lib/model/`, `lib/repository/`) |
| `json_annotation` | ^4.9.0 | JSON serialization for `Game` and `Player` models |
| `path_provider` | ^2.1.5 | Resolves `getApplicationDocumentsDirectory()` for local JSON file storage (`lib/repository/repository_service.dart`) |
| `shared_preferences` | ^2.5.3 | Persistent key-value settings (background image, game type, language, duration) via `lib/state/persistent_setting.dart` |
| `file_picker` | ^10.2.0 | Native file picker for CSV import and JSON save/load (`lib/core/importer.dart`, `lib/repository/serializer.dart`) |
| `csv` | ^6.0.0 | CSV parsing for player bulk import (`lib/core/importer.dart`) |
| `intl` | any | Internationalization formatting (required by `flutter_localizations`) |
| `trotter` | ^2.2.0 | Combinatorics/permutation utilities used in game organization logic (`lib/core/organizer.dart`) |
| `uuid` | ^4.5.1 | UUID generation for unique player/game identifiers |
| `collection` | ^1.19.1 | Extended collection utilities (`firstWhereOrNull`, etc.) |
| `cupertino_icons` | ^1.0.8 | iOS-style icon font |
## Dev Dependencies
| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | sdk | Widget and unit test framework |
| `test` | ^1.25.15 | Dart test runner and assertion library |
| `build_runner` | ^2.5.2 | Code generation runner for `freezed` and `json_serializable` |
| `freezed` | ^3.0.6 | Code generator for immutable classes (produces `.freezed.dart` files) |
| `json_serializable` | ^6.9.5 | Code generator for JSON serialization (produces `.g.dart` files) |
| `flutter_lints` | ^6.0.0 | Recommended Flutter lint rule set |
## Configuration
- `--dart-define=VERSION=<ver>` passed at build time for Windows artifact versioning (set by CI tag action)
- `.env` file present at root — contents not read; likely local dev config only (not used in build pipeline)
- `asset/image/` — Court background images (including `badminton.webp` as default)
- `asset/font/NotoSans-VariableFont_wdth,wght.ttf` — Registered as `Gotham` font family
- `lib/model/game.freezed.dart`, `lib/model/game.g.dart`
- `lib/model/player.freezed.dart`, `lib/model/player.g.dart`
- `lib/repository/game_repository.freezed.dart`, `lib/repository/game_repository.g.dart`
- `lib/repository/player_repository.freezed.dart`, `lib/repository/player_repository.g.dart`
- `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`, `lib/l10n/app_localizations_zh.dart`
## Platform Requirements
- Flutter SDK (stable channel)
- Dart SDK ^3.8.1
- Code generation must run before building: `dart run build_runner build --delete-conflicting-outputs`
- Primary deployment target: Windows desktop (`.zip` artifact published to GitHub Releases)
- Secondary targets: Android, iOS (configured but not in active CI artifact pipeline)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Conventions
- `snake_case.dart` for all Dart source files (enforced by `file_names` lint rule)
- Suffixes encode role: `_page.dart` for route-level screens, `_repository.dart` for data access, `_data.dart` for state objects, `_extension.dart` for Dart extensions
- Generated files follow the `freezed`/`json_serializable` convention: `model.freezed.dart`, `model.g.dart`
- Dialog widgets live in `lib/view/component/dialog/`
- `PascalCase` for all classes (enforced by `camel_case_types` lint rule)
- Widgets use a descriptive noun + role suffix: `CourtComponent`, `ClickablePlayerComponent`, `DraggablePlayerComponent`
- Private widget helpers within a file are prefixed with `_`: `_PlayerComponent`, `_CourtSameSide`, `_AppLoaderState`
- State classes: `ChangeNotifier` subclasses — `GameData`, `TimerData`, `PersistentSetting`
- Singletons use `._init()` or `._()` private constructors plus a `static final instance` field
- Abstract interfaces: plain `abstract class` with `InMemory` prefix — `InMemoryRepository<V>`
- Data Transfer Objects: `Dto` suffix — `GameDto`, `PlayerDto`, `GameDatabase`
- `camelCase` for all local variables, fields, and parameters (enforced by `non_constant_identifier_names`)
- `SCREAMING_SNAKE_CASE` for top-level `const` values (e.g., `maxIteration`, `playerPerCourt` are `const int`, spacing constants are `const double spacePageX`)
- Spacing constants are defined as plain `const double` with a `space` prefix: `space8`, `space16`, `spaceCard`, `spaceDefault`
- `typedef` aliases are `PascalCase`: `GameContainer`, `PlayerContainer`
- `PascalCase` for enum names, `camelCase` for values: `Elo { c2, c1, b2, b1, a2, a1, s2, s1 }`, `ButtonType { filled, outlined, text }`, `Setting { background, gameType, gameDuration, language, autoMakegame }`
## Code Style
- `dart format` is the enforced formatter; the CI step runs `dart format --output=none --set-exit-if-changed .` and fails the build on any diff
- No `.prettierrc` or custom formatter config; Dart's default 80-character line width applies
- Base: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`
- Additional rules enabled:
- Analyzer override: `invalid_annotation_target: ignore` (silences `freezed` annotation noise)
- CI: `flutter analyze --fatal-infos --no-pub` — infos are treated as errors
- `const` constructors are used pervasively on all widgets and constants: `const AppLoader({super.key})`, `const Button(...)`, `const EdgeInsets.symmetric(...)`
- `const` on `static` fields: `static const int playerPerCourt = 4;`
## Widget Patterns
- Default choice for widgets with no mutable state
- Always pass `super.key` in the constructor: `const MyWidget({super.key})`
- Common pattern:
- Used when lifecycle methods (`initState`, `dispose`) or `setState` are needed
- Example: `GameMakerPage` uses `TickerProviderStateMixin` for `AnimationController`, calls `controller.dispose()` in `dispose()`
- Example: `AddPlayerDialog` uses state fields (`firstName`, `lastName`, `elo`) mutated by form validators before `setState`
- State class is always private: `_GameMakerPageState`, `_AddPlayerDialogState`
- Private base widget classes are extended within the same file to share `build` logic; the base class is prefixed `_`:
- `ChangeNotifier` + `provider` package
- Providers are injected at the root in `AppLoader.build` via `MultiProvider`
- Reading with side effects: `Provider.of<GameData>(context, listen: false)` or `context.read<GameData>()`
- Reactive reading: `context.select((GameData data) => data.someField)` or `Provider.of<GameData>(context)` (with rebuild)
- Singletons (`PersistentSetting.instance`) are accessed directly when a `ChangeNotifierProvider.value` is not needed
- Repositories use the singleton pattern with a private constructor and `static final instance`:
- Initialization is deferred to an `async initialize()` method called at app startup in `AppLoader`
- Data models use `@freezed` / `@Freezed(...)` with `freezed_annotation`
- Factory constructors: `Player(...)` for the main constructor, `Player.create(...)` for a named factory with auto-generated `id` and `createdDate`, `Player.fromJson(...)` for deserialization
- `part` files are declared at the top: `part 'player.freezed.dart'; part 'player.g.dart';`
- `go_router` with a top-level `final router = GoRouter(...)` in `lib/routes.dart`
- Navigation: `context.go('/route')` for replacing the stack, `Navigator.of(context).pop()` for popping dialogs
- Named path strings are plain `String` literals (no constants)
- Methods are added directly to enum: `String toDisplayName() => name.toUpperCase();`
- Context-dependent display uses `BuildContext`: `String toDisplayString(BuildContext context) => switch (this) { ... };`
## Error Handling
- Business logic throws `Exception(message)` with an uppercase, descriptive message string:
- No custom exception classes; all errors are plain `Exception`
- Caught at the widget layer using `try/catch` in event handlers; errors are shown via `context.showErrorToast(e.toString())`
- `context.mounted` is checked before async calls update the UI:
- `FutureBuilder` errors in `AppLoader` are logged with `debugPrint(snapshot.error!.toString())`
- `assert(...)` is used in performance-critical paths (game generation) to catch logic bugs in debug mode, not for user-facing validation
- Form fields use the `validator:` callback pattern with `GlobalKey<FormState>` and `_formKey.currentState!.validate()`
## Imports & Organization
- Each file is imported directly by its full `package:` path; no `lib/index.dart` or export-only files exist
- Used exclusively for code generation (`freezed`, `json_serializable`): `part 'player.freezed.dart'; part 'player.g.dart';`
- Conflicts resolved with `hide`: `import 'dart:math' hide log;` (avoids collision with `dart:developer`'s `log`)
## Comments & Documentation
- `///` triple-slash style used for public and notable private members; example from `lib/state/game_data.dart`:
- `//` single-line comments explain non-obvious intent:
- No `@param`, `@returns`, or `@throws` tags; documentation is plain prose
- Generated files (`*.freezed.dart`, `*.g.dart`) contain auto-generated headers and should not be manually edited
- Only present in generated localization files: `// ignore: unused_import`
- Production code has no `// ignore` suppressions
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern
- No BLoC, no Riverpod — pure `provider` package (`ChangeNotifier` + `MultiProvider`)
- Singletons used for repositories and services (all via `ClassName._()` private constructor + `static final instance`)
- In-memory caching in repositories backed by local JSON files on disk
- Code generation via `freezed` + `json_serializable` for immutable models and DTOs
- Navigation managed declaratively via `go_router`
## Layer Structure
- Purpose: Pure data classes. Immutable value objects using `freezed`.
- Contains: `Player`, `Game` — domain entities with factory constructors and business helpers (`eloGap()`, `isPlayable()`)
- Depends on: `freezed_annotation`, `uuid`, `collection`
- Used by: state, repository, view layers
- Purpose: Persistence layer. Reads/writes JSON files to the device's application documents directory.
- Contains: `InMemoryRepository<V>` interface; `PlayerRepository`, `GameRepository` (singleton implementations); DTO classes (`PlayerDto`, `GameDto`, `PlayerDatabase`, `GameDatabase`); `RepositoryService` (resolves root storage path); `Serializer` (file picker helper)
- Pattern: Each repository holds a `Map<String, V> _cache` that is the single source of truth at runtime. All mutations write through to a JSON file immediately.
- Depends on: `path_provider`, `dart:io`, `freezed_annotation`, `json_serializable`
- Used by: state layer, directly by some view widgets (e.g., `SignInPage` calls `PlayerRepository.instance.add()`)
- Purpose: Application state and business logic. Acts as the ViewModel layer.
- Contains:
- Depends on: model, repository layers
- Used by: view layer via `Provider.of<T>` / `context.select<T>`
- Purpose: UI layer. All Flutter widgets and pages.
- Pages: `LandingPage`, `SignInPage`, `GameMakerPage`, `PlayerStatisticPage`
- Components (`lib/view/component/`): Reusable widgets — `Button`, `Court`, `GameEditor`, `InactivePlayer`, `ListRenderer`, `Overlay`, `PlayerComponent`, `Timer`, `SettingPage`, `ShadedContainer`; dialogs (`AddPlayer`, `EditPlayer`, `Toasts`)
- Depends on: state layer, model, core utilities
- Used by: router
- Purpose: Pure utilities and extensions. No Flutter-framework dependencies except `BuildContext` extension.
- Contains:
- `main.dart` — App bootstrap: initialises repositories sequentially, wraps app in `MultiProvider`
- `routes.dart` — `GoRouter` configuration with named routes
- `global.dart` — App-wide constants (`appName`, `navigatorKey`, `version`, `goldenRatio`)
- `theme.dart` — `lightTheme` / `darkTheme` definitions, `AppColors`, shared border/shape constants
- `spacing.dart` — Spacing constants (`space8`, `space16`, `spacePageX`, etc.)
## State Management
```dart
```
- `context.select<T, R>((T t) => t.field)` — granular rebuild, preferred in pages
- `Provider.of<T>(context)` — full widget rebuild on any change, used in components
- `Provider.of<T>(context, listen: false)` — one-time read without subscribing
- `PersistentSetting.instance` accessed directly (as singleton) in some places, bypassing the provider tree
- `GameData` is the session object; it is NOT persisted across app restarts. History is reloaded from `GameRepository` on the `PlayerStatisticPage` when needed.
- `PersistentSetting` wraps `SharedPreferences`; it is persisted and survives restarts.
- `TimerData` is in-memory only; saves elapsed time so the timer can resume across page transitions within a session.
## Data Flow
```
```
## Key Design Decisions
## Module Boundaries
| Directory | Role |
|---|---|
| `lib/model/` | Domain entities |
| `lib/repository/` | Data persistence (JSON files, SharedPreferences) |
| `lib/state/` | App state / business logic (ChangeNotifier) |
| `lib/view/` | Screens and UI components |
| `lib/core/` | Pure utilities and Dart extensions |
| `lib/l10n/` | Internationalisation (ARB files + generated `.dart`) |
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
