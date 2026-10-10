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

1. **Navigation**: flat route list → responsive 6-tab shell (TopNavBar / BottomTabBar / HamburgerMenu depending on breakpoint)
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
| 5 | Check-in, Sessions, Schedule, Settings | Stages 1, 2 | Remaining tabs (check-in flow, round config, templates, schedule, notification toggles) |
| 6 | Analytics Dashboard | Stages 1, 2 | Analytics page with KPI strip, bar charts, progress bars, tables |
| 7 | Self-Registration & Polish | All prior | Self-registration page, responsive polish, theme integration |

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
Build the responsive navigation shell. The app detects breakpoint and renders the correct nav pattern. All 6 tabs are wired (Check-in was merged into the Players tab per UAT spec).

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
// Desktop layout (≥1080px): horizontal bar with club name + tab row in one row.
// Tablet layout (720–1079px): stacked — club name on top, scrollable tab row below.
// Props: clubName, subtitle, tabs (list of {label, isActive, onTap}), selectedIndex
// Dark bg (#221d18), club name in Space Grotesk 22px white.
```

#### 2.3 — `CompactHeader`
```dart
// Phone header: dark bar with club name (16px) + current tab label (11px).
// Optional hamburger button (38×38, radius 8px) at trailing edge.
// Props: clubName, currentTabLabel, showHamburger, onHamburgerTap
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
// Content: #221d18 bg, "NAVIGATE" label, vertical list of all 7 tabs.
// Active tab: accent bg, #221d18 text. Inactive: transparent, white.
// Props: tabs, selectedIndex, isOpen, onClose, onTabSelected
```

#### 2.6 — `MoreBottomSheet`
```dart
// Slide-up sheet from bottom.
// Drag handle: 38×4px, #e2d8c8.
// Lists secondary tabs: Sessions, Schedule, Analytics, Settings.
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
// Props: clubName, subtitle, tabLabels, pages (list of Widgets)
```

#### 2.8 — Route & Main Integration
```dart
// routes.dart: Replace current GoRouter with one that delegates to ResponsiveShell.
//   6 routes (/dashboard, /players, /sessions, /schedule, /analytics, /settings)
//   Check-in is integrated into the Players tab, not a separate route.
//   All wrapped in a shared ResponsiveShell via ShellRoute or custom builder.
// main.dart: Ensure ChangeNotifierProviders are above the shell.
//   Each page gets context.read<GameData>() etc. as needed.
// Initially: each page renders a placeholder with the tab name.
```

### Acceptance Criteria

> **UAT mapping:** NAV-01, NAV-02, NAV-03, NAV-04, NAV-05

- [x] **NAV-01** — Desktop/tablet (≥720px): top header bar with club name, session subtext, and all 6 tabs visible; compact header and bottom bar not shown
- [x] **NAV-02** — Phone (<720px): compact dark header with club short name + current tab label; 6-tab top row hidden
- [x] **NAV-03** — Phone bottom tab bar (default `phoneNav: tabbar`): 3 destinations — Courts (Dashboard), Players (with integrated check-in), More. Selecting More opens bottom sheet with Sessions/Schedule/Analytics/Settings; tapping scrim closes sheet without switching
- [x] **NAV-04** — "More" tab highlighted when current tab is Sessions, Schedule, Analytics, or Settings (secondary tabs)
- [x] **NAV-05** — Phone hamburger nav (`phoneNav: hamburger`): ☰ button in compact header, full-screen dark overlay listing all 6 tabs, current tab highlighted, scrim closes without switching
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
//   - Occupied: player name (14px, 600) + level/ELO (13px, 800, accent)
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
// Desktop layout: RoundRotationBar → StatStrip → [Court Grid (2 cols) + WaitlistSidebar]
// Non-desktop layout: RoundRotationBar → StatStrip → WaitlistChips → Court Grid (stacked)
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

> **UAT mapping:** NAV-06, NAV-07, RND-01…11, GB-01…07, COURT-01…09, WL-01, WL-02

#### Navigation & layout (shared with Stage 2 shell)
- [x] **NAV-06** — Stat strip reflow: desktop (≥1080px) 6 cols (Checked In, Remaining Slots, Waitlist, Avg Level, Avg Level Gap, Re-rolls); tablet (720–1079px) 3-per-row wrap; phone (<720px) 4 stats in 2×2 grid (Checked In, Waitlist, Avg Level, Remaining)
- [x] **NAV-07** — Dashboard layout reflow: desktop (≥1080px, incl. iPad landscape 1194px) 2-col court grid + fixed-width waitlist sidebar; tablet/phone (<1080px) waitlist chips above courts, courts stacked (2 cols tablet, 1 col phone). The grid itself renders with `shrinkWrap` + `NeverScrollableScrollPhysics`, so **both** layouts wrap it in a `SingleChildScrollView` — without it, courts past the first row are unreachable on desktop

#### Round rotation (RND-01…11) — time-based mode only
- [x] **RND-01** — Live `mm:ss` countdown, progress bar fill = remaining/D as percentage, updates at least once per second
- [x] **RND-02** — Urgency styling when ≤60s: countdown text + progress bar switch to amber (#ffb38a)
- [x] **RND-03** — Auto-rotation at 0:00: recomputes level-balanced court assignment from all checked-in players, increments round number, restarts countdown at full duration — no organizer action required
- [x] **RND-04** — "Rotate now" triggers immediate rotation: the finished round is logged via `GameData._logRound` (history + `SessionLog`, incomplete courts included so a clock expiry is never blocked), round increments, courts recomputed (or staged lineup adopted per RND-06), countdown restarts. A half-made lineup can neither block nor break it: `_improveEloSpread` swaps only between courts holding a full `Game.playerPerCourt` (it addresses all four slots by index, so a short court used to throw `RangeError`), and the dashboard's rotate handler catches `Error` as well as `Exception` and restarts the clock either way — an auto-rotation that died would strand the session on a finished round
- [x] **RND-05** — "Pre-make next round": computes staged lineup without changing live courts; a "NEXT ROUND · READY" panel appears with summary ("N players across M courts"), a striped progress bar that fills up, and the "Cancel next" button; the next round becomes the selected view so the courts show the plan
- [x] **RND-06** — Staged round becomes live: when countdown hits 0:00 or "Rotate now" is tapped, the previously staged lineup — including the organizer's edits — is adopted (not recomputed), the staged panel disappears and the selector returns to the current round
- [x] **RND-07** — Cancel staged: panel disappears, selector returns to the current round, "Pre-make next round" returns, live round unaffected
- [x] **RND-08** — Only one staged round at a time: "Pre-make" hidden while staged round exists
- [x] **RND-09** — Mode label: Time-based → "Time-based · {mm:ss} rounds"; Game-based renders no round bar at all. Switching mode does not force rotation
- [x] **RND-10** — Round selector: the two panels are radio buttons; the selected one is what the court grid, waitlist sidebar and stat strip show. The next round is fully editable (`GameData.visibleMatches` routes `placePlayerInSlot` / `makeSingleCourt` / `removePlayerFromCourt` through `_onLineup`), and `visibleWaitlistedPlayers` follows the round on screen so no player is double-booked or dropped. Court cards carry a NEXT badge; global Generate/Save are hidden on the next view
- [x] **RND-11** — The staged lineup does not go stale: `checkOutPlayer` / `removePlayer` drop the player from it, `onUpdatePlayer` refreshes it, and `setNumberOfCourt` pads it

#### Game-based mode (GB-01…07)

No clock. The committee drives each court: Regenerate → re-roll a court → Save → PLAYING →
re-roll when the game finishes → Save again.

- [x] **GB-01** — No countdown: `RoundRotationBar` is not built and `TimerData` is never started while the mode is game-based
- [x] **GB-02** — "Generate Game" is offered only while no court holds players (`GameData.hasAnyCourtLineup`); after the first lineup exists the button is hidden and courts are driven one at a time
- [x] **GB-03** — No global Save button in the action bar
- [x] **GB-04** — Per-court Save (`GameData.saveSingleGame`): writes the match to `GameRepository` and a `SessionLog` snapshot, leaves the four players on the court, and flags the court as playing
- [x] **GB-05** — PLAYING badge in the court header; Save hidden while playing; Re-roll stays available
- [x] **GB-06** — A playing lineup is locked: `placePlayerInSlot` is a no-op for a playing court and its slots are not tappable
- [x] **GB-07** — Re-roll ends the game: the court gets a new `Game` (so the playing flag clears by construction), drawn only from players not on any other court

#### Courts (COURT-01…09)
- [x] **COURT-01** — Each court shows: number, level-gap badge (0="Same level", N>0="N level gap"), up to 4 player rows (name + tier), "Open slot" italic for empty positions
- [x] **COURT-02** — Re-roll: evaluates multiple random 4-player combos from court occupants + full checked-in waitlist pool, selects lowest level gap, returns others to waitlist, increments re-roll count
- [x] **COURT-03** — Re-roll no-op when court occupants + waitlist ≤ 4 players: nothing changes, no re-roll count increment
- [x] **COURT-04** — Selecting a waitlisted player: highlighted as "selected", hint reads "Placing {name} — tap a court slot", court slots become interactive
- [x] **COURT-05** — Switching selection: tapping waitlisted player B while A selected moves selection to B directly
- [x] **COURT-06** — Deselecting: tapping already-selected player clears selection, hint reverts to "Tap a waitlisted player, then a court slot to place or swap them in."
- [x] **COURT-07** — Placing selected player into empty "Open slot": seated, removed from waitlist, selection clears
- [x] **COURT-08** — Swapping into occupied slot: two players trade places (selected takes slot, previous occupant → waitlist), selection clears
- [x] **COURT-09** — Court slots inert with no selection: tapping any slot does nothing

#### Waitlist (WL-01…02)
- [x] **WL-01** — Waitlist shows position number + name + level tier per entry; "No one waiting" when empty
- [x] **WL-02** — Auto-promotion on check-out: when a court slot opens (player checks out or set Disabled), highest-level waitlisted player(s) fill open slot(s), highest tier first — no organizer action required *(triggered by Stage 5 Check-in; logic lives in GameData)*

#### Quality gates
- [x] Widget tests for CourtCard, PlayerSlot, StatStrip (21 tests)
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
| Create | `lib/features/players/player_profile_card.dart` | Expandable profile with stats + sparkline |
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
//   - Level progression sparkline (polyline SVG → use CustomPaint or fl_chart)
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

> **UAT mapping:** PLY-01…12, NAV-08 (partial)

#### Pending registrations (PLY-01…03)
- [x] **PLY-01** — Pending card at top when ≥1 self-registration awaiting approval: name, estimated level, contact info, Approve/Reject buttons; hidden entirely when zero pending
- [x] **PLY-02** — Approve: creates active player with name + estimated tier as starting level, membership defaulted to Casual, not checked in; removed from pending list; appears in searchable player list immediately
- [x] **PLY-03** — Reject: removes applicant from pending list; no player record created

#### Player list & search (PLY-04, NAV-08)
- [x] **PLY-04** — Search filters by name (case-insensitive substring match) in real time; clearing search box shows all players
- [x] **NAV-08** — Table header row (Name/Level/Status/etc.) visible ≥720px; hidden <720px (only data rows)

#### Level, status, membership, check-in (PLY-05…08)
- [x] **PLY-05** — Level ±1 tier per click, clamped [Amateur…Professional]; "−" disabled (visually dimmed) at Amateur, "+" disabled at Professional
- [x] **PLY-06** — Membership cycles Member → Casual → Disabled → Member. Casual → Disabled while checked in requires confirmation (auto-checked-out, removed from court/waitlist, triggers WL-02 auto-promotion); not checked in needs no confirmation. Disabled → Member: no auto-check-in
- [x] **PLY-07** — Delete player (profile card): confirmation dialog, then permanent removal from the roster; triggers checkout/WL-02 if currently checked in
- [x] **PLY-08** — Check-in toggle inline behaves identically to Check-in tab (CHK-02/03/05), both tabs stay in sync
- [x] **PLY-13** — Add player: `AddPlayerDialog` closes itself and returns the player through `showDialog<Player>`; the caller only reads the result and awaits the repository write. Callers must never pop it — `showDialog` uses the root navigator while a page's context resolves to its `StatefulShellRoute` branch navigator, so popping from the caller unmounts the tab and blanks the screen. Covered by `integration_test/players_add_player_test.dart`

#### Expandable profile (PLY-09…12)
- [x] **PLY-09** — Tap name expands inline panel directly beneath row (not modal/drawer): membership status (+ "fee due" if Member with outstanding fee), 3 stat tiles (Current Level, Matches, Diversity %), level-progression sparkline, up to 3 most-frequent partners with match counts, session-attendance history summary (or "No sessions logged yet")
- [x] **PLY-10** — Only one profile expanded: tapping player B while A's profile open collapses A and expands B
- [x] **PLY-11** — Collapse: via "✕" in profile panel or tapping same player's name again
- [x] **PLY-12** — Profile stats computed from logged session history — unaffected by re-rolls or check-ins in the current live session until session is logged

#### Quality gates
- [x] `flutter analyze --no-pub` passes

---

## Stage 5 — Sessions, Schedule, Settings

### Goal
Implement the remaining 3 tabs (Sessions, Schedule, Settings). Check-in (CHK-01…06) was merged into the Players tab per UAT spec — its capacity bar, check-in/out toggles, and at-capacity banner are integrated directly into `PlayersPage`.

### Inputs
- Stages 0, 1, 2

### File Manifest

| Action | Path | Notes |
|--------|------|-------|
| Create | `lib/features/sessions/sessions_page.dart` | Session config + templates |
| Create | `lib/features/schedule/schedule_page.dart` | Recurring schedule cards |
| Create | `lib/features/settings/settings_page.dart` | Notifications + membership settings |
| Create | `lib/features/sessions/sessions.dart` | Barrel |
| Create | `lib/features/schedule/schedule.dart` | Barrel |
| Create | `lib/features/settings/settings.dart` | Barrel |
| Modify | `lib/routes.dart` | Wire all 3 tabs |

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

#### 5.2 — `SchedulePage`
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
- [x] **SESS-01** — Round mode toggle: Game-based / Time-based buttons with highlight; description updates ("Time-based · {mm:ss} rounds" / "Game-based · save and re-roll each court by hand"); duration control visible only for Time-based (RND-09)
- [x] **SESS-02** — `mm:ss` duration control: two digit fields in one box, clicking either selects the whole segment, `Tab` moves minutes → seconds; minutes clamped 0–99, seconds 0–59; a total of 0:00 restores the previous value; Dashboard countdown recalculates on next tick via `TimerData.updateDuration`, triggering immediate rotation if the new duration < time already elapsed
- [x] **SESS-03** — Session capacity change: stat strip / Check-in bar reflect immediately; a value below the minimum is **clamped up to 4** (`GameData.minSessionCapacity`), never raised back to the default of 20, and the number field writes the clamped value back so it cannot display a rejected number; no currently checked-in player bumped even if new capacity < current count — limit applies to future check-ins only
- [x] **SESS-04** — Courts count change (1–8): full reshuffle — every checked-in player unassigned and redistributed across new court count using level-sorted courts-of-4 logic
- [x] **SESS-05** — Save template: captures mode, duration (minutes **and** seconds), capacity, courts; blank/whitespace-only name is no-op; name field clears on success; summary shown (e.g. "4 courts · game-based · cap 20")
- [x] **SESS-06** — Load template: overwrites all 4 settings; triggers full reshuffle (same as SESS-04)

#### Schedule (SCHED-01)
- [x] ~~**SCHED-01**~~ **REMOVED 2026-10-10** — Schedule tab removed; session templates replace it. Was: read-only recurring session list: day, time window, descriptive note, "Auto check-in opens 30 min prior" badge per entry; no create/edit/delete controls in this build

#### Settings (SET-01…05)
- [x] ~~**SET-01**~~ **REMOVED 2026-10-10** (offline app, no notifications). Was: 3 independent notification toggles: Session reminders, Court assignment alerts, General announcements; each shows On/Off label
- [x] **SET-02** — Membership summary: total members (read-only, computed live from player roster). Fees outstanding removed 2026-10-10 (no fee data)
- [x] **SET-03** — Invite link removed 2026-10-10 (offline, no server). Keeps "Preview signup page →" link opening Self-Registration in new tab/window
- [x] **SET-04** — Level calibration note: explanatory text that new players self-estimate and organizers may override from Players tab (ref. PLY-05)
- [x] **SET-05** — Language picker (added 2026-10-10): chips with native language names; saves through `PersistentSetting.setLanguage`

#### Responsive & quality
- [x] **NAV-08** — All 4 pages respond to breakpoint changes (column layouts stack on phone, header rows hidden <720px)
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
| Create | `lib/features/analytics/analytics_engine.dart` | Pure computation layer for ANA-01…13 |
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
- [x] **ANA-01** — Time-range switcher: 4 wks / 12 wks / 26 wks segmented control, defaults to 12 wks; selecting different range recomputes all charts/KPIs against that window with "vs. prior period" deltas
- [x] **ANA-02** — KPI strip: 6 tiles — Active players, Avg attendance %, Retention (4wk) %, Court utilization %, Avg waitlist (per session), Re-rolls per session — each with labeled value and delta/context line vs prior period

#### Attendance & waitlist (ANA-03…04)
- [x] **ANA-03** — Attendance trend: per-session bar chart of checkedIn ÷ capacity; most recent session visually emphasized; growth note (e.g. "+X%") summarizing month-over-month change
- [x] **ANA-04** — Waitlist pressure: per-session bar chart of waitlisted counts; contextual note recommending capacity/schedule changes when avg waitlist ≥ ~2.5/session

#### Matchmaking fairness (ANA-05…06)
- [x] **ANA-05** — Level-gap trend: per-session bar chart of average level-gap per court (expressed as tier-gap, e.g. "1.2"); note whether trend is improving (gap shrinking) or not
- [x] **ANA-06** — Per-court comparison: horizontal bar per court showing average level-gap; flag courts with consistently wider gaps (overflow absorbers)

#### Court utilization & re-rolls (ANA-07…08)
- [x] **ANA-07** — Court utilization: horizontal bar per court showing fill rate; summary line with overall "full-4 fill rate" and average idle-court time per session
- [x] **ANA-08** — Re-rolls per session: bar chart with counts; note connecting spikes to high-attendance/high-level-spread nights

#### Level distribution (ANA-09)
- [x] **ANA-09** — Level distribution: 4-bar chart (Amateur/Intermediate/Advanced/Professional); summary with median tier and trend direction; stagnation callout ("N players flat 6+ sessions") when applicable
- **ANA-10 removed** (issue #42) — "Top level movers" needed two `Player` snapshots for the same id
  embedded in different `Game`s to compute a delta. Moving `Game` to `playerIds: List<String>` makes
  that unrepresentable, and `GameRepository` already only ever resolved a historical roster to the
  *current* player row, so the feature never showed a real delta from production data. See ADR-0001.

#### At-risk & mixing (ANA-11…13)
- [x] **ANA-11** — At-risk players: regular attendees (historically ≥2×/month) not seen in 3+ weeks; usual frequency + time since last seen; total "lapsed" count
- [x] **ANA-12** — Player mixing: horizontal bar per player showing 0–1 mixing score (distinct partners ÷ games played); tagged "connector" (high), "clique" (low), or "isolated" (very low); summary note
- [x] **ANA-13** — New player integration: recently joined players with join date, sessions attended, "% of games with regulars"; styled favorable (≥50%) or needs-attention (<50%); contextual note

#### Responsive & quality (ANA-14)
- [x] **ANA-14** — Responsive reflow: KPI strip and chart grids reflow from multi-column desktop to single-column phone, consistent with breakpoints in §1
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
