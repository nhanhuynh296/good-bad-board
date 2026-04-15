# Directory Structure

**Analysis Date:** 2026-04-16

## Root Layout

```
good-bad-board/
├── lib/                    # All Dart source code
├── test/                   # Unit and widget tests
├── asset/                  # Static assets (fonts, images)
├── android/                # Android platform project
├── ios/                    # iOS platform project
├── macos/                  # macOS platform project
├── linux/                  # Linux platform project
├── windows/                # Windows platform project
├── web/                    # Web platform project
├── .planning/              # GSD planning documents
├── .github/workflows/      # CI/CD pipeline definitions
├── pubspec.yaml            # Package manifest and dependency declarations
├── pubspec.lock            # Locked dependency versions
├── analysis_options.yaml   # Dart linter configuration
├── l10n.yaml               # Flutter localisation generation config
├── sonar-project.properties # SonarQube analysis config
└── justfile                # Task runner commands
```

## Source Tree

```
lib/
├── main.dart               # App entry point, provider setup, async initialisation
├── routes.dart             # GoRouter configuration (all named routes)
├── global.dart             # App-wide constants (appName, navigatorKey, version, goldenRatio)
├── theme.dart              # lightTheme / darkTheme, AppColors, shared shape/border constants
├── spacing.dart            # Spacing constants (space8, space16, spacePageX, etc.)
│
├── model/                  # Domain entities (freezed, immutable)
│   ├── game.dart           # Game entity (players list, id, createdDate, eloGap, isPlayable)
│   ├── game.freezed.dart   # Generated
│   ├── game.g.dart         # Generated
│   ├── player.dart         # Player entity (firstName, lastName, Elo enum, id)
│   ├── player.freezed.dart # Generated
│   └── player.g.dart       # Generated
│
├── repository/             # Persistence layer — JSON file storage
│   ├── repository_interface.dart   # InMemoryRepository<V> abstract interface
│   ├── repository_service.dart     # Resolves application documents directory path
│   ├── player_repository.dart      # PlayerRepository singleton + PlayerDto, PlayerDatabase
│   ├── player_repository.freezed.dart
│   ├── player_repository.g.dart
│   ├── game_repository.dart        # GameRepository singleton + GameDto, GameDatabase
│   ├── game_repository.freezed.dart
│   ├── game_repository.g.dart
│   └── serializer.dart             # File picker helper for JSON import
│
├── state/                  # App state and business logic (ChangeNotifier)
│   ├── game_data.dart      # GameData — active session: players, staging matches, history, game gen
│   ├── persistent_setting.dart  # PersistentSetting singleton — SharedPreferences wrapper
│   └── timer_data.dart     # TimerData — countdown timer elapsed tracking
│
├── core/                   # Pure utilities and Dart extensions
│   ├── build_context_extension.dart  # ThemeX extension (theme, textTheme, colorScheme)
│   ├── duration_extension.dart       # Duration helpers
│   ├── iterable_extension.dart       # Collection helpers (shuffled, choices, mostPopular)
│   ├── random.dart                   # Shared Random instance
│   ├── importer.dart                 # CSV file import (FilePicker + CsvToListConverter)
│   └── organizer.dart                # Empty file (unused/reserved)
│
├── view/                   # UI layer — pages and reusable components
│   ├── landing_page.dart           # Home screen (grid of navigation options + drawer)
│   ├── sign_in_page.dart           # Player registration / session check-in screen
│   ├── game_maker_page.dart        # Core game session screen (courts, timer, history)
│   ├── player_statistic_page.dart  # Stats dashboard (game history, highlights)
│   └── component/                  # Shared reusable widgets
│       ├── button.dart             # Unified Button widget (filled/outlined/text types)
│       ├── container.dart          # ShadedContainer (card-style container)
│       ├── court.dart              # Court display widget
│       ├── game_editor.dart        # Court editing UI (add/remove/swap players)
│       ├── inactive_player.dart    # Off-court player roster component
│       ├── list_renderer.dart      # Generic scrollable list builder
│       ├── overlay.dart            # Overlay/floating UI helpers
│       ├── player.dart             # ClickablePlayerComponent, player card widget
│       ├── reusable.dart           # Miscellaneous shared widgets (HighlightWidget, etc.)
│       ├── setting.dart            # SettingPage widget (in-app settings screen)
│       ├── timer.dart              # CountdownTimer widget (AnimationController-based)
│       └── dialog/                 # Modal dialogs
│           ├── add_player.dart     # Add new player dialog (form)
│           ├── edit_player.dart    # Edit existing player dialog
│           └── toasts.dart         # Toast/snackbar helpers (showToast, showErrorToast)
│
└── l10n/                   # Internationalisation
    ├── app_en.arb          # English strings (source of truth)
    ├── app_fr.arb          # French strings
    ├── app_zh.arb          # Simplified Chinese strings
    ├── app_zh_HK.arb       # Traditional Chinese (Hong Kong) strings
    ├── app_localizations.dart        # Generated localisation base class
    ├── app_localizations_en.dart     # Generated English implementation
    ├── app_localizations_fr.dart     # Generated French implementation
    └── app_localizations_zh.dart     # Generated Chinese implementation
```

## Feature Organisation

The app has no feature-module grouping. Screens are flat in `lib/view/` and components are shared globally in `lib/view/component/`. The four screens map to four routes:

| Screen File | Route | Purpose |
|---|---|---|
| `lib/view/landing_page.dart` | `/` | Navigation hub |
| `lib/view/sign_in_page.dart` | `/register` | Player check-in for a session |
| `lib/view/game_maker_page.dart` | `/game` | Court assignment and game management |
| `lib/view/player_statistic_page.dart` | `/stats` | Historical stats viewer |

To add a new screen:
1. Create `lib/view/your_page.dart`
2. Add a `GoRoute` entry in `lib/routes.dart`
3. Add navigation call (`context.go('/your-route')`) where needed

## Shared/Common Code

**Utilities (`lib/core/`):**
- Extension methods go here. No business logic.
- `iterable_extension.dart` is the most widely used — import for `shuffled()`, `choices()`, `mostPopular()`, `toUnmodifiableList()`
- `build_context_extension.dart` — import for `context.textTheme`, `context.colorScheme`, `context.theme`
- `importer.dart` — CSV import logic (used in `sign_in_page.dart`)

**Constants:**
- `lib/spacing.dart` — all layout spacing values
- `lib/global.dart` — app name, navigator key, version, golden ratio
- `lib/theme.dart` — `AppColors`, border/shape constants, `lightTheme`, `darkTheme`

**Shared widgets (`lib/view/component/`):**
- `button.dart` — use `Button(type: ButtonType.filled/outlined/text, ...)` instead of raw Flutter buttons
- `container.dart` — use `ShadedContainer` for card-style surfaces
- `dialog/toasts.dart` — use `context.showToast(msg)` / `context.showErrorToast(msg)` extension methods

## Assets & Resources

```
asset/
├── font/
│   └── NotoSans-VariableFont_wdth,wght.ttf   # Variable font (registered as family "Gotham")
└── image/
    └── badminton.webp                          # Default court background image
```

**Fonts:** Declared in `pubspec.yaml` under `flutter.fonts`. Family name is `Gotham` — used as `fontFamily` in both `lightTheme` and `darkTheme`.

**Images:** All images in `asset/image/` are bundled via `pubspec.yaml` (`assets: - asset/image/`). Add new images to this directory; they will be auto-included.

**Localisation (l10n):**
- ARB source files live in `lib/l10n/`
- Config: `l10n.yaml` at project root
- Generated Dart files (`app_localizations*.dart`) are in `lib/l10n/` — committed to repo (in `.gitignore` exception)
- To add a string: edit `lib/l10n/app_en.arb`, add translations to other ARB files, run `flutter gen-l10n`
- Access in widgets: `AppLocalizations.of(context)!.your_key`
- Supported locales: `en`, `fr`, `zh`, `zh_HK`

**Generated code:**
- `*.freezed.dart` and `*.g.dart` files alongside model/repository sources — regenerate with `dart run build_runner build`
- Do not edit generated files manually

---

*Structure analysis: 2026-04-16*
