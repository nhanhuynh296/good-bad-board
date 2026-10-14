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

1. **Navigation**: flat route list → responsive 5-tab shell (TopNavBar / BottomTabBar / HamburgerMenu depending on breakpoint)
2. **File organization**: flat `lib/view/` → `lib/features/<feature>/` with barrel exports + `lib/design/` for shared tokens + `lib/shell/` for navigation
3. **Visual language**: blue/gold with Gotham → warm neutral (#fffdfa / #221d18 / #ff6a2b) with Space Grotesk display + Inter body
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

---

## Release Build Flags (batch 9b5ab49..692c492)

Four flags keep code in the tree but hide it in the release UI. All four default to `false`. Tests set them on to cover the hidden code.

| Flag | File | Effect when `false` |
|------|------|---------------------|
| `GameMode.enabled` | `lib/state/persistent_setting.dart` | `getGameType()` returns time-based. The stored `gameType` preference is never rewritten. The Sessions mode toggle is hidden. A template mode is ignored. GB-01…07 are hidden |
| `PlayersPage.showImportButton` | `lib/features/players/players_page.dart` | CSV Import button hidden |
| `SettingsPage.showSignupPreview` | `lib/features/settings/settings_page.dart` | "Preview signup page" link hidden. The `/register` route stays. REG-* is not reachable from the UI |
| `AnalyticsPage.showHiddenCards` | `lib/features/analytics/analytics_page.dart` | ANA-06 (per-court comparison) and ANA-12 (player mixing) hidden |

Other release changes: `Game.tierGap()` (4-tier gap, display only; logs keep `eloGap`); `GameData.defaultCourtCount` (4, not persisted); `NewPlayerEntry.needsAttention`; nullable retention in the KPI strip; `AppLoader` error screen (`app_load_error`). Release tests: `test/features/release_time_mode_test.dart`, `test/game_data_release_fixes_test.dart`, `test/features/dashboard_release_fixes_test.dart`, `test/features/dashboard_four_courts_fit_test.dart`, `test/timer_data_test.dart`, `test/app_loader_error_test.dart`, `test/features/players_scanner_test.dart`, `test/features/players_add_dialog_test.dart`.

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

#### 0.2 — `app_typography.dart`
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

#### 2.1 — `AppTabButton`
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

- [x] **NAV-01** — Desktop/tablet (≥720px): top header bar with session subtext and all 5 tabs visible (no club name); compact header and bottom bar not shown
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

#### 3.1 — `PlayerSlot`
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

#### 3.4 — `WaitlistSidebar`
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

#### 3.6 — `StatStrip`
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

#### 3.8 — `RoundRotationBar`
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
- [x] **NAV-06** — Stat strip reflow: desktop (≥1080px) 6 cols (Checked In, Remaining Slots, Waitlist, Avg Level, Avg Level Gap, Re-rolls); tablet (720–1079px) 3-per-row wrap; phone (<720px) 4 stats in 2×2 grid (Checked In, Waitlist, Avg Level, Remaining). Breakpoint from the viewport width (`MediaQuery.sizeOf`), not the content width. Phone 4th cell reads "Remaining" (`dashboard_stat_remaining`). "Avg Level" and "Avg Level Gap" use `Game.tierGap()`; Avg Level shows a tier name, not an Elo code
- [x] **NAV-07** — Dashboard layout reflow: desktop (≥1080px, incl. iPad landscape 1194px) court grid + fixed-width waitlist sidebar; tablet/phone (<1080px) waitlist chips above courts, courts stacked (2 cols tablet, 1 col phone). Desktop: `courtGridLayout` (`lib/features/dashboard/court_grid_layout.dart`, ported from main's `getIdealNumberOfColumn`) picks the column count with the largest court that fits the free height and stretches rows to fill it; `courtGridLayout(minCourtHeight:)` (the desktop passes `_minDesktopCourtHeight` = 136px) lets a court be flatter than 1.6:1 down to that height, but never under 320px wide or taller than wide, so 4 courts fit at 1280x720, 1366x768, 1440x900 and 1920x1080 (`test/features/dashboard_four_courts_fit_test.dart`). `CourtCard` and `PlayerSlot` use compact padding when the card is under 200px tall (`compact`). When nothing fits it uses the most columns and the grid scrolls itself (more than 4 courts). Known limit: with a staged next round the rotation bar is taller, and the courts may scroll at 1280x720 and 1366x768. Stacked layouts keep `shrinkWrap` + `NeverScrollableScrollPhysics` inside the page `SingleChildScrollView`. Court slots are `Expanded`, so the card has no empty band below the last slot. Breakpoint from the viewport width; stacked grid caps columns with `courtGridLayout(maxColumnCount:)` (2 tablet, 1 phone). Tests: `test/features/dashboard_breakpoints_test.dart`. Stacked layout: the whole page scrolls (stat strip, bars, chips, courts)

#### Round rotation (RND-01…11) — time-based mode only
- [x] **RND-01** — Live `mm:ss` countdown, progress bar fill = remaining/D as percentage, updates at least once per second
- [x] **RND-02** — Urgency styling when ≤60s: countdown text + progress bar switch to amber (#ffb38a)
- [x] **RND-03** — Auto-rotation at 0:00: recomputes level-balanced court assignment from all checked-in players, increments round number, restarts countdown at full duration — no organizer action required
- [x] **RND-04** — Global Save (`GameData.saveCurrentGame`) keeps one empty court per court, clears the staged next round (`_stagedLineup = null`), returns to `RoundView.current`, and throws "No game to save" when no court holds a player. "Rotate now" triggers immediate rotation: the finished round is logged via `GameData._logRound` (history + `SessionLog`, incomplete courts included so a clock expiry is never blocked), round increments, courts recomputed (or staged lineup adopted per RND-06), countdown restarts. A half-made lineup can neither block nor break it: `_improveEloSpread` swaps only between courts holding a full `Game.playerPerCourt` (it addresses all four slots by index, so a short court used to throw `RangeError`), and the dashboard's rotate handler catches `Error` as well as `Exception` and restarts the clock either way — an auto-rotation that died would strand the session on a finished round
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

#### 4.1 — `LevelAdjuster`
```dart
// Row: [−] button + level text (13px, 800, accent, 82px wide) + [+] button.
// Buttons: 20–22px square, bg=pillBg, text=textPrimary, radius=6px.
// Disabled at tier boundaries: Amateur (tier 0, minus disabled), Professional (tier 3, plus disabled).
// Disabled state: opacity 0.35.
// Props: currentLevel(String), canDecrease, canIncrease, onDecrease, onIncrease
```

#### 4.2 — `PlayerRow`
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
- [x] **PLY-08** — The row tap is the check-in toggle (tap = in / out) and performs CHK-02/03/05 directly (no separate Check-in tab). Design in `lib/features/players/player_row.dart`: no In/Out pill and no "Checked in" column; Disabled rows ignore taps (CHK-06); at capacity the tap is refused with the capacity message (CHK-03). The header has Name/ID, Level, Membership and a blank More column (`PlayerRow.moreColumnWidth` = 100)
- [x] **PLY-13** — Add player: `AddPlayerDialog` closes itself and returns the player through `showDialog<Player>`; the caller only reads the result and awaits the repository write. Callers must never pop it — `showDialog` uses the root navigator while a page's context resolves to its `StatefulShellRoute` branch navigator, so popping from the caller unmounts the tab and blanks the screen. Covered by `integration_test/players_add_player_test.dart`

#### Expandable profile (PLY-09…12)
- [x] **PLY-09** — The "More" button (`AppButton.secondary` with a chevron `trailingIcon`, `players_more`) opens the inline panel directly beneath the row; a row tap does not open it (it toggles check-in). More, level −/+ and membership taps never toggle check-in; a dimmed −/+ does nothing. Row + panel share one rounded `AppCard` (`player-accordion-panel`), the profile has no card chrome of its own; chevron down when hidden, up when shown (not modal/drawer): membership status, 3 stat tiles (Diversity % = distinct co-players ÷ other listed players) (Current Level, Matches, Diversity %), up to 3 most-frequent partners with match counts, session-attendance history summary (or "No sessions logged yet"). The level progression sparkline is removed
- [x] **PLY-10** — Only one profile expanded: tapping the More button of player B while A's profile open collapses A and expands B
- [x] **PLY-11** — Collapse: via "✕" in profile panel or tapping the same player's More button again
- [x] **PLY-12** — Profile stats computed from logged session history — unaffected by re-rolls or check-ins in the current live session until session is logged. `computePlayerProfileStats` (`lib/features/players/player_profile_stats.dart`) reads `GameRepository` + `SessionLogRepository` caches; `PlayersPage` listens to both. Not `GameData.history`

#### Scanner and sign-in ID (PLY-14, PLY-15)
- [x] **PLY-14** — Barcode scan check-in: the search field is focused when the Players tab opens (and gives up focus when the tab is hidden). `_onSearchSubmitted` in `players_page.dart` runs on Enter (`AppSearchInput.onSubmitted`, which also covers the keyboard done action); no debounce (two fast scans both count); Enter during an IME composition is ignored (`Focus.onKeyEvent`). `_refocusSearch` gives the field focus again after row taps (`AppSearchInput.onTapOutside` replaces the desktop unfocus), profile toggles and dialogs, unless another `EditableText` has focus; a row tap clears a stale query. Target: the one listed player whose sign-in ID equals the text (trimmed, case-insensitive), else the only player in `_listedPlayers()` (search + level chips). The target is toggled: check in (capacity and Disabled rules apply, `players_scan_checked_in`) or check out (`players_scan_checked_out`). Disabled: `players_scan_disabled`. At capacity: the capacity message. Empty list: `players_scan_no_match`. Many listed and no exact ID: nobody changes, `players_scan_many_matches`. Two exact IDs: nobody changes, `players_scan_duplicate_id`. In all cases `_selectSearchText` keeps the text, selects all of it (again after the frame) and keeps focus, so the result stays listed and the next scan replaces the text. Empty field: nothing. Test: `test/features/players_scanner_test.dart`
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
- [x] **SESS-04** — Courts count change (1–8; default `GameData.defaultCourtCount` = 4, not persisted; Dashboard stepper clamped 1..8): full reshuffle — every checked-in player unassigned and redistributed across new court count using level-sorted courts-of-4 logic. Shared `confirmDiscard` (`lib/features/dashboard/discard_confirmation.dart`) asks first when a time-based round is running and `GameData.wouldReshuffleLineup`; Cancel keeps the count. No lineup is generated when no court holds players or <4 are checked in (reducing the count then returns players on removed courts to the waitlist, `_dropCourtsBeyondCount`; raising it pads `stagingMatches` with empty courts, also after Save and on template load). A re-roll or a court-count change clears the selected player
- [x] **SESS-05** — Save template: captures duration (minutes **and** seconds), capacity, courts; blank/whitespace-only name is no-op; name field clears only when `saveTemplate` returns `true`; summary shown as "N courts · cap C" with no mode (`sessions_template_summary_no_mode`)
- [x] **SESS-06** — Load template: overwrites duration, capacity and courts; the template mode is ignored in release; triggers full reshuffle (same as SESS-04); same confirmation

#### Schedule (SCHED-01)
- [x] ~~**SCHED-01**~~ **REMOVED 2026-10-10** — Schedule tab removed; session templates replace it. Was: read-only recurring session list: day, time window, descriptive note, "Auto check-in opens 30 min prior" badge per entry; no create/edit/delete controls in this build

#### Settings (SET-01…05)
- [x] ~~**SET-01**~~ **REMOVED 2026-10-10** (offline app, no notifications). Was: 3 independent notification toggles: Session reminders, Court assignment alerts, General announcements; each shows On/Off label
- [x] **SET-02** — Membership summary: total members (read-only, computed live from player roster). Fees outstanding removed 2026-10-10 (no fee data). `ListenableBuilder` on `PlayerRepository.listenable`
- [x] **SET-03** — Invite link removed 2026-10-10 (offline, no server). Keeps "Preview signup page →" link opening Self-Registration in new tab/window. **Hidden in release (`SettingsPage.showSignupPreview=false`);** the `/register` route is kept
- [x] **SET-04** — Level calibration note: explanatory text that new players self-estimate and organizers may override from Players tab (ref. PLY-05)
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
- [x] **ANA-02** — KPI strip: 6 tiles — Active players, Avg attendance %, Retention (4wk) %, Court utilization %, Avg waitlist (per session), Re-rolls per session — each with labeled value and delta/context line vs prior period. Active players = distinct players in games in the range. Retention = share of players seen in the 4 weeks before the last 4 who came back. Retention is nullable: the value and delta show "—" when there is no base. The delta line shows "—" when the prior period has no players or sessions

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
- [x] Dark mode: not supported. The redesign has a light palette only, so `MyApp` uses `ThemeMode.light`. A dark system theme changed only Material defaults (white text in light text fields)
- [ ] All breakpoints tested with window resize *(rendered at 390, 900 and 1400 px wide in widget tests; a live resize on Windows is still a manual check)*
- [x] Full `flutter analyze --fatal-infos --no-pub` passes (0 issues)
- [x] All existing tests pass (`flutter test`) — 375 passing, 0 failing
- [ ] App launches and navigates correctly *(needs manual check — not run interactively)*
- [x] Old inline theme code is fully removed (`lib/theme.dart` has zero references to the old `stAndrewsBlue`/`goldRush` palette; `lib/view/` retains only `component/` — the still-active dialogs and helpers, not old theme code)

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
│   ├── top_nav_bar.dart
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
│   │   └── pending_registration.dart
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
