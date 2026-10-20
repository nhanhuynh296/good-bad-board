# ARCHITECTURE.md — Riverside Badminton Club Design System

> Extracted from the UX-Redesign HTML handoff (`Badminton App.dc.html`, `Analytics Dashboard.dc.html`, `Dashboard Options.dc.html`, `Responsive Layouts.dc.html`, `Self Registration.dc.html`).
> This document defines a **reusable design system** to guide the Flutter implementation.
>
> **2026-10-17 design build.** The approved design (`Main`, `Players`, `ScanStates`, `TypeColour` `.dc.html`, artifact `9JBfi4Rk8igxQMVDexk6So`) and `audit/design-diff-2026-10-17/decisions.md` (R1-Q1 … R11-Q6; a later row overrides an earlier one) and the 2026-10-20 design review (`audit/design-review-2026-10-20/resolution.md`, F01 … F30; F05 and F28 wait for Nathan) replace §1.1, §1.2 and the desktop components of the Courts tab, the shell and the Players tab. Phone and tablet keep the PR 45 components as they are now (R2-Q23, R6-Q7). UAT.md is the feature source of truth; "TODO" marks points Nathan has not decided. Courts round Undo is on hold (R6-Q6, UAT RND-21). The Players scan Undo is removed (R9-Q8): the only Undo is the Courts swap. **Sessions tab redesign: canvas board "Sessions", pending** (R7-Q3).

---

## 1. Design Tokens

### 1.1 Color Palette

#### Primary Theme: "Clubhouse" (Light/Warm) — 2026-10-17

Source: `TypeColour.dc.html` swatches, plus the colours the other design files use but the
swatch sheet does not list. Ratios use the WCAG 2.x relative-luminance formula. Text needs
4.5:1. Borders, icons, focus rings and state fills need 3:1 (UX-22, R2-Q22). Card and row
separators may stay light (R2-Q22).

**Surfaces**

| Token | Value | Usage | Contrast |
|-------|-------|-------|----------|
| `color.page.bg` | `#fffdfa` | Page / scaffold background | ink 16.45:1 |
| `color.card.bg` | `#fbf6ee` | Court card, waitlist panel, row not checked in, READY result box | ink 15.53:1 |
| `color.card.border` | `#e4d8c4` | Card and row **separator** only (was `#eee4d8`) | 1.39:1 page, 1.31:1 card — allowed for separators (R2-Q22) |
| `color.surface.hover` | `#f3eadb` | Slot hover, next-round strip fill | ink 14.00:1 |
| `color.surface.next` | `#fffaf2` | Court card fill in edit mode (next round) | ink 16.08:1 |
| `color.header.bg` | `#221d18` | Top nav | white 16.71:1 |
| `color.bar.bg` | `#2b241e` | Round bar, session bar | white 15.29:1 |
| `color.bar.track` | `#4a4038` | Round progress track, READY chip fill | white 10.09:1; fill vs track: white 10.09, orange 3.53, grey 5.71 |

**Text**

| Token | Value | Usage | Contrast |
|-------|-------|-------|----------|
| `color.text.primary` | `#221d18` | All body text, names | 16.45:1 page, 15.53:1 card, 12.14:1 checked-in row |
| `color.text.muted` | `#6f6352` | Labels, levels, helper text, caps labels (was `#8a7c68`, 4.01:1) | 5.77:1 page, 5.45:1 card, 4.72:1 on `#ece6dc`. **Fails on the checked-in row (4.26:1): use `color.text.primary`, or `#5f5446` (5.37:1) for the TYPE label, there** |
| (Disabled row text) | `#6f6352` | A Disabled player's name, ID and level use `color.text.muted`; there is no paler disabled token and no contrast exemption (F13) | 5.45:1 card |
| `color.header.text` | `#ffffff` | Text on the top nav and bars | 16.71:1 / 15.29:1 |
| `color.header.sub` | `#c9c2b8` | Inactive tabs, round label, counts, paused timer on the bars | 9.46:1 nav, 8.66:1 bar, 5.71:1 on track |

**Action and state**

| Token | Value | Usage | Contrast |
|-------|-------|-------|----------|
| `color.accent.primary` | `#ff6a2b` | Fill of the **one** primary button per view; active-tab underline; CHANGEOVER chip and timer | ink on it 5.85:1; on bar 5.35:1; vs nav 5.85:1. **Never text on a light surface (2.81:1)** |
| `color.accent.onPrimary` | `#221d18` | Text on orange | 5.85:1 |
| `color.accent.strong` | `#c2410c` | Focus ring on light surfaces only (3 px, 2 px offset; F07), selection outline, dashed edit-mode border, amber-state border | 5.10:1 page, 4.81:1 card, 4.98:1 next fill, 4.30:1 on amber |
| `color.focus.onDark` | `#ff6a2b` | Focus ring on `#221d18` and `#2b241e`: the tabs, the nav "⋯", the round bar buttons and "⋯", the session bar link (F07; `#c2410c` is only 2.95:1 on `#2b241e`, 3.23:1 on `#221d18`) | 5.35:1 bar, 5.85:1 nav |
| `color.control.border` | `#6f6352` | Inputs (scan field 2 px, waitlist search 1 px), "More", "Edit round" and other outline buttons | 5.77:1 page, 5.45:1 card, 5.86:1 white |
| `color.control.borderSoft` | `#8f826e` | Secondary outline button, e.g. "Re-roll" (replaces design `#d6c9b4`, 1.61:1) — R2-Q22; accepted with `#6f6352` for inputs and outline buttons (R6-Q16) | 3.70:1 page, 3.49:1 card, 3.62:1 next fill, 3.15:1 hover |
| `color.checkedIn.bg` | `#bfe5c8` | Checked-in row fill, CHECKED IN result box | ink 12.14:1; fill vs page 1.36:1, so the edge carries the state |
| `color.success` | `#1f7a3d` | Checked-in 1 px border and 6 px bar, RUNNING chip, IN icon, "Next in" tag, "Round n saved" | 5.29:1 page, 4.99:1 card, 3.90:1 on green row; white on it 5.37:1 |
| `color.success.text` | `#14532d` | Text in the CHECKED IN result box | 6.62:1 on `#bfe5c8` |
| `color.warning.bg` | `#fde7c8` | NEXT tag, PAUSED chip, edit strip, SCANNED TWICE / MANY / FULL / DUPLICATE ID boxes | — |
| `color.warning.text` | `#9a3412` | Text on amber; "Round n not saved" title (was `#a8481a` on `#fdeee4`) | 6.07:1 on amber, 7.20:1 page, 6.13:1 strip |
| `color.error` | `#b91c1c` | NOT FOUND / DISABLED border and icon, error text on page (was `#f44336`, 3.63:1) | 6.37:1 page; white on it 6.47:1; 5.28:1 on error bg |
| `color.error.bg` / `color.error.text` | `#fde2e2` / `#991b1b` | NOT FOUND, DISABLED result box | 6.79:1 |
| `color.neutral.bg` | `#ece6dc` | CHECKED OUT result box (border `#6f6352`, icon `#6f6352` with white 5.86:1) | ink 13.46:1 |
| `color.urgent.onDark` | `#ffb38a` | Time on the session bar and the Courts round bar, and the round bar progress fill, at ≤60 s while RUNNING; not when PAUSED (R4-Q6, R6-Q8). The only ≤60 s amber on every board and bar; the Sessions board `#fde7c8` is wrong (F26) | 8.78:1 on bar |

**Round state chips** (12 px, weight 600, caps, radius 4)

| State | Fill | Text | Ratio |
|---|---|---|---|
| READY | `#4a4038` | `#ffffff` | 10.09:1 |
| RUNNING | `#1f7a3d` | `#ffffff` | 5.37:1 |
| PAUSED | `#fde7c8` | `#9a3412` | 6.07:1 |
| TIME UP | `#b91c1c` | `#ffffff` | 6.47:1 — decided (R11-Q5, F04): on the round bar, the session bar and every board. The TIME UP time is `#ff6a2b` |
| CHANGEOVER | `#ff6a2b` | `#221d18` | 5.85:1 |

The state chip is a polite live region on both bars (`Semantics(liveRegion: true)` on the chip
only); the time is not a live region (F24).

**Charts.** The Analytics chart colours (`#e8dcc8`, `#d9c7a8`, `#f0e6d6`, `#ffb38a`) stay until
Analytics is drawn (R2-Q19).

**Removed tokens:** `#8a7c68` (→ `#6f6352`), `#2ea043` and `#e6f4ea` (→ `#1f7a3d`, `#bfe5c8`),
`#f44336` (→ `#b91c1c`), `#a8481a` / `#fdeee4` (→ `#9a3412` / `#fde7c8`), `#eee4d8` (→
`#e4d8c4`), `#e2d8c8` input border (→ `#6f6352`), `#d6c9b4` (→ `#8f826e`), `#b3a891`
`color.text.disabled` (→ `#6f6352`, F13).

#### Alternative Themes — Removed (2026-10-17)

The `command` and `playful` themes from `Dashboard Options.dc.html` were never built. Removed.

#### Dark Theme — Removed (2026-10-17)

The app is light only. The dark tokens (`app_colors.dart:78-92`), `AppTheme.dark()` and the
`darkTheme:` wiring are removed (IMPLEMENTATION Stage 8.1.3).

### 1.2 Typography

**One family: Source Sans 3** (variable font, `wght` axis, bundled in `asset/font/`). No other
family is bundled. OpenSans, SpaceGrotesk and the unused NotoSans file are removed. Hierarchy
comes from size and weight, not from a second family (UX-25, R3-Q6).

| Weight | Role |
|--------|------|
| 400 | Body and data: levels, IDs, helper text, result text |
| 600 | Names, buttons, titles, timers, counts, caps labels, tags, chips |
| 800 | Page titles only. Icon glyphs in the result box use 600 (the design used 800 there) |

**Chinese.** Source Sans 3 has no Chinese glyphs. `fontFamilyFallback` gives the Windows system
font for the locale: zh → `Microsoft YaHei`, zh_HK → `Microsoft JhengHei` (R3-Q6). Nothing is
bundled for Chinese (0 MB). These fonts have Regular and Bold only, so Chinese text at 600 or
800 renders in Bold.

**Type Scale (6 sizes, R2-Q20):**

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `text.timer` | 50px | 600, tabular | Round bar time |
| `text.display` | 28px | 800 page title / 600 number | Page titles; the Players check-in count; Analytics KPI values |
| `text.title` | 20px | 600 | Scan field text, result box name, session bar time |
| `text.subtitle` | 16px | 600 (400 for result text) | Court titles (letter-spacing 0.04em), Players row names, panel titles ("Waitlist"), result box text |
| `text.body` | 14px | 400 / 600 | Body and data (400); slot names, buttons, tabs (600) |
| `text.caption` | 12px | 400 / 600 caps | Secondary lines (400); caps labels, chips, tags (600, letter-spacing 0.08em) |

Mapping of old sizes: 9.5–13 px → 12 or 14; 15 → 16; 18–22 → 20; 24–26 → 28. Nothing on desktop is
smaller than 12 px. The family applies to every size of screen; phone and tablet keep their
PR 45 sizes until they are redesigned (R2-Q23). The sizes in the older component specs below
(phone nav, charts) are PR 45 values.

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
| `bp.desktop` | ≥1080px | Top nav Courts · Players · Sessions · ⋯, session bar, 2×2 courts + 280px waitlist |

---

## 2. Component Catalog

### 2.1 Navigation

#### TopNavBar (desktop ≥1080px, 2026-10-17)
```
56px bar, bg #221d18, padding 0 24px
├── Left, two lines (F29): "Session" over "{duration} rounds" (14/600 white; R3-Q5 — no club or
│   template name); {duration} = "10 min" for whole minutes, else m:ss ("10:30 rounds")
└── Right (margin-left auto): tabs "Courts", "Players", "Sessions" + "⋯" (44×44)
    ├── Tab: full bar height, padding 0 16px, 14px
    ├── Active: white, weight 600, 3px #ff6a2b bottom border, no fill (UX-21)
    ├── Inactive: #c9c2b8, weight 400
    └── "⋯" opens a menu: "Analytics", "Settings"; active style when one of them is open
Focus on the bar: 3px #ff6a2b ring (`color.focus.onDark`) on the tabs and "⋯" (F07)
```
Tablet (720–1079px) keeps the PR 45 bar (5 tabs with "Dashboard", pill style) (R6-Q7, UAT NAV-01).

#### SessionBar (desktop, every tab except Courts)
```
40px link band under the top nav, bg #2b241e, padding 0 24px, gap 16
├── "ROUND N" (12/600 caps, #c9c2b8)
├── Time (20/600 tabular, white; #ffb38a at ≤60 s while RUNNING, not PAUSED, R6-Q8;
│   #ff6a2b in TIME UP, R11-Q5)
├── State chip (READY / RUNNING / PAUSED / TIME UP / CHANGEOVER, §1.1); polite live region (F24)
├── "{in}/{capacity} in · {waiting} waiting · round N+1 saved" or "· round N+1 not saved" (14/400, #c9c2b8, R6-Q12)
└── Right: "View courts →" (14/600 white). The whole bar opens Courts.
Before the first lineup: "No round yet" in place of round, chip and time.
No toast on a round change (R4-Q4). Order ROUND · time · chip, as on the round bar (F29).
Focus: 3px #ff6a2b ring on the link (F07).
```

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
└── Vertical list of all 5 tabs
    ├── Active: bg=accent, color=#221d18
    └── Inactive: bg=transparent, color=white
```

#### MoreBottomSheet (Phone)
```
Slide-up sheet from bottom
├── Drag handle (38×4px, #e2d8c8)
└── List of secondary tabs (Sessions, Analytics, Settings)
    ├── Chevron on right
    └── Active: color=accent
```

### 2.2 Data Display

#### StatStrip — Removed on desktop (2026-10-17, R3-Q4); tablet/phone unchanged
```
Horizontal grid of StatCell items
├── Desktop: 6 columns
├── Tablet: 3 columns
└── Phone: 2×2 grid
```

#### StatCell
```
Card with label/value pair
├── Label: 12px, 600, uppercase, #6f6352, letter-spacing 0.08em (2026-10-17 scale)
├── Value: 19px, 800, #221d18 (or accent for waitlist/ELO)
└── Background: page.bg, 1px border between cells
```

#### KpiCard
```
Larger stat card for analytics
├── Label: 12px, 600, uppercase, #6f6352, letter-spacing 0.08em
├── Value: 28px, 600, #221d18 (Source Sans 3)
└── Delta: 12px, 600, green (#1f7a3d) or red (#b91c1c)
```

#### Card
```
Container with:
├── bg: #fbf6ee
├── border: 1px solid #e4d8c4 (separator)
├── radius: 12px
└── padding: 16px 18px
```

#### SectionTitle
```
├── Font: Source Sans 3, 600
├── Size: 16px (card title) / 14px (tight variant)
└── Color: #221d18
```

### 2.3 Court & Game

Desktop components below follow the 2026-10-17 design (`Main.dc.html`) and decisions. Phone and
tablet keep their PR 45 widgets (R2-Q23) with the new state names and labels.

#### RoundBar (desktop; replaces RoundRotationBar)
```
Full-width band under the top nav: 80px, bg #2b241e, no radius, padding 0 24px
├── Left: "ROUND N" (12/600 caps, 0.08em, #c9c2b8) over the sub-label (14/400, #c9c2b8)
├── Time "mm:ss" (50/600, tabular) in the state colour + state chip (polite live region, F24)
├── Counts "{in}/{capacity} in · {waiting} waiting" (14/400, #c9c2b8)
├── Right: the state buttons (44px tall), then "⋯" round menu (44×44) → "End session"
└── Progress bar: 4px at the bottom edge, track #4a4038, fill = state colour,
    width = elapsed ÷ duration (fills up, R4-Q7); time and fill #ffb38a at ≤60 s while RUNNING (R6-Q8)
```

| State | Chip | Sub-label | Time colour | Buttons (left → right; last is primary orange) |
|---|---|---|---|---|
| No lineup | READY | "Not started" | `#ffffff` | "Generate round 1" |
| READY (draft) | READY | "Not started" | `#ffffff` | "Discard & regenerate" (outline), "Start round 1" (R7-Q1) |
| RUNNING | RUNNING | none (R4-Q8) | `#ffffff`; `#ffb38a` at ≤60 s (R6-Q8) | "Pause" (text), "Discard round N and start again" (outline, R9-Q1), "Start round N+1" |
| RUNNING + edit mode | RUNNING | none | as RUNNING | "Pause" only (R4-Q9) |
| PAUSED | PAUSED | "Clock paused" | `#c9c2b8` (never amber, R6-Q8) | "Discard round N and start again" (outline), "Start round N+1" (outline, R6-Q14), "Resume round N" |
| PAUSED + edit mode | PAUSED | "Clock paused" | `#c9c2b8` | "Start round N+1" (outline), "Resume round N" (R9-Q5, as the board "Courts · Paused") |
| TIME UP | TIME UP | "Clock stopped at 0:00" | `#ff6a2b` (R11-Q5) | "Discard round N and start again" (outline), "Start round N+1" (R6-Q4, R7-Q1). Courts show the planned round N+1, each card tagged "ROUND N+1" (F08); no strip |
| TIME UP + edit mode | TIME UP | "Clock stopped at 0:00" | `#ff6a2b` (R11-Q5) | no start buttons (edit mode, R4-Q9); the edit strip "Save round N+1" starts the changeover (R6-Q3) |
| CHANGEOVER | CHANGEOVER | "Players to courts" | `#ff6a2b` | "Pause" (text), "Start round N+1 now" (after a discard the new round keeps number N: "ROUND N", "Start round N now", R9-Q1) |
| CHANGEOVER + edit mode | CHANGEOVER | "Players to courts" | `#ff6a2b` | "Pause" only (R4-Q9). At 0:00 with unsaved edits the time stops at 00:00 and the bar shows no buttons; the edit strip "Save round N+1" starts the round (R9-Q4) |
| CHANGEOVER paused | PAUSED | (TODO) | `#c9c2b8` | "Resume changeover" (R6-Q12). Courts follow the PAUSED rules for round N+1: Re-roll, swap, full slot "⋯" menu (F17) |

No "COURTS − 4 +" stepper (R2-Q2). No "Ends 19:42" (R4-Q8). Bar buttons: outline = 1px
`#c9c2b8` border, white text; text = no border; primary = `#ff6a2b` fill, `#221d18` text.
Focus ring on the bar: `#ff6a2b` (F07). Edit mode is a flag beside the phase, never a phase:
"Pause" keeps edit mode (F02). PAUSED label width: if fr / zh / zh_HK labels do not fit at
1280 px, PAUSED uses "Discard round N" (IMPLEMENTATION 8.8, F16).

**Actions** (see §4.7 for the state machine)

| Action | Description |
|--------|-------------|
| `generateFirstRound` | Fills the courts for round 1; clock stays stopped |
| `startFirstRound` | "Start round 1": starts the round 1 clock at once, no changeover (R9-Q2) |
| `startNextRound` | "Start round N+1": saves round N+1 (saved, planned or fresh lineup; in paused edit mode the edit lineup, R9-Q5) → 20 s changeover; round N is logged when N+1 starts (R6-Q1, R6-Q2) |
| `discardAndStartNext` | "Discard round N and start again": confirm dialog first ("Discard round N?", "Discard round" / "Cancel", R9-Q3; the UAT RND-16 text, F14) → 20 s changeover; round N is never logged; the new round keeps number N (R2-Q5, R9-Q1) |
| `pause` / `resume` | Freezes / continues the round or the changeover |
| `startNextNow` | Ends the changeover at once; logs round N (unless discarded) |
| `endSession` | Confirm dialog ("End session?"; text by state, F09: "Round N goes into the history." in RUNNING / PAUSED / TIME UP, "Round N−1 goes into the history." in CHANGEOVER, "Nothing is logged." in READY, no lineup, or a changeover after a discard; then "Everyone is checked out."); logs the round that started last once (also in TIME UP / CHANGEOVER, R6-Q5), stops the clock, checks out all, round 1, empty courts. No Undo (on hold, R6-Q6) |

Every start button has a double-click guard: two fast clicks start one changeover and log once (R6-Q18).

**Confirm dialogs (F14, F18).** "Close without saving?" ("Close" / "Keep editing", R11-Q2,
only when the edit has changes, F03), "Discard round N?" and "End session?" use one pattern:
alert dialog semantics with title and description, initial focus on the cancel button, Esc =
cancel, the dialog pops itself (§4.6). A phase change while the Discard or End session dialog
is open closes it with no action.

#### NextRoundStrip (desktop)
```
48px band under the round bar, padding 0 24px, bg #f3eadb, bottom 1px #e4d8c4
├── Title (14/600): "Round N+1 not saved" (#9a3412) or "Round N+1 saved" (#1f7a3d)
├── Text (14/400, #221d18): "Clock stops at 0:00 if not saved." / "Starts 20 s after round N ends."
└── Right: "Make round N+1" or "Edit round N+1" (36px, 1px #6f6352 border, #fffdfa fill)
Edit mode: bg #fde7c8, bottom 1px #c2410c, title "Editing round N+1" (#9a3412)
└── Right: "Discard & regenerate" (outline #9a3412), "Save round N+1" (primary), "×" (far right)
```
Shown in RUNNING and PAUSED (and edit mode). CHANGEOVER: title "Round N ended", no button
(R6-Q2); after a discard: "Round N discarded · new lineup for round N" (F10). "×" asks
"Close without saving?" first when the edit has changes (R11-Q2, F03). Not shown in TIME UP (the courts show the planned next round, R6-Q4), READY or with
no lineup.

#### CourtCard
```
Card: bg #fbf6ee, 1px #e4d8c4, radius 12, padding 8 12 8 16; fills its 2×2 grid cell
Edit mode: bg #fffaf2, 2px dashed #c2410c, "NEXT" tag
├── Header row (40px):
│   ├── "Court N" (16/600, letter-spacing 0.04em)
│   ├── Level gap as plain text (12/400, #6f6352): "Same level" / "N level gap"
│   ├── Tag (conditional): "NEXT" or "{count} players", e.g. "3 players" on a court one short (12/600 caps, #fde7c8 / #9a3412)
│   └── "Re-roll" (36px, 1px #8f826e border, #fffdfa, 14/600, ⟲ icon) at the right edge;
│       hidden on a live court while the clock runs (R3-Q10)
└── 4× PlayerSlot rows, spread over the card height
```
The SpreadPill is not used on desktop (plain text instead). Tablet/phone keep it:

#### SpreadPill (tablet/phone only)
```
├── bg: #f0e6d6, color: #6f6352 (was #8a7c68), radius 999px, padding 4px 8px
└── font: 12px, 600; content "Same level" / "N level gap"
```

#### PlayerSlot
```
Button row, 40px, radius 6, padding 0 8, no border:
├── Occupied: name (14/600, ellipsis) + tier name (14/400, #6f6352, 96px, right) + "⋯" (16px)
│   ├── Hover: bg #f3eadb, "⋯" shows; it also shows when the slot or the "⋯" has keyboard
│   │   focus (F06); "⋯" hit area 40×40 (F27); focus: 3px #c2410c ring, 2px offset
│   ├── Checked-out player on a live court while the clock runs: no "⋯" (R11-Q4)
│   └── Semantics label: "{name}, {tier}. Open actions"
└── Empty: "Open slot" (14/400 italic, #6f6352)
```
No "×" remove button (R3-Q11). Tap = select for a swap. On a live court while the clock runs
(not edit mode) the slot is not a tap button and a tap does nothing (F11).

#### SlotActionMenu ("⋯" on a slot)
| Court | Items |
|---|---|
| READY draft, PAUSED, TIME UP, edit mode (next round) | "Move to waitlist", "Check out" |
| Live court while the clock runs (RUNNING, CHANGEOVER; not in edit mode, R7-Q4) | "Check out" only |

Menu: card bg, 1px `#6f6352` border, radius 8, items 40px, 14/400. "Move to waitlist" refills
the place by the fill rule (§4.3, R7-Q6). A Courts check-out shows no message (R7-Q5).
Keyboard (F06): arrow keys move between items, Enter selects, Esc closes; on close, focus goes
back to the slot "⋯".

A swap of two players shows the bottom message "Swapped {A} and {B}. Undo" for 10 s (§2.8,
R6-Q6, R7-Q2). No Ctrl/Cmd+Z.

### 2.4 Lists & Tables

#### PlayerRow (desktop, 2026-10-17)
```
48px row, radius 8, 6px gap between rows; grid: NAME 1fr | SIGN-IN ID 140 | LEVEL 140 | TYPE 120 | More 88
├── Row tap = check-in toggle (the whole row except More is one button)
├── NAME: 16/600, ellipsis
├── SIGN-IN ID: 14/400 tabular; empty when the player has no ID
├── LEVEL: tier name, 14/400 (no stepper, no Elo code; R2-Q17, R2-Q18)
├── TYPE: blank for Member; "Casual" / "Disabled", 14/400 muted (ink on a checked-in row)
└── "More": 72×36 outline button, 1px #6f6352, radius 8, #fffdfa, 14/600
Semantics label: "{name}, checked in. Tap to check out" / "{name}, not checked in. Tap to check in"
Focus: 3px #c2410c ring, 2px offset
```

Row states:

| State | Fill | Border | Left bar | Hover |
|---|---|---|---|---|
| Checked in | `#bfe5c8` | 1px `#1f7a3d` | 6px `#1f7a3d` (inset) | 3% darker |
| Not checked in | `#fbf6ee` | 1px `#e4d8c4` (separator) | none | 3% darker |
| Disabled | `#fbf6ee` | 1px `#e4d8c4` | none | none; forbidden cursor; text `#6f6352` (F13); tap shows the bottom message |

The table header reads NAME · SIGN-IN ID · LEVEL · TYPE · (blank), 12/600 caps, 0.08em,
`#6f6352`. Tablet/phone rows keep the PR 45 layout, with the stepper and pill (R6-Q7, UAT NAV-08).

#### MorePanel (ExpandablePlayerProfile)
**As drawn on the canvas board "Players · More panel" (R5-Q1, accepted R6-Q17).** An accordion
under the row (row and panel in one rounded panel):
```
├── Top row: Sign In ID field (selects all on focus, F30) + "Save" (PLY-15; a duplicate ID gives
│   "ID {id} is used by {name}.", F23); delete (btn.danger-outline, F23) and close at the right
├── Level: "−" "Intermediate (B1)" "+" (tier name with the Elo code, PLY-05)
├── Membership: "Member / Casual / Disabled" (PLY-06). Disabled asks for confirmation,
│   then checks the player out
└── 3 stat tiles, partners, attendance (PLY-09)
```
The row's "More" is a button with `aria-expanded` / `aria-controls` on the board and
`Semantics(expanded:)` in Flutter (F23). The Disabled confirm is drawn on the board (F23).
Desktop only; tablet/phone keep the PR 45 profile with the new tokens (R6-Q7).

#### WaitlistPanel (desktop, 2026-10-17)
```
280px panel: bg #fbf6ee, 1px #e4d8c4, radius 12, padding 16, gap 12
├── Header: "Waitlist" (16/600) + count (14/600)
├── Search: caps label "SEARCH WAITLIST" + field (40px, 1px #6f6352, radius 8,
│   placeholder "Name or sign-in ID") — same matching as Players search, no chips (UX-14)
├── List (fill-rule order, no numbers, R3-Q12): flex 1, min-height 0, scrolls (Flutter
│   `Expanded(child: ListView)`); header, search and hint stay fixed (F12). Each item a 48px
│   button, radius 6; not pressable while the live clock runs and not in edit mode (F11):
│   ├── Name (14/600) over "{tier} · {n} rounds" (12/400, #6f6352)
│   ├── "Next in" tag (12/600, #1f7a3d) when the player is in the saved next round
│   ├── Hover #f3eadb; selected: 2px #c2410c outline (UX-21: outline, not fill)
│   └── Semantics label: "{name}, {n} rounds. Select to place"
├── Empty: "No one waiting" (14/400 italic, #6f6352); no search match: "No one matches “{text}”" (R6-Q12)
└── Selection hint (kept, R2-Q19): "Placing {name} — tap a court slot" (12/400, #6f6352); while
    the live clock runs (not edit mode): "Courts change at the next round" (F11)
```
In edit mode the panel lists the players who sit out the next round. With no lineup it lists
the checked-in players in check-in order, no "Next in" (F22).

#### WaitlistItem — Superseded on desktop by WaitlistPanel (2026-10-17). Tablet/phone unchanged.
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

#### ScanField (Players, desktop, 2026-10-17; replaces SearchInput there)
```
Row: [field (flex)] [count] [Add player]
├── Caps label "CHECK IN" (12/600, 0.08em, #6f6352)
├── Field: 52px, 2px #6f6352, radius 10, bg #ffffff, scan icon (22px, #6f6352) at left 14,
│   text 20/600, placeholder "Scan card or search name"; focus: 3px #c2410c ring, 2px offset
├── onSubmitted (Enter) runs the scan (PLY-14): the exact sign-in ID match runs over all listed
│   players before the chips and the query, and does not clear the chips (F01); the text stays
│   selected after each scan, except MANY MATCHES: caret at the end, no selection (F19)
├── Focus returns to the field after pointer actions (scanner rule); Esc on the tab returns
│   focus to it (F21)
├── Count: "{in}" (28/600) + " / {capacity} in" (16/400, #6f6352), under it
│   "{n} places left" (12/400, #6f6352, plural)
└── "Add player": 52px, #ff6a2b fill, #221d18 text 14/600, radius 10 (the primary of the view)
```
No capacity progress bar on desktop (R6-Q11). The at-capacity banner and pending card stay,
restyled (R2-Q19). Level chips: 4 tier chips (Amateur, Intermediate, Advanced, Professional)
replace the 8 Elo-code chips (R6-Q13); chip border `#8f826e`.

#### ScanResultBox (Players, under the scan field)
```
min-height 52px, radius 10, padding 8 16, gap 12, 1px border; role=status, polite live region
├── Icon: 28px circle, white glyph 16/600
├── Name: 20/600
├── Text: 16/400
└── Action (optional, right): 36px outline button in the text colour, 14/600
Stays until the next scan. A row tap does not change it (R3-Q3). No "Undo" button in any state (R9-Q8).
```

| State | Fill | Text | Border | Icon (fill) | Name · text | Action |
|---|---|---|---|---|---|---|
| READY | `#fbf6ee` | `#6f6352` | `#e4d8c4` | › (`#6f6352`) | "Ready to scan" · "Scan a card, or type a name and press Enter." | — |
| CHECKED IN | `#bfe5c8` | `#14532d` | `#1f7a3d` | ✓ (`#1f7a3d`) | "{name}" · "is in · waits for round {n}" (no "joins" text: a late check-in never joins a saved round, R7-Q7) | — (no Undo, R9-Q8) |
| CHECKED OUT | `#ece6dc` | `#221d18` | `#6f6352` | ← (`#6f6352`) | "{name}" · "is out · {X} takes Court {k} in round {n}" / "is out" | — (no Undo, R9-Q8) |
| SCANNED TWICE | `#fde7c8` | `#9a3412` | `#c2410c` | ! (`#c2410c`) | "{name}" · "is already in (same card as the last scan). Nothing changed." (no time limit, R6-Q15) | Check out |
| NOT FOUND | `#fde2e2` | `#991b1b` | `#b91c1c` | × (`#b91c1c`) | "No match" · "for “{text}”. Check the card, or add the player." | — |
| MANY MATCHES | `#fde7c8` | `#9a3412` | `#c2410c` | ? (`#c2410c`) | "{count} players match" · "“{text}” · nothing changed. Tap a row, or type more." | — |
| SESSION FULL | `#fde7c8` | `#9a3412` | `#c2410c` | ! (`#c2410c`) | "Session full" · "{in} / {capacity} in · {name} is not checked in." | — |
| DISABLED | `#fde2e2` | `#991b1b` | `#b91c1c` | × (`#b91c1c`) | "{name}" · "is disabled · enable the player in More to check in." | — |
| DUPLICATE ID | `#fde7c8` | `#9a3412` | `#c2410c` | ! (`#c2410c`) | "ID {id}" · "is used by {count} players · nothing changed. Fix the ID in More." (R6-Q12) | — |

Icon contrast: white on `#1f7a3d` 5.37, on `#6f6352` 5.86, on `#c2410c` 5.18, on `#b91c1c` 6.47.
Text contrast: 6.62 / 13.46 / 6.07 / 6.79. The READY icon in `Players.dc.html` used `#e4d8c4`
fill (fails 3:1); use `#6f6352` as in `ScanStates.dc.html`.

#### SearchInput (all other search fields)
```
Full-width text field
├── onSubmitted callback (`AppSearchInput.onSubmitted`)
├── height 40px, padding 0 12px
├── border: 1px solid #6f6352 (was #e2d8c8, 1.39:1), radius 8px
├── font: 14/400, Source Sans 3
└── placeholder: per use ("Search players…", "Name or sign-in ID")
```

#### NumberInput
```
Constrained number field
├── width: 100px
├── padding: 8px 10px
├── Same border/radius as SearchInput
└── font: 14px
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
├── On: bg=#1f7a3d, color=white (5.37:1), radius=6px
├── Off: bg=#e5e5e5, color=#555, radius=6px
├── font: 12px, 600, padding: 5px 12px
└── Label text beside
```

#### LevelSelector (Self Registration)
```
Vertical list of selectable cards
├── Unselected: bg=#fbf6ee, border=1px solid #8f826e (3:1 control, R2-Q22), color=#221d18
├── Selected: bg=#221d18, border=1px solid #221d18, color=white
├── Content: title (14px, 700) + description (12px)
└── radius: 9px, padding: 12px 14px
```

### 2.6 Buttons (2026-10-17)

One orange primary button per view (UX-21). All buttons use 14/600, radius 8 (10 on the 52px
Players row).

| Variant | Background | Color | Border | Height | Use |
|---------|-----------|-------|--------|--------|-----|
| `btn.primary` | `#ff6a2b` | `#221d18` (5.85:1) | none | 44 bar / 36 strip / 52 Players | "Start round N", "Resume round N", "Save round N", "Add player" |
| `btn.outline` | `#fffdfa` | `#221d18` | 1px `#6f6352` | 36 | "More", "Make / Edit round N" |
| `btn.secondary` | `#fffdfa` | `#221d18` | 1px `#8f826e` (3.70:1) | 36 | "Re-roll" |
| `btn.onDark.outline` | transparent | `#ffffff` | 1px `#c9c2b8` (8.66:1) | 44 | "Discard & regenerate", "Discard round N and start again", "Start round N+1" in PAUSED |
| `btn.onDark.text` | transparent | `#ffffff` | none | 44 | "Pause" |
| `btn.icon.onDark` | transparent | `#c9c2b8` | none | 44×44 | "⋯" nav and round menus |
| `btn.inState` | transparent | current text colour | 1px current colour | 36 | Result box "Check out" (SCANNED TWICE). No "Undo" (R9-Q8) |
| `btn.danger-outline` | transparent | `#b91c1c` | 1px `#b91c1c` | 36 | Delete (profile) |

Focus: 3px ring, 2px offset — `#c2410c` on light, `#ff6a2b` on dark surfaces (`#221d18`,
`#2b241e`; F07).
Hit areas (F27): the slot "⋯" (32×32 drawn) and every 32 px button (for example Approve /
Reject) keep their look but get a 40×40 / 40 px tall hit area.

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
(Not used in the release build: the level progression sparkline is removed from the player profile.)
```
SVG polyline for trend data
├── stroke: accent color, width: 2.5px
├── fill: none
└── viewBox: responsive (e.g., "0 0 260 80")
```

### 2.8 Feedback & Status

| Element | Style |
|---------|-------|
| **Capacity Warning** | `bg=#fde7c8, color=#9a3412, radius=8px, padding=8px 12px` |
| **Stagnation Warning** | `color=#9a3412, font=12px, 600, prefix "⚠"` |
| **Success Badge** | `bg=#bfe5c8, color=#14532d, radius=999px` |
| **Empty State** | `font-style=italic, color=#6f6352, 14px` |
| **Selection Hint** | `font=12px, color=#6f6352, margin-top=12px` |
| **Scan result** | ScanResultBox (§2.5), not a SnackBar |
| **Bottom message** (SnackBar) | Only for: a refused row tap on Players (R4-Q1, R45-38), the swap Undo message "Swapped {A} and {B}. Undo" (10 s, R6-Q6, R7-Q2; no keyboard shortcut), and errors. The Courts round Undo message is on hold (R6-Q6). bg `#221d18`, text white 14/400, action `#ff6a2b` 14/600 (5.85:1). Bottom-centre, as now; the message blocks pointer input only inside its own box (360 × 48 px), never outside it (F15) |

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

### 3.1 Courts Layout

```
Desktop (≥1080px), 2026-10-17:
┌────────────────────────────────────────────────────────────┐
│ TopNavBar 56px: Session / 10 min rounds   Courts Players Sessions ⋯ │
├────────────────────────────────────────────────────────────┤
│ RoundBar 80px: ROUND 3 · 04:12 [RUNNING] · 18/20 in · 2 waiting · buttons · ⋯ │
├────────────────────────────────────────────────────────────┤
│ NextRoundStrip 48px (RUNNING, PAUSED, CHANGEOVER, edit mode) │
├──────────────────────────────────────────┬─────────────────┤
│ ┌──────────┐ ┌──────────┐                │ WaitlistPanel   │
│ │ Court 1  │ │ Court 2  │   2×2 grid,    │ 280px           │
│ └──────────┘ └──────────┘   gap 16,      │ count, search,  │
│ ┌──────────┐ ┌──────────┐   padding 16 24│ list            │
│ │ Court 3  │ │ Court 4  │                │                 │
│ └──────────┘ └──────────┘                │                 │
└──────────────────────────────────────────┴─────────────────┘
Other tabs on desktop: TopNavBar → SessionBar 40px → page.

Tablet/Phone (<1080px), unchanged (R2-Q23):
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
| Stat Strip | none (R3-Q4) | 3 cols | 2 cols (4 stats) |
| Court Grid | 2×2, fills the free height (4 courts fixed, R2-Q2); with `CourtCount.editable` on: largest courts that fit, min height 136px, else scroll | 2 cols | 1 col |
| Analytics Grid | 2 cards per row | 1 col | 1 col |
| KPI Row | 6 cols | 3 cols | 1 col |
| Two-Column Form | Row | Row | Column |
| Chart Grid | 2:1 | 1 col | 1 col |
| Player Row | NAME 1fr, SIGN-IN ID 140, LEVEL 140, TYPE 120, More 88 | fixed (PR 45) | intrinsic widths, so the name keeps the leftover space |

All breakpoints use the viewport width (`MediaQuery.sizeOf(context).width`), not the width left
after the shell padding.

On desktop the court grid fills the free height and scrolls itself when the courts do not fit
(`courtGridLayout`). A court may be flatter than 1.6:1 down to a minimum height of 136px (`minCourtHeight`), never under 320px wide. A court card shorter than 200px uses compact padding (`CourtCard`, `PlayerSlot`). The default court count is 4. In the stacked layout (<1080px) the grid is shrink-wrapped and one page
scroll view holds the stat strip, the action and rotation bars, the chips and the courts.

### 3.3 Navigation Patterns by Breakpoint

| Breakpoint | Primary Nav | All Tabs Accessible Via |
|------------|-------------|------------------------|
| Desktop | Top nav: Courts, Players, Sessions + session bar | "⋯" menu (Analytics, Settings) |
| Tablet | Top tab bar (scrollable, 5 tabs; unchanged) | Top tab bar |
| Phone (tabbar) | Bottom tab bar (3 items: Courts, Players, More) | "More" bottom sheet |
| Phone (hamburger) | Hamburger menu overlay | Hamburger menu |

---

## 4. Interaction Patterns

### 4.1 Waitlist → Court Placement
```
Only on a court whose clock does not run, or on the next round in edit mode (R3-Q11).
1. User taps waitlisted player → player highlights (2px #c2410c outline on desktop)
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

### 4.3 Fill rule (replaces "Auto-Promote by tier", 2026-10-17, R2-Q9; narrowed 2026-10-20, R10-Q1)
```
Scope: ONE empty place only (R10-Q1). A full round is not made by this rule (see below).
When a slot opens (check-out, delete, set Disabled) in a round that can change
(saved next round, or a live round whose clock does not run):
1. Candidates = players who sit out that round
2. Fewest rounds played this session first (GameData.getCurrentPlayersHistory).
   A late player starts at 0 rounds: no average credit (R10-Q3)
3. Tie: the candidate who gives the smallest level gap on that court (R10-Q2)
4. Fill only the freed slot. A live court while the clock runs is never changed:
   the leaving player stays there until the round ends.
5. "Move to waitlist" opens a slot too; it is filled the same way (R7-Q6).
   In CHANGEOVER, round N+1 is the saved next round, so it is filled.
Waitlist panel order (R10-Q2): the order the rule would use for the next open place
(first court with an open slot, Court 1 first); with no open slot, the tie-break is
check-in order, earliest first.
```
**Full round (matchmaker, unchanged, R10-Q1).** "Generate round 1", "Discard & regenerate",
"Make round N+1", the planned round at TIME UP and a fresh lineup at a start button keep
`GameData.makeGame()`: the weighted random pick `_choosePlayer` (weight
`1 / exp(2 × (rounds played − session average))`) and then the court swap optimiser
`_improveEloSpread` (cost `0.1 × average court gap + largest court gap`). Re-roll (§4.2) also
stays as it is.

### 4.4 Check-in Flow (2026-10-17)
```
1. Scan (or type + Enter) in the scan field, or tap a row
2. Check in: the waitlist only — never a live court, never a saved next round (R7-Q7, overrides R2-Q7)
3. Check out: count drops at once; fill rule (4.3) in the next round (R2-Q8)
4. A scan updates the ScanResultBox (no Undo, R9-Q8); a row tap does not (R3-Q3)
   A late check-in starts at 0 rounds played (R10-Q3)
5. Same card as the last scan check-in (no time limit): SCANNED TWICE, nothing changes (R2-Q11, R6-Q15)
6. At capacity: banner; the check-in is refused (SESSION FULL / bottom message)
```

### 4.5 Level Adjustment (in the More panel since 2026-10-17, R2-Q17)
```
+/- buttons adjust the Elo level (C2…S1) up/down; the panel shows the Elo code (R2-Q18)
├── Disabled at boundaries (Amateur / Professional)
├── Buttons visually dim (opacity 0.35) when disabled
└── ELO value changes to tier midpoint
```

### 4.7 Round lifecycle (2026-10-17)
```
            Generate round 1                 Start round 1 (at once, no changeover, R9-Q2)
 [no lineup] ───────────────► [READY draft] ─────────────────────────► [RUNNING n]
      ▲                         │ Discard & regenerate (stays READY)        │  ▲
      │ End session (any)       ▼                                    Pause  │  │ Resume round n
      │                                                                     ▼  │
      │                                                                 [PAUSED n]
      │
 [RUNNING n] ── 0:00, round n+1 saved ──► [CHANGEOVER n+1, 20 s] ── 0:00 / Start round n+1 now ──► [RUNNING n+1]
      │                                         ▲ (Pause freezes the 20 s;       logs round n
      │                                         │  "Resume changeover")          (not if discarded)
      │                                         │  0:00 with unsaved edits: waits at 00:00 until
      │                                         │  "Save round n+1" (R9-Q4)
      └── 0:00, not saved ──► [TIME UP n] ──────┤ Start round n+1 / Discard… / Save round n+1 (edit open)
                              courts show the   │
                              planned round n+1 │
 Start round n+1  (RUNNING, PAUSED, TIME UP) ───┤ saves n+1, logs nothing at the click
 Discard round n and start again (same; confirm) ┘ round n never logged; number n again (R9-Q1, R9-Q3)
 Make / Edit round n+1 (RUNNING, PAUSED) → edit mode → Save round n+1 | Discard & regenerate | ×
```
Rules: every new round after round 1 goes through the 20 s changeover (R6-Q1). A round is
logged only when the next round starts (R3-Q8, R6-Q2). Round number = logged rounds this session
+ 1. One next round at a time. 0:00 with edit mode open: TIME UP (not saved) or CHANGEOVER
(saved), and edit mode stays open (R6-Q3). Re-roll and editing work on a court whose clock does
not run, and on the next round in edit mode; a live court while the clock runs (RUNNING or
CHANGEOVER, R7-Q4) offers only "Check out" (R3-Q10, R3-Q11). End session in TIME UP or
CHANGEOVER logs the round that ended, once (R6-Q5). Round 1 starts at once (R9-Q2). Discard
asks first and keeps the number (R9-Q1, R9-Q3). Paused in edit mode: "Start round n+1" and
"Resume round n" (R9-Q5). A changeover that ends with unsaved edits waits at 00:00 for the save
(R9-Q4). "×" asks "Close without saving?" first; while the changeover waits, "Close" starts the
saved round n+1 unchanged (R11-Q2). "Start round n+1" in paused edit mode saves the edits,
then the changeover starts (R11-Q3). The changeover strip after a discard reads "Round n
discarded · new lineup for round n" (F10). A paused changeover follows the PAUSED rules for
round n+1 (F17). Edit mode is a flag, kept through Pause (F02).

### 4.8 Undo (memento, one level, swap only)
```
action (a swap on Courts — the only Undo in this build, R9-Q8)
  1. take SessionMemento (in-memory session copy) — replaces any older memento
  2. run the swap (it logs no round)
Undo
  3. restore the memento, notify
```
Courts: a swap shows the bottom message "Swapped {A} and {B}. Undo", 10 s; any other change
closes it; no Ctrl/Cmd+Z (R6-Q6, R7-Q2). Players: no Undo after a scan (R9-Q8 overrides
R2-Q10 and the scan part of R3-Q2; UAT PLY-20 removed).
**On hold (R6-Q6, R4-Q2 paused):** Courts round Undo for Start, Discard and End session, with the
log receipt and the log-entry delete (IMPLEMENTATION 8.3 keeps the design for later).

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
| **Courts** | Round bar, next-round strip, 2×2 court grid, waitlist panel (desktop); stat strip and chips on tablet/phone | Generate / start / discard and start rounds, pause, edit the next round, place/swap, undo a swap, re-roll, slot ⋯ menu, end session |
| ~~**Check-in**~~ | Merged into Players | — |
| **Players** | Scan field + result box, count, player table, More panel, pending approvals, 4 tier chips | Scan check-in/out, add player, adjust level and membership (More panel), view stats |
| **Sessions** | Round mode toggle, capacity/courts inputs, template list. Sessions tab redesign: canvas board "Sessions", pending (R7-Q3); its court count control shows only with `CourtCount.editable` | Configure session, save/load templates |
| ~~**Schedule**~~ | Removed 2026-10-10 | — |
| **Analytics** (via ⋯) | Attendance trend, court utilization, level gap, level distribution, KPI row | Filter time range (4/12/26 wks) |
| **Settings** (via ⋯) | Language, membership summary, level note | Change language |

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
- Stat strip columns: none on desktop (R3-Q4) → 3 → 2
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
