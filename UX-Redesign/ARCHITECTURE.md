# ARCHITECTURE.md — Riverside Badminton Club Design System

> Extracted from the UX-Redesign HTML handoff (`Badminton App.dc.html`, `Analytics Dashboard.dc.html`, `Dashboard Options.dc.html`, `Responsive Layouts.dc.html`, `Self Registration.dc.html`).
> This document defines a **reusable design system** to guide the Flutter implementation.

---

## 1. Design Tokens

### 1.1 Color Palette

#### Primary Theme: "Clubhouse" (Light/Warm)

| Token | Value | Usage |
|-------|-------|-------|
| `color.page.bg` | `#fffdfa` | Page / scaffold background |
| `color.card.bg` | `#fbf6ee` | Card, panel, modal surface |
| `color.card.border` | `#eee4d8` | Card border, divider lines |
| `color.header.bg` | `#221d18` | Top nav, header bar |
| `color.header.text` | `#ffffff` | Header title text |
| `color.header.sub` | `#c9c2b8` | Header subtitle / inactive tab |
| `color.accent.primary` | `#ff6a2b` | Primary action, selected state, ELO value, waitlist count |
| `color.accent.onPrimary` | `#221d18` | Text on accent background (or `#ffffff`) |
| `color.text.primary` | `#221d18` | Headings, body text |
| `color.text.muted` | `#8a7c68` | Secondary text, stat labels |
| `color.text.subtle` | `#b3a891` | Placeholder, disabled, tertiary text |
| `color.pill.bg` | `#f0e6d6` | Chip/pill background, inactive toggle |
| `color.success` | `#2ea043` | Check-in confirmed, active status |
| `color.success.bg` | `#e6f4ea` | Success chip background |
| `color.warning.text` | `#a8481a` | Warning / at-capacity text |
| `color.warning.bg` | `#fdeee4` | Warning background |
| `color.error` | `#f44336` | Form error border and text (`AppColors.error`) |
| `color.bar.secondary` | `#221d18` | Secondary chart bar color (dark) |
| `color.bar.tertiary` | `#ffb38a` | Tertiary chart bar (light orange) |

#### Alternative Themes (from `Dashboard Options.dc.html`)

| Theme | Accent | Header Bg | Mood |
|-------|--------|-----------|------|
| `command` | `#1f7a74` (teal) | `#16202b` | Professional, calm |
| `playful` | `#ff4d6d` (pink) | `#2b1533` | Bold, rounded cards |

#### Dark Theme (1c — "Command Center")

| Token | Value |
|-------|-------|
| Page bg | `#12141c` |
| Card bg | `#181b26` |
| Card border | `#262a38` |
| Accent | `#e94ff5` (pink) |
| Secondary accent | `#c4ff5c` (lime) |

### 1.2 Typography

| Token | Family | Weights | Usage |
|-------|--------|---------|-------|
| `font.display` | `Space Grotesk` | 700 | Page titles, section headings, court labels, KPI values |
| `font.body` | `Inter` | 400, 500, 600, 700, 800 | Body text, player names, buttons, labels |

**Type Scale:**

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `text.xs` | 10px | 700 | Stat strip labels, KPI labels |
| `text.kpiLabel` | 10.5px | 800 | Analytics KPI labels (`AppTypography.kpiLabel`) |
| `text.input` | 14px | 500 | Text input value and hint (`AppTypography.input`) |
| `text.xs2` | 11px | 600–700 | Helper text, hints, table headers, chart labels |
| `text.sm` | 12px | 500–700 | Secondary info, tab buttons, chip text |
| `text.base` | 13px | 500–600 | Body text, list items, form labels |
| `text.md` | 14px | 600–700 | Player names, section titles |
| `text.lg` | 15px | 700 | Card titles (Space Grotesk) |
| `text.xl` | 16–19px | 700–800 | Stat values, header titles |
| `text.2xl` | 20–22px | 700–800 | KPI values (dashboard) |
| `text.3xl` | 24–26px | 700–800 | Page titles, large KPI values |

### 1.3 Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `space.1` | 1px | Grid dividers (stat strip) |
| `space.xs` | 4px | Tab button gaps, inline gaps |
| `space.sm` | 6–8px | Small gaps, chart bar gaps, button gaps |
| `space.md` | 10–12px | List item gaps, card gaps (compact) |
| `space.lg` | 16px | Standard card gaps, section gaps |
| `space.xl` | 20–24px | Layout gaps (sidebar, main content) |
| `space.2xl` | 32px | Content padding (desktop) |

**Content Padding (responsive):**

| Breakpoint | Padding | Density: Compact |
|------------|---------|------------------|
| Desktop (≥1080px) | `24px 32px 32px` | `16px 22px 24px` |
| Tablet (720–1079px) | `20px 24px 28px` | `14px 18px 20px` |
| Phone (<720px) | `14px 12px 20px` | Same |

### 1.4 Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius.sm` | 6px | Small buttons, bar ends |
| `radius.md` | 8px | Buttons, inputs, tabs |
| `radius.lg` | 10px | Compact cards, menu items |
| `radius.xl` | 12px | Cards, panels |
| `radius.2xl` | 14px | Large cards, KPI cards (analytics) |
| `radius.full` | 999px | Chips, pills, badges |

### 1.5 Breakpoints

| Token | Range | Layout |
|-------|-------|--------|
| `bp.phone` | <720px | Single column, bottom tab bar or hamburger |
| `bp.tablet` | 720–1079px | 3-col stat strip, stacked courts |
| `bp.desktop` | ≥1080px | Full 7-tab nav, sidebar layout |

---

## 2. Component Catalog

### 2.1 Navigation

#### TopNavBar
```
Desktop/Tablet: horizontal bar, dark bg (#221d18)
├── Club name (Space Grotesk, 22px, white)
├── Subtitle (12px, #c9c2b8)
└── TabRow: scrollable row of TabButton pills
```
- Active tab: `bg=accent, color=onAccent, radius=8px, padding=8px 12px`
- Inactive tab: `bg=transparent, color=#c9c2b8`

#### CompactHeader (Phone)
```
Phone: dark bar, flex row
├── Club name (16px, white) + current tab label (11px, #c9c2b8)
└── Hamburger button (optional, 38×38, border-radius 8px)
```

#### BottomTabBar (Phone)
```
3 tabs: Courts, Players, More
├── Icon + label (10px)
├── Active: color=accent
└── Inactive: color=#8a7c68
```
Note: Check-in functionality is integrated into the Players tab (CHK-01…06).

#### HamburgerMenu (Phone)
```
Dark overlay (#221d18)
├── "Navigate" label (11px, uppercase)
└── Vertical list of all 7 tabs
    ├── Active: bg=accent, color=#221d18
    └── Inactive: bg=transparent, color=white
```

#### MoreBottomSheet (Phone)
```
Slide-up sheet from bottom
├── Drag handle (38×4px, #e2d8c8)
└── List of secondary tabs (Sessions, Schedule, Analytics, Settings)
    ├── Chevron on right
    └── Active: color=accent
```

### 2.2 Data Display

#### StatStrip
```
Horizontal grid of StatCell items
├── Desktop: 6 columns
├── Tablet: 3 columns
└── Phone: 2×2 grid
```

#### StatCell
```
Card with label/value pair
├── Label: 10px, 700, uppercase, #8a7c68, letter-spacing 0.05em
├── Value: 19px, 800, #221d18 (or accent for waitlist/ELO)
└── Background: page.bg, 1px border between cells
```

#### KpiCard
```
Larger stat card for analytics
├── Label: 10.5px, 800, uppercase, #8a7c68
├── Value: 26px, Space Grotesk 700, #221d18
└── Delta: 11px, 700, green (#2e7d4f) or red (#c2410c)
```

#### Card
```
Container with:
├── bg: #fbf6ee
├── border: 1px solid #eee4d8
├── radius: 12px
└── padding: 16px 18px
```

#### SectionTitle
```
├── Font: Space Grotesk, 700
├── Size: 15px (card title) / 14px (tight variant)
└── Color: #221d18
```

### 2.3 Court & Game

#### CourtCard
```
Card variant containing:
├── Header row:
│   ├── "COURT N" (Space Grotesk, 15px, 700)
│   ├── SpreadPill (11px, pill bg, radius 999px)
│   └── ReRollButton (accent bg, 11px)
└── 4× PlayerSlot rows
```

#### PlayerSlot
```
Row within court card:
├── Occupied:
│   ├── Player name (14px, 600)
│   └── Level tier, e.g. "Intermediate" (13px, 800, accent color; no Elo on court)
└── Empty:
    └── "Open slot" (13px, italic, #b3a891)
```

#### SpreadPill
```
Chip showing level gap
├── bg: #f0e6d6
├── color: #8a7c68
├── font: 11px, 700
├── radius: 999px
└── padding: 4px 8px
```

#### RoundRotationBar
```
Dark bar positioned between StatStrip and court grid on the Dashboard tab.
Displays round progress, a live countdown timer, and rotation controls.

The two sections below are radio buttons. Exactly one is selected, and the
selected one is the round the court grid renders and edits. The radio header
strip only appears once a next round exists — before that there is no choice
to make.

├── Current-round panel [key: round-panel-current]:
│   ├── Radio header (conditional): dot + "CURRENT ROUND" (10px, 800)
│   ├── "ROUND N" (Space Grotesk, 20px, 700, white) + mode label (12px, #c9c2b8)
│   ├── Countdown timer (26px, 800, tabular-nums, white) + "until rotation" (11px, #c9c2b8)
│   ├── Action buttons (12px):
│   │   ├── "Pre-make next round" — ghost button, shown when no round is staged
│   │   └── "Rotate now →" — accent-filled primary button, always visible
│   └── Progress bar:
│       ├── Track: rgba(255,255,255,0.14), height=10px, radius=999px
│       ├── Fill: accent (#ff6a2b) normally, barTertiary (#ffb38a) when urgent (≤60s)
│       └── Transition: width 0.9s linear
└── Next-round panel [key: round-panel-next] (conditional, fades in):
    ├── Divider: 1px solid rgba(255,255,255,0.12)
    ├── Radio header: dot + "NEXT ROUND" (10px, 800, #ffb38a when selected)
    ├── Badge row: "NEXT ROUND · READY" (10px, 800, bg=#ffb38a, color=#221d18,
    │   radius=999px) + "Cancel next" ghost button, right-aligned
    ├── Summary text (12px, #c9c2b8): "N players placed across M courts"
    └── Dashed progress bar: striped gradient (#ffb38a), height=8px, radius=999px

Selection styling: selected panel = 2px accent border (accent #ff6a2b for
current, #ffb38a for next) at full opacity; unselected = transparent border,
0.55 opacity. Accessibility: Semantics(selected:, button:) on each panel.
```

**Timer states:**

| State | Timer Color | Progress Bar Color |
|-------|-------------|-------------------|
| Normal (>60s remaining) | `#ffffff` | `#ff6a2b` (accent) |
| Urgent (≤60s remaining) | `#ffb38a` | `#ffb38a` |

**Actions:**

| Action | Description |
|--------|-------------|
| `rotateNow` | Logs the finished round (history + `SessionLog`), then adopts the pre-made round — or a fresh draw if none — and returns the grid to the current round |
| `stageNext` | Pre-computes the next round's court assignments without applying them, and selects the next round so the courts show the plan |
| `cancelStaged` | Clears the pre-made round and returns the grid to the current round |
| `selectView` | Chooses which round the court grid, waitlist sidebar and stat strip show (`RoundView.current` / `RoundView.next`) |

### 2.4 Lists & Tables

#### PlayerRow
```
Table list row with:
├── Whole row tappable for profile; trailing expand/collapse arrow
├── Name (14px, 600, accent when profile is open)
├── ID code (12px, #b3a891)
├── Level adjuster: [−] button + value (13px, 800, accent) + [+] button
│   └── Buttons: 20–22px square, bg=#f0e6d6, radius=6px
├── Membership toggle (Member/Casual/Disabled)
└── Check-in toggle (In/Check in)
```

#### ExpandablePlayerProfile
```
Expanded panel below player row (row + panel share one rounded card):
├── Close button (✕)
├── Stat trio: Current Level | Matches | Diversity
│   └── Each: value (18–20px, 800) + label (10px, 700, #8a7c68)
├── Level progression sparkline (SVG polyline, accent stroke)
├── Most frequent partners list (name + count)
└── Attendance history text
```

#### WaitlistItem
```
Selectable player row:
├── Unselected: bg=transparent, cursor=pointer
├── Selected: bg=accent, color=white, radius=8px
└── Content: position number + name + level tier
```

#### WaitlistChip (stacked/phone layout)
```
Pill variant for horizontal waitlist:
├── Unselected: bg=#f0e6d6, color=#221d18
├── Selected: bg=accent, color=white
└── radius: 999px, padding: 7px 11px
```

### 2.5 Forms & Inputs

#### SearchInput
```
Full-width text field
├── padding: 10–14px
├── border: 1px solid #e2d8c8
├── radius: 8px
├── font: 14px, Inter
└── placeholder: "Search players…"
```

#### NumberInput
```
Constrained number field
├── width: 100px
├── padding: 8px 10px
├── Same border/radius as SearchInput
└── font: 13px
```

#### RangeSlider
```
Full-width slider
├── Label above: "Rotation duration: N min"
├── Min/Max/Step defined per use
└── accent color track
```

#### ToggleButton (On/Off)
```
Binary toggle for settings
├── On: bg=#2ea043, color=white, radius=6px
├── Off: bg=#e5e5e5, color=#555, radius=6px
├── font: 11px, padding: 5px 12px
└── Label text beside
```

#### LevelSelector (Self Registration)
```
Vertical list of selectable cards
├── Unselected: bg=#fbf6ee, border=1px solid #eee4d8, color=#221d18
├── Selected: bg=#221d18, border=1px solid #221d18, color=white
├── Content: title (14px, 700) + description (12px)
└── radius: 9px, padding: 12px 14px
```

### 2.6 Buttons

| Variant | Background | Color | Radius | Padding | Font |
|---------|-----------|-------|--------|---------|------|
| `btn.primary` | `accent` | `onAccent` | 8px | 6–8px 10–14px | 11–12px, 700 |
| `btn.secondary` | `#f0e6d6` (pillBg) | `#221d18` | 8px | 6px 12px | 11px |
| `btn.success` | `#2ea043` | `white` | 6px | 5px 9–12px | 11px |
| `btn.danger-outline` | transparent | `#a3a3a3` | 6px | 5px 9px | 11px |
| `btn.ghost` | transparent | `#b3a891` | — | — | — |
| `btn.icon` | `#f0e6d6` | `#221d18` | 6px | 22px square, 14px glyph | 800 |

### 2.7 Charts & Data Viz

#### BarChart
```
Horizontal bars with optional labels
├── Bars: flex=1, variable height, border-radius=3-5px
├── Color: accent (highlight) or #e8dcc8 (neutral)
├── Gap between bars: 5–8px
├── Optional top label (percentage/value, 10px)
└── Optional bottom label (session name, 9.5px)
```

#### ProgressBar
```
Horizontal fill bar
├── Track: bg=#f0e6d6, height=8–12px, radius=6–8px
├── Fill: bg=accent, height=100%, radius matches track
├── Optional label row above (name + percentage)
└── Width expressed as percentage
```

#### Sparkline
```
SVG polyline for trend data
├── stroke: accent color, width: 2.5px
├── fill: none
└── viewBox: responsive (e.g., "0 0 260 80")
```

### 2.8 Feedback & Status

| Element | Style |
|---------|-------|
| **Capacity Warning** | `bg=#fdeee4, color=#a8481a, radius=8px, padding=8px 12px` |
| **Stagnation Warning** | `color=#a8481a, font=11px, 700, prefix "⚠"` |
| **Success Badge** | `bg=#e6f4ea, color=#2ea043, radius=999px` |
| **Empty State** | `font-style=italic, color=#b3a891, 13px` |
| **Selection Hint** | `font=11px, color=#8a7c68, margin-top=14px` |

### 2.9 Overlays & Sheets

#### BottomSheet
```
Slide-up from page bottom
├── Background: page.bg
├── radius: 18px 18px 0 0 (top only)
├── Drag handle: 38×4px, #e2d8c8
├── Animation: sheetUp (translateY 100%→0, 220ms ease)
└── Backdrop: rgba(20,16,12, 0.45), fadeIn 150ms
```

#### OverlayMenu
```
Fullscreen dark overlay
├── Backdrop: rgba(20,16,12, 0.5)
├── Content: header.bg (#221d18)
├── Items: 15px, 600
└── Animation: same as BottomSheet
```

---

## 3. Layout Patterns

### 3.1 Dashboard Layout

```
Desktop (≥1080px):
┌────────────────────────────────────────────┐
│ TopNavBar                                   │
├────────────────────────────────────────────┤
│ StatStrip (6 cols)                          │
├────────────────────────────┬───────────────┤
│ Court Grid (fit to height) │ Waitlist      │
│                            │ Sidebar       │
│  ┌──────┐ ┌──────┐        │ (270px)       │
│  │Court1│ │Court2│        │               │
│  └──────┘ └──────┘        │               │
│  ┌──────┐ ┌──────┐        │               │
│  │Court3│ │Court4│        │               │
│  └──────┘ └──────┘        │               │
└────────────────────────────┴───────────────┘

Tablet/Phone (<1080px):
┌────────────────────────────────────────────┐
│ TopNavBar / CompactHeader                   │
├────────────────────────────────────────────┤
│ StatStrip (3 cols or 2×2)                   │
├────────────────────────────────────────────┤
│ Waitlist Chips (horizontal wrap)            │
├────────────────────────────────────────────┤
│ Court Cards (stacked 1-col or 2-col)        │
└────────────────────────────────────────────┘
```

### 3.2 Responsive Grid Patterns

| Pattern | Desktop | Tablet | Phone |
|---------|---------|--------|-------|
| Stat Strip | 6 cols | 3 cols | 2 cols (4 stats) |
| Court Grid | largest courts that fit the height, else scroll | 2 cols | 1 col |
| Analytics Grid | 2 cols | 1 col | 1 col |
| KPI Row | 6 cols | 3 cols | 1 col |
| Two-Column Form | Row | Row | Column |
| Chart Grid | 2:1 | 1 col | 1 col |
| Player Row | fixed-width Level/Membership/Checked-in columns | fixed | intrinsic widths, so the name keeps the leftover space |

All breakpoints use the viewport width (`MediaQuery.sizeOf(context).width`), not the width left
after the shell padding.

On desktop the court grid fills the free height and scrolls itself when the courts do not fit
(`courtGridLayout`). In the stacked layout (<1080px) the grid is shrink-wrapped and the page
scroll view supplies the scrolling.

### 3.3 Navigation Patterns by Breakpoint

| Breakpoint | Primary Nav | All Tabs Accessible Via |
|------------|-------------|------------------------|
| Desktop | Top tab bar (7 tabs) | Top tab bar |
| Tablet | Top tab bar (scrollable, 7 tabs) | Top tab bar |
| Phone (tabbar) | Bottom tab bar (4 tabs) | "More" bottom sheet |
| Phone (hamburger) | Hamburger menu overlay | Hamburger menu |

---

## 4. Interaction Patterns

### 4.1 Waitlist → Court Placement
```
1. User taps waitlisted player → player highlights (accent bg)
2. Helper text updates: "Placing {name} — tap a court slot"
3. User taps court slot:
   a. Empty slot → player placed in slot
   b. Occupied slot → swap (existing player moves to waitlist)
4. Selection clears
```

### 4.2 Court Re-roll
```
1. User taps "Re-roll ⟲" on a court card
2. Algorithm: shuffles court occupants + waitlisted players,
   picks best 4-player combination (lowest level spread) from 24 iterations
3. Remaining players go to waitlist
4. Re-roll counter increments
```

### 4.3 Auto-Promote from Waitlist
```
When a checked-in player is unchecked:
1. Waitlist sorted by skill tier (descending)
2. First waiting player fills the open court slot
3. If no court has an open slot, waitlist is unchanged
```

### 4.4 Check-in Flow
```
1. Active players shown in list with "Mark present" / "Present" toggle
2. Progress bar shows checked-in / capacity
3. At capacity:
   a. Warning banner appears
   b. New check-ins go to waitlist
4. Un-checking a player auto-promotes from waitlist
```

### 4.5 Level Adjustment
```
+/- buttons adjust tier up/down
├── Disabled at boundaries (Amateur / Professional)
├── Buttons visually dim (opacity 0.35) when disabled
└── ELO value changes to tier midpoint
```

### 4.6 Dialogs — a dialog closes itself

**Rule: the dialog widget pops itself, using its own `BuildContext`, and returns its result
through the `showDialog` future. The caller only reads that result — it never pops.**

This is not a style preference. `showDialog` defaults to `useRootNavigator: true`, so the dialog
route lives on the **root** Navigator. Every page, meanwhile, sits inside a per-tab Navigator
created by `StatefulShellRoute.indexedStack`, holding exactly one route. So a caller that pops
with its own context tears its own tab off that branch — leaving an empty Navigator and a blank
screen — while the dialog stays up and its future resolves to `null`, silently discarding the
result.

```
✅  builder: (_) => const AddPlayerDialog()      // dialog: Navigator.of(context).pop(value)
❌  builder: (_) => AddPlayerDialog(onSubmit: (v) => Navigator.of(context).pop(v))
```

This bug has shipped twice (`03ed233`, then again via `ac65048`). Regression cover lives in
`integration_test/players_add_player_test.dart`, which asserts the page is still mounted after
the dialog closes.

---

## 5. Page Map

| Tab | Key Components | Primary Actions |
|-----|---------------|-----------------|
| **Dashboard** | Round rotation bar, court grid, waitlist sidebar/chips, stat strip | Rotate now, pre-make next round, cancel staged round, place/swap players, re-roll courts |
| **Check-in** | Capacity bar, player list | Toggle player presence |
| **Players** | Search, filterable player table, expandable profiles, pending approvals | Adjust levels, toggle active/member/checkin, view stats |
| **Sessions** | Round mode toggle, capacity/courts inputs, template list | Configure session, save/load templates |
| **Schedule** | Recurring session cards | View schedule |
| **Analytics** | Attendance trend, court utilization, level gap, level distribution, KPI row | Filter time range (4/12/26 wks) |
| **Settings** | Notification toggles, invite link, membership info | Toggle notifications, copy invite link |

### Deep Analytics (standalone page)
- KPI strip (6 metrics)
- Attendance rate bar chart
- Waitlist pressure chart
- ELO spread trend
- Court fairness bars
- Court utilization bars
- Re-roll frequency chart
- ELO distribution histogram
- Top ELO movers table
- At-risk players list
- Player mixing (diversity) bars
- New player integration table

### Self Registration (standalone page)
- Step 1: Name + contact form
- Step 2: Self-estimated level selector (4 tiers with descriptions)
- Submit → confirmation screen with pending approval notice

---

## 6. Implementation Strategy for Flutter

### 6.1 Token Mapping

The design tokens in Section 1 should become a `DesignTokens` Dart class (or `ThemeData` extension) with:
- `AppColors` — all color tokens as static const
- `AppTextStyles` — all type tokens as static `TextStyle`
- `AppSpacing` — spacing scale as static const doubles
- `AppRadii` — border radius scale as static const `BorderRadius` / doubles
- `AppBreakpoints` — const ints for width thresholds

### 6.2 Widget Mappings

| Design Component | Flutter Widget |
|-----------------|----------------|
| Card | `Container` with `BoxDecoration` matching card tokens |
| StatStrip | `GridView` / `Wrap` of stat cells |
| CourtCard | Custom `CourtCard` widget |
| PlayerRow | Custom `PlayerListTile` widget |
| TabButton | `TextButton` / `ElevatedButton` styled to match |
| SearchInput | `TextField` with `InputDecoration` |
| ToggleButton | `ToggleButtons` or custom `GestureDetector` |
| BottomSheet | `showModalBottomSheet` with custom shape |
| BarChart | Custom `CustomPaint` or `fl_chart` package |
| ProgressBar | `LinearProgressIndicator` or custom `Container` |
| LevelSelector | `RadioListTile` custom or `Wrap` of selectable cards |

### 6.3 Responsive Strategy
- Use `LayoutBuilder` to read available width
- Break at 720px (phone/tablet) and 1080px (tablet/desktop)
- Switch navigation pattern at each breakpoint
- Stat strip columns: 6 → 3 → 2
- Court grid columns: 2 → 2 → 1

### 6.4 Priority Components (build order)
1. **Design tokens** (colors, typography, spacing) — foundation for everything
2. **Card, StatCell, KpiCard** — used everywhere
3. **TopNavBar + TabButton** — shell navigation
4. **CourtCard + PlayerSlot** — core dashboard
5. **PlayerRow + ExpandableProfile** — player management
6. **WaitlistItem + WaitlistChip** — waitlist interaction
7. **SearchInput + ToggleButton + NumberInput** — form controls
8. **ProgressBar + BarChart** — data display
9. **BottomSheet + BottomTabBar + HamburgerMenu** — responsive nav
10. **LevelSelector + ConfirmationScreen** — self-registration
