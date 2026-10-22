# IMPLEMENTATION.md — Riverside BC UX Redesign: Multi-Stage Plan

> **Purpose:** Persistent, self-contained implementation plan that can be handed to subagents.
> Each stage includes: goal, inputs (what must exist before starting), file manifest (what to create/modify), detailed tasks, acceptance criteria, and a completion checklist.
>
> **Source design:** `UX-Redesign/ARCHITECTURE.md` — read it for the full token catalog and component specs.
>
> **Current codebase:** Flutter desktop (Windows), Provider + ChangeNotifier, go_router, freezed models. See repo `CLAUDE.md` for full architecture context.

---

## Gap Analysis: Current → Target

### What stays (domain logic to preserve)

| Module | File | What to keep |
|--------|------|-------------|
| GameData | `lib/state/game_data.dart` | `makeGame()`, `_improveEloSpread()`, `swapPlayer()`, `Picker.choices` weighted random — the matchmaking algorithm is sound |
| PlayerRepository | `lib/repository/player_repository.dart` | JSON file persistence, `getAllCachedPlayers()` |
| GameRepository | `lib/repository/game_repository.dart` | Game persistence |
| PersistentSetting | `lib/state/persistent_setting.dart` | SharedPreferences wrapper |
| TimerData | `lib/state/timer_data.dart` | Countdown timer logic |
| Models | `lib/model/player.dart`, `lib/model/game.dart` | freezed Player + Game classes (may add fields, keep existing) |
| Localization | `lib/l10n/` | ARB files + generated delegates |
| Core utils | `lib/core/random.dart` | `Picker` / weighted selection |

### What gets replaced/rewritten

| Current | Why | Replaced by |
|---------|-----|-------------|
| `lib/theme.dart` — `AppColors`, `lightTheme`, `darkTheme` | Blue/gold palette (#060D87 / #F4B142) doesn't match Clubhouse warm palette (#221d18 / #ff6a2b) | `lib/design/app_colors.dart`, `lib/design/app_theme.dart` |
| `lib/spacing.dart` — 4-value scale, no responsive padding | Not enough tokens, no breakpoint awareness | `lib/design/app_spacing.dart` |
| `lib/view/landing_page.dart` — card grid landing page | ARCHITECTURE.md calls for tab-based shell, not card grid | `lib/shell/responsive_shell.dart` |
| `lib/view/game_maker_page.dart` — court grid with drag-drop | Functional but visually wrong; needs new widgets + waitlist concept | `lib/features/dashboard/dashboard_page.dart` |
| `lib/view/sign_in_page.dart` — player sign-in | Needs restyle to match PlayerRow + pending approval spec | `lib/features/players/players_page.dart` |
| `lib/view/player_statistic_page.dart` | Needs restyle + new chart widgets | `lib/features/analytics/analytics_page.dart` |
| `lib/view/component/*` — existing widgets | Visual mismatch with new design tokens | `lib/design/widgets/*` + feature widgets |
| `lib/routes.dart` — flat 4-route GoRouter | No tab-based routing, no responsive shell | Updated with ResponsiveShell |

### Key architectural changes

1. **Navigation**: flat route list → responsive 5-tab shell (TopNavBar / BottomTabBar / HamburgerMenu depending on breakpoint). *Desktop superseded by Stage 8: Courts, Players, Sessions + ⋯ menu, and a session bar.*
2. **File organization**: flat `lib/view/` → `lib/features/<feature>/` with barrel exports + `lib/design/` for shared tokens + `lib/shell/` for navigation
3. **Visual language**: blue/gold with Gotham → warm neutral (#fffdfa / #221d18 / #ff6a2b) with Space Grotesk display + Inter body. *Superseded by Stage 8: Source Sans 3 only.*
4. **New concepts**: waitlist (separate from inactive players), session templates, self-registration with approval, analytics dashboard with charts
5. **Drag-drop**: existing DragTarget system in GameMakerPage → replaced with click-to-select-then-click-to-place interaction (simpler, works better on tablet/phone)

---

## Stage Overview

| # | Stage | Depends On | Produces |
|---|-------|-----------|----------|
| 0 | Design Token Foundation | Nothing | `lib/design/` directory with colors, typography, spacing, radii |
| 1 | Core Primitives (Card, StatCell, Button) | Stage 0 | Reusable widget library in `lib/design/widgets/` |
| 2 | App Shell & Navigation | Stage 0 | Responsive nav (TopNavBar, BottomTabBar, CompactHeader, HamburgerMenu) |
| 3 | Dashboard — Court Grid & Waitlist | Stages 1, 2 | CourtCard, PlayerSlot, WaitlistItem, WaitlistChip, re-roll + swap |
| 4 | Player Management | Stages 1, 2 | PlayerTable, ExpandableProfile, LevelAdjuster, SearchInput |
| 5 | Check-in, Sessions, Settings | Stages 1, 2 | Remaining tabs (check-in flow, round config, templates, settings). Schedule and notification toggles removed 2026-10-10 |
| 6 | Analytics Dashboard | Stages 1, 2 | Analytics page with KPI strip, bar charts, progress bars, tables |
| 7 | Self-Registration & Polish | All prior | Self-registration page, responsive polish, theme integration |
| 8 | 2026-10-17 design build | Stages 0–7, Nathan review of the docs (R1-Q3) | Round lifecycle, Courts tab, shell + session bar, Players scan check-in, Source Sans 3 tokens (desktop) |

---

## Release Build Flags (batch 9b5ab49..692c492)

Five flags keep code in the tree but hide it in the release UI. All five default to `false`. Tests set them on to cover the hidden code.

| Flag | File | Effect when `false` |
|------|------|---------------------|
| `GameMode.enabled` | `lib/state/persistent_setting.dart` | `getGameType()` returns time-based. The stored `gameType` preference is never rewritten. The Sessions mode toggle is hidden. A template mode is ignored. GB-01…07 are hidden |
| `PlayersPage.showImportButton` | `lib/features/players/players_page.dart` | CSV Import button hidden |
| ~~`SettingsPage.showSignupPreview`~~ | removed | The flag went with the "Membership & self-registration" card (Nathan 2026-10-22, R13-Q2). The `/register` route stays. REG-* is not reachable from the UI |
| `AnalyticsPage.showHiddenCards` | `lib/features/analytics/analytics_page.dart` | ANA-06 (per-court comparison) and ANA-12 (player mixing) hidden |
| `CourtCount.editable` | `lib/state/game_data.dart` | **On** (Nathan 2026-10-22, R13-Q1): the Sessions court count control shows, minimum 1, no upper limit (R13-Q12), and a template Load applies its court count. The Courts tab has no stepper with the flag on too (R2-Q2). Off: 4 courts, Load keeps them (R45-36) |

Stage 8 (2026-10-17 design) adds no flag. `GameMode.enabled` stays `false`. `CourtCount.editable` is `true` from 2026-10-22 (R13-Q1, 8.11).

Other release changes: `Game.tierGap()` (4-tier gap, display only; logs keep `eloGap`); `GameData.defaultCourtCount` (4, not persisted); `NewPlayerEntry.needsAttention`; nullable retention in the KPI strip; `AppLoader` error screen (`app_load_error`). Release tests: `test/features/release_time_mode_test.dart`, `test/game_data_release_fixes_test.dart`, `test/features/dashboard_release_fixes_test.dart`, `test/features/dashboard_four_courts_fit_test.dart`, `test/timer_data_test.dart`, `test/app_loader_error_test.dart`, `test/features/players_scanner_test.dart`, `test/features/players_add_dialog_test.dart`, `test/features/release_court_count_test.dart`.

---

## Stage 0 — Design Token Foundation

### Goal
Create `lib/design/` as the single source of truth for all visual tokens. Every subsequent stage imports from here. No hardcoded colors, sizes, or text styles anywhere else.

### Inputs
- `ARCHITECTURE.md` Section 1 (Design Tokens)
- Existing `lib/spacing.dart` (to be absorbed and replaced)

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/design/app_colors.dart` | All color tokens as static const `Color` |
| Create | `lib/design/app_typography.dart` | All text styles as static `TextStyle` |
| Create | `lib/design/app_spacing.dart` | Spacing scale + content padding breakpoints |
| Create | `lib/design/app_radii.dart` | Border radius scale |
| Create | `lib/design/app_breakpoints.dart` | Width thresholds (720, 1080) + helpers |
| Create | `lib/design/app_theme.dart` | `ThemeData` factory that wires tokens into Material theme |
| Create | `lib/design/design.dart` | Barrel export file |
| Modify | `lib/main.dart` | Replace inline `ThemeData` with `AppTheme.light()` |
| Modify | `lib/theme.dart` | Replace `AppColors` with new palette; update `lightTheme`/`darkTheme` to use `AppTheme.light()`/`AppTheme.dark()`; keep existing Material 3 component themes that don't conflict |
| Delete | `lib/spacing.dart` | Absorbed into `app_spacing.dart`; update all imports (currently used in: `landing_page.dart`, `game_maker_page.dart`, `sign_in_page.dart`, `reusable.dart`) |
| Modify | `lib/view/component/reusable.dart` | Update `pageSpacing` to use `AppSpacing` instead of deleted `spacing.dart` |

### Detailed Tasks

#### 0.1 — `app_colors.dart`
```dart
// Static const Color for every token in ARCHITECTURE.md Section 1.1.
// Grouped into nested classes or flat namespace — match existing codebase pattern.
// Must include:
//   - pageBg, cardBg, cardBorder
//   - headerBg, headerText, headerSub
//   - accentPrimary, accentOnPrimary
//   - textPrimary, textMuted, textSubtle
//   - pillBg, success, successBg, warningText, warningBg
//   - barSecondary, barTertiary
//   - All chart-neutral colors (#e8dcc8, #d9c7a8, #f0e6d6)
```

#### 0.2 — `app_typography.dart` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// Static const TextStyle for every entry in the type scale (Section 1.2).
// Use the existing Google Fonts setup (NotoSans aliased as "Gotham") as the body font.
// Add Space Grotesk as the display font via google_fonts or asset.
// Each style includes: fontSize, fontWeight, color (from AppColors), letterSpacing where specified.
// Named tokens: statLabel, statValue, cardTitle, playerName, etc.
```

#### 0.3 — `app_spacing.dart`
```dart
// Static const double for spacing scale (1, 4, 6, 8, 10, 12, 16, 20, 24, 32).
// EdgeInsets constants for content padding at each breakpoint (desktop, tablet, phone).
// EdgeInsets constants for card padding, button padding, etc.
```

#### 0.4 — `app_radii.dart`
```dart
// Static const double / BorderRadius for each radius token.
// sm=6, md=8, lg=10, xl=12, 2xl=14, full=999.
```

#### 0.5 — `app_breakpoints.dart`
```dart
// Const ints: phoneMax=719, tabletMax=1079, desktopMin=1080.
// Helper: bool isPhone(double width), isTablet(double width), isDesktop(double width).
```

#### 0.6 — `app_theme.dart`
```dart
// class AppTheme { static ThemeData light() { ... } }
// Wires AppColors into ColorScheme, AppTypography into textTheme.
// Sets card theme, input decoration theme, button themes, etc.
// Uses the existing outlined border style pattern from main.dart.
```

#### 0.7 — Update `main.dart`
```dart
// Replace the ThemeData constructor with: theme: AppTheme.light()
// Remove the Localizations.localeOf(context) workaround if present for theme.
```

#### 0.8 — Absorb `lib/spacing.dart`
```dart
// Move any spacing constants still referenced into AppSpacing.
// Update all imports across the project to use 'package:.../design/design.dart'.
// Delete lib/spacing.dart.
```

### Migration Notes

- **Color palette:** The existing `AppColors` class in `lib/theme.dart` uses blue/gold (`stAndrewsBlue` #060D87, `goldRush` #F4B142). The new `AppColors` in `lib/design/app_colors.dart` uses the Clubhouse warm palette (`accentPrimary` #FF6A2B, `headerBg` #221D18, `pageBg` #FFFDFA). Existing widget code referencing `AppColors.stAndrewsBlue` will need to be migrated to use the new token names. **Do this migration in Stage 0** — every widget touching `AppColors` gets updated here so subsequent stages start from a clean slate.
- **Font:** The current font is `Gotham` (aliased from NotoSans in `asset/font/`). The target uses `Space Grotesk` for display and `Inter` for body. Add these via `google_fonts` (already a dependency per `CLAUDE.md`). Keep the existing NotoSans as a fallback.
- **Material 3:** The current `ThemeData` uses `useMaterial3: true`. Preserve this. The new `AppTheme.light()` should still be Material 3.
- **Existing component themes:** The current `lib/theme.dart` defines detailed `cardTheme`, `inputDecorationTheme`, `buttonTheme`, `chipTheme`, etc. These can serve as a baseline. Map their colors to new tokens rather than rewriting from scratch.
- **`lib/view/component/reusable.dart`** defines `pageSpacing` (an `EdgeInsets` using `spacePageX` and `spacePageY`). Update it to import from `lib/design/` instead of `lib/spacing.dart`. Same for all other files importing `spacing.dart`.
- **Imports:** Search for `import 'package:good_bad_board/spacing.dart'` and `import 'package:good_bad_board/theme.dart'` across the project — every site needs updating.

### Acceptance Criteria

> **UAT mapping:** No direct UAT scenarios — Stage 0 is foundational plumbing. All subsequent stages depend on these tokens being correct.

- [x] `lib/design/design.dart` exports all 6 token files
- [x] Zero hardcoded colors remain in `lib/main.dart` ThemeData
- [x] All text styles reference `AppTypography` tokens
- [x] `flutter analyze --no-pub` passes with zero errors
- [x] Existing tests pass (`flutter test`)
- [x] `lib/spacing.dart` is deleted and all imports updated
- [x] `lib/theme.dart` `AppColors` is replaced with new palette tokens
- [x] `Space Grotesk` and `OpenSans` fonts load and render correctly (bundled as assets; `Inter` replaced with available `OpenSans` bundled font)

---

## Stage 1 — Core Primitives (Card, StatCell, Button)

### Goal
Build the reusable widget primitives that every page/tab will compose from. These are pure presentational widgets — no business logic, no state management.

### Inputs
- Stage 0 complete (`lib/design/` exists, `AppTheme.light()` wired)

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/design/widgets/app_card.dart` | `AppCard` widget |
| Create | `lib/design/widgets/app_stat_cell.dart` | `AppStatCell` widget |
| Create | `lib/design/widgets/app_kpi_card.dart` | `AppKpiCard` widget |
| Create | `lib/design/widgets/app_section_title.dart` | `AppSectionTitle` widget |
| Create | `lib/design/widgets/app_button.dart` | `AppButton` with variants |
| Create | `lib/design/widgets/app_chip.dart` | `AppChip` (pill) widget |
| Create | `lib/design/widgets/app_progress_bar.dart` | `AppProgressBar` widget |
| Create | `lib/design/widgets/app_search_input.dart` | `AppSearchInput` widget |
| Create | `lib/design/widgets/app_toggle_button.dart` | `AppToggleButton` widget |
| Create | `lib/design/widgets/widgets.dart` | Barrel export |
| Create | `test/design/widgets_test.dart` | Golden/unit tests for primitives |

### Detailed Tasks

#### 1.1 — `AppCard`
```dart
// A Container wrapper with:
//   - bg: AppColors.cardBg
//   - border: 1px solid AppColors.cardBorder
//   - borderRadius: AppRadii.xl (12px)
//   - padding: AppSpacing.cardPadding
// Accepts: child, padding override, borderRadius override, onTap (wraps in InkWell)
```

#### 1.2 — `AppStatCell`
```dart
// A label + value pair used in StatStrip.
//   - label: 10px, 700, uppercase, AppColors.textMuted, letterSpacing 0.05em
//   - value: 19px, 800, AppColors.textPrimary (or accent)
// Accepts: label, value, isAccent (bool — colors value with accent)
```

#### 1.3 — `AppKpiCard`
```dart
// Larger stat card for analytics dashboards.
//   - label: 10.5px, 800, uppercase, AppColors.textMuted
//   - value: 26px, Space Grotesk 700, AppColors.textPrimary
//   - delta: 11px, 700, green or red
// Accepts: label, value, delta, deltaPositive
```

#### 1.4 — `AppSectionTitle`
```dart
// Section heading within a card or page.
//   - Font: Space Grotesk, 700
//   - Two size variants: 15px (default) and 14px (tight)
// Accepts: title, tight (bool)
```

#### 1.5 — `AppButton`
```dart
// Six variants from ARCHITECTURE.md Section 2.6 via factory constructors or enum.
//   AppButton.primary(label, onPressed)
//   AppButton.secondary(label, onPressed)
//   AppButton.success(label, onPressed)
//   AppButton.dangerOutline(label, onPressed)
//   AppButton.icon(icon, onPressed)
// Each maps to the exact bg, color, radius, padding, font from the token table.
```

#### 1.6 — `AppChip`
```dart
// Pill-shaped container for spread indicator, waitlist chips, status badges.
//   - bg: AppColors.pillBg (or accent when selected)
//   - radius: AppRadii.full (999px)
//   - padding: 4px 8px or 7px 11px
// Accepts: label, isSelected, onTap
```

#### 1.7 — `AppProgressBar`
```dart
// Horizontal bar with fill.
//   - Track: AppColors.pillBg, height 8–12px, radius 6–8px
//   - Fill: AppColors.accentPrimary, width as fraction
// Accepts: fraction (0.0–1.0), height, showLabel
```

#### 1.8 — `AppSearchInput`
```dart
// Styled TextField matching the search input spec.
//   - full-width, padding 10–14px
//   - border: 1px solid #e2d8c8, radius 8px
//   - font: 14px
// Accepts: controller or onChanged callback, placeholder
```

#### 1.9 — `AppToggleButton`
```dart
// On/Off toggle for settings.
//   - On: AppColors.success bg, white text
//   - Off: #e5e5e5 bg, #555 text
//   - radius: 6px, font: 11px, padding: 5px 12px
// Accepts: value (bool), onChanged, label (text beside toggle)
```

### Acceptance Criteria

> **UAT mapping:** No direct UAT scenarios — Stage 1 is foundational widget library. All subsequent feature stages consume these primitives.

- [x] All 9 widgets render correctly in a test page / widget test
- [x] `AppButton` variants match the spec table exactly (ARCHITECTURE.md §2.6)
- [x] Widgets are pure — no business logic or state management dependencies
- [x] `flutter analyze --no-pub` passes
- [x] Widget tests pass

---

## Stage 2 — App Shell & Navigation

### Goal
Build the responsive navigation shell. The app detects breakpoint and renders the correct nav pattern. All 5 tabs are wired (Check-in was merged into the Players tab per UAT spec; Schedule was removed 2026-10-10).

### Inputs
- Stage 0 (design tokens)
- Existing `lib/routes.dart` (go_router config)

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/design/widgets/app_tab_button.dart` | Tab pill button (active/inactive) |
| Create | `lib/shell/top_nav_bar.dart` | Desktop/tablet header with tabs |
| Create | `lib/shell/compact_header.dart` | Phone header bar |
| Create | `lib/shell/bottom_tab_bar.dart` | Phone 4-tab bottom nav |
| Create | `lib/shell/hamburger_menu.dart` | Phone hamburger overlay |
| Create | `lib/shell/more_bottom_sheet.dart` | Phone "More" slide-up sheet |
| Create | `lib/shell/responsive_shell.dart` | Breakpoint-aware shell that picks nav |
| Create | `lib/shell/shell.dart` | Barrel export |
| Modify | `lib/routes.dart` | Replace ShellRoute with ResponsiveShell |
| Modify | `lib/main.dart` | Update routing setup |

### Detailed Tasks

#### 2.1 — `AppTabButton` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// A single tab pill.
// Active: bg=accent, color=onAccent, radius=8px, padding=8px 12px, 12px
// Inactive: bg=transparent, color=AppColors.headerSub, radius=8px, padding=8px 12px, 12px
// Accepts: label, isActive, onTap
```

#### 2.2 — `TopNavBar`
```dart
// Desktop layout (≥1080px): horizontal bar with tab row (no club name).
// Tablet layout (720–1079px): scrollable tab row.
// Props: subtitle, tabs (list of {label, isActive, onTap}), selectedIndex
// Dark bg (#221d18).
```

#### 2.3 — `CompactHeader`
```dart
// Phone header: dark bar with current tab label.
// Optional hamburger button (38×38, radius 8px) at trailing edge.
// Props: currentTabLabel, showHamburger, onHamburgerTap
```

#### 2.4 — `BottomTabBar`
```dart
// 3 fixed tabs: Courts (▦), Players (☰), More (•••).
// (Check-in was merged into Players tab)
// Active: accent color. Inactive: #8a7c68.
// Icon emoji + label (10px, 700) in a column.
// Props: selectedIndex, onTabSelected, onMoreTap
```

#### 2.5 — `HamburgerMenu`
```dart
// Fullscreen dark overlay.
// Backdrop: rgba(20,16,12, 0.5), fade animation.
// Content: #221d18 bg, "NAVIGATE" label, vertical list of all 5 tabs.
// Active tab: accent bg, #221d18 text. Inactive: transparent, white.
// Props: tabs, selectedIndex, isOpen, onClose, onTabSelected
```

#### 2.6 — `MoreBottomSheet`
```dart
// Slide-up sheet from bottom.
// Drag handle: 38×4px, #e2d8c8.
// Lists secondary tabs: Sessions, Analytics, Settings.
// Each row: label + chevron "›". Active: accent color.
// Backdrop: rgba(20,16,12, 0.45).
// Props: secondaryTabs, selectedIndex, isOpen, onClose, onTabSelected
```

#### 2.7 — `ResponsiveShell`
```dart
// Uses LayoutBuilder to read available width.
// <720px: CompactHeader + page content + BottomTabBar (or hamburger)
// 720–1079px: TopNavBar (tablet variant) + page content
// ≥1080px: TopNavBar (desktop variant) + page content
//
// Manages internal state for: selected tab index, hamburger open, more sheet open.
// Delegates to current tab's page widget via IndexedStack or child.
// Props: subtitle, tabLabels, pages (list of Widgets)
```

#### 2.8 — Route & Main Integration
```dart
// routes.dart: Replace current GoRouter with one that delegates to ResponsiveShell.
//   5 routes (/dashboard, /players, /sessions, /analytics, /settings); /schedule redirects to /sessions
//   Check-in is integrated into the Players tab, not a separate route.
//   All wrapped in a shared ResponsiveShell via ShellRoute or custom builder.
// main.dart: Ensure ChangeNotifierProviders are above the shell.
//   Each page gets context.read<GameData>() etc. as needed.
// Initially: each page renders a placeholder with the tab name.
```

### Acceptance Criteria

> **UAT mapping:** NAV-01, NAV-02, NAV-03, NAV-04, NAV-05, START-01

- [x] **NAV-01** — *(desktop superseded by Stage 8.6.1)* Desktop/tablet (≥720px): top header bar with session subtext and all 5 tabs visible (no club name); compact header and bottom bar not shown
- [x] **NAV-02** — Phone (<720px): compact dark header with current tab label (no club name); 5-tab top row hidden
- [x] **NAV-03** — Phone bottom tab bar (always shown on phone): 3 destinations — Courts (Dashboard), Players (with integrated check-in), More. Selecting More opens bottom sheet with Sessions/Analytics/Settings; tapping scrim closes sheet without switching
- [x] **NAV-04** — "More" tab highlighted when current tab is Sessions, Analytics, or Settings (secondary tabs)
- [x] **NAV-05** — Phone hamburger nav (no `phoneNav` setting; shown with the bottom tab bar): ☰ button in compact header, right-hand dark panel listing all 5 tabs, current tab highlighted, scrim closes without switching
- [x] **START-01** — Start-up load error: when a data file fails to load, `AppLoader` (`lib/main.dart`) shows a plain error screen that names the data folder (l10n `app_load_error`). Nothing is written to disk. Test: `test/app_loader_error_test.dart`
- [x] `flutter analyze --no-pub` passes
- [x] Existing functionality (state management, routing) is not broken

---

## Stage 3 — Dashboard (Court Grid & Waitlist)

### Goal
Implement the core Dashboard tab with the court grid, waitlist, stat strip, and all interactions (place/swap, re-roll, auto-promote).

### Inputs
- Stages 0, 1 (design tokens, primitives)
- Stage 2 (navigation shell — Dashboard tab is wired)
- Existing `lib/state/game_data.dart` (GameData logic — preserve `makeGame()`, `_improveEloSpread()`, `swapPlayer()`, `Picker.choices`; add waitlist methods if needed)

### Migration Notes
- The existing `GameMakerPage` uses **drag-and-drop** (`DraggablePlayerComponent` → `DragTarget<Player>` in `CourtComponent`). The new UX replaces this with **click-to-select-then-click-to-place** (tap waitlist player to select, tap court slot to place). This is simpler and works better on tablet/phone. The drag-and-drop widgets (`lib/view/component/court.dart`, `lib/view/component/player.dart`) can be removed after this stage.
- `GameData.swapPlayer()` currently handles drag-drop swap logic. Extend it (or add a new method) for the click-based placement flow: `selectWaitlistPlayer(id)`, `placePlayer(courtId, slotIndex)`.
- The waitlist is a **new concept**. Currently, `GameMakerPage` has "inactive players" (a list of all players not on a court). The waitlist is specifically checked-in players who aren't assigned to a court. Add a `waitlistedPlayers` getter to `GameData`.
- The re-roll button in the design triggers a per-court re-optimization (`reroll(courtId)`). `GameData` currently has `_improveEloSpread()` which operates globally. Add a per-court variant or parameterize the existing method.

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/features/dashboard/court_card.dart` | CourtCard widget |
| Create | `lib/features/dashboard/player_slot.dart` | PlayerSlot widget |
| Create | `lib/features/dashboard/waitlist_sidebar.dart` | Desktop waitlist sidebar |
| Create | `lib/features/dashboard/waitlist_chips.dart` | Tablet/phone waitlist chips |
| Create | `lib/features/dashboard/spread_pill.dart` | Level gap pill |
| Create | `lib/features/dashboard/round_rotation_bar.dart` | Round rotation bar with countdown timer |
| Create | `lib/features/dashboard/stat_strip.dart` | Responsive stat strip |
| Create | `lib/features/dashboard/dashboard_page.dart` | Full dashboard page |
| Create | `lib/features/dashboard/dashboard.dart` | Barrel export |
| Modify | `lib/routes.dart` | Wire DashboardPage to /dashboard route |

### Detailed Tasks

#### 3.1 — `PlayerSlot` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// A row within a CourtCard representing one of 4 positions.
// Two states:
//   - Occupied: player name (14px, 600) + level tier (13px, 800, accent); no Elo on court
//   - Empty: "Open slot" (13px, italic, #b3a891)
// Row has border-top: 1px solid #f0e6d6.
// When a waitlist selection is active, all slots get accent-tinted bg + cursor style.
// Props: player (Player?), isSelectable, onTap
```

#### 3.2 — `SpreadPill`
```dart
// Chip showing level gap for a court.
// bg: AppColors.pillBg, text: AppColors.textMuted
// Content: e.g., "Same level" or "1 level gap"
// radius: 999px, padding: 4px 8px, font: 11px 700
// Props: levelGap (int)
```

#### 3.3 — `CourtCard`
```dart
// Card header: "COURT N" (Space Grotesk 15px 700) + SpreadPill + Re-roll button.
// 4 PlayerSlot rows.
// Uses AppCard as base.
// Props: courtNumber, players (list of 4 Player?), spreadLevel, onReroll, onSlotTap(int slotIndex), isSelectionActive
```

#### 3.4 — `WaitlistSidebar` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// Desktop: fixed 270px sidebar card.
// Title: "Waitlist" (Space Grotesk 15px 700).
// List of WaitlistItem widgets.
// Empty state: "No one waiting" (13px, italic, #b3a891).
// Hint text at bottom: explains tap-to-place flow.
// Props: waitlistedPlayers, selectedPlayerId, onPlayerSelect, swapHint
```

#### 3.5 — `WaitlistChips`
```dart
// Tablet/phone: horizontal wrapping row of chips.
// Each chip: position + name + level.
// Selected: accent bg, white text. Unselected: pillBg, textPrimary.
// Props: same as WaitlistSidebar
```

#### 3.6 — `StatStrip` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// Responsive grid of AppStatCell widgets.
// Desktop: 6 cols, Tablet: 3 cols, Phone: 2×2.
// Cells: Checked In, Remaining Slots, Waitlist, Avg Level, Avg Level Gap, Re-rolls.
// Waitlist cell uses accent color for value.
// Props: GameData-derived stats
```

#### 3.7 — `DashboardPage`
```dart
// Composes RoundRotationBar + StatStrip + court grid + waitlist.
// Reads from context.read<GameData>() / context.watch<GameData>().
// Implements the interaction flows (Section 4 of ARCHITECTURE.md):
//   - selectWaitlistPlayer(id) → sets selected state
//   - placeOrSwap(courtId, slotIndex) → calls GameData.swapPlayer
//   - reroll(courtId) → calls GameData reroll logic
//   - swapHint text updates based on selection state
// Desktop layout: RoundRotationBar → StatStrip → [Court Grid (fit to height, courtGridLayout) + WaitlistSidebar]
// Non-desktop layout: one page scroll view: RoundRotationBar → StatStrip → WaitlistChips → Court Grid (stacked)
```

#### 3.8 — `RoundRotationBar` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// A dark bar widget positioned between StatStrip and the court grid.
// Displays round progress with a live countdown timer and rotation controls.
//
// Left section:
//   - Round number: Space Grotesk 20px, 700, white — "ROUND N"
//   - Mode label: 12px, color=headerSub — e.g. "Game-based · auto-rotates…"
//
// Right section:
//   - Countdown timer: 26px, 800, tabular-nums
//     · Normal (>60s): white
//     · Urgent (≤60s): barTertiary (#ffb38a)
//   - "until rotation" label: 11px, 600, headerSub
//   - Action buttons (12px, 700):
//     · "Pre-make next round": ghost (rgba white 0.12 bg, white text, white
//       border) — shown only when !isStaged; once staged, the next-round
//       panel owns its own controls
//     · "Rotate now →": accent-filled primary
//       — always visible
//
// Progress bar:
//   - Track: rgba(255,255,255,0.14), height=10px, radius=999px
//   - Fill: accent (normal) or barTertiary (urgent)
//   - animated width via AnimatedContainer or TweenAnimationBuilder
//
// Pending next-round section (when isStaged):
//   - Divider line at top (1px solid rgba(255,255,255,0.12))
//   - Badge: "NEXT ROUND · READY"
//     · 10px, 800, letter-spacing=0.06em
//     · bg=barTertiary (#ffb38a), color=headerBg (#221d18), radius=999px
//   - "Cancel next" ghost button, right-aligned on the badge row
//   - Summary text: 12px, headerSub — e.g. "16 players placed across 4 courts"
//   - Dashed progress bar: 8px height, repeating gradient on barTertiary
//
// Round selector (RND-10) — the two sections are radio buttons:
//   - Each is wrapped in _SelectablePanel: Semantics(selected:, button:) +
//     InkWell, keyed RoundRotationBar.currentPanelKey / .nextPanelKey
//   - Header strip (only rendered once a choice exists, i.e. isStaged):
//     radio dot + panel name ("CURRENT ROUND" / "NEXT ROUND"), 10px, 800
//   - Selected: 2px accent border (accentPrimary for current, #ffb38a for
//     next), full opacity. Unselected: transparent border, 0.55 opacity
//   - The selected panel is the round the court grid renders and edits
//
// Props:
//   - roundNumber (int)
//   - modeLabel (String)
//   - remainingLabel (String) — formatted MM:SS
//   - pct (double) — remaining percentage (0.0–100.0)
//   - isUrgent (bool) — true when ≤60s remain
//   - isStaged (bool)
//   - stagedSummary (String)
//   - stagedPct (double) — elapsed percentage for dashed bar
//   - selectedView (RoundView) — which panel is selected
//   - onSelectView (ValueChanged<RoundView>)
//   - onRotateNow, onStageNext, onCancelStaged (VoidCallback)
//
// State considerations:
//   - roundNumber, isStaged, selectedView → from GameData
//   - remaining time, isUrgent → from TimerData (existing, preserved)
//   - stageNextRound() → pre-computes the next round without applying it, and
//     selects RoundView.next so the courts show the plan
//   - setRoundView(view) → switches which lineup the grid renders and edits
//   - cancelStagedRound() → clears the plan, returns to RoundView.current
//   - rotateNow() → logs the finished round, then adopts the plan
```

### Acceptance Criteria

> **UAT mapping:** NAV-06, NAV-07, RND-01…11, GB-01…07 (hidden in release), COURT-01…13, WL-01, WL-02

#### Navigation & layout (shared with Stage 2 shell)
- [x] **NAV-06** — *(desktop part superseded by Stage 8.5.1: no stat strip on desktop)* Stat strip reflow: desktop (≥1080px) 6 cols (Checked In, Remaining Slots, Waitlist, Avg Level, Avg Level Gap, Re-rolls); tablet (720–1079px) 3-per-row wrap; phone (<720px) 4 stats in 2×2 grid (Checked In, Waitlist, Avg Level, Remaining). Breakpoint from the viewport width (`MediaQuery.sizeOf`), not the content width. Phone 4th cell reads "Remaining" (`dashboard_stat_remaining`). "Avg Level" and "Avg Level Gap" use `Game.tierGap()`; Avg Level shows a tier name, not an Elo code
- [x] **NAV-07** — Dashboard layout reflow: desktop (≥1080px, incl. iPad landscape 1194px) court grid + fixed-width waitlist sidebar; tablet/phone (<1080px) waitlist chips above courts, courts stacked (2 cols tablet, 1 col phone). Desktop: `courtGridLayout` (`lib/features/dashboard/court_grid_layout.dart`, ported from main's `getIdealNumberOfColumn`) picks the column count with the largest court that fits the free height and stretches rows to fill it; `courtGridLayout(minCourtHeight:)` (the desktop passes `_minDesktopCourtHeight` = 136px) lets a court be flatter than 1.6:1 down to that height, but never under 320px wide or taller than wide, so 4 courts fit at 1280x720, 1366x768, 1440x900 and 1920x1080 (`test/features/dashboard_four_courts_fit_test.dart`). `CourtCard` and `PlayerSlot` use compact padding when the card is under 200px tall (`compact`). When nothing fits it uses the most columns and the grid scrolls itself (more than 4 courts). Known limit: with a staged next round the rotation bar is taller, and the courts may scroll at 1280x720 and 1366x768. Stacked layouts keep `shrinkWrap` + `NeverScrollableScrollPhysics` inside the page `SingleChildScrollView`. Court slots are `Expanded`, so the card has no empty band below the last slot. Breakpoint from the viewport width; stacked grid caps columns with `courtGridLayout(maxColumnCount:)` (2 tablet, 1 phone). Tests: `test/features/dashboard_breakpoints_test.dart`. Stacked layout: the whole page scrolls (stat strip, bars, chips, courts)

#### Round rotation (RND-01…11) — time-based mode only

> **Superseded (2026-10-17 design).** The criteria below record the PR 45 round model (Pre-make, Rotate now, auto-rotation at 0:00, radio panels). UAT RND-01…11 are rewritten and RND-12…22 added; Stage 8 (8.2, 8.5) builds them.
- [x] **RND-01** — Live `mm:ss` countdown, progress bar fill = remaining/D as percentage, updates at least once per second. Only the bar rebuilds on a tick: `_buildRoundRotationBar` watches `TimerData` through a `Consumer`, the page never does (R45-03, `test/features/dashboard_timer_rebuild_test.dart`)
- [x] **RND-02** — Urgency styling when ≤60s: countdown text + progress bar switch to amber (#ffb38a)
- [x] **RND-03** — Auto-rotation at 0:00: recomputes level-balanced court assignment from all checked-in players, increments round number, restarts countdown at full duration — no organizer action required
- [x] **RND-04** — Global Save (`GameData.saveCurrentGame`) keeps one empty court per court, clears the staged next round (`_stagedLineup = null`), returns to `RoundView.current`, and throws `NothingToSave` when no court holds a player (a typed `LineupError`, R45-02; the Dashboard maps each `LineupError` to an ARB message and shows `dashboard_error_generic` for any other error, never the error text). "Rotate now" triggers immediate rotation: the finished round is logged via `GameData._logRound` (history + `SessionLog`, incomplete courts included so a clock expiry is never blocked), round increments, courts recomputed (or staged lineup adopted per RND-06), countdown restarts. A half-made lineup can neither block nor break it: `_improveEloSpread` swaps only between courts holding a full `Game.playerPerCourt` (it addresses all four slots by index, so a short court used to throw `RangeError`), and the dashboard's rotate handler catches `Error` as well as `Exception` and restarts the clock either way. `rotateNow` runs one at a time (a second press while one is in flight returns `false` and does nothing) and writes games and the `SessionLog` before it adds to history, so a failed write leaves the session unchanged and the restarted clock retries the same round without a duplicate row (R45-01) — an auto-rotation that died would strand the session on a finished round
- [x] **RND-05** — "Pre-make next round": computes staged lineup without changing live courts; a "NEXT ROUND · READY" panel appears with summary ("N players placed across M courts"), a striped progress bar (`StripedProgressBar`, CustomPainter) that fills up, and the "Cancel next" button; the next round becomes the selected view so the courts show the plan
- [x] **RND-06** — Staged round becomes live: when countdown hits 0:00 or "Rotate now" is tapped, the previously staged lineup — including the organizer's edits — is adopted (not recomputed), the staged panel disappears and the selector returns to the current round
- [x] **RND-07** — Cancel staged: panel disappears, selector returns to the current round, "Pre-make next round" returns, live round unaffected
- [x] **RND-08** — Only one staged round at a time: "Pre-make" hidden while staged round exists
- [x] **RND-09** — Mode label: Time-based → "Time-based · {mm:ss} rounds"; Game-based (hidden in release, `GameMode.enabled=false`) renders no round bar at all. Switching mode does not force rotation
- [x] **RND-10** — Round selector: the two panels are radio buttons; the selected one is what the court grid, waitlist sidebar and stat strip show. The next round is fully editable (`GameData.visibleMatches` routes `placePlayerInSlot` / `makeSingleCourt` / `removePlayerFromCourt` through `_onLineup`), and `visibleWaitlistedPlayers` follows the round on screen so no player is double-booked or dropped. Court cards carry a NEXT badge; global Generate/Save are hidden on the next view
- [x] **RND-11** — The staged lineup does not go stale: `checkOutPlayer` / `removePlayer` drop the player from it, `onUpdatePlayer` refreshes it, and `setNumberOfCourt` pads it

#### Game-based mode (GB-01…07) — hidden in release build (`GameMode.enabled=false`); covered by tests with the flag on

No clock. The committee drives each court: Regenerate → re-roll a court → Save → PLAYING →
re-roll when the game finishes → Save again.

- [x] **GB-01** — No countdown: `RoundRotationBar` is not built and `TimerData` is never started while the mode is game-based. Switching to game-based (or loading a game-based template) calls `TimerData.reset()`; `_onAutoRotate` returns early in game-based mode
- [x] **GB-02** — "Generate Game" is offered only while no court holds players (`GameData.hasAnyCourtLineup`); after the first lineup exists the button is hidden and courts are driven one at a time
- [x] **GB-03** — No global Save button in the action bar
- [x] **GB-04** — Per-court Save (`GameData.saveSingleGame`): writes the match to `GameRepository` and a `SessionLog` snapshot, leaves the four players on the court, and flags the court as playing
- [x] **GB-05** — PLAYING badge in the court header; Save hidden while playing; Re-roll stays available
- [x] **GB-06** — A playing lineup is locked: `placePlayerInSlot` is a no-op for a playing court and its slots are not tappable
- [x] **GB-07** — Re-roll ends the game: the court gets a new `Game` (so the playing flag clears by construction), drawn only from players not on any other court

#### Courts (COURT-01…13)

> **Partly superseded (2026-10-17 design).** COURT-11…13 are removed in UAT; COURT-01, COURT-02, COURT-04…10 change and COURT-14…16 are new (Stage 8.5.4).
- [x] **COURT-01** — Each court shows: number, level-gap badge (0="Same level", N>0="N level gap"; value is `Game.tierGap()`, the 4-tier gap, display only), up to 4 player rows (name + tier), "Open slot" italic for empty positions
- [x] **COURT-02** — Re-roll: evaluates multiple random 4-player combos from court occupants + full checked-in waitlist pool, selects lowest level gap, returns others to waitlist, increments re-roll count (the stat strip counts only re-rolls on the current round, not on the pre-made next round). `GameData.rerollSampleCount` (100) weighted-random draws; gap = SkillTier spread, Elo spread breaks ties. `GameData(random:)` is injectable for tests. Tests: `test/game_data_reroll_test.dart`
- [x] **COURT-03** — Re-roll no-op when a full court's occupants + waitlist = 4 (or any court when < 4); a court with an open slot still fills from exactly 4: nothing changes, no re-roll count increment. `GameData.canRerollCourt(i)`; the dashboard stays silent (no dialog, no SnackBar)
- [x] **COURT-04** — Selecting a waitlisted player: highlighted as "selected", hint reads "Placing {name} — tap a court slot", court slots become interactive. Sidebar and chips take `selectedPlayerName` (the selection can be a court player)
- [x] **COURT-05** — Switching selection: tapping waitlisted player B while A selected moves selection to B directly
- [x] **COURT-06** — Deselecting: tapping already-selected player clears selection, hint reverts to "Tap a waitlisted player, then a court slot to place or swap them in."
- [x] **COURT-07** — Placing selected player into empty "Open slot": seated, removed from waitlist, selection clears
- [x] **COURT-08** — Swapping into occupied slot: two players trade places (selected takes slot, previous occupant → waitlist), selection clears
- [x] **COURT-09** — Empty slots inert with no selection; tapping an occupied slot selects that player (changed 2026-10-12)
- [x] **COURT-10** — Swap between courts: select a court player, tap a slot on another idle court; `GameData.placePlayerInSlot` swaps the occupant into the source slot; a playing court cannot give or take a player. Tests: `test/game_data_court_swap_test.dart`, `test/features/dashboard_court_edit_test.dart`
- [x] **COURT-11** — Remove (×) on each player of an incomplete idle court → waitlist; `removePlayerFromCourt` ignores playing courts
- [x] **COURT-12** — Re-roll warning while the time-based clock runs (`dashboard_discard_court_*`)
- [x] **COURT-13** — Regenerate warning while the time-based clock runs (`dashboard_discard_round_*`), restored from main

#### Waitlist (WL-01…02)

> **Superseded (2026-10-17 design).** WL-01…03 now use the fill rule and the new panel; WL-04 is new (Stage 8.4, 8.5.5).
- [x] **WL-01** — Waitlist shows position number + name + level tier per entry; "No one waiting" when empty
- [x] **WL-03** — Promotion refills only the court that lost the player (`_removeAndRefillCourt` → `_autoPromoteFromWaitlist(court)`); a PLAYING court is never refilled. Tests: `test/game_data_waitlist_promotion_test.dart`
- [x] **WL-02** — Auto-promotion on check-out: when a court slot opens (player checks out or set Disabled), highest-level waitlisted player(s) fill open slot(s), highest tier first — no organizer action required *(triggered by Stage 5 Check-in; logic lives in GameData)*

#### Quality gates
- [x] Widget tests for CourtCard, PlayerSlot, StatStrip (20 tests)
- [x] `flutter analyze --no-pub` passes (0 errors, 0 warnings)

---

## Stage 4 — Player Management

### Goal
Implement the Players tab: searchable player list, expandable profile cards, level adjustment, status/membership/checkin toggles, and pending registration approvals.

### Inputs
- Stages 0, 1 (design tokens, primitives)
- Stage 2 (navigation shell)
- Existing `lib/state/game_data.dart`, `lib/repository/player_repository.dart`

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/features/players/player_row.dart` | Table row for a single player |
| Create | `lib/features/players/level_adjuster.dart` | +/- buttons with value display |
| Create | `lib/features/players/player_profile_card.dart` | Expandable profile with stats and the Sign In ID field (no sparkline) |
| Create | `lib/features/players/pending_registration.dart` | Pending approvals card |
| Create | `lib/features/players/players_page.dart` | Full players page |
| Create | `lib/features/players/players.dart` | Barrel export |
| Modify | `lib/routes.dart` | Wire PlayersPage |

### Detailed Tasks

#### 4.1 — `LevelAdjuster` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// Row: [−] button + level text (13px, 800, accent, 82px wide) + [+] button.
// Buttons: 20–22px square, bg=pillBg, text=textPrimary, radius=6px.
// Disabled at tier boundaries: Amateur (tier 0, minus disabled), Professional (tier 3, plus disabled).
// Disabled state: opacity 0.35.
// Props: currentLevel(String), canDecrease, canIncrease, onDecrease, onIncrease
```

#### 4.2 — `PlayerRow` — **Superseded (2026-10-17 design, Stage 8)**
```dart
// A single row in the players table.
// Columns: Name (14px, 600, underlined, tappable) | ID (12px, subtle) | Level (LevelAdjuster) | Membership (pill, cycles Member → Casual → Disabled) | Checked In (toggle)
// Name tap toggles profile expansion.
// Uses AppButton variants for toggles.
// Props: player (Player), isExpanded, onToggleProfile, onLevelUp, onLevelDown, canLevelUp, canLevelDown, onCycleMembership, onToggleCheckin
```

#### 4.3 — `PlayerProfileCard`
```dart
// Expandable card below a PlayerRow.
// Displays:
//   - Membership label + delete button + close button
//   - Stat trio: Current Level | Matches | Diversity (each in a small card with value + label)
//   - (Level progression sparkline removed in release: no level history is stored)
//   - Most frequent partners list (name + count)
//   - Attendance history text
// Uses AppCard as base.
// Props: player, profileStats, onDelete
```

#### 4.4 — `PendingRegistration`
```dart
// Card shown at top of Players page when there are pending registrations.
// Title: "Pending self-registrations (N)" (12px, 800).
// Each pending: name + est. level + contact + [Approve] [Reject] buttons.
// Approve: success bg. Reject: pillBg bg, textMuted text.
// Props: pendingRegistrations, onApprove, onReject
```

#### 4.5 — `PlayersPage`
```dart
// Full page: PendingRegistration (if any) + AppSearchInput + table header + list of PlayerRow widgets.
// Table header: "Name | ID | Level | Membership | Checked in" (11px, 700, uppercase, textSubtle).
// Filters from context.read<GameData>() based on search text.
// Manages which player profile is expanded (profileOpenId state).
// Props: none (reads from context)
```

### Acceptance Criteria

> **UAT mapping:** PLY-01…15, NAV-08 (partial)

#### Pending registrations (PLY-01…03)
- [x] **PLY-01** — Pending card at top when ≥1 self-registration awaiting approval: name, estimated level, contact info, Approve/Reject buttons; hidden entirely when zero pending
- [x] **PLY-02** — Approve: creates active player with name + estimated tier as starting level, membership defaulted to Casual, not checked in; removed from pending list; appears in searchable player list immediately
- [x] **PLY-03** — Reject: removes applicant from pending list; no player record created

#### Player list & search (PLY-04, NAV-08)
- [x] **PLY-04** — Search filters by name OR sign-in ID (case-insensitive substring match; level is not searched) in real time; clearing search box shows all players
- [x] **NAV-08** — Table header row (Name/Level/Status/etc.) visible ≥720px; hidden <720px (only data rows). Breakpoint from the viewport width; `PlayerRow` compact layout also uses the viewport width, so header and rows agree

#### Level, status, membership, check-in (PLY-05…08)
- [x] **PLY-05** — Level ±1 of the 8 `Elo` levels per click, clamped [C2…S1]; "−" disabled (visually dimmed) at C2, "+" disabled at S1
- [x] **PLY-06** — Membership cycles Member → Casual → Disabled → Member. Casual → Disabled while checked in requires confirmation (auto-checked-out, removed from court/waitlist, triggers WL-02 auto-promotion); not checked in needs no confirmation. Disabled → Member: no auto-check-in. Disabled players stay in the list with check-in disabled
- [x] **PLY-07** — Delete player (profile card): confirmation dialog, then removal from the roster (record anonymised, ADR-0001); triggers checkout and WL-02 auto-promotion (`removePlayer` calls `_autoPromoteFromWaitlist`) if currently checked in
- [x] **PLY-08** — *(row layout superseded by Stage 8.7.3)* The row tap is the check-in toggle (tap = in / out) and performs CHK-02/03/05 directly (no separate Check-in tab). Design in `lib/features/players/player_row.dart`: no In/Out pill and no "Checked in" column; a Disabled row tap is refused with the disabled message (CHK-06, R45-38); `GameData.checkInPlayer` returns a `CheckInResult` that names the reason; at capacity the tap is refused with the capacity message (CHK-03). The header has Name/ID, Level, Membership and a blank More column (`PlayerRow.moreColumnWidth` = 100)
- [x] **PLY-13** — Add player: `AddPlayerDialog` closes itself and returns the player through `showDialog<Player>`; the caller only reads the result and awaits the repository write. Callers must never pop it — `showDialog` uses the root navigator while a page's context resolves to its `StatefulShellRoute` branch navigator, so popping from the caller unmounts the tab and blanks the screen. Covered by `integration_test/players_add_player_test.dart`

#### Expandable profile (PLY-09…12)
- [x] **PLY-09** — The "More" button (`AppButton.secondary` with a chevron `trailingIcon`, `players_more`) opens the inline panel directly beneath the row; a row tap does not open it (it toggles check-in). More, level −/+ and membership taps never toggle check-in; a dimmed −/+ does nothing. Row + panel share one rounded `AppCard` (`player-accordion-panel`), the profile has no card chrome of its own; chevron down when hidden, up when shown (not modal/drawer): membership status, 3 stat tiles (Diversity % = distinct co-players ÷ other listed players) (Current Level, Matches, Diversity %), up to 3 most-frequent partners with match counts, session-attendance history summary (or "No sessions logged yet"). The level progression sparkline is removed
- [x] **PLY-10** — Only one profile expanded: tapping the More button of player B while A's profile open collapses A and expands B
- [x] **PLY-11** — Collapse: via "✕" in profile panel or tapping the same player's More button again
- [x] **PLY-12** — Profile stats computed from logged session history — unaffected by re-rolls or check-ins in the current live session until session is logged. `computePlayerProfileStats` (`lib/features/players/player_profile_stats.dart`) reads `GameRepository` + `SessionLogRepository` caches; `PlayersPage` listens to both. Not `GameData.history`

#### Scanner and sign-in ID (PLY-14, PLY-15)
- [x] **PLY-14** — *(result messages superseded by Stage 8.7.2: result box, not SnackBars; target rule superseded by 8.7.7: the exact ID match ignores the level chips, F01)* Barcode scan check-in: the search field is focused when the Players tab opens (and gives up focus when the tab is hidden). `_onSearchSubmitted` in `players_page.dart` runs on Enter (`AppSearchInput.onSubmitted`, which also covers the keyboard done action); no debounce (two fast scans both count); Enter during an IME composition is ignored (`Focus.onKeyEvent`). `_refocusSearch` gives the field focus again after row taps (`AppSearchInput.onTapOutside` replaces the desktop unfocus), profile toggles and dialogs, unless another `EditableText` has focus; a row tap clears a stale query. Target: the one listed player whose sign-in ID equals the text (trimmed, case-insensitive), else the only player in `_listedPlayers()` (search + level chips). The target is toggled: check in (capacity and Disabled rules apply, `players_scan_checked_in`) or check out (`players_scan_checked_out`). Disabled: `players_scan_disabled`. At capacity: the capacity message. Empty list: `players_scan_no_match`. Many listed and no exact ID: nobody changes, `players_scan_many_matches`. Two exact IDs: nobody changes, `players_scan_duplicate_id`. In all cases `_selectSearchText` keeps the text, selects all of it (again after the frame) and keeps focus, so the result stays listed and the next scan replaces the text. Empty field: nothing. Test: `test/features/players_scanner_test.dart`
- [x] **PLY-15** — Edit sign-in ID: the profile panel (`player_profile_card.dart`) has a Sign In ID field and Save; the value is trimmed, empty = no ID, an ID used by another listed player is refused with `players_sign_in_id_taken` (names that player), success shows `players_sign_in_id_saved`; no other field changes. Add player (`AddPlayerDialog`) trims name and ID, and refuses a blank name, a duplicate name and a duplicate ID. Test: `test/features/players_add_dialog_test.dart`

#### Quality gates
- [x] `flutter analyze --no-pub` passes

Note: the CSV Import button is hidden in release (`PlayersPage.showImportButton=false`, no UAT ID). New l10n keys: `players_more`, `players_scan_checked_in`, `players_scan_checked_out`, `players_scan_many_matches`, `players_scan_no_match`, `players_scan_disabled`, `players_sign_in_id_taken`, `players_sign_in_id_saved`.

---

## Stage 5 — Sessions, Settings

### Goal
Implement the remaining tabs (Sessions, Settings). The Schedule tab was removed 2026-10-10. Check-in (CHK-01…06) was merged into the Players tab per UAT spec — its capacity bar, check-in/out toggles, and at-capacity banner are integrated directly into `PlayersPage`.

### Inputs
- Stages 0, 1, 2

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/features/sessions/sessions_page.dart` | Session config + templates |
| Create | `lib/features/settings/settings_page.dart` | Round, language and membership settings |
| Create | `lib/features/sessions/sessions.dart` | Barrel |
| Create | `lib/features/settings/settings.dart` | Barrel |
| Modify | `lib/routes.dart` | Wire Sessions and Settings tabs |

### Detailed Tasks

> **Check-in (CHK-01…06)** is implemented directly in the Players tab (`PlayersPage`) — capacity bar, check-in/out toggles, at-capacity banner, and WL-02 auto-promotion trigger. See Stage 4 acceptance criteria for CHK case details. There is no separate Check-in tab.

#### 5.1 — `SessionsPage`
```dart
// Two-column layout (stacks on phone):
//   Left card: "Round mode"
//     - AppToggleButton group: Game-based / Time-based
//     - Description text (12px, textMuted)
//     - RangeSlider for duration (if time-based) — 10–45 min, step 5
//     - NumberInput for session capacity
//     - NumberInput for number of courts (1–8)
//   Right card: "Session templates"
//     - TextField + AppButton.primary("Save current")
//     - List of saved templates: name + summary + AppButton.secondary("Load")
// Props: reads/writes GameData settings
```

#### 5.2 — ~~`SchedulePage`~~ REMOVED 2026-10-10
```dart
// Section title: "Recurring sessions"
// Cards for each scheduled session:
//   - Day + time + note (14px, 700 + 12px, textMuted)
//   - Auto check-in badge (success bg, 11px)
// Footer: "Public calendar view and reminder scheduling live under Settings." (12px, textSubtle)
// Props: scheduleItems (from GameData or settings)
```

#### 5.3 — `SettingsPage`
```dart
// Two-column layout:
//   Left card: "Notifications"
//     - Session reminders toggle (AppToggleButton + label)
//     - Court assignment alerts toggle
//     - General announcements toggle
//   Right card: "Membership & self-registration"
//     - Member count + fees outstanding text
//     - Invite link (readonly TextField)
//     - "Preview signup page →" link
//     - Level calibration info text
// Props: reads/writes PersistentSetting
```

### Acceptance Criteria

> **UAT mapping:** SESS-01…06, SCHED-01, SET-01…04, NAV-08 (partial), RND-09 (partial), WL-02 (trigger)
>
> **CHK-01…06** (Check-in) are satisfied in the Players tab — see Stage 4 acceptance criteria. Check-in capacity bar, present/absent toggles, at-capacity banner, and WL-02 auto-promotion trigger are all integrated into `PlayersPage`.

#### Sessions (SESS-01…06), plus RND-09 integration
- [x] **SESS-01** — Round mode toggle: Game-based / Time-based buttons with highlight; description updates; duration control visible only for Time-based (RND-09). **Hidden in release build (`GameMode.enabled=false`):** the toggle and description are not shown, the duration field is always shown, and tests cover the toggle with the flag on
- [x] **SESS-02** — `mm:ss` duration control: two digit fields in one box, clicking either selects the whole segment, `Tab` moves minutes → seconds; minutes clamped 0–99, seconds 0–59; a total of 0:00 restores the previous value; Dashboard countdown recalculates at once via `TimerData.updateDuration`, triggering immediate rotation if the new duration < time already elapsed; a stopped timer takes the new duration as its remaining time (`_remaining = newDuration`); template Load applies the same rule (`test/timer_data_test.dart`)
- [x] **SESS-03** — Session capacity change: stat strip / Check-in bar reflect immediately; a value below the minimum is **clamped up to 4** (`GameData.minSessionCapacity`), never raised back to the default of 20, and the number field writes the clamped value back so it cannot display a rejected number; no currently checked-in player bumped even if new capacity < current count — limit applies to future check-ins only. Empty/non-numeric courts entry clamps to 1
- [x] **SESS-04** — Changed (Nathan 2026-10-22, R13-Q1, R13-Q9, R13-Q12; 8.11): `CourtCount.editable=true`, the Sessions control shows (no Courts tab stepper, R2-Q2). Minimum 1, no upper limit; default `GameData.defaultCourtCount` = 4, not persisted. A change never reshuffles and never asks: `GameData._applyCourtCount` drops the courts beyond the count (their players go to the waitlist) and pads empty courts, in the live round, a saved round n+1 and the edit lineup (and its base). Desktop "−" with players on a court opens "Remove which court?" (`showRemoveCourtDialog`, `GameData.removeCourt(index)`; the courts after it move up). Removed: the reshuffle confirm, `wouldReshuffleLineup`, `confirmDiscard`, the `sessions_reshuffle_confirm*` keys. Tests: `test/game_data_court_count_test.dart`, `test/features/sessions_desktop_test.dart`, `test/features/sessions_test.dart`, `test/features/release_court_count_test.dart`. A re-roll or a court-count change clears the selected player
- [x] **SESS-05** — Save template: captures duration (minutes **and** seconds), capacity, courts; blank/whitespace-only name is no-op; name field clears only when `saveTemplate` returns `true`; summary shown as "N courts · cap C" with no mode (`sessions_template_summary_no_mode`) on tablet and phone; desktop shows "10 min · cap 20" (8.10)
- [x] **SESS-06** — Load template: overwrites duration, capacity and courts (courts only when `CourtCount.editable`, now on); the template mode is ignored in release. Changed 2026-10-21 (F25, 8.10): duration and capacity apply at once with no dialog. Changed (Nathan 2026-10-22, R13-Q1): a new court count also applies at once with no dialog and no reshuffle; with fewer courts the courts at the end go

#### Schedule (SCHED-01)
- [x] ~~**SCHED-01**~~ **REMOVED 2026-10-10** — Schedule tab removed; session templates replace it. Was: read-only recurring session list: day, time window, descriptive note, "Auto check-in opens 30 min prior" badge per entry; no create/edit/delete controls in this build

#### Settings (SET-01…05)
- [x] ~~**SET-01**~~ **REMOVED 2026-10-10** (offline app, no notifications). Was: 3 independent notification toggles: Session reminders, Court assignment alerts, General announcements; each shows On/Off label
- [x] ~~**SET-02**~~ **REMOVED (Nathan 2026-10-22, R13-Q2)** — the "Membership & self-registration" card (`_MembershipCard`) is removed. Was: total members, computed live from the roster (it counted every listed player). The member count moves to Analytics (ANA-02, R13-Q10)
- [x] ~~**SET-03**~~ **REMOVED (Nathan 2026-10-22, R13-Q2)** — the signup preview link and `SettingsPage.showSignupPreview` went with the card; the `/register` route is kept
- [x] ~~**SET-04**~~ **REMOVED (Nathan 2026-10-22, R13-Q2, R13-Q11)** — the level calibration note went with the card. Keys removed: `settings_membership_title`, `settings_total_members`, `settings_preview_signup`, `settings_level_calibration_note`. Test: `test/features/settings_test.dart`
- [x] **SET-05** — Language picker (added 2026-10-10): chips with native language names; saves through `PersistentSetting.setLanguage`

#### Responsive & quality
- [x] **NAV-08** — All 4 pages respond to breakpoint changes (column layouts stack on phone); only the Players page has a header row, hidden <720px
- [x] `flutter analyze --no-pub` passes

---

## Stage 6 — Analytics Dashboard

### Goal
Implement the Analytics tab with charts, KPI strip, and data tables. This tab has the most complex data visualization needs.

### Inputs
- Stages 0, 1, 2
- Existing session log data (GameData / GameRepository)

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/model/session_log.dart` | Session-level analytics snapshot (Stage 6a) |
| Create | `lib/repository/session_log_repository.dart` | Persists `SessionLog`s to `session_logs.json` (Stage 6a) |
| Create | `lib/features/analytics/analytics_engine.dart` | Pure computation layer for ANA-01…14 |
| Create | `lib/features/analytics/analytics_page.dart` | Analytics tab page |
| Create | `lib/features/analytics/kpi_strip.dart` | 6-KPI row + time-range switcher |
| Create | `lib/features/analytics/bar_chart.dart` | Reusable bar chart + horizontal bar list |
| Create | `lib/features/analytics/attendance_chart.dart` | Attendance trend chart |
| Create | `lib/features/analytics/waitlist_pressure_chart.dart` | Waitlist pressure chart |
| Create | `lib/features/analytics/level_gap_trend.dart` | Level-gap trend (replaces originally planned `elo_spread_chart.dart` — no raw ELO) |
| Create | `lib/features/analytics/court_gap_comparison.dart` | Per-court fairness comparison |
| Create | `lib/features/analytics/court_utilization.dart` | Court utilization bars |
| Create | `lib/features/analytics/reroll_chart.dart` | Re-rolls per session |
| Create | `lib/features/analytics/level_distribution.dart` | Level distribution histogram |
| Create | `lib/features/analytics/at_risk_players.dart` | At-risk players list |
| Create | `lib/features/analytics/player_mixing.dart` | Player mixing / diversity bars |
| Create | `lib/features/analytics/new_player_integration.dart` | New player integration list |
| Create | `lib/features/analytics/analytics.dart` | Barrel |
| Modify | `lib/routes.dart` | Wire AnalyticsPage (replaces old `PlayerStatisticPage`) |

### Detailed Tasks

#### 6.1 — `BarChart` (reusable)
```dart
// A generic, reusable bar chart widget.
// Props:
//   - bars: List of {height (0.0–1.0 fraction), label (optional bottom text), valueLabel (optional top text), color, tooltip}
//   - barWidth: max-width per bar
//   - gap: spacing between bars
//   - height: total chart height
//   - borderRadius: bar end radius
// Bars are bottom-aligned; tallest bar fills the height.
// Uses CustomPaint or simple Row of Containers with fractional heights.
```

#### 6.2 — `KpiStrip`
```dart
// Responsive grid of AppKpiCard widgets.
// Desktop: 6 cols, Tablet: 3 cols, Phone: 2 cols.
// KPIs: Active players, Avg attendance, Retention, Court utilization, Avg waitlist, Re-rolls/session.
// Each with delta text (green positive, red negative, or neutral muted).
// Props: kpis map
```

#### 6.3 — `AnalyticsPage`
```dart
// Scrollable page with:
//   - Date range selector (segmented button: 4 wks | 12 wks | 26 wks)
//   - KpiStrip
//   - Row 1: Attendance trend chart + Waitlist pressure chart
//   - Row 2: ELO spread chart + Court fairness bars
//   - Row 3: Court utilization + Re-roll frequency chart
//   - Row 4: ELO distribution + At-risk players
//   - Row 5: Player mixing + New player integration
//
// Layout is a series of responsive grid rows (2:1, 1:1, or stacked on phone).
// Props: reads from GameData / repository for session logs
// Date range filter uses local state.
```

### Acceptance Criteria

> **UAT mapping:** ANA-01…14. No raw ELO is displayed — all metrics use the 4 named tiers and tier-gap only.

#### Time range & KPI (ANA-01…02)
- [x] **ANA-01** — Time-range switcher: 4 wks / 12 wks / 26 wks segmented control, defaults to 12 wks; selecting different range recomputes all charts/KPIs against that window with "vs. prior period" deltas. At-risk, Mixing and New-player cards also recompute on range change. Speed (2026-10-14): `_recompute` builds every card once per data, range or language change, never on a plain rebuild. A save while the tab is hidden only marks the results stale; they recompute when the tab opens (`TickerMode`). `gamesForRange` drops games older than the prior period and the retention look-back before the KPI and level cards read them. Test: `test/features/analytics_speed_test.dart`
- [x] **ANA-02** — KPI strip: 7 tiles (Nathan 2026-10-22, R13-Q10) — Members (`computeMembersKpi`: listed players with membership Member now; not range-based, line "Current count", no delta), Active players, Avg attendance %, Retention (4wk) %, Court utilization %, Avg waitlist (per session), Re-rolls per session — each with labeled value and delta/context line vs prior period. Active players = distinct players in games in the range. Retention = share of players seen in the 4 weeks before the last 4 who came back. Retention is nullable: the value and delta show "—" when there is no base. The delta line shows "—" when the prior period has no players or sessions

#### Attendance & waitlist (ANA-03…04)
- [x] **ANA-03** — Attendance trend: per-session bar chart of checkedIn ÷ capacity; most recent session visually emphasized; growth note (e.g. "+X%") summarizing month-over-month change. Month = last 28 days vs the 28 days before, read from all logs
- [x] **ANA-04** — Waitlist pressure: per-session bar chart of waitlisted counts; contextual note recommending capacity/schedule changes when avg waitlist ≥ ~2.5/session; with no sessions the card reads `analytics_not_enough_sessions` ("Not enough sessions logged yet.")

#### Matchmaking fairness (ANA-05…06)
- [x] **ANA-05** — Level-gap trend: per-session bar chart of average level-gap per court (expressed as tier-gap, e.g. "1.2"); note whether trend is improving (gap shrinking) or not. Per-session mean of court gaps; tier-gap = stored Elo-step gap ÷ 2
- [x] **ANA-06** — **Hidden in release (`AnalyticsPage.showHiddenCards=false`).** Per-court comparison: horizontal bar per court showing average level-gap; flag courts with consistently wider gaps (overflow absorbers). Flag: ≥3 sessions (`_minSessionsToFlagCourt`), wider than session mean on ≥60% (`_overflowConsistency`), avg > 1.25× club avg (`_overflowGapFactor`). Same-day saves fold by court position (average)

#### Court utilization & re-rolls (ANA-07…08)
- [~] **ANA-07** — Court utilization: horizontal bar per court showing fill rate (share of sessions the court held a game); summary line with overall "full-4 fill rate" and average idle courts per session. **Partial:** idle-court *time* and real court numbers need new session-log fields
- [x] **ANA-08** — Re-rolls per session: bar chart with counts; note connecting spikes to high-attendance/high-level-spread nights

#### Level distribution (ANA-09)
- [~] **ANA-09** — Level distribution: 4-bar chart (Amateur/Intermediate/Advanced/Professional); summary with median tier and trend direction. The "N players flat 6+ sessions" warning is removed. **Partial:** no tier history is stored, so the trend compares the current tier mix of active players with the prior range
- **ANA-10 removed** (issue #42) — "Top level movers" needed two `Player` snapshots for the same id
  embedded in different `Game`s to compute a delta. Moving `Game` to `playerIds: List<String>` makes
  that unrepresentable, and `GameRepository` already only ever resolved a historical roster to the
  *current* player row, so the feature never showed a real delta from production data. See ADR-0001.

#### At-risk & mixing (ANA-11…13)
- [x] **ANA-11** — At-risk players: regular attendees (historically ≥2 session days a month; two games on one day count once) not seen in 3+ weeks; usual frequency + time since last seen; total "lapsed" count
- [x] **ANA-12** — **Hidden in release (`AnalyticsPage.showHiddenCards=false`).** Player mixing: horizontal bar per player showing 0–1 mixing score (distinct partners ÷ games played); tagged "connector" (high), "clique" (low), or "isolated" (very low); summary note. `MixingTag` enum shown under each name; >10 players → top 5 + bottom 5 (`sampleMixing`)
- [x] **ANA-13** — New player integration: recently joined players with join date, sessions attended, "% of games with regulars"; styled favorable (≥50%) or needs-attention (<50%); contextual note. Window = `kNewPlayerWindowDays` (60, no setting yet); sessions attended = distinct days. `NewPlayerEntry.needsAttention` = attended > 0 and not favorable; a new player with no games in range is not counted in the "pair them up" warning, and the "playing alongside regulars" line hides if nobody played

#### Responsive & quality (ANA-14)
- [x] **ANA-14** — Responsive reflow: KPI strip and chart grids reflow from multi-column desktop to single-column phone, consistent with breakpoints in §1. KPI strip 6/3/1 columns; chart rows stack below desktop; breakpoints from the viewport width (`MediaQuery.sizeOf`). Release: 8 visible cards, 2 per row — Attendance + Waitlist, Level gap + Court utilization, Re-rolls + Level distribution, At-risk + New player integration
- [x] No chart library required — built with simple Flutter layout widgets (CustomPaint acceptable)
- [x] `flutter analyze --no-pub` passes

---

## Stage 7 — Self-Registration & Polish

### Goal
Implement the self-registration page, integrate the new design system with the existing app theme, and do responsive polish pass.

### Inputs
- All prior stages
- Existing app theme (light/dark mode support)

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/features/registration/registration_page.dart` | Self-registration page |
| Create | `lib/features/registration/level_selector.dart` | 4-tier level picker |
| Create | `lib/features/registration/confirmation_screen.dart` | Post-submit confirmation |
| Create | `lib/features/registration/registration.dart` | Barrel |
| Modify | `lib/routes.dart` | Add /register route for self-registration |
| Modify | `lib/main.dart` | Polish theme, dark mode integration |
| Modify | Various | Responsive polish pass |

### Detailed Tasks

#### 7.1 — `LevelSelector`
```dart
// Vertical list of 4 selectable tier cards.
// Tiers: Amateur, Intermediate, Advanced, Professional.
// Each card: title (14px, 700) + description (12px, 0.75 opacity).
// Selected: bg=#221d18, text=white, border=#221d18.
// Unselected: bg=#fbf6ee, text=#221d18, border=#eee4d8.
// radius: 9px, padding: 12px 14px.
// Props: selectedTier, onTierSelected
```

#### 7.2 — `ConfirmationScreen`
```dart
// Centered card after form submission.
// Checkmark icon (✓), "Thanks, {name}!" (Space Grotesk, 19px).
// Body text: explains pending approval, shows selected tier.
// Props: firstName, selectedTierLabel
```

#### 7.3 — `RegistrationPage`
```dart
// Centered max-width 520px card.
// Header: "Riverside Badminton Club" + "Join the club — takes about a minute".
// Step 1: Name field + Contact field (AppSearchInput style).
// Step 2: "Which best describes your level?" + LevelSelector.
// Submit button: AppButton.primary, disabled until name + contact filled.
// Footer: "An organizer reviews every new sign-up…" (11px, textSubtle).
// Post-submit: ConfirmationScreen.
// Props: onSubmit callback (creates pending registration)
```

#### 7.4 — Polish
```dart
// - Ensure dark mode works with the new theme (invert colors where appropriate)
// - Test all breakpoint transitions for smoothness
// - Verify existing functionality: PlayerRepository, GameRepository persistence
// - Check keyboard navigation / tab order on desktop
// - Verify GoRouter back/forward behavior with tabs
// - Add any missing empty states or error states
// - Remove any old/unused code referencing the pre-refactor theme
```

### Acceptance Criteria

> **UAT mapping:** REG-01…07
>
> **Release note:** REG-* is not reachable from the UI in the release build (`SettingsPage.showSignupPreview=false`). The `/register` route is kept.

#### Self-registration form (REG-01…05)
- [x] **REG-01** — Initial state: full-name input, email/phone input, 4 level-tier options (Amateur/Intermediate/Advanced/Professional) with one-line descriptions; Intermediate pre-selected by default; "Submit for approval" disabled until both fields non-blank
- [x] **REG-02** — Field validation: submit remains disabled when name or contact is blank/whitespace-only; no inline validation message in this build (known gap — no email/phone format validation)
- [x] **REG-03** — Selecting a tier: selected option gets dark fill, previous deselected; exactly one tier always selected (defaults to Intermediate, never "none")
- [x] **REG-04** — Submission: form replaced with confirmation — "Thanks, {first name}!" + message confirming starting level + organizer-may-adjust note; no edit/resubmit from this state
- [x] **REG-05** — Pending review framing: note visible before submission — "An organizer reviews every new sign-up before you're added to the roster"

#### Integration (REG-06)
- [x] **REG-06** — Submission wired to Players-tab pending-approval queue: REG-04 creates pending record consumed by PLY-01/02/03 (not separately-seeded mock data)

#### Responsive & polish (REG-07)
- [x] **REG-07** — Responsive: single centered column (max-width ~520px), fully usable at all widths from phone to desktop, no horizontal scrolling or overlapping controls
- [x] Dark mode: not supported. *(Stage 8.1.3 removes the dark theme code too.)* The redesign has a light palette only, so `MyApp` uses `ThemeMode.light`. A dark system theme changed only Material defaults (white text in light text fields)
- [ ] All breakpoints tested with window resize *(rendered at 390, 900 and 1400 px wide in widget tests; a live resize on Windows is still a manual check)*
- [x] Full `flutter analyze --fatal-infos --no-pub` passes (0 issues)
- [x] All existing tests pass (`flutter test`) — 375 passing, 0 failing
- [ ] App launches and navigates correctly *(needs manual check — not run interactively)*
- [x] Old inline theme code is fully removed (`lib/theme.dart` has zero references to the old `stAndrewsBlue`/`goldRush` palette; `lib/view/` retains only `component/` — the still-active dialogs and helpers, not old theme code)

---

## Stage 8 — 2026-10-17 design build (Courts, shell, Players, type and colour)

### Goal
Build the approved 2026-10-17 design on desktop: the new round lifecycle, the Courts tab, the
shell with the session bar, the Players scan check-in, and the new type and colour tokens.

### Rules for this stage
- **Authority.** `audit/design-diff-2026-10-17/decisions.md` (IDs R1-Q1 … R13-Q12; a
  later row overrides an earlier one) overrides the design HTML and the UX review resolutions.
  R11-Q2 … Q5 are in force: "×" in edit mode asks "Close without saving?" first, also while the
  changeover waits; "Start round {n+1}" in paused edit mode saves the edits, then the changeover
  starts; a checked-out player on a running live court has no slot "⋯"; the TIME UP chip is red
  `#b91c1c` with white text, time `#ff6a2b`. The design review
  `audit/design-review-2026-10-20/resolution.md` (F01 … F30) is written into UAT.md and this
  stage. Nathan answered F05 and F28 (R12-Q1, R12-Q2): "Start round {n+1}" while RUNNING with
  time left asks "End round {n} now? {mm:ss} left." first (no dialog in PAUSED or TIME UP);
  the RUNNING strip with round n+1 not saved also offers "Save round {n+1}" (matchmaker
  lineup, saved at once, no edit mode). Both are built in this stage. The 2026-10-22 decisions
  R13-Q1 … R13-Q12 replace the quick save with "Generate next round ({n+1})" and change the
  court count, Settings and Analytics (8.11).
  R6-Q12…18 accept the recommendations in `review-round6.md`. On a new conflict, ask Nathan and
  investigate first (R1-Q2). UAT.md is the feature source of truth.
- **Order.** Docs first, Nathan reviews (R1-Q3). Then the design canvas is updated (R3-Q13).
  Then code. Build on PR 45; the release waits (R1-Q1).
- **Scope.** Desktop only (≥1080px). Phone and tablet layouts stay as they are now (R2-Q23,
  R6-Q7): 5 tabs, the level stepper and membership pill in the row, the capacity bar. The
  round logic (8.2) is shared by every size, so phone and tablet show the new state names and
  button labels in their existing layout. Time mode only (`GameMode.enabled=false`, code kept).
  4 courts fixed on the Courts tab (`CourtCount.editable=false`). Light theme only. The app
  stays offline.
- **On hold (R6-Q6).** Courts Undo for "Start round {n+1}", "Discard round {n} and start again"
  and "End session" (R4-Q2, UAT RND-21) is not in this build.
- **Removed (R9-Q8).** The Players scan Undo (UAT PLY-20 removed). The only Undo in this build
  is the swap Undo on Courts (UAT COURT-17).
- **Matchmaker unchanged (R10-Q1).** A full lineup keeps the current algorithm: the weighted
  random pick `GameData._choosePlayer` (weight `1 / exp(2 × (played − average))`,
  `game_data.dart:688-702`) and the court swap optimiser `GameData._improveEloSpread` (cost
  `0.1 × average gap + max gap`, `game_data.dart:751-754`). The strict fill rule (8.4.1) fills
  one empty place only. Do not replace round generation with it.
- **Sessions tab redesign: built on desktop (8.10, 2026-10-21)** from the canvas board
  "Sessions" (R7-Q3). No approval was needed; Nathan fixes it later in a separate task. Its court
  count row shows only when `CourtCount.editable` is on. The design review rule F25 (template
  Load applies duration and capacity at once and asks only when the court count changes; new
  dialog text; template delete asks first) is built (UAT SESS-04, SESS-06).
- **Data format: unchanged.** No decision needs a new field in `players.json`, `games.json`,
  `session_logs.json` or `session_templates.json`. The Courts Undo log delete
  (`SessionLogRepository.delete`, 8.3) is on hold with RND-21, so this build adds no repository
  method. ADR-0002 (round id) stays a separate task.
- **l10n.** Every new string is an ARB key in en, fr, zh and zh_HK, with ICU plurals for counts
  ("1 round", "1 place left"). Run `flutter gen-l10n`.
- **TDD.** Write the failing tests for each UAT ID first (repo `CLAUDE.md`). Tests never touch
  the real data directory (PERSISTENCE.md §2.2, §6 phase 4): use a temp dir through
  `test/support/repository_sandbox.dart` (`RepositorySandbox.setUp`).
- **Release flags.** No flag changes in this stage (see the flag table).

### Superseded by this stage
| Old task / criterion | Replaced by |
|---|---|
| Stage 0 font notes (Space Grotesk + Inter/OpenSans), 0.2 | 8.1 (Source Sans 3 only) |
| Stage 2 2.1 `AppTabButton` pill style; 2.2 `TopNavBar` 5 tabs (desktop); NAV-01 criterion | 8.6 |
| Stage 3 3.6 `StatStrip` on desktop; NAV-06 desktop part | 8.5.1 (removed on desktop, R3-Q4) |
| Stage 3 3.8 `RoundRotationBar` (Pre-make, Rotate now, radio panels, depleting bar) | 8.2, 8.5.2 |
| Stage 3 criteria RND-01…11, COURT-11…13, WL-01…03 | 8.2, 8.4, 8.5 |
| Stage 3 3.1 `PlayerSlot` × remove, 3.4 `WaitlistSidebar` numbers and hint-only | 8.5.4, 8.5.5 |
| Stage 4 4.1 `LevelAdjuster` and the membership pill in the row; 4.2 `PlayerRow` | 8.7.3 |
| Stage 4 PLY-14 SnackBars for scan results | 8.7.2 |
| Stage 7 7.4 "dark mode works" | 8.1.3 (dark theme removed) |

### 8.0 — Canvas pass from the design review (2026-10-20, before code)
The acceptance criterion "The design canvas shows every decided change (R3-Q13)" needs these
board changes (`audit/design-review-2026-10-20/resolution.md`). The spec texts are in UAT.md.
- **Main (F02).** Add an `editing` flag next to `mode`; "Pause" keeps edit mode. Draw the
  states PAUSED + edit ("Start round {n+1}", "Resume round {n}"), TIME UP + edit (no bar
  buttons; "Save round {n+1}" in the strip), CHANGEOVER + edit, and the changeover waiting at
  00:00 (no bar buttons).
- **Main (R12-Q1, R12-Q2).** Draw the RUNNING confirm "End round {n} now? {mm:ss} left."
  ("Start round {n+1}" / "Cancel", alert dialog, focus on Cancel; none in PAUSED or TIME UP,
  F05), and the RUNNING not-saved strip with "Save round {n+1}" beside "Make round {n+1}"
  (F28).
- **Main.** "×" confirm "Close without saving?" (F03, R11-Q2); TIME UP chip `#b91c1c` /
  `#ffffff` (F04, R11-Q5); slot "⋯" on focus-within and menu keys (F06); focus ring `#ff6a2b`
  on dark surfaces (F07); TIME UP card tag "ROUND {n+1}" (F08); End session text by state
  (F09); discard strip text (F10); no slot tap and no pressable waitlist on a live court while
  the clock runs, hint "Courts change at the next round", one checked-out slot with no "⋯"
  (F11, R11-Q4); scrolling waitlist with 8 waiting (F12); one alert-dialog pattern and the
  RND-16 text (F14); paused changeover = PAUSED rules (F17); no-lineup waitlist (F22); "Running
  · 00:45" in `#ffb38a` (F26).
- **Players / More panel.** Disabled row text `#6f6352` (F13); exact-ID match before chips
  (F01); MANY MATCHES caret at end and the PLY-14 text (F19); CHECKED OUT after "Check out" in
  SCANNED TWICE (F20); "More" as a button with `aria-expanded` / `aria-controls`, Delete as
  `btn.danger-outline`, the duplicate-ID text with the name, the Disabled confirm (F23).
- **Sessions.** Amber `#ffb38a` (F26), TIME UP chip (F04). The F25 Load and delete rules are
  built in 8.10 (R7-Q3).
- **All boards.** Focus rule for tabs and the session bar link (F07); the state chip is a
  polite live region (F24); session bar order ROUND · time · chip (F29).

### 8.1 — Tokens: type and colour (ARCHITECTURE.md §1)
| Task | Files | Decision / UAT |
|---|---|---|
| 8.1.1 Bundle the Source Sans 3 variable font (one `wght` axis file) in `asset/font/`. Remove OpenSans and SpaceGrotesk from `pubspec.yaml` and the asset folder. Delete the unused `asset/font/NotoSans-VariableFont_wdth,wght.ttf` | `pubspec.yaml`, `asset/font/` | facts; UX-25 |
| 8.1.2 Rewrite `AppTypography` to the 6-size scale (50, 28, 20, 16, 14, 12) and 3 weights (400, 600, 800 page titles only). Replace every literal `fontSize` and `FontWeight` in `lib/` with a token. Set `fontFamilyFallback` per locale: zh → `Microsoft YaHei`, zh_HK → `Microsoft JhengHei` | `lib/design/app_typography.dart`, `app_theme.dart`, feature widgets | R2-Q20, R3-Q6 |
| 8.1.3 Replace `AppColors` with the ARCHITECTURE §1.1 tokens. Darken control borders to ≥3:1 (R2-Q22). Design review: focus ring `#ff6a2b` on `#221d18` / `#2b241e` (tabs, bar buttons, "⋯", session bar link) and `#c2410c` on light surfaces (F07); Disabled row text `#6f6352`, no `color.text.disabled` (F13); TIME UP chip `#b91c1c` / `#ffffff`, TIME UP time `#ff6a2b` (R11-Q5, F04); one ≤60 s amber `#ffb38a` (F26). Remove the dark theme: dark tokens (`app_colors.dart:78-92`), `AppTheme.dark()`, `theme.dart` `darkTheme`, `main.dart` `darkTheme:`; replace `AppColors.darkCardBorder` in `hamburger_menu.dart` | `lib/design/`, `lib/theme.dart`, `lib/main.dart`, `lib/shell/hamburger_menu.dart` | R2-Q22, UX-22, R11-Q5, F04, F07, F13, F26 |
| 8.1.4 Contrast test: a unit test computes the WCAG 2.x ratio of every token pair in ARCHITECTURE §1.1 and fails below 4.5:1 (text) or 3:1 (non-text) | `test/design/contrast_test.dart` | UX-22 |

### 8.2 — Round state machine (`GameData`, `TimerData`)
Add `RoundPhase { noLineup, ready, running, paused, timeUp, changeover }` and a separate
`isEditingNext` flag. The UI reads the phase only; it never derives it from the timer. The
changeover also keeps a `discarded` flag for the round it follows (R2-Q5, R9-Q1) and a
`waitingForEdit` flag: the changeover reached 0:00 while edit mode had unsaved changes (R9-Q4).

| Method | From phase | Effect | UAT |
|---|---|---|---|
| `generateFirstRound()` | noLineup | Matchmaker lineup → `ready`. Refuses with <4 checked in (R45-39) | RND-12 |
| `regenerateDraft()` | ready | New lineup; clock stays stopped | RND-13 |
| `startFirstRound()` | ready | Save round 1 → `running` at once, clock from full duration. No changeover (R9-Q2). No Undo | RND-13 |
| `generateNextRound()` (was `makeNextRound()`) / `editNextRound()` | running, paused, timeUp (generate); running, paused (edit) | "Generate next round ({n+1})": matchmaker lineup for n+1 → `isEditingNext`. No round n+1 exists before this click (Nathan 2026-10-22, R13-Q3 … R13-Q5) | RND-05, RND-10 |
| ~~`quickSaveNextRound()`~~ | — | Removed (Nathan 2026-10-22, R13-Q3; overrides R12-Q2, F28) | RND-05 |
| `saveNextRound()` / `regenerateNext()` / `exitEditNext()` | edit mode | Save n+1 / new n+1 lineup / drop edits (× ). `exitEditNext()` is called only after the "Close without saving?" dialog ("Close" / "Keep editing"), or with no dialog when nothing changed since edit mode opened; add `hasUnsavedEdits` (R11-Q2, F03). In `timeUp`, `saveNextRound()` also starts the changeover (R6-Q3). In `changeover` with `waitingForEdit`, `saveNextRound()` and `exitEditNext()` start round n+1 (log round n, → `running`; × starts the saved round unchanged, R11-Q2); `regenerateNext()` keeps waiting (R9-Q4) | RND-14, RND-07, RND-06 |
| `pause()` / `resume()` | running, changeover | `paused` keeps remaining time and the phase to return to ("Resume round n" / "Resume changeover"). `pause()` never changes `isEditingNext` (F02). Paused in edit mode: the round bar shows "Start round {n+1}" and "Resume round {n}" (R9-Q5). A paused changeover follows the PAUSED rules for round n+1: Re-roll, swap and the full slot menu (F17) | RND-17, RND-18, RND-14, COURT-14 |
| tick at 0:00 | running | Saved n+1 → `changeover` (20 s, `TimerData` second countdown). Else `timeUp`: the clock stops and no round n+1 is made; the courts show round n, locked (Nathan 2026-10-22, R13-Q4). `isEditingNext` stays as it is in both cases (R6-Q3, R7-Q4) | RND-03, RND-14, RND-15 |
| changeover end / `startNextNow()` | changeover | Log round n (8.2.1) unless `discarded`, n+1 → `running`, leave edit mode. If edit mode has unsaved changes at the end, the countdown stops at 0:00 and sets `waitingForEdit`; nothing is logged until `saveNextRound()` (R9-Q4) | RND-06, RND-19 |
| `startNextRound()` (was `saveAndStartNew`) | round n+1 saved, and running or paused, not edit mode; or paused in edit mode of the saved n+1 (R9-Q5) | The saved n+1 (in paused edit mode with its changes, R11-Q3) → `changeover` (R6-Q1, R6-Q14, R7-Q1). With no saved n+1 it does nothing, and the bar has no button (Nathan 2026-10-22, R13-Q5). Logs nothing at the click. In `running` the UI calls it only after the "End round {n} now?" confirm (R12-Q1, F05); in `paused` it calls it at once. Add `timeLeft` for the dialog text | RND-04, RND-14 |
| `discardAndStartNext()` (was `discardAndStartNew`) | running, paused, timeUp; not edit mode | Called only after the confirm dialog (R9-Q3). → `changeover` with `discarded = true`; never logs round n; number n again, label "Discard round {n} and start again" (R2-Q5, R9-Q1) | RND-16 |
| `endSession()` | any with a lineup | Log the round that started last once (also the round that ended in `timeUp` / before `changeover`; never a discarded or not-started round, R6-Q5), stop clock, check out all, `noLineup`, round 1. Add `roundToLog` (n, n−1 in `changeover`, or none) for the dialog text (F09) | RND-20 |
| `swapPlayers()` / `undoSwap()` | any state that allows a swap | Swap two players; keep one swap memento for 10 s; any other change clears it (R6-Q6, R7-Q2) | COURT-08, COURT-10, COURT-17 |
| ~~`undoScan()`~~ | — | Removed: no Undo after a scan (R9-Q8; UAT PLY-20 removed) | — |

8.2.1 **Round logging at next-round start (R3-Q8, R6-Q2).** Round n is logged only when round
n+1 starts: the end of the changeover or `startNextNow`, or by `endSession`. The start buttons
log nothing at the click; they go through the changeover (R6-Q1). Reuse `_logRound` (disk
first, then `history`, R45-01) and the one-at-a-time guard of `rotateNow`. A discarded round
logs nothing. The round number is `logged rounds this session + 1`, so a discard uses the
number again (R2-Q5, R9-Q1: "Discard round {n} and start again") and `endSession` resets it to
1. Keep the current rule for empty courts; changing it belongs to ADR-0002.

8.2.2 Remove the old flow: `rotateNow` auto-rotation at 0:00 (`_onAutoRotate`), the radio
`RoundView` panels, the time-mode global Save (`saveCurrentGame` path from the action bar),
and "Pre-make" / "Cancel next". Keep `rotateNow`'s write guard as the core of 8.2.1.

8.2.3 `TimerData`: default duration 10 min (R2-Q24, was 20). A duration change while PAUSED
applies at once, by the RUNNING rule: remaining = new duration − elapsed; at or below 0 the
round reaches 0:00 at once (R9-Q6, UAT SESS-02). The changeover countdown can stop at 0:00
and wait (R9-Q4). `isUrgent` is true only while
RUNNING with ≤60 s, never while PAUSED (UX-09, R6-Q8); the round bar and the session bar both
read it. Progress = elapsed ÷ duration (R4-Q7). Add the 20 s changeover countdown (R3-Q7) and
the pause of it (R4-Q5). Wire the existing unused `pause()`.

8.2.4 **Double-click guard (R6-Q18).** Two fast clicks on "Start round {n+1}" (also the
"End round {n} now?" confirm, R12-Q1), "Discard round
{n} and start again" (dialog confirm), "Save round {n+1}" or "Start round {n+1} now" start one changeover
and log round n once. Two fast clicks on "Generate next round ({n+1})" make one round n+1 (R13-Q3). The guard is a phase check plus the one-at-a-time flag of 8.2.1, so the
second call is a no-op. Test: `test/game_data_round_logging_test.dart`
`should_log_round_once_when_start_clicked_twice` (and one per button).

8.2.5 **As built (2026-10-21).** State layer. The 8.5 widgets call it (see 8.5.7).
- `RoundPhase` is in `lib/state/round_phase.dart` (exported by `game_data.dart`). `GameData`
  takes `timer:`; `main.dart` gives it the provided `TimerData`, with the duration from the
  settings. Without `timer:` it owns its own clock.
- Extra getters for the UI: `pausedFrom` (`running` or `changeover`), `nextLineup`,
  `isNextRoundSaved`, `discarded`, `waitingForEdit`, `hasUnsavedEdits`, `displayRoundNumber`
  (n+1 in the changeover, n again after a discard), `roundToLog`, `timeLeft`, and
  `startNeedsConfirm` (R12-Q1: true only in RUNNING with time left, not in edit mode). The UI
  shows the "End round {n} now?" dialog when `startNeedsConfirm` is true, then calls
  `startNextRound()`. `visibleMatches` shows the edit lineup in edit mode, and `nextLineup` in
  the changeover. TIME UP shows round n (R13-Q4).
- Every method returns `false` (or a `Future` of `false`) when the phase does not allow it.
  That is the 8.2.4 guard. `saveNextRound`, `exitEditNext`, `startNextNow` and `endSession`
  return a `Future`, because they can log a round. They share the `_isRotating` flag (the
  write guard that `rotateNow` had; it stays after 8.2.2).
- `startNextNow()` does nothing while edit mode has unsaved changes (the bar shows "Pause" only,
  R4-Q9). `quickSaveNextRound()` is removed (R13-Q3).
- Write failure at the end of the changeover (RND-06, R45-01): the phase stays CHANGEOVER at
  00:00, nothing is logged, and `roundLogError` holds the error for the message. "Start round
  {n+1} now" (`startNextNow()`) tries again; that call throws when its write fails.
- `endSession()` also clears the in-memory `history` (the disk keeps the log), so every Player
  starts the next Session at 0 rounds and the round number is again logged rounds + 1. It pauses
  the clock during the write and resumes it if the write fails.
- A check-out removes the player from the round n+1 lineups (saved, planned, edit). The fill
  of that place and the swap Undo came later: see 8.3.1 and 8.4.7.
- **8.2.2 done (2026-10-21, with 8.5).** Removed: `rotateNow`, `RoundView`, `roundView`,
  `setRoundView`, `stageNextRound`, `cancelStagedRound`, `stagedLineup`, `isStaged`,
  `stagedSummary`, `saveCurrentGame` (game-based mode uses `saveSingleGame` only),
  `RoundRotationBar`, `TimerData.pct` and `TimerData.start`, the `TODO(8.2.2)` markers, and
  14 ARB keys with no reader (`regenerate`, `dashboard_rotate_now`, `dashboard_premake_next`,
  `dashboard_cancel_next`, `dashboard_current_round`, `dashboard_next_round`,
  `dashboard_next_round_ready`, `dashboard_until_rotation`, `dashboard_staged_summary`,
  `dashboard_player_count`, `dashboard_court_count`, `dashboard_mode_time_based`,
  `dashboard_discard_court_title`, `dashboard_discard_court_body`). The write guard
  (`_isRotating`, disk first, then `history`) stays. `makeGame` stays for game-based mode; it
  does not change the round phase.
- `TimerData`: `startRound`, `startChangeover`, `pause`, `resume`, `isPaused`, `isChangeover`,
  `elapsed`, `progress` (elapsed ÷ length), `changeoverLength` = 20 s, default 10 min. The clock
  now calls `onExpired` on the tick that reaches 0:00 (PR 45 waited one more tick). `elapse()`
  is for tests only.
- Tests: `test/game_data_round_phase_test.dart`, `test/game_data_round_logging_test.dart`,
  `test/timer_data_test.dart` (updated).

### 8.3 — Undo: memento of session state, one level, swap only (R3-Q2, R6-Q6, R7-Q2, R9-Q8)
- **Swap only (R9-Q8).** The only Undo in this build is the Courts swap (UAT COURT-17). A scan
  on Players sets no memento and shows no Undo (R9-Q8 overrides R2-Q10 and the scan part of
  R3-Q2; UAT PLY-20 removed).
- `SessionMemento` is an immutable copy of the in-memory session: live lineup, next lineup and
  its saved flag, round number, phase, remaining time and running flag, checked-in ids in
  check-in order (the waitlist tie-break reads it, 8.4.1), re-roll count, playing game ids,
  selection cleared.
- `GameData` holds one slot `_undo`. Only a swap on Courts sets it (COURT-17): the bottom
  message "Swapped {A} and {B}. Undo" expires the slot after 10 s, and any other change (a scan,
  a check-out, a round change, a new swap) clears it (R6-Q6). No Ctrl/Cmd+Z (R7-Q2). A new
  swap memento replaces the old. A swap logs no round, so this Undo never deletes a log entry.
- The memento restores `history` too, so rounds played (`getCurrentPlayersHistory`) and the
  fill rule stay correct after Undo.
- **On hold (R6-Q6, R4-Q2 paused): Courts round Undo.** Not in this build. Note for later: the
  memento would be set by `startFirstRound`, `startNextRound`, `discardAndStartNext` and
  `endSession`, and would carry a **log receipt** (the game ids, the `SessionLog` id, the
  `history` index). Undo after a logged round would delete that log entry, disk first:
  `GameRepository.delete(id)` per game id, then a new `SessionLogRepository.delete(id)` over
  `JsonCollection.remove`, then the `history` entry, then restore. The delete removes whole rows
  by their own id and never loads, resolves or rewrites a roster, so it cannot lose history
  (PERSISTENCE.md §3.1, ADR-0001). Golden test then: `games.json` and `session_logs.json` after
  log + Undo are byte-equal to the files before the log. R6 answers: restore the clock time at
  the click; any other change cancels the Undo; round 1 included.

8.3.1 **As built (2026-10-21).** State layer. The 8.5 swap message calls it (see 8.5.7).
- `GameData.swapPlayers(a, b)` swaps in the round on screen (`visibleMatches`): two court
  players trade slots (COURT-10), or a waitlisted player takes the slot of a court player, who
  goes to the waitlist (COURT-08). It returns `false` when `canEditCourts` is false (8.4.6), when
  neither player is on a court, or when a court holds a saved game-based game. The existing
  drag-and-drop `swapPlayer` and `placePlayerInSlot` set no memento (a move to an open slot is
  not a swap, COURT-17).
- **Drift from the memento list above.** The memento is `_SwapMemento`: the rosters of the one
  lineup that the swap changed, the two players, and the time. It holds no phase, clock,
  `history` or check-in order. A swap changes only those rosters, and any other change clears
  the memento, so there is nothing else to restore. Restoring the clock would turn back a
  running round by up to 10 s. The full `SessionMemento` waits for the round Undo (on hold).
- "Any other change clears it": `GameData.notifyListeners` clears the slot, except during the
  swap's own notification. Every state change notifies, so a scan, a check-out, a round change
  or a new swap clears it. A clock tick is a `TimerData` notification and does not.
- `canUndoSwap` is true for `GameData.swapUndoWindow` (10 s) after the swap; `lastSwap` gives
  `(A, B)` for the message text; `undoSwap()` restores the rosters and returns `false` after
  the window. The time comes from the `clock:` constructor argument (tests pass a fake one).
- Tests: `test/game_data_undo_test.dart` (21).

### 8.4 — Fill rule, late check-in, check-out (R2-Q8, R2-Q9, R3-Q12, R7-Q4…Q7, R10-Q1…Q3)
- 8.4.0 **Scope of the fill rule (R10-Q1, narrows R2-Q9).** The fill rule fills **one** empty
  place only: a check-out, a delete or a set to Disabled, and "Move to waitlist". A full round
  (`generateFirstRound`, `regenerateDraft`, `generateNextRound`, `regenerateNext`, a fresh lineup
  for "Discard round {n} and start again") keeps `makeGame()`: the weighted random pick
  `_choosePlayer` and the swap optimiser `_improveEloSpread`, unchanged. Re-roll (COURT-02)
  stays as it is. Test: a full round still calls `_choosePlayer` (seeded `random:`), not
  `pickForSlot`.
- 8.4.1 `GameData.pickForSlot(court, candidates)`: sort the candidates by rounds played this
  session ascending (`getCurrentPlayersHistory`; in time mode each `history` entry is one
  Round, so the count is rounds). Tie: the candidate that gives the smallest `tierGap()` for
  that court with the candidate in it (R10-Q2). Replace the `elo.index` sort in
  `_autoPromoteFromWaitlist`. Waitlist display (WL-01, R10-Q2): the same order as
  `pickForSlot` for the next open place (the first court, Court 1 first, with an open slot);
  with no open slot, tie by check-in order, earliest first (`_checkedInPlayers` is an
  insertion-ordered `Map`, so its order is the check-in order; keep it so on restore and on
  Undo). UAT WL-01…03.
- 8.4.2 Fix the `isCourtPlaying(stagingMatches.indexOf(court))` lookup in
  `_autoPromoteFromWaitlist`: it reads `visibleMatches`, which can be the next round
  (verification.json, checkin-mid-round extra 2). Test it with the next round on screen.
- 8.4.3 `checkInPlayer`: never place on a live court, and never add to a saved next round, also
  when it has an open slot (R7-Q7, overrides R2-Q7). The player goes to the waitlist. A late
  player starts at 0 rounds played: no average credit (R10-Q3), so `_choosePlayer` weights them
  up and `pickForSlot` puts them first. UAT CHK-02, PLY-17.
- 8.4.4 `checkOutPlayer`: drop the id from the checked-in set at once (count drops, R2-Q8).
  Live court while the clock runs (RUNNING): leave the player in the live lineup until the round
  ends (the log holds them), no marker. Saved next round (also in CHANGEOVER), round n+1 in edit
  mode, or a stopped live court: remove and fill by 8.4.1. No bottom message on Courts
  (R7-Q5). Return a result that names who took which slot, for PLY-18. UAT CHK-05, COURT-16,
  RND-11.
- 8.4.5 `moveToWaitlist`: the player goes to the waitlist, stays checked in, and the place is
  filled by 8.4.1 from the other players who sit out that round (R7-Q6). UAT COURT-15, WL-02.
- 8.4.6 CHANGEOVER counts as "the clock runs" for Re-roll and the slot menu (R7-Q4), except in
  edit mode for the new round. UAT COURT-10, COURT-14.
- 8.4.7 **As built (2026-10-21).** State layer. The 8.5 widgets call it (see 8.5.7).
  - `pickForSlot(court, candidates)` sorts by rounds played, then the level gap of the court
    with the candidate in it, then check-in order. The level gap is the tier gap (`tierGap()`),
    then the Elo gap inside one tier (the re-roll's `_levelGap`); no doc gives the second key.
  - `waitlistOrder` is the WL-01 list (new getter; `visibleWaitlistedPlayers` keeps check-in
    order for the PR 45 sidebar). With no lineup it is check-in order (F22).
  - `checkOutPlayer` returns `List<SlotFill>` (`player`, `courtIndex`, `round`) for PLY-18. It
    names the fills of the live round and of round n+1; the edit-mode copy is filled too, but
    not named. The fill puts the new player in the freed slot position, and the edit-mode base
    gets the same change, so a fill alone is not an unsaved edit (R11-Q2).
  - **Round n keeps the leaver in RUNNING, TIME UP and CHANGEOVER** (also a paused
    changeover): the round is played and waits for its log. TIME UP shows round n and makes no
    planned round (R13-Q4). In READY and a paused round the
    live court is filled.
  - `isCheckedOutOnLiveCourt(player)` is true for a checked-out player still on round n; the
    8.5 slot hides "⋯" for that player (R11-Q4).
  - `moveToWaitlist(player)` works on the round on screen when `canEditCourts` is true.
  - `canEditCourts` (8.4.6) is false in RUNNING and CHANGEOVER, except in edit mode; true in
    READY, PAUSED (both kinds, F17), TIME UP and with no lineup.
  - `checkInPlayer` in time mode never seats the player. Game-based mode (hidden) keeps the old
    first-non-full-court placement.
  - 8.4.2 fixed: the PLAYING check of a fill reads the court's own game id
    (`_playingGameIds`), not `isCourtPlaying(index)` on the round on screen. Also in
    `removePlayerFromCourt`.
  - A delete or a set to Disabled goes through the same check-out path.
  - Changed old tests (behaviour replaced by R7-Q7 and 8.4.1): the highest-level refill in
    `game_data_waitlist_promotion_test.dart` (removed; fill order now in the new file), the
    part-full court check-in in `game_data_late_checkin_test.dart` and CHK-02 in
    `game_data_stage5_test.dart` (now: the player waits).
  - Tests: `test/game_data_fill_rule_test.dart` (48).

### 8.5 — Courts tab (desktop)
- 8.5.1 Page structure: round bar → next-round strip → 2×2 grid + 280 px waitlist. Remove the
  desktop `StatStrip` and `_ActionBar` (R3-Q4, UX-10). Keep the phone/tablet layout. UAT NAV-06,
  NAV-07.
- 8.5.2 `RoundBar` (replaces `RoundRotationBar` on desktop): 80 px full-width band, states
  and buttons per ARCHITECTURE §2.3, 50 px timer, chip, counts, round "⋯" menu with "End
  session", 4 px bar filling with elapsed time. Time and progress fill amber at ≤60 s while
  RUNNING, not PAUSED (R6-Q8). Labels "Start round {n}" (R7-Q1) and "Discard round {n} and
  start again" (R9-Q1), which opens a confirm dialog first (R9-Q3); PAUSED also has "Start
  round {n+1}" (R6-Q14); PAUSED in edit mode shows "Start round {n+1}" and "Resume round {n}"
  only (R9-Q5); paused changeover "Resume changeover" (R6-Q12); "Start round {n+1}" in RUNNING
  opens the confirm "End round {n} now? {mm:ss} left." ("Start round {n+1}" / "Cancel"; 8.5.6),
  and in PAUSED and TIME UP starts at once (R12-Q1, F05). Test first:
  `should_ask_before_ending_round_early` (Arrange: RUNNING with 04:12 left; Act: tap "Start
  round 4"; Assert: the dialog "End round 3 now?" shows and the phase is still `running`), then
  `should_start_round_without_dialog_when_paused` and `..._when_time_up`; a changeover waiting at 0:00
  for an edit shows no buttons (R9-Q4). No "COURTS − 4 +" stepper (R2-Q2). TIME UP chip `#b91c1c`
  / `#ffffff`, time `#ff6a2b`, sub-label "Clock stopped at 0:00" (R11-Q5, F04). The state chip is
  `Semantics(liveRegion: true)`; the time is not (F24). Focus ring `#ff6a2b` on the bar (F07).
  Each 32 px button gets a 40 px hit area (F27). UAT RND-01, RND-02, RND-04, RND-09,
  RND-12, RND-13, RND-15…19, RND-06.
- 8.5.3 `NextRoundStrip` and edit mode: strip texts; in RUNNING, PAUSED and TIME UP with no
  round n+1 one button, "Generate next round ({n+1})" (`courts_generate_next_round`, calls
  `generateNextRound()`, opens edit mode; key `generate-next-round`). The quick save and "Make
  round {n+1}" are removed (Nathan 2026-10-22, R13-Q3 … R13-Q5). Tests:
  `should_show_generate_when_running_not_saved`, `should_show_generate_when_time_up`; dashed NEXT cards, edit strip with
  "Discard & regenerate", "Save round {n+1}", "×"; round bar shows Pause only while RUNNING
  (R4-Q9), and "Start round {n+1}" (only after round n+1 is saved, R13-Q5) + "Resume round {n}"
  while PAUSED (R9-Q5). Court tag
  "{count} players" (for example "3 players", ICU plural) on a court one player short (UX-04). CHANGEOVER
  strip reads "Round {n} ended" (R6-Q2); after a discard it reads "Round {n} discarded · new lineup
  for round {n}" (`discarded` flag, F10). TIME UP shows the strip with "Generate next round
  ({n+1})" and no "Clock stops" text; the courts show round n, with no "ROUND {n+1}" tag (the
  F08 tag and `courts_tag_round` are removed, R13-Q4). "×" opens "Close without saving?"
  ("Close" / "Keep editing") when the edit has changes, and closes at once when it has none
  (R11-Q2, F03). UAT RND-05, RND-07, RND-08, RND-10, RND-14, RND-15, RND-22.
- 8.5.4 `CourtCard` / `PlayerSlot`: "Court {k}", plain gap text, secondary Re-roll shown per
  R3-Q10 and R7-Q4, slot tap = select for swap, hover fill and "⋯" menu ("Move to waitlist",
  "Check out"; live court while the clock runs, CHANGEOVER included: "Check out" only), no "×"
  (R3-Q11). Keep "Open slot" (R2-Q19). On a live court while the clock runs (not edit mode) the
  slot tap is a no-op and the slot is not a tap button (F11); a checked-out player there has no
  "⋯" (R11-Q4). The "⋯" shows on hover and on keyboard focus of the slot or the button, with a
  40×40 hit area; the menu takes arrow keys, Enter and Esc, and focus goes back to the "⋯" when
  it closes (F06, F27). Paused changeover: PAUSED rules (F17). UAT COURT-01, COURT-04…10,
  COURT-14…16.
- 8.5.5 `WaitlistPanel`: title + count, "SEARCH WAITLIST" field (UX-14), fill-rule order, no
  numbers, "{tier} · {n} rounds", "Next in" tag, "No one waiting", "No one matches “{text}”"
  (R6-Q12), selection hint kept. The list is `Expanded(child: ListView)` under a fixed header,
  search and hint, so it scrolls (F12). While the live clock runs (not edit mode) the items are
  not pressable and the hint reads "Courts change at the next round" (F11). With no lineup the
  panel lists the checked-in players in check-in order, no "Next in" (F22). Desktop only;
  `WaitlistChips` unchanged. UAT WL-01, WL-04, NAV-07, RND-12, COURT-04…06, COURT-10.
- 8.5.6 End session dialog: "End session?", "End session" / "Cancel" (no Undo message; RND-21
  on hold). Text from `roundToLog` (F09): RUNNING, PAUSED, TIME UP "Round {n} goes into the
  history. Everyone is checked out."; CHANGEOVER (not discarded) "Round {n−1} goes into the
  history. Everyone is checked out."; READY, no lineup, or a changeover after a discard
  "Nothing is logged. Everyone is checked out." Discard confirm dialog: "Discard round {n}?",
  "Round {n} is not logged. The next lineup goes on the courts and round {n} starts again.",
  "Discard round" / "Cancel" (R9-Q3; this text wins over the board, F14). "Close without
  saving?" dialog: "Close" / "Keep editing" (R11-Q2, F03). Early start confirm (R12-Q1,
  F05): "End round {n} now?", "{mm:ss} left.", "Start round {n+1}" / "Cancel", RUNNING only. One
  confirm widget for all four (F14): alert dialog semantics with title and description, initial focus on the cancel
  button, Esc = cancel; it pops itself (ARCHITECTURE §4.6). A phase change while the early start, Discard or
  End session dialog is open closes it with no action (F18, R12-Q1). The swap Undo bottom message (10 s,
  "Swapped {A} and {B}. Undo", no keyboard shortcut, R7-Q2) stays bottom-centre and blocks
  pointer input only inside its own 360 × 48 px box (F15). UAT RND-07, RND-16, RND-20,
  COURT-17.
- 8.5.7 **As built (2026-10-21).**
  - Files: `lib/features/dashboard/courts/` (`round_bar.dart`, `next_round_strip.dart`,
    `desktop_court_card.dart`, `waitlist_panel.dart`, `courts_confirm_dialog.dart`,
    `courts_menu.dart`, `courts_button.dart`), wired in `dashboard_page.dart`. The shell gives
    the desktop Courts tab no padding, so the round bar is full width under the nav.
  - Desktop, time mode: `RoundBar` → `NextRoundStrip` (edit mode, RUNNING, PAUSED,
    CHANGEOVER only) → grid (`courtGridLayout`, minimum court height 216 px; it scrolls only
    when that does not fit) + 280 px `WaitlistPanel`. 4 courts fit at 1280 × 720 in every
    phase and in en, fr, zh, zh_HK.
  - Phone and tablet, time mode: `StatStrip`, `RoundBar(compact: true)` (a wrapped card),
    `NextRoundStrip(compact: true)`, `WaitlistChips` (in `waitlistOrder`), and the old
    `CourtCard` grid. The compact round bar replaces `RoundRotationBar` there too, because
    8.2.2 removed it (drift from 8.5.2, which says desktop only).
  - Game-based mode keeps the PR 45 page: `StatStrip`, Generate Game, the court stepper (only
    with `CourtCount.editable`), `CourtCard` with per-court Save. On desktop it has its own
    24 px padding.
  - "Discard round {n} and start again" becomes "Discard round {n}" in any state where the full
    label does not fit (F16, measured with `TextPainter`).
  - "End session" with no lineup: `endSession()` refuses `noLineup`, so the UI checks out every
    player itself after the dialog ("Nothing is logged. Everyone is checked out.").
  - "Close without saving?" body: "Your changes to round {n} are lost." (new key,
    `courts_close_unsaved_body`).
  - The confirm dialog listens to `GameData` and closes on a phase change (F18) for the early
    start, Discard and End session dialogs. "Close without saving?" does not.
  - Slot menu: no player → no "⋯"; courts can change → "Move to waitlist" + "Check out"; live
    court while the clock runs → "Check out" only, and no "⋯" for a player checked out there
    (`isCheckedOutOnLiveCourt`).
  - A selection clears when the phase, edit mode or the lineup on screen changes.
  - A failed round log (`roundLogError`) shows "Something went wrong. Try again." once.
  - Tests: `test/features/courts_round_bar_test.dart` (41),
    `courts_confirm_dialog_test.dart` (24), `courts_slot_menu_test.dart` (24),
    `courts_swap_undo_test.dart` (10), `courts_waitlist_test.dart` (15),
    `dashboard_four_courts_fit_test.dart` (rewritten, 39). Harness:
    `test/support/courts_harness.dart` (loads Source Sans 3, so text has its real width).
  - Old tests changed for 8.2.2 and 8.5: removed `dashboard_round_rotation_test.dart`,
    `dashboard_next_round_test.dart`, `game_data_round_rotation_test.dart`,
    `game_data_round_view_test.dart`, `game_data_rotation_guard_test.dart` (the guard and
    failed-write cases are in `game_data_round_logging_test.dart`); removed the Save, staged
    round and rotate cases in `game_data_release_fixes_test.dart`,
    `game_data_lineup_error_test.dart`, `game_data_court_count_test.dart`,
    `game_data_fill_rule_test.dart`, `dashboard_release_fixes_test.dart` (F1),
    `dashboard_court_edit_test.dart` (old warnings), `dashboard_game_based_test.dart` (global
    Save), `layout_feedback_test.dart` (rotation bar); updated
    `dashboard_breakpoints_test.dart`, `dashboard_scroll_test.dart`,
    `dashboard_timer_rebuild_test.dart`, `dashboard_lineup_error_test.dart`,
    `release_court_count_test.dart` (no stepper even with the flag on, R2-Q2),
    `game_data_late_checkin_test.dart`, `game_data_session_log_test.dart`, `timer_data_test.dart`.
  - Not as the canvas: the edit strip has no helper text; the early start dialog body is only
    "{mm:ss} left."; with no lineup the sub-label reads "Not started"; the card tags are not
    upper-case; dialog action buttons are red.

### 8.6 — Shell (desktop)
- 8.6.1 `TopNavBar` desktop: left text "Session" over "{duration} rounds" (R3-Q5, F29); whole
  minutes as "10 min", else `m:ss`, for example "10:30 rounds"; tabs "Courts",
  "Players", "Sessions"; "⋯" menu with "Analytics", "Settings" (R2-Q13); active tab = white
  600 + 3 px orange underline (UX-21). Tabs and "⋯" have a `#ff6a2b` focus ring (F07). Routes stay the same 5 routes. Tablet keeps 5 tabs and
  "Dashboard" (R6-Q7). UAT NAV-01, NAV-09.
- 8.6.2 `SessionBar`: 40 px, on every tab except Courts; order ROUND · time · chip, as on the
  round bar (F29); the chip is `Semantics(liveRegion: true)`, the time is not (F24); the bar link
  has a `#ff6a2b` focus ring (F07); TIME UP chip `#b91c1c` / `#ffffff` (R11-Q5); chip always; "No round yet" before
  the first lineup; "· round {n+1} saved" or "· round {n+1} not saved" (R6-Q12); amber time
  ≤60 s while RUNNING, not PAUSED (R6-Q8); click → Courts; no round-change message (R4-Q4,
  R4-Q6). It watches `TimerData` through a `Consumer` so only the bar rebuilds on a tick
  (R45-03). UAT NAV-10, NAV-11.
- 8.6.3 **As built (2026-10-21).**
  - Files: `lib/shell/desktop_top_nav_bar.dart` (`DesktopTopNavBar`, `roundDurationText`),
    `lib/shell/session_bar.dart` (`SessionBar`), `lib/shell/inset_focus_ring.dart`, wired in
    `responsive_shell.dart` (`_buildDesktopLayout`). Tablet keeps `TopNavBar` (5 tabs,
    "Dashboard"); phone is unchanged.
  - The chip text, chip colours, time and time colour come from one class,
    `lib/features/dashboard/courts/round_status.dart` (`RoundStatus`), so the round bar and the
    session bar always agree (NAV-11). The session bar watches `GameData`; its time is a
    `Consumer<TimerData>`. The header reads the duration with `context.select`, so a tick does
    not rebuild it.
  - Header duration: whole minutes "{m} min" (`shell_duration_minutes`), else `m:ss` with no
    leading zero on the minutes ("10:30", "5:30").
  - "· round {n+1} saved / not saved" shows only while round n has its clock: RUNNING, PAUSED
    (round clock) and TIME UP. READY, CHANGEOVER and a paused changeover show only
    "{in}/{capacity} in · {waiting} waiting". In CHANGEOVER the bar shows "ROUND {n+1}", as the
    round bar does. "No round yet" replaces the round, time and chip; the counts stay.
  - The "⋯" menu uses the Courts menu (`courtsMenuAnchor`: card fill, 1 px `#6f6352` border,
    40 px items; Esc and a click outside close it; focus goes back to "⋯"). "⋯" is a 44 px
    `CourtsIconButton` (outset ring); the tabs and the session bar draw an inset 3 px
    `#ff6a2b` ring (canvas `outline-offset: -3px`). "⋯" has the label "More pages: Analytics,
    Settings" (`shell_more_menu`).
  - Fix: on desktop the page area is a `Semantics(container: true)` boundary. Without it the
    modal barrier of the branch route (`BlockSemantics`) hid the top nav and the session bar
    from screen readers. Tablet and phone do not have this boundary yet (unchanged layout).
  - Tests: `test/shell/top_nav_test.dart` (26), `test/shell/session_bar_test.dart` (35), with
    `test/support/shell_harness.dart` (the 5 real branches with plain pages).
    `integration_test/shell_navigation_test.dart` and the `navigateToTab` helper use the desktop
    tabs and the "⋯" menu. For 8.5, `generateGame` became `generateRoundOne` ("Generate round
    1"), `dashboard_courts_test.dart` finds "Court N", and `dashboard_layout_test.dart` expects
    no desktop stat strip (R3-Q4).
  - Integration tests run on the Linux desktop one file at a time:
    `xvfb-run -a flutter test integration_test/<file>_test.dart -d linux`. With the whole
    folder in one run, every file after the first fails to start the app ("Error waiting for a
    debug connection").
  - Not as the canvas: hover fills on the tabs (`#2b241e`) and the bar (`#221d18`), which the
    canvas does not draw; the menu is the Courts menu style, not drawn on the canvas.

### 8.7 — Players tab (desktop)
- 8.7.1 Scan field ("CHECK IN" label, scan icon, "Scan card or search name", 52 px, 2 px
  border, 20/600), the count "{in} / {capacity} in" + "{n} places left", the orange "Add
  player" button. No capacity progress bar on desktop (R6-Q11). Keep the banner and pending card
  restyled (R2-Q19). Level chips: 4 tier chips replace the 8 Elo-code chips (R6-Q13). Control
  borders per ARCHITECTURE §1.1 (`#6f6352` inputs and outline buttons, `#8f826e` secondary,
  R6-Q16). Focus: the scan field gets focus back after pointer actions (scanner rule, kept,
  F21), and Esc anywhere on the tab returns focus to it (F21). After a scan the text is
  selected, except in MANY MATCHES: caret at the end, no selection (F19). UAT PLY-14, CHK-01,
  CHK-04, PLY-13.
- 8.7.2 `ScanResultBox` with the 9 states (READY, CHECKED IN, CHECKED OUT, SCANNED TWICE, NOT
  FOUND, MANY MATCHES, SESSION FULL, DISABLED, DUPLICATE ID), `Semantics(liveRegion: true)`,
  stays until the next scan, not changed by row taps (R3-Q3). Texts per R4-Q3 and R6-Q12:
  DUPLICATE ID "ID {id} is used by {count} players · nothing changed. Fix the ID in More.";
  CHECKED IN "waits for round {n}" only (the "joins round {n} on Court {k}" text is not used,
  R7-Q7); no "Undo" button in any state (R9-Q8). Scan results no longer use SnackBars. A refused row tap keeps the
  small bottom message (R4-Q1). UAT PLY-14, PLY-16…18, CHK-03, CHK-06.
- 8.7.3 `PlayerRow`: 48 px, columns NAME / SIGN-IN ID / LEVEL (tier name) / TYPE / More;
  checked-in fill, 1 px border and 6 px bar in green (UX-16). Move `LevelAdjuster` (with the Elo
  code) and the membership control into the More panel (R2-Q17, R2-Q18); phone/tablet rows keep
  them (R6-Q7). Disabled row: name, ID and level in `#6f6352`, not a paler colour (F13). "More"
  is a button with `Semantics(expanded:)` for its panel (F23). UAT PLY-05, PLY-06, PLY-08,
  NAV-08.
- 8.7.4 Double-scan guard: keep only the last scan check-in (id); a scan of the same target, with
  no time limit, shows SCANNED TWICE "(same card as the last scan)" with "Check out" (R2-Q11,
  R6-Q15). Its "Check out" shows the CHECKED OUT result for that player, not READY (F20).
  UAT PLY-19.
- 8.7.5 Removed (R9-Q8): no Undo button on CHECKED IN / CHECKED OUT (UAT PLY-20 removed).
- 8.7.6 More panel as drawn on the canvas board "Players · More panel" (R6-Q17): accordion under
  the row; sign-in ID + Save; level "− Intermediate (B1) +"; "Member / Casual / Disabled";
  delete (`btn.danger-outline`, F23); close; stats, partners, attendance. Disabled asks for
  confirmation, then checks the player out. The Sign-in ID field selects all its text on focus
  (F30). A duplicate ID on Save is refused with "ID {id} is used by {name}." (F23). UAT PLY-05,
  PLY-06, PLY-09, PLY-15. Two columns (Nathan, canvas comment 2026-10-22): left = sign-in ID,
  delete, close, level, membership; right = stat tiles, partners, attendance; a 1 px
  `#e4d8c4` line between them.
- 8.7.7 **Bug: exact sign-in-ID match must ignore the level chips (F01, P1).** Today
  `_onSearchSubmitted` (`lib/features/players/players_page.dart:258`) looks for the exact ID in
  `_listedPlayers()` (`players_page.dart:339-347`), which applies the level chips and the search
  text. So a card of a level that no chip selects gives NOT FOUND, and the operator may add a
  duplicate player. Fix: match the exact sign-in ID first over
  `PlayerRepository.instance.listedPlayers()` (all listed players, no chips, no query); only
  when no ID equals the text, use `_listedPlayers()` for the "only player in the list" fallback.
  Do not clear the chips. Write the failing test first in
  `test/features/players_scanner_test.dart`:
  `should_check_in_by_exact_sign_in_id_when_level_chip_hides_player` (Arrange: one chip on, the
  scanned player's tier not selected; Act: type the ID, Enter; Assert: the player is checked
  in). UAT PLY-14.
- 8.7.8 **As built (2026-10-21).**
  - Files: `lib/features/players/` `scan_field.dart` (`DesktopScanBar`), `scan_result.dart`
    (`ScanKind`, `ScanResult`), `scan_result_box.dart` (`ScanResultBox`),
    `desktop_player_row.dart` (`DesktopPlayerRow`, `DesktopPlayerTableHeader`),
    `more_panel.dart` (`MorePanel`); `PendingRegistrationCard(desktop: true)`;
    `players_page.dart` builds the desktop layout at ≥1080 px (`_buildDesktop`), and the PR 45
    layout below it (`_buildCompact`). The buttons reuse `CourtsButton` and `FocusRing`, and the
    Disabled and Delete confirms reuse `showCourtsConfirm` (one dialog pattern, F14).
  - Desktop order: scan row → result box → at-capacity banner → pending card → tier chips →
    table header → list (6 px between rows). The shell keeps its desktop padding (24 px sides,
    32 px top and bottom).
  - F01 (8.7.7) is fixed in the shared scan code, so phone and tablet get it too. The test
    `should_check_in_by_exact_sign_in_id_when_level_chip_hides_player` in
    `players_scanner_test.dart` uses the tablet Elo chips; the desktop tier-chip case is
    `should_check_in_by_exact_sign_in_id_when_tier_chip_hides_player`.
  - **Phone and tablet keep the PR 45 scan flow** (R6-Q7): bottom messages for scan results,
    no scanned-twice guard, all text selected also after many matches. Shared with desktop: the
    F01 match, Esc returns focus to the search field (F21), and the duplicate-ID refusal text
    "ID {id} is used by {name}." (F23) in the profile.
  - "waits for round {n}" reads `GameData.waitsForRound` (new getter): no lineup and READY →
    round n (1 at the start; the READY draft is not saved); RUNNING, PAUSED and TIME UP → n+1,
    or n+2 when round n+1 is saved; CHANGEOVER (also paused) → the starting round + 1. No doc
    names READY and TIME UP here.
  - "{X} takes Court {k} in round {n}" names the first `SlotFill` of `checkOutPlayer` (the
    earliest round, then the lowest court). In PAUSED a check-out can fill round n and a saved
    round n+1; the text names round n. No doc names this case.
  - Scanned-twice guard: `_lastScanCheckInId`, set by a scan check-in only, no time limit.
    It applies only while that player is checked in, so after a row-tap check-out the next
    scan checks the player in again. "Check out" in the box clears it.
  - Tier chips: no chip on = every tier; a chip on shows its tier (as on the canvas). The
    tablet Elo chips keep the old rule (all on = every level).
  - Membership in the More panel is a segmented choice "Member / Casual / Disabled" (the
    board), not the PR 45 cycle: a tap picks that state. Disabled for a checked-in player asks
    "Disable {name}?" first; not checked in, it sets at once.
  - The More panel says "Saved." under the field after a save; desktop shows no bottom message
    for a saved ID or a deleted player (bottom messages are only for a refused row tap, R4-Q1).
  - Tests (110 + 11): `test/features/players_scan_box_test.dart` (52),
    `players_row_test.dart` (27), `players_more_panel_test.dart` (31),
    `players_desktop_fit_test.dart` (11: pending card, no overflow at 1080 and 1280 px in en,
    fr, zh, zh_HK), `test/game_data_waits_for_round_test.dart` (8), harness
    `test/support/players_harness.dart`. `players_scanner_test.dart` keeps the tablet cases
    (not rewritten) plus the F01 cases. Integration: `players_test.dart` and
    `players_add_player_test.dart` use the desktop row, More panel and "Add player".
  - Not as the canvas: the shell padding (32 px top, canvas 16 px); the scan icon is the
    Material `qr_code_scanner` glyph; the row not checked in and the READY box have the
    `#e4d8c4` separator border (canvas `#8f826e`, ARCHITECTURE §2.4/§2.5 win); the Sign-in ID
    field has the `#6f6352` input border (canvas `#8f826e`); the Disabled TYPE text is muted
    `#6f6352` (canvas red); the pending line also shows the contact (PLY-01); "More" has
    `Semantics(expanded:)` but Flutter has no `aria-controls`.

### 8.8 — l10n keys (en, fr, zh, zh_HK)
New keys, prefix by feature. Courts: `courts_generate_round_one`, `courts_start_round` ("Start
round {n}", also round 1; replaces `courts_save_and_start_round` and `courts_save_and_start_new`),
`courts_discard_and_regenerate`, `courts_discard_and_start_round` ("Discard round {n} and start
again", R9-Q1; replaces `courts_discard_and_start_new`), `courts_discard_confirm_title`,
`courts_discard_confirm_body`, `courts_discard_confirm_action` (R9-Q3), `courts_pause`, `courts_resume_round`,
`courts_resume_changeover`, `courts_start_round_now`, `courts_end_round_confirm_title` ("End
round {n} now?"), `courts_end_round_confirm_body` ("{time} left.") (R12-Q1, F05; the button
reuses `courts_start_round`, Cancel reuses the existing cancel key), `courts_chip_ready`,
`courts_chip_running`, `courts_chip_paused`, `courts_chip_time_up`, `courts_chip_changeover`,
`courts_sub_not_started`, `courts_sub_paused`, `courts_sub_time_up`,
`courts_sub_players_to_courts`, `courts_counts_in_waiting`, `courts_next_not_saved`,
`courts_next_saved`, `courts_next_clock_stops`, `courts_next_starts_after`,
`courts_round_ended`, `courts_generate_next_round` (replaces `courts_make_round`, R13-Q3),
`courts_edit_round`, `courts_editing_round`,
`courts_save_round`, `courts_tag_next`, `courts_tag_players` ("{count} players", plural), `courts_slot_move_to_waitlist`,
`courts_slot_check_out`, `courts_swapped_undo` ("Swapped {a} and {b}. Undo"), `common_undo`
(the swap message action only),
`courts_end_session*`, `courts_waitlist_search_label`, `courts_waitlist_search_hint`,
`courts_waitlist_no_match`, `courts_waitlist_rounds_played` (plural), `courts_waitlist_next_in`.
Not in this build (on hold): `courts_round_started_undo`. Shell: `shell_session_header` (whole minutes "{m} min", else "{mm:ss}"),
`shell_tab_courts` (desktop), `shell_more_menu`, `shell_session_bar_*` (saved and not saved),
`shell_no_round_yet`, `shell_view_courts`. Players: `players_check_in_label`,
`players_scan_placeholder`, `players_count_in`, `players_places_left` (plural),
`players_add_player`, `players_scan_ready*`, `players_scan_in_waits`, `players_scan_out_takes`,
`players_scan_out`, `players_scan_twice`, `players_scan_not_found`, `players_scan_many`,
`players_scan_full`, `players_scan_disabled_more`, `players_scan_duplicate_id`. No Undo key
on Players (R9-Q8).
Design review keys (2026-10-20): `courts_close_unsaved_title` ("Close without saving?"),
`courts_close_unsaved_close` ("Close"), `courts_keep_editing` ("Keep editing") (R11-Q2, F03);
`courts_round_discarded` ("Round {n} discarded · new lineup for round {n}", F10);
`courts_tag_round` ("ROUND {n}", TIME UP card tag, F08); `courts_waitlist_hint_live` ("Courts
change at the next round", F11); `courts_end_session_body_round` ("Round {n} goes into the
history.") and `courts_end_session_nothing_logged` ("Nothing is logged."), each followed by
"Everyone is checked out." (F09); `players_id_used_by` ("ID {id} is used by {name}.", F23);
`players_disable_confirm_*` (F23); `sessions_reshuffle_confirm_*` and
`sessions_delete_template_confirm_*` (F25, for the Sessions task).
**Label width (F16).** In the build, check the PAUSED round bar at 1280 px in fr, zh and zh_HK
("Discard round {n} and start again", "Start round {n+1}", "Resume round {n}", "⋯"). If the
labels do not fit, PAUSED uses the short label `courts_discard_round_short` ("Discard round
{n}"); the dialog keeps the full text.
As built for Players (8.7.8): the result box has a name part and a text part, so each state
has a title and a text key: `players_scan_ready_title` / `_body`, `players_scan_not_found_title`
/ `players_scan_not_found`, `players_scan_many_title` (plural) / `players_scan_many`,
`players_scan_full_title` / `players_scan_full`, `players_scan_duplicate_title` /
`players_scan_duplicate_body` (plural; `players_scan_duplicate_id` stays for the tablet bottom
message); `players_scan_check_out`, `players_count_in`, `players_header_name`,
`players_header_sign_in_id`, `players_header_level`, `players_header_type`,
`players_membership_label`, `players_filter_by_level`, `players_row_checked_in`,
`players_row_not_checked_in`, `players_row_disabled`, `players_more_about`, `players_details`,
`players_lower_level`, `players_raise_level`, `players_delete_named`, `players_close_details`,
`players_id_saved`, `players_disable_confirm_title`, `players_disable_confirm_body`. The
Disabled confirm reuses `players_disable` and `cancel`. `players_sign_in_id_taken` stays for
the Add-player dialog.
As built for Sessions (8.10): `sessions_round_settings`, `sessions_round_duration`,
`sessions_duration_note_left` / `_next` / `_ready`, `sessions_duration_less` / `_more`,
`sessions_minutes`, `sessions_seconds`, `sessions_capacity_note` / `_over`,
`sessions_capacity_less` / `_more`, `sessions_courts_note`, `sessions_courts_less` / `_more`,
`sessions_changeover`, `sessions_changeover_value`, `sessions_save_settings_label`,
`sessions_saves_summary`, `sessions_template_summary_duration` (plural) /
`_duration_no_courts`, `sessions_load_named`, `sessions_delete_named`, `sessions_no_templates`,
`sessions_delete_template_confirm_title` / `_body`. The actions reuse `delete` and `cancel`.
The `sessions_reshuffle_confirm*` keys are removed (R13-Q1). Added 2026-10-22 (8.11):
`sessions_remove_court_title`, `_body`, `_option` (plural), `_action` (R13-Q9),
`courts_generate_next_round` (R13-Q3), `analytics_kpi_members`, `_members_context` (R13-Q10).
**l10n check (2026-10-21).** A script compared the 140 stage 8 keys in en, fr, zh and zh_HK:
no key is missing, the placeholders match, and every en plural is a plural in the other three.
Kept as they are: fr "Pause", "TYPE", "Minutes" and "{minutes} min" (French words equal to the
English); zh and zh_HK "Enter" (the key name). fr adds a plural to
`sessions_capacity_note` / `_over` ("1 présent", "2 présents"), which en does not need.
Fixed: `history` and `to_current_session` were en only and had no reader, so they are removed.
F16 measured in `test/features/courts_label_width_test.dart` (RUNNING and PAUSED at 1280 px,
real Source Sans 3, a system CJK font for zh): every bar label shows in full in all four
locales. In fr PAUSED the counts were cut ("20/20 présents · 4 en atte…"), because the width
check kept only 120 px for them. The check now keeps the full counts width, so fr PAUSED uses
`courts_discard_round_short` ("Annuler la manche {n}"); en, zh and zh_HK keep the full label.
The check also measures with the ambient text style, so Chinese is measured in YaHei or
JhengHei. A probe found no other cut text on the desktop Courts (every phase), Players and
Sessions tabs.
Not used (R7-Q7): `players_scan_in_joins`. Remove keys the build no longer reads (for example
`dashboard_rotate_now`, `dashboard_premake_next`, `dashboard_next_round_ready`,
`dashboard_mode_time_based`) only after a grep shows no reader.

### 8.9 — Tests (write first)
| Area | Test file (new unless noted) | UAT |
|---|---|---|
| Round state machine | `test/game_data_round_phase_test.dart` | RND-03…08, RND-11…20, RND-22 |
| Logging, round number, double-click guard (8.2.4) | `test/game_data_round_logging_test.dart` | RND-04, RND-06, RND-16, RND-19, RND-20 |
| Swap Undo (memento; a scan sets none, R9-Q8) | `test/game_data_undo_test.dart` | COURT-17 |
| Fill rule (one place), waitlist order, late player at 0 rounds, full round still uses `_choosePlayer` (8.4.0) | `test/game_data_fill_rule_test.dart` (replaces the level order in `game_data_waitlist_promotion_test.dart`) | WL-01…03, CHK-02, CHK-05, COURT-15, COURT-16 |
| Round bar, strip, edit mode, strip "Generate next round ({n+1})" (R13-Q3) | `test/features/courts_round_bar_test.dart` | RND-01, RND-02, RND-05, RND-09, RND-10, RND-15, RND-22 |
| Slot menu, re-roll visibility | `test/features/courts_slot_menu_test.dart` | COURT-01, COURT-10, COURT-14, COURT-15 |
| Swap Undo message | `test/features/courts_swap_undo_test.dart` | COURT-17 |
| Confirm dialogs: "×" asks first, End session text by state, early start confirm in RUNNING only (R12-Q1), focus and Esc, a phase change closes the dialog (R11-Q2, F03, F09, F14, F18) | `test/features/courts_confirm_dialog_test.dart` | RND-04, RND-06, RND-07, RND-16, RND-20 |
| Waitlist panel (scrolls, not pressable while the clock runs, no-lineup list) | `test/features/courts_waitlist_test.dart` | WL-01, WL-04, RND-12 |
| Shell | `test/shell/session_bar_test.dart`, `top_nav_test.dart` | NAV-01, NAV-09…11 |
| Duration change while paused | `test/timer_data_test.dart` (update) | SESS-02 |
| Scan result box; exact-ID match ignores the level chips (8.7.7, F01) | `test/features/players_scan_box_test.dart` (desktop); `players_scanner_test.dart` keeps the tablet cases and F01 (as built, 8.7.8) | PLY-14, PLY-16…19 |
| Player row, level chips | `test/features/players_row_test.dart` | PLY-05, PLY-06, PLY-08, NAV-08 |
| More panel | `test/features/players_more_panel_test.dart` | PLY-05, PLY-06, PLY-09 |
| Layout fit | `test/features/dashboard_four_courts_fit_test.dart` (update) | NAV-07 |
| Contrast | `test/design/contrast_test.dart` | ARCHITECTURE §1.1 |
| Sessions tab (desktop, 8.10) | `test/features/sessions_desktop_test.dart`, `test/game_data_court_count_test.dart` (update), `integration_test/sessions_test.dart` | SESS-01…06 |
| Round bar labels at 1280 px (F16, 8.8) | `test/features/courts_label_width_test.dart` | NAV-07, F16 |

### 8.10 — Sessions tab (desktop, R7-Q3)
Built 2026-10-21 from the canvas board "Sessions" (R7-Q3: no approval needed; Nathan fixes it
later in a separate task), with the decisions R9-Q6 (a duration change while paused applies at
once), `GameMode.enabled=false` (no round mode toggle), `CourtCount.editable=false` (no court
row) and F25. Tablet and phone keep the PR 45 layout (R6-Q7).
- **As built.**
  - Files: `lib/features/sessions/sessions_page.dart` (actions, tablet/phone layout, the shared
    `_DurationField` and `_NumberField` with a `desktop` look) and `desktop_sessions.dart`
    (`part`): `_DesktopSettingsCard`, `_DesktopTemplatesCard`, `SessionsStepButton`,
    `SessionsSaveButton`, `templateSummary`. The page picks the board at ≥1080 px
    (`isDesktop`).
  - Layout: two equal cards (`#fbf6ee`, 1 px `#e4d8c4`, radius 12, 20/600 title), 24 px apart,
    filling the page inside the shell padding. No page scroll at 1280×720; only the template
    list scrolls inside its card.
  - "Round settings": rows of 92 px (label 16/600, note 14/400 `#6f6352`; "−" value "+").
    Steppers 52×52, 1 px `#8f826e`, radius 10, 28/600, `#c2410c` focus ring, 45 % when off.
    Value boxes 128×52, white, 1 px `#6f6352` (3 px `#c2410c` with focus), 28/600 tabular.
    Round duration: the `mm:ss` fields (SESS-02 rules) and ±1 minute ("−" off at ≤1:00, "+" off
    at 99:59). Session capacity: the field (clamped 4…200) and ±1. Number of courts (only with
    `CourtCount.editable`, on from 2026-10-22): read-only value, "−" from 2 (opens "Remove which
    court?" when a court holds players, R13-Q9), "+" with no upper limit (R13-Q12), a live region. Changeover: "20 s ·
    fixed" (R3-Q7).
  - Duration note: "Applies now · round {n} has {mm:ss} left" while round n has its clock
    (RUNNING, PAUSED; it ticks); "Applies from round {n+1}" in TIME UP (and RUNNING at 0:00);
    "Applies from round {n}" in CHANGEOVER (the round that starts next); "Applies now to every
    round" before round 1. Capacity note: "{in} checked in · min 4", or "{in} checked in · no one
    is checked out" when the capacity is below the count (SESS-03).
  - "Session templates": caps label "SAVE CURRENT SETTINGS", name field 44 px, orange "Save
    current" 44 px (off with a blank name; Enter saves), the line "Saves {summary}". Rows of 64 px:
    name 16/600 (ellipsis), summary, "Load" (40 px, 1 px `#8f826e`, label "Load {name}") and a
    40×40 delete button (red bin, label "Delete {name}"). Empty list: "No templates yet".
  - Summary: "{duration} · {n} courts · cap {c}", duration as in the top nav ("10 min", else
    `m:ss`). With `CourtCount.editable` off the courts are left out ("10 min · cap 20"), because a
    Load keeps 4 courts.
  - F25 Load: duration (by `TimerData.updateDuration`, SESS-02), capacity and court count apply
    at once (Nathan 2026-10-22, R13-Q1: no reshuffle and no confirm for a new court count).
  - ~~Reshuffle confirm~~: removed (Nathan 2026-10-22, R13-Q1).
  - Delete confirm (desktop): "Delete template “{name}”?", "The template is deleted. The current
    settings do not change.", "Delete" / "Cancel". Tablet and phone have no delete button.
  - Data format unchanged: `session_templates.json` is read and written as before.
  - Tests: `test/features/sessions_desktop_test.dart` (65, harness
    `test/support/sessions_harness.dart`), two F25 cases in `test/game_data_court_count_test.dart`,
    `integration_test/sessions_test.dart` (4). `sessions_test.dart` (tablet) now drives real round
    phases and expects the F25 title; `layout_feedback_test.dart` measures the desktop buttons.
  - Not as the canvas: no bottom messages ("Loaded …", "Deleted …", "Courts reshuffled …"),
    because bottom messages are for errors and the listed cases only (ARCHITECTURE §2.8); no
    design note; the shell padding (32 px top and bottom, canvas 24); the "Reshuffle" button is
    red, as every Courts confirm (canvas orange); the bin is the Material `delete_outline` glyph;
    a focused value box draws a 3 px border, not an outline 2 px outside; the duration notes in
    READY and TIME UP and the reshuffle text follow UAT, not the canvas ("round 3 is past this
    length", "round 3 starts again"); the summary leaves out the courts when the flag is off.

### 8.11 — 2026-10-22 decisions (Nathan, R13-Q1 … R13-Q12)
As built (2026-10-22). Tests first, one commit per change.
- **Court count (R13-Q1, R13-Q12).** `CourtCount.editable = true`. Minimum 1, no upper limit
  (`saveTemplate` accepts any count from 1; `_maxCourts` is removed; the tablet field has no
  upper clamp). `setNumberOfCourt` and `loadTemplate` never reshuffle:
  `_applyCourtCount` drops courts beyond the count and pads empty courts in the live round,
  the saved round n+1 and the edit lineup (the edit base gets the same change, so the count
  alone is not an unsaved edit). The round phase and the clock do not change. Note under the
  control: "No reshuffle · a new court starts empty" (`sessions_courts_note`).
- **Remove a chosen court (R13-Q9).** Desktop "−": with a player on any court,
  `showRemoveCourtDialog` (`lib/features/sessions/remove_court_dialog.dart`, F14 pattern, last
  court selected first) returns the index; `GameData.removeCourt(index)` drops that court from
  every lineup, its players go to the waitlist, later courts move up one number. With every court
  empty, "−" removes the last court at once (as built; no decision covers it). The tablet field
  and a template with fewer courts remove from the end.
- **Hand fill (R13-Q7, R13-Q8).** `GameData.canHandFillCourt(i)`, `hasHandFillCourt`,
  `handFillSlot(player, i, slot)`: while `canEditCourts` is false (RUNNING, TIME UP,
  CHANGEOVER), a waitlist player can go into an open slot of a court with no players. The
  court id joins `_handFillCourtIds` at the first player, so the organizer can fill all 4
  places; the set is pruned when a round starts and cleared at End session. No auto fill. The
  round log takes the players on the court at the end of the round (test
  `test/game_data_hand_fill_test.dart`). The Courts tab lets the waitlist select and the open
  slot take the tap (`test/features/courts_hand_fill_test.dart`).
- **Generate next round (R13-Q3 … R13-Q6, overrides R12-Q2 / F28).** One strip button in
  RUNNING, PAUSED and TIME UP. `generateNextRound()` (was `makeNextRound`) works in TIME UP too.
  `quickSaveNextRound()` is removed. 0:00 with no saved round n+1 makes no lineup (the planned
  round of RND-15 is gone); TIME UP shows round n and locks it (`canEditCourts` is false in
  TIME UP without edit mode; choice: round n was played, so its log must not change). "×" in
  TIME UP drops the unsaved round n+1. `startNextRound()` works only with a saved round n+1; the
  round bar shows "Start round {n+1}" only then, in RUNNING and PAUSED (R13-Q5 names PAUSED;
  RUNNING follows the same rule, as built). TIME UP has "Discard round {n} and start again"
  only. In paused edit mode of a round n+1 that was never saved, the bar shows "Resume round
  {n}" only. The session bar text "· round {n+1} not saved" stays correct and is unchanged.
  Tests use `test/support/next_round_steps.dart` (`saveNewNextRound`, `saveAndStartNextRound`).
- **Settings (R13-Q2, R13-Q11).** `_MembershipCard` and `SettingsPage.showSignupPreview` are
  removed with their 4 keys. Settings shows the language card only.
- **Analytics (R13-Q10).** `computeMembersKpi` is the first KPI tile: players with membership
  Member (the old Settings count was every listed player). The desktop strip has 7 columns and
  tiles 144 px high. `TODO(Nathan)`: the fr label "OCCUPATION DES TERRAINS" is cut at 1280 px,
  with 6 columns too.

### Acceptance Criteria
> **UAT mapping:** NAV-01, NAV-06…11, RND-01…20, RND-22 (RND-21 on hold), COURT-01…17,
> WL-01…04, CHK-01…06, PLY-05, PLY-06, PLY-08, PLY-09, PLY-12…19 (PLY-20 removed), SESS-01…06 (8.10),
> ANA-02 and SET-02…04 removed (8.11).

- [ ] Every UAT ID above has a test that failed first and now passes
- [ ] All TODO(Nathan) points in UAT.md are answered and the specs updated
- [ ] The design canvas shows every decided change (R3-Q13), and the More panel is drawn (R5-Q1);
      the design-review canvas pass (8.0) is done
- [ ] F05 is built as decided: the RUNNING early start confirm, no dialog in PAUSED (R12-Q1).
      F28 (R12-Q2) is replaced by "Generate next round ({n+1})" (Nathan 2026-10-22, R13-Q3)
- [ ] Two fast clicks on any start or save button log round n once (R6-Q18, 8.2.4)
- [ ] No Courts round Undo ships (R6-Q6); no scan Undo ships (R9-Q8); the swap Undo has no
      keyboard shortcut (R7-Q2)
- [ ] A full round still comes from `_choosePlayer` + `_improveEloSpread`; the fill rule fills
      one place only (R10-Q1)
- [ ] `flutter analyze --fatal-infos --no-pub` passes; `flutter test` passes
- [ ] No test writes outside a temp dir (PERSISTENCE.md §6 phase 4)
- [ ] All new strings exist in en, fr, zh and zh_HK
- [ ] Manual check on Windows at 1280×720: 4 courts visible in every round state; Chinese text
      renders in YaHei (zh) and JhengHei (zh_HK)

---

## Cross-Cutting Rules (All Stages)

### State Management
- Continue using Provider + ChangeNotifier (existing pattern in `CLAUDE.md`)
- New pages read state via `context.watch<T>()` or `context.read<T>()`
- No new state management packages without explicit approval

### Code Generation
- Run `just generate` after modifying any freezed model
- Run `flutter gen-l10n` if adding new localized strings

### Testing
- Each stage adds widget tests for new widgets
- Business logic tests for interaction-heavy components (court re-roll, waitlist swap)
- At minimum: `flutter test` must pass after each stage

### Commit Strategy
- One commit per stage, or one commit per file group within a stage
- Use conventional commits: `feat(design): add color and typography tokens`

### Import Convention
- All design imports go through `package:good_bad_board/design/design.dart`
- Feature imports go through their barrel file
- No relative imports between feature directories

---

## File Tree (Target State)

```
lib/
├── main.dart                          # Updated: Provider setup, AppTheme.light()
├── routes.dart                        # Updated: GoRouter with ResponsiveShell
├── theme.dart                         # Updated: delegates to lib/design/
├── global.dart                        # Unchanged
│
├── design/                            # NEW
│   ├── design.dart                    # Barrel: exports all below
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   ├── app_radii.dart
│   ├── app_breakpoints.dart
│   ├── app_theme.dart
│   └── widgets/
│       ├── widgets.dart               # Barrel: exports all below
│       ├── app_card.dart
│       ├── app_stat_cell.dart
│       ├── app_kpi_card.dart
│       ├── app_section_title.dart
│       ├── app_button.dart
│       ├── app_chip.dart
│       ├── app_progress_bar.dart
│       ├── app_search_input.dart
│       ├── app_toggle_button.dart
│       └── app_tab_button.dart
│
├── shell/                             # NEW
│   ├── shell.dart                     # Barrel
│   ├── responsive_shell.dart
│   ├── top_nav_bar.dart               # Tablet (5 tabs)
│   ├── desktop_top_nav_bar.dart       # Desktop (8.6.1)
│   ├── session_bar.dart               # Desktop, every tab except Courts (8.6.2)
│   ├── inset_focus_ring.dart
│   ├── compact_header.dart
│   ├── bottom_tab_bar.dart
│   ├── hamburger_menu.dart
│   └── more_bottom_sheet.dart
│
├── features/                          # NEW (replaces flat lib/view/)
│   ├── dashboard/
│   │   ├── dashboard.dart
│   │   ├── dashboard_page.dart
│   │   ├── stat_strip.dart
│   │   ├── court_card.dart
│   │   ├── player_slot.dart
│   │   ├── spread_pill.dart
│   │   ├── round_rotation_bar.dart
│   │   ├── waitlist_sidebar.dart
│   │   └── waitlist_chips.dart
│   ├── players/
│   │   ├── players.dart
│   │   ├── players_page.dart
│   │   ├── player_row.dart
│   │   ├── level_adjuster.dart
│   │   ├── player_profile_card.dart
│   │   ├── pending_registration.dart
│   │   ├── scan_field.dart            # Desktop scan row (8.7.1)
│   │   ├── scan_result.dart           # ScanKind, ScanResult (8.7.2)
│   │   ├── scan_result_box.dart       # Desktop result box (8.7.2)
│   │   ├── desktop_player_row.dart    # Desktop row and header (8.7.3)
│   │   └── more_panel.dart            # Desktop More panel (8.7.6)
│   ├── sessions/
│   │   ├── sessions.dart
│   │   └── sessions_page.dart
│   ├── schedule/
│   │   ├── schedule.dart
│   │   └── schedule_page.dart
│   ├── analytics/
│   │   ├── analytics.dart
│   │   ├── analytics_page.dart
│   │   ├── kpi_strip.dart
│   │   ├── bar_chart.dart
│   │   ├── attendance_chart.dart
│   │   ├── court_utilization.dart
│   │   ├── level_distribution.dart
│   │   ├── elo_spread_chart.dart
│   │   └── player_mixing.dart
│   ├── settings/
│   │   ├── settings.dart
│   │   └── settings_page.dart
│   └── registration/
│       ├── registration.dart
│       ├── registration_page.dart
│       ├── level_selector.dart
│       └── confirmation_screen.dart
│
├── state/                             # Existing — unchanged
│   ├── game_data.dart
│   ├── persistent_setting.dart
│   └── timer_data.dart
│
├── repository/                        # Existing — unchanged
│   ├── repository_interface.dart
│   ├── player_repository.dart
│   ├── game_repository.dart
│   └── repository_service.dart
│
├── model/                             # Existing — may add fields
│   ├── player.dart
│   ├── player.freezed.dart
│   ├── player.g.dart
│   ├── game.dart
│   ├── game.freezed.dart
│   └── game.g.dart
│
├── core/                              # Existing — unchanged
│   ├── random.dart
│   ├── build_context_extension.dart
│   └── ...
│
└── l10n/                              # ARB files (en, fr, zh, zh_HK); keys use a
    ├── skill_tier_l10n.dart           #   feature prefix (dashboard_, players_, ...)
    └── membership_l10n.dart           # Localized enum labels; models stay string-free
```

### Files to Remove (by stage)

| Stage | File | Reason |
|-------|------|--------|
| 0 | `lib/spacing.dart` | Absorbed into `lib/design/app_spacing.dart` |
| 2 | `lib/view/landing_page.dart` | Replaced by `lib/shell/responsive_shell.dart` |
| 3 | `lib/view/game_maker_page.dart` | Replaced by `lib/features/dashboard/dashboard_page.dart` |
| 3 | `lib/view/component/court.dart` | Replaced by `lib/features/dashboard/court_card.dart` |
| 3 | `lib/view/component/inactive_player.dart` | Replaced by `lib/features/dashboard/waitlist_sidebar.dart` + `waitlist_chips.dart` |
| 4 | `lib/view/sign_in_page.dart` | Replaced by `lib/features/players/players_page.dart` |
| 6 | `lib/view/player_statistic_page.dart` | Replaced by `lib/features/analytics/analytics_page.dart` |

**Correction (post-Stage 7 review):** `lib/view/component/*` was not removed and should not be. `button.dart`,
`container.dart`, `dialog/add_player.dart`, `dialog/edit_player.dart`, and `dialog/toasts.dart` are active code —
the add/edit-player dialogs depend on them and neither was in scope for the `lib/design/widgets/*` rebuild. They
carry no old-palette colors (verified: no `stAndrewsBlue`/`goldRush`/hardcoded hex references remain). Keep them.
