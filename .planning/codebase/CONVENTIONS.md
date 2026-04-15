# Code Conventions

**Analysis Date:** 2026-04-16

## Naming Conventions

**Files:**
- `snake_case.dart` for all Dart source files (enforced by `file_names` lint rule)
- Suffixes encode role: `_page.dart` for route-level screens, `_repository.dart` for data access, `_data.dart` for state objects, `_extension.dart` for Dart extensions
- Generated files follow the `freezed`/`json_serializable` convention: `model.freezed.dart`, `model.g.dart`
- Dialog widgets live in `lib/view/component/dialog/`

**Classes:**
- `PascalCase` for all classes (enforced by `camel_case_types` lint rule)
- Widgets use a descriptive noun + role suffix: `CourtComponent`, `ClickablePlayerComponent`, `DraggablePlayerComponent`
- Private widget helpers within a file are prefixed with `_`: `_PlayerComponent`, `_CourtSameSide`, `_AppLoaderState`
- State classes: `ChangeNotifier` subclasses — `GameData`, `TimerData`, `PersistentSetting`
- Singletons use `._init()` or `._()` private constructors plus a `static final instance` field
- Abstract interfaces: plain `abstract class` with `InMemory` prefix — `InMemoryRepository<V>`
- Data Transfer Objects: `Dto` suffix — `GameDto`, `PlayerDto`, `GameDatabase`

**Variables and Parameters:**
- `camelCase` for all local variables, fields, and parameters (enforced by `non_constant_identifier_names`)
- `SCREAMING_SNAKE_CASE` for top-level `const` values (e.g., `maxIteration`, `playerPerCourt` are `const int`, spacing constants are `const double spacePageX`)
- Spacing constants are defined as plain `const double` with a `space` prefix: `space8`, `space16`, `spaceCard`, `spaceDefault`
- `typedef` aliases are `PascalCase`: `GameContainer`, `PlayerContainer`

**Enums:**
- `PascalCase` for enum names, `camelCase` for values: `Elo { c2, c1, b2, b1, a2, a1, s2, s1 }`, `ButtonType { filled, outlined, text }`, `Setting { background, gameType, gameDuration, language, autoMakegame }`

## Code Style

**Formatter:**
- `dart format` is the enforced formatter; the CI step runs `dart format --output=none --set-exit-if-changed .` and fails the build on any diff
- No `.prettierrc` or custom formatter config; Dart's default 80-character line width applies

**Lint Configuration:**
- Base: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`
- Additional rules enabled:
  - `prefer_const_constructors` — use `const` wherever possible
  - `prefer_const_declarations` — prefer `const` for declarations
  - `avoid_relative_lib_imports` — always use `package:` URIs
  - `curly_braces_in_flow_control_structures` — always brace `if`/`for`/`while`
  - `prefer_is_empty` / `prefer_is_not_empty` — use `.isEmpty` / `.isNotEmpty` not `.length == 0`
  - `avoid_empty_else`, `empty_catches`, `unnecessary_overrides`, `valid_regexps`
- Analyzer override: `invalid_annotation_target: ignore` (silences `freezed` annotation noise)
- CI: `flutter analyze --fatal-infos --no-pub` — infos are treated as errors

**`const` usage:**
- `const` constructors are used pervasively on all widgets and constants: `const AppLoader({super.key})`, `const Button(...)`, `const EdgeInsets.symmetric(...)`
- `const` on `static` fields: `static const int playerPerCourt = 4;`

## Widget Patterns

**StatelessWidget:**
- Default choice for widgets with no mutable state
- Always pass `super.key` in the constructor: `const MyWidget({super.key})`
- Common pattern:
  ```dart
  class LandingPage extends StatelessWidget {
    const LandingPage({super.key});

    @override
    Widget build(BuildContext context) { ... }
  }
  ```

**StatefulWidget:**
- Used when lifecycle methods (`initState`, `dispose`) or `setState` are needed
- Example: `GameMakerPage` uses `TickerProviderStateMixin` for `AnimationController`, calls `controller.dispose()` in `dispose()`
- Example: `AddPlayerDialog` uses state fields (`firstName`, `lastName`, `elo`) mutated by form validators before `setState`
- State class is always private: `_GameMakerPageState`, `_AddPlayerDialogState`

**Widget Inheritance:**
- Private base widget classes are extended within the same file to share `build` logic; the base class is prefixed `_`:
  ```dart
  class _PlayerComponent extends StatelessWidget { ... }
  class ClickablePlayerComponent extends _PlayerComponent { ... }
  class DraggablePlayerComponent extends _PlayerComponent { ... }
  ```

**State Management (Provider):**
- `ChangeNotifier` + `provider` package
- Providers are injected at the root in `AppLoader.build` via `MultiProvider`
- Reading with side effects: `Provider.of<GameData>(context, listen: false)` or `context.read<GameData>()`
- Reactive reading: `context.select((GameData data) => data.someField)` or `Provider.of<GameData>(context)` (with rebuild)
- Singletons (`PersistentSetting.instance`) are accessed directly when a `ChangeNotifierProvider.value` is not needed

**Singleton Repositories:**
- Repositories use the singleton pattern with a private constructor and `static final instance`:
  ```dart
  class GameRepository extends InMemoryRepository<Game> {
    GameRepository._();
    static final GameRepository instance = GameRepository._();
  }
  ```
- Initialization is deferred to an `async initialize()` method called at app startup in `AppLoader`

**Freezed Models:**
- Data models use `@freezed` / `@Freezed(...)` with `freezed_annotation`
- Factory constructors: `Player(...)` for the main constructor, `Player.create(...)` for a named factory with auto-generated `id` and `createdDate`, `Player.fromJson(...)` for deserialization
- `part` files are declared at the top: `part 'player.freezed.dart'; part 'player.g.dart';`

**Routing:**
- `go_router` with a top-level `final router = GoRouter(...)` in `lib/routes.dart`
- Navigation: `context.go('/route')` for replacing the stack, `Navigator.of(context).pop()` for popping dialogs
- Named path strings are plain `String` literals (no constants)

**Enums with behavior:**
- Methods are added directly to enum: `String toDisplayName() => name.toUpperCase();`
- Context-dependent display uses `BuildContext`: `String toDisplayString(BuildContext context) => switch (this) { ... };`

## Error Handling

**Exceptions:**
- Business logic throws `Exception(message)` with an uppercase, descriptive message string:
  ```dart
  throw Exception('Not enough players, need at least ${Game.playerPerCourt}, got ${_players.length}');
  throw Exception("CAN NOT SWAP BETWEEN INACTIVE PLAYERS");
  ```
- No custom exception classes; all errors are plain `Exception`

**UI error display:**
- Caught at the widget layer using `try/catch` in event handlers; errors are shown via `context.showErrorToast(e.toString())`
- `context.mounted` is checked before async calls update the UI:
  ```dart
  try {
    await context.read<GameData>().makeGame();
    if (!context.mounted) return;
    ...
  } catch (e) {
    if (context.mounted) context.showErrorToast(e.toString());
  }
  ```
- `FutureBuilder` errors in `AppLoader` are logged with `debugPrint(snapshot.error!.toString())`

**Assertions:**
- `assert(...)` is used in performance-critical paths (game generation) to catch logic bugs in debug mode, not for user-facing validation

**Form validation:**
- Form fields use the `validator:` callback pattern with `GlobalKey<FormState>` and `_formKey.currentState!.validate()`

## Imports & Organization

**Import ordering (enforced by `dart format`):**
1. `dart:` core libraries
2. `package:flutter/` and other `package:` dependencies
3. `package:good_bad_board/` internal package imports (always absolute, never relative — enforced by `avoid_relative_lib_imports`)

**Example from `lib/state/game_data.dart`:**
```dart
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/model/player.dart';
...
```

**No barrel files:**
- Each file is imported directly by its full `package:` path; no `lib/index.dart` or export-only files exist

**`part` files:**
- Used exclusively for code generation (`freezed`, `json_serializable`): `part 'player.freezed.dart'; part 'player.g.dart';`

**Hiding symbols:**
- Conflicts resolved with `hide`: `import 'dart:math' hide log;` (avoids collision with `dart:developer`'s `log`)

## Comments & Documentation

**Doc comments:**
- `///` triple-slash style used for public and notable private members; example from `lib/state/game_data.dart`:
  ```dart
  /// When a player came after the late and paid a fractional price.
  /// Use a average count of all player, multiply by total game to represent the
  /// number of "matches" that the player had played.
  ```

**Inline comments:**
- `//` single-line comments explain non-obvious intent:
  ```dart
  // Has to be toList(growable: true) as we need to add/remove player
  // Depends on PlayerRepository to initialize first
  ```

**No JSDoc-style annotations:**
- No `@param`, `@returns`, or `@throws` tags; documentation is plain prose

**Generated file headers:**
- Generated files (`*.freezed.dart`, `*.g.dart`) contain auto-generated headers and should not be manually edited

**`ignore` directives:**
- Only present in generated localization files: `// ignore: unused_import`
- Production code has no `// ignore` suppressions

---

*Convention analysis: 2026-04-16*
