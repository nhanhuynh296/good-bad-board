# Tech Stack

**Analysis Date:** 2026-04-16

## Language & Runtime

**Primary:**
- Dart ^3.8.1 - All application code under `lib/`
- Kotlin - Android platform layer under `android/app/src/main/kotlin/`

**Runtime:**
- Flutter (stable channel) - cross-platform UI framework targeting Windows desktop (primary artifact), Android, and iOS

## Frameworks & Core Libraries

- `flutter` (sdk) - UI framework
- `flutter_localizations` (sdk) - i18n/l10n support (en, fr, zh locales)
- `go_router` ^16.0.0 - Declarative routing (`lib/routes.dart`)
- `provider` ^6.1.2 - State management via `ChangeNotifier` + `MultiProvider` (`lib/main.dart`)
- `freezed_annotation` ^3.0.0 - Immutable data class code generation for models and repositories
- `json_annotation` ^4.9.0 - JSON serialization annotations for models

## Build & Package Management

**Package Manager:** `pub` (via `flutter pub`)
- Lockfile: `pubspec.lock` present
- Install: `flutter pub get`
- Code generation: `dart run build_runner build --delete-conflicting-outputs`
  - Generates `.freezed.dart` and `.g.dart` files for models and repositories
  - Must be run before building or testing (enforced in CI)

**Build Commands:**
```bash
flutter pub get                                                    # Install dependencies
dart run build_runner build --delete-conflicting-outputs          # Generate code
flutter build windows --dart-define=VERSION=<ver>                 # Build Windows artifact
flutter analyze --fatal-infos --no-pub                            # Static analysis
dart format --output=none --set-exit-if-changed .                 # Format check
flutter test                                                       # Run tests
```

**Linting:**
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

**Environment:**
- `--dart-define=VERSION=<ver>` passed at build time for Windows artifact versioning (set by CI tag action)
- `.env` file present at root — contents not read; likely local dev config only (not used in build pipeline)

**Assets:**
- `asset/image/` — Court background images (including `badminton.webp` as default)
- `asset/font/NotoSans-VariableFont_wdth,wght.ttf` — Registered as `Gotham` font family

**Generated Files (do not edit manually):**
- `lib/model/game.freezed.dart`, `lib/model/game.g.dart`
- `lib/model/player.freezed.dart`, `lib/model/player.g.dart`
- `lib/repository/game_repository.freezed.dart`, `lib/repository/game_repository.g.dart`
- `lib/repository/player_repository.freezed.dart`, `lib/repository/player_repository.g.dart`
- `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`, `lib/l10n/app_localizations_zh.dart`

## Platform Requirements

**Development:**
- Flutter SDK (stable channel)
- Dart SDK ^3.8.1
- Code generation must run before building: `dart run build_runner build --delete-conflicting-outputs`

**Production:**
- Primary deployment target: Windows desktop (`.zip` artifact published to GitHub Releases)
- Secondary targets: Android, iOS (configured but not in active CI artifact pipeline)

---

*Stack analysis: 2026-04-16*
