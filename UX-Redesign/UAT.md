# UAT Spec — Badminton App

Source of truth: `Badminton App.dc.html` (primary), `Self Registration.dc.html`
(linked public flow), `Analytics Dashboard.dc.html` (merged into the Analytics tab per
decisions below), `Responsive Layouts.dc.html` (breakpoint/device reference only, not a
separate screen). `Dashboard Options.dc.html` and `Calming Wireframes.dc.html`
are superseded explorations — excluded (see "Excluded from scope").

**2026-10-17 design build.** The approved design (artifact `9JBfi4Rk8igxQMVDexk6So`: Main,
Players, ScanStates, TypeColour) and the decisions in
`audit/design-diff-2026-10-17/decisions.md` (IDs R1-Q1 … R12-Q2; a later row overrides an
earlier one) replace the old prototype for
the Courts tab, the shell and the Players tab. A decision overrides the design HTML. A case
changed by this build names its decision IDs in brackets, for example (R2-Q4). A removed case
keeps its ID and reads "Removed (2026-10-17 design): reason". A case on hold keeps its ID and
reads "On hold": it is not in this build. `TODO(Nathan)` marks wording or
behaviour that no decision fixes yet. This release changes the desktop layout only (R2-Q23,
R6-Q7): phone and tablet layouts stay as they are now. The round logic is shared by all sizes.
**Sessions tab redesign: built on desktop** from the canvas board "Sessions" (R7-Q3,
IMPLEMENTATION 8.10, 2026-10-21). Nathan reviews and fixes it later in a separate task. Phone
and tablet keep the §5 layout. The template Load and delete rules of the design review below
(F25) are built.

**2026-10-20 decisions and design review.** Decisions R11-Q1 … R11-Q6 are in force: "×" in
edit mode asks "Close without saving?" first, also while the changeover waits (R11-Q2, RND-06,
RND-07); "Start round {n+1}" in paused edit mode saves the edits, then the changeover starts
(R11-Q3, RND-14); a checked-out player on a running live court has no "⋯" (R11-Q4, COURT-16);
the TIME UP chip is red `#b91c1c` with white text and the time is `#ff6a2b` (R11-Q5, RND-09).
The design review (`audit/design-review-2026-10-20/resolution.md`, findings F01 … F30) is
applied: a case it changes names the finding, for example (F01). Nathan answered F05 and F28
(R12-Q1, R12-Q2): "Start round {n+1}" while RUNNING with time left asks "End round {n} now?"
first, with no dialog in PAUSED or TIME UP (RND-04); the next-round strip in RUNNING, when round
n+1 is not saved, also offers "Save round {n+1}", which saves the matchmaker lineup with no
edit mode (RND-05, RND-22).

Each case has an ID for traceability to future test names (e.g. `DASH-03` → `test('DASH-03: ...')`).
Format: **Given / When / Then**. Numbers, thresholds and defaults below are taken directly from the
prototype's logic and should be treated as acceptance values, not approximations.

--- 

## 1. Domain glossary & reference data

| Concept | Value |
|---|---|
| Skill tiers (index → label) | 0 Amateur · 1 Intermediate · 2 Advanced · 3 Professional |
| Level gap (a group of players) | `max(tier index) − min(tier index)` across the group |
| Level gap label | `0` → "Same level"; `N>0` → "N level gap" |
| Level gap source | The court pill and the Avg Level Gap stat use the 4-tier gap (`Game.tierGap()`). This is display only. Session logs keep the Elo gap (`eloGap`). |
| Court size | 4 players per court |
| Default courts | 4. Fixed on the Courts tab (`CourtCount.editable=false`, R2-Q2). Range **1–8** only with the flag on. The Sessions tab design adds a court count control, shown only when `CourtCount.editable` is on (R7-Q3, SESS-04) |
| Default session capacity | 20 (organizer-adjustable, minimum **4**) |
| Default round mode | Time-based |
| Round modes in the release build | Time-based only. Game-based mode is hidden behind `GameMode.enabled` (`false` in release). `getGameType()` then returns time-based. A stored game-based setting, or the mode in a template, is ignored. The stored `gameType` preference is never rewritten. |
| Other release flags (code kept, hidden in UI) | `PlayersPage.showImportButton=false` (CSV Import button), `SettingsPage.showSignupPreview=false` (signup preview link), `AnalyticsPage.showHiddenCards=false` (per-court gap and player mixing cards) |
| Default round duration | **10 min** (R2-Q24). The organizer sets it as `mm:ss` on the Sessions tab (SESS-02) |
| Changeover | **20 s**, fixed (R3-Q7). It runs before every new round after round 1: at 0:00 when the next round is saved (RND-03), and after "Start round {n+1}" (in RUNNING after its confirm, R12-Q1), "Discard round {n} and start again" and "Save round {n+1}" in TIME UP (R6-Q1, R6-Q3, R7-Q1, R9-Q1). "Start round 1" has no changeover: round 1 starts at once (R9-Q2). The changeover counts as "the clock runs" (R7-Q4). If edit mode has changes that are not saved when the changeover reaches 0:00, the changeover stops at 0:00 and waits for "Save round {n+1}" (R9-Q4, RND-06) |
| Round states | READY · RUNNING · PAUSED · TIME UP · CHANGEOVER. The round bar and the session bar show the state as a chip (R4-Q6) |
| Rounds played | The number of logged Rounds of this Session that hold the Player (`GameData.getCurrentPlayersHistory`). A Round is logged when the next Round starts (R3-Q8). A Player who checks in late starts at 0 Rounds: the app gives no credit for the Rounds played before the check-in, such as the Session average (R10-Q3) |
| Matchmaker (a full round) | To make a full lineup ("Generate round 1", "Discard & regenerate", "Make round {n+1}", the strip "Save round {n+1}" (R12-Q2), the planned round at TIME UP, a fresh lineup at a start button), the app keeps the current algorithm: a weighted random pick of the Players (`GameData._choosePlayer`, weight `1 / exp(2 × (rounds played − Session average))`, so a Player with fewer Rounds is more likely to play), then the court swap optimiser (`GameData._improveEloSpread`, cost `0.1 × average court level gap + largest court level gap`). The fill rule does not make full rounds (R10-Q1) |
| Fill rule (one open place) | Used only when the app fills **one** open place: a check-out, a delete or a set to Disabled (WL-02), and "Move to waitlist" (COURT-15). The app takes the waiting Player who has played the fewest Rounds this Session. On a tie, it takes the Player who gives the smallest level gap on that court (R2-Q9, UX-01, R10-Q1, R10-Q2) |
| Waitlist order | The waitlist panel lists the Players in the order the fill rule would use for the next open place: fewest Rounds first; on a tie, the smallest level gap on the first court (Court 1 first) that has an open place; with no open place to compare, check-in order, earliest first (R10-Q2, WL-01) |
| Level text | Tier name (for example "Intermediate") in every user-facing place. The Elo code (for example "B1") shows only in the Players More panel (R2-Q18). The Players level chips are the 4 tiers, not the 8 Elo codes (R6-Q13) |
| Typeface | Source Sans 3 only. Chinese text uses the Windows system fonts (Microsoft YaHei for zh, Microsoft JhengHei for zh_HK) (R3-Q6). All UI text comes from ARB keys in en, fr, zh, zh_HK |
| Theme | Light only. The dark theme is removed |
| Minimum enforced round duration | 30 sec (floor, not reachable via the UI slider) |
| Responsive breakpoints | Phone `< 720px` · Tablet `720–1079px` · Desktop `≥ 1080px` |
| Reference device widths | Desktop 1280px · iPad landscape 1194px (**renders as desktop layout**) · iPad portrait 834px (tablet layout) · Phone 390px |
| Phone nav variants | `tabbar` (default) — bottom bar + "More" sheet; `hamburger` — full-screen menu |
| Level-up/down step | ±1 tier per click, clamped to [0,3] |

**No raw ELO is ever displayed to any user (organizer or player).** Internally a numeric "elo" field
may exist for tie-breaking/sorting, but every acceptance case below is written in terms of the 4
named tiers and tier-index gaps only. One exception: the Players More panel shows the Elo code
(C2 … S1) beside the level stepper (R2-Q18, PLY-05). This applies to the Analytics tab as well (see §9), overriding
the raw-ELO numbers shown in the standalone `Analytics Dashboard.dc.html` prototype file.

### Excluded from scope
- `Dashboard Options.dc.html` (iterations 1a/1b/1c/2a and the 3a "Tweaks" panel — Mood/Layout/Density
  props) — superseded by the standalone `Badminton App.dc.html`. The Mood/Layout tweaks were a
  design-tool comparison aid (set via `dc_set_props`), never exposed as an in-app control, and were
  not carried into the final build.
- `Calming Wireframes.dc.html` — explicitly divergent A/B exploration, never adopted.
- `Responsive Layouts.dc.html` — a showcase canvas that mounts multiple instances of the real app in
  device frames; it has no behavior of its own. Its device dimensions are used as the reference
  breakpoints in §1 and §3.
- **Schedule tab, notification toggles, fees, invite link and club name** are removed
  (2026-10-10). The app runs offline. Session templates (§5) replace the Schedule tab.
- **UX review rows out of scope (2026-10-17).** UX-30 … UX-36 ("revisit after implementation"),
  UX-13 (skipped), UX-23 and UX-24 (phone, deferred). UX-12, UX-15, UX-19 and UX-20 were
  deferred, but R2-Q6, R2-Q17, R2-Q13 and R3-Q5 bring parts of them into scope. The design
  header "Tuesday session · 7:00–9:00 PM" and the round sub-label "Ends 19:42" are not built
  (R3-Q5, R4-Q8).
- **`phoneNav` and `density`** are prototype component props only. The app has no such setting:
  phones always show the bottom tab bar and the ☰ menu together (NAV-03, NAV-05), at one density.

---

## 2. Cross-cutting: Navigation & Responsive Layout

**NAV-01** — Desktop top nav (changed 2026-10-17: R2-Q13, R3-Q5; 2026-10-20: duration text, F29)
Given viewport width ≥ 1080px
When the app loads
Then a 56 px dark top nav shows, at the left, the text on two lines: "Session" over
"{duration} rounds" (for example "Session" / "10 min rounds", as on the boards, F29). It shows
no club name and no template name.
And a duration that is not whole minutes shows as `m:ss`, for example "10:30 rounds". A
duration in whole minutes shows as "{m} min", for example "10 min".
And at the right it shows 3 tabs, "Courts", "Players", "Sessions", and a "⋯" button (NAV-09).
And the active tab has white text at weight 600 and a 3 px orange underline. It has no fill.
And the compact phone header and the bottom bar or hamburger are not shown.
Given viewport width 720–1079px (tablet)
Then the top nav stays as before this build: 5 tabs (Dashboard, Players, Sessions, Analytics,
Settings), with the label "Dashboard" (R2-Q23, R6-Q7).
As built (8.6.3, 2026-10-21): the minutes in `m:ss` have no leading zero ("5:30 rounds"). The
tabs and "⋯" have the 3 px `#ff6a2b` focus ring (F07). Tests: `test/shell/top_nav_test.dart`,
`integration_test/shell_navigation_test.dart`.

**NAV-02** — Phone compact header
Given viewport width < 720px
When the app loads
Then a compact dark header shows the current tab's label (no club name); the 5-tab top row is
not shown.

**NAV-03** — Phone bottom tab bar (default nav)
Given viewport width < 720px
When the app loads
Then a bottom bar shows 3 destinations: Dashboard ("Courts"), Players, and "More".
Selecting Dashboard/Players switches tabs directly. Selecting "More" opens a bottom sheet
listing Sessions, Analytics, Settings; selecting any of those switches to that tab and
closes the sheet; tapping the scrim outside the sheet closes it without switching tabs.

**NAV-04** — "More" tab highlighted when on a secondary tab
Given phone width and the current tab is Sessions, Analytics, or Settings
When the bottom bar is shown
Then the "More" button is rendered in its active/highlighted state (not one of the 3 primary
buttons).

**NAV-05** — Phone hamburger nav
Given viewport width < 720px
When the app loads
Then the compact header shows a ☰ button, and the bottom tab bar (NAV-03) is also shown (there is
no `phoneNav` setting). Tapping ☰ opens a dark menu panel on the right that lists all 5 tabs with
the current tab highlighted; selecting a tab switches to it and closes the menu; tapping the scrim closes the menu without switching tabs.

**NAV-06** — Stat strip reflow (changed 2026-10-17: R3-Q4)
Given the app is on the Dashboard/any tab
(All breakpoints in NAV-06…08 and ANA-14 use the viewport width, not the width left after the shell
padding.)
When viewport width is desktop (≥1080px)
Then the Courts tab shows no stat strip (R3-Q4). The round bar shows "{in}/{capacity} in ·
{waiting} waiting" instead (RND-01). The re-roll count shows on the Analytics tab only (ANA-08).
When viewport width is tablet (720–1079px)
Then the same 6 stats are shown, wrapped 3-per-row.
When viewport width is phone (<720px)
Then only 4 stats are shown in a 2×2 grid: Checked In, Waitlist, Avg Level, Remaining.

**NAV-07** — Dashboard layout reflow (desktop changed 2026-10-17: R3-Q4, R2-Q2)
Given the Courts tab is active
When viewport width is desktop (≥1080px, including the 1194px iPad-landscape reference)
Then, from the top, the page shows: the top nav (56 px), the round bar (80 px, full width,
RND-01), the next-round strip (48 px, when RND-22 shows it), then a 2×2 court grid with a
280 px waitlist panel at its right. There is no stat strip and no action bar.
And the 4 courts are visible without scrolling at 1280x720, 1366x768, 1440x900 and 1920x1080,
also when the next-round strip shows. The 4 player slots share the card height, so there is no
empty band below the last slot. The waitlist panel scrolls independently: its header, search
field and hint stay fixed, and its list takes the rest of the panel height and scrolls, so
with 8 or more waiting players every entry is reachable at 1280x720 (F12).
With the flag `CourtCount.editable` on and more than 4 courts, the grid uses the most columns
and **scrolls**, so every court stays reachable (as before this build).
When viewport width is tablet or phone (<1080px)
Then the waitlist renders as a horizontally-wrapping chip row above the courts, and courts stack
below it at the minimum proportion (2 columns on tablet, 1 column on phone); the page scrolls.
And the stat strip, then a compact round bar (the same states and buttons as RND-01, wrapped in
a card), then the next-round strip show above the chips (as built in 8.5, 2026-10-21: the PR 45
rotation bar is removed, 8.2.2). Tests: `test/features/dashboard_breakpoints_test.dart`,
`test/features/dashboard_four_courts_fit_test.dart`.

**NAV-08** — Table header rows hidden on phone
Given the Players tab is active (with integrated check-in)
When viewport width ≥ 1080px
Then a column-header row is shown above the list, reading NAME · SIGN-IN ID · LEVEL · TYPE
and a blank More column (R2-Q17). There is no "Checked in" header. The labels are caps,
12 px, weight 600, muted colour.
When viewport width is 720–1079px
Then the header row stays as before this build (NAME / ID · LEVEL · MEMBERSHIP) (R2-Q23).
And phone and tablet rows keep the level stepper and the membership pill as now. R2-Q17 moves
them into the More panel on desktop only (R6-Q7).
When viewport width < 720px
Then the header row is omitted; only data rows are shown, and each row fits the width without
clipping its controls (the level, membership and More columns drop their fixed widths so the
name keeps the remaining space).

**NAV-09** — "⋯" menu for Analytics and Settings (added 2026-10-17: R2-Q13)
Given viewport width ≥ 1080px
When the organizer clicks "⋯" in the top nav
Then a menu opens with 2 items: "Analytics" and "Settings".
When the organizer selects an item
Then the app shows that tab and the menu closes.
Given the current tab is Analytics or Settings
Then the "⋯" button shows the active style (white, 3 px orange underline), and no other tab does.
When the organizer presses Esc or clicks outside the menu
Then the menu closes and the tab does not change.
And a screen reader reads the "⋯" button as "More pages: Analytics, Settings". Test:
`test/shell/top_nav_test.dart`.

**NAV-10** — Session bar on the other tabs (added 2026-10-17: UX-05, R4-Q4, R4-Q6; 2026-10-20: F24, F29)
Given viewport width ≥ 1080px and the current tab is not Courts
Then a 40 px dark session bar shows under the top nav, on every tab except Courts.
And it shows, from the left: "ROUND {n}", the time ("04:12"), the state chip (READY, RUNNING,
PAUSED, TIME UP or CHANGEOVER), "{in}/{capacity} in · {waiting} waiting", and then "· round
{n+1} saved" when the next round is saved, or "· round {n+1} not saved" when it is not (R6-Q12).
The order ROUND · time · chip is the same as on the round bar (F29).
At the right it shows "View courts →".
And the state chip is a polite live region, so a screen reader announces a state change (for
example TIME UP) on any tab. The time is not a live region (F24).
When the organizer clicks the session bar
Then the app shows the Courts tab.
When a round starts or ends while the organizer is on another tab
Then the session bar updates. The app shows no other message (R4-Q4).
As built (8.6.3, 2026-10-21): "· round {n+1} saved" or "· round {n+1} not saved" shows only
while round n has its clock (RUNNING, PAUSED, TIME UP). READY and CHANGEOVER show only the
counts. In CHANGEOVER the bar shows "ROUND {n+1}", as the round bar does. The bar has the 3 px
`#ff6a2b` focus ring (F07) and is a link for screen readers. Test:
`test/shell/session_bar_test.dart`.

**NAV-11** — Session bar states (added 2026-10-17: R4-Q6)
Given no lineup exists (session start, or after End session)
Then the session bar shows "No round yet" in place of the round, chip and time.
Given a round is RUNNING and 60 s or less remain
Then the time in the session bar is amber, as on the Courts round bar (RND-02). Above 60 s it
is white.
Given the state is PAUSED and 60 s or less remain
Then the time is not amber (R6-Q8).
Given the state is READY, PAUSED, TIME UP or CHANGEOVER
Then the chip shows that state, and the time shows the same value as the Courts round bar.
And with no lineup the counts still show after "No round yet". The time colours are those of
the round bar: PAUSED `#c9c2b8`, TIME UP `#ff6a2b`, CHANGEOVER `#ff6a2b` (one `RoundStatus`
class gives both bars their chip and time). Test: `test/shell/session_bar_test.dart`.

**START-01** — Data file fails to load at start-up
Given a data file cannot be loaded when the app starts
Then a plain error screen shows and names the data folder (`app_load_error`). The app writes
nothing to disk (see PERSISTENCE.md §3.1).

---

## 3. Courts tab — round lifecycle & courts

> **Scope note:** RND-01…22 describe **Time-based** mode only. Game-based mode
> has no countdown and no automatic rotation — see GB-01…07 below.
>
> **2026-10-17 round model.** A Round has these states: no lineup → READY (draft, clock
> stopped) → RUNNING ⇄ PAUSED → (0:00) TIME UP or CHANGEOVER → next Round RUNNING. A Round
> must be saved before its clock starts (R2-Q4). Round 1 starts at once, with no changeover
> (R9-Q2). Every new Round after round 1 starts through the 20 s CHANGEOVER: at 0:00 with a
> saved next Round, and after "Start round {n+1}" or "Discard round {n} and start again"
> (R6-Q1, R7-Q1, R9-Q1). The app logs Round n (history, `games.json`, one `SessionLog`) when
> Round n+1 starts: at the end of the changeover, or with "Start round {n+1} now" (R3-Q8,
> R6-Q2). A discarded Round is never logged, and the next Round uses the same number again
> (R2-Q5, R9-Q1). So the round number is always the number of logged Rounds this Session + 1. The state names on the chips are READY,
> RUNNING, PAUSED, TIME UP and CHANGEOVER (R6-Q12).

**RND-01** — Round bar display (changed 2026-10-17: R2-Q20, R4-Q7, R4-Q8)
Given the Courts tab is active on desktop
Then an 80 px dark round bar shows under the top nav in every state. It shows, from the left:
"ROUND {n}" (caps label) with the sub-label of RND-09 under it; the time as `mm:ss` at 50 px;
the state chip; and "{in}/{capacity} in · {waiting} waiting". The buttons of the state are at
the right, then a "⋯" round menu (RND-20).
And a 4 px progress bar at the bottom edge **fills with elapsed time**: its width is elapsed ÷
duration (R4-Q7). In CHANGEOVER it fills with elapsed changeover time ÷ 20 s.
When the clock runs
Then the time and the progress bar update at least once per second.
And the state chip is a polite live region; the time is not (F24, NAV-10).

**RND-02** — Final-minute amber (changed 2026-10-17: R4-Q6, R6-Q8; 2026-10-20: F26)
Given a round is RUNNING and 60 s or less remain
Then the round bar time and its progress fill turn amber, and the session bar time turns amber
(NAV-11). Both bars use the same amber, `#ffb38a` (`color.urgent.onDark`; R6-Q8, F26).
Given the state is PAUSED
Then the time is not amber, also with 60 s or less left (R6-Q8).
Given the state is CHANGEOVER
Then the time keeps the CHANGEOVER colour.

**RND-03** — 0:00 with a saved next round starts the changeover (changed 2026-10-17: R2-Q4, R3-Q7, R6-Q2)
Given round n is RUNNING and round n+1 is saved
When the time reaches 00:00
Then the state becomes CHANGEOVER. The round label reads "ROUND {n+1}", the sub-label reads
"Players to courts", the chip reads "CHANGEOVER", and the time counts down from 00:20.
And the court grid and the waitlist show the round n+1 lineup. The strip reads "Round {n}
ended" (RND-22).
And the round bar shows "Pause" and "Start round {n+1} now".
And round n is not logged yet. It is logged when round n+1 starts (RND-06).
And the courts count as "the clock runs": no "Re-roll", and the slot "⋯" shows "Check out"
only, except while the organizer edits round n+1 in edit mode (R7-Q4, COURT-14).
And if edit mode for round n+1 is open, it stays open (RND-14).

**RND-04** — "Start round {n+1}" (changed 2026-10-17: UX-07, R3-Q8, R6-Q1, R6-Q14, R6-Q18, R7-Q1; 2026-10-20: R9-Q5; 2026-10-21: R12-Q1, F05)
Was "Save and start new round".
Given round n is RUNNING, PAUSED or TIME UP and the page is not in edit mode, or round n is
PAUSED and edit mode is open (RND-14, R9-Q5)
When the organizer clicks "Start round {n+1}" (in RUNNING: and confirms it, below)
Then round n+1 is saved with its lineup: the saved round n+1, or in TIME UP the planned round
on the courts (RND-15), or else a new matchmaker lineup. The click saves it (R2-Q4).
And the state becomes CHANGEOVER for round n+1, as in RND-03 (R6-Q1). The courts show the
round n+1 lineup for 20 s before its clock starts.
And round n is not logged at the click. It is logged when round n+1 starts (RND-06, R6-Q2). A
court with fewer than 4 players is logged as it stands.
And no Undo message shows (RND-21 is on hold, R6-Q6).
And a double click starts one changeover, and round n is logged once (R6-Q18).
Confirm in RUNNING (R12-Q1, F05):
Given round n is RUNNING with time left and the page is not in edit mode
When the organizer clicks "Start round {n+1}" in the round bar
Then a dialog asks "End round {n} now?" and says "{mm:ss} left." ({mm:ss} is the time left
on the clock). The buttons are "Start round {n+1}" and "Cancel". The dialog follows the
confirm pattern (RND-07): initial focus on "Cancel", Esc = "Cancel".
And the clock continues while the dialog shows.
When the organizer clicks "Cancel" or presses Esc
Then nothing changes, and round n keeps running.
When the phase changes while the dialog shows (for example the time reaches 00:00)
Then the dialog closes with no action. The state that the phase change makes applies (RND-03,
RND-15).
When the organizer clicks "Start round {n+1}" in the dialog
Then the cases above apply: round n+1 is saved and the changeover starts.
And a double click on that button starts one changeover (R6-Q18).
Given round n is PAUSED (also in edit mode) or TIME UP
When the organizer clicks "Start round {n+1}"
Then no dialog shows, and the changeover starts at once as above (R12-Q1).

**RND-05** — "Make round {n+1}" opens edit mode; "Save round {n+1}" saves at once (changed 2026-10-17: R2-Q6, UX-10; 2026-10-21: R12-Q2, F28)
Given round n is RUNNING or PAUSED and round n+1 is not saved
When the organizer clicks "Make round {n+1}" in the next-round strip
Then the app makes a round n+1 lineup with the matchmaker. It does not change the live courts.
And the page enters edit mode (RND-10). (R2-Q6 is unchanged: this is the way to review the
lineup first.)
Given round n is RUNNING, round n+1 is not saved, and the page is not in edit mode
When the organizer clicks "Save round {n+1}" in the next-round strip
Then the app makes a round n+1 lineup with the matchmaker and saves it at once. The page does
not enter edit mode, and the live courts do not change (R12-Q2, F28).
And the result is the same as "Make round {n+1}" and then "Save round {n+1}" with no change:
the strip reads "Round {n+1} saved" with "Edit round {n+1}" (RND-22), and at 0:00 the
changeover starts (RND-03).
And nothing is logged, and the clock of round n does not change.
And a double click saves one round n+1 (R6-Q18, RND-08).
Given round n+1 is saved
When the organizer clicks "Edit round {n+1}"
Then the page enters edit mode with the saved lineup.

**RND-06** — The changeover ends and round n+1 starts (changed 2026-10-17: R3-Q7, R3-Q8, R6-Q2; 2026-10-20: R9-Q4)
Given the state is CHANGEOVER for round n+1
When the changeover time reaches 00:00
Then the app logs round n: one history entry, one row per court in `games.json`, one
`SessionLog`. When round n was discarded (RND-16), nothing is logged.
And round n+1 becomes RUNNING with the full duration.
And the saved lineup, with every edit the organizer made, is the live lineup.
And no round n+2 exists yet. The strip reads "Round {n+2} not saved".
And if the write fails, round n+1 does not start, nothing is logged, and the message reads
"Something went wrong. Try again." (R45-01). The state stays CHANGEOVER at 00:00, and "Start
round {n+1} now" tries the write again (as built in 8.2, 2026-10-21).
Given the state is CHANGEOVER for round n+1 and edit mode for round n+1 is open with no changes
that are not saved
When the changeover time reaches 00:00
Then round n+1 starts as above, and the page leaves edit mode.
Given the state is CHANGEOVER for round n+1 and edit mode for round n+1 has changes that are not
saved (R7-Q4 allows edits in CHANGEOVER)
When the changeover time reaches 00:00
Then the changeover time stops at 00:00 and waits (R9-Q4). The chip stays "CHANGEOVER", edit
mode stays open with its changes, and round n is not logged yet.
And the round bar shows no buttons, only the round "⋯" menu (R4-Q9: no start button in edit
mode; "Pause" has no time to freeze).
When the organizer clicks "Save round {n+1}"
Then round n+1 is saved with the edits, the page leaves edit mode, and round n+1 starts as
above (round n logged, round n+1 RUNNING with the full duration).
When the organizer clicks "Discard & regenerate"
Then the app replaces the round n+1 lineup with a new matchmaker lineup, edit mode stays open,
and the changeover still waits. The next "Save round {n+1}" starts round n+1 (R9-Q4).
When the organizer clicks "×"
Then RND-07 applies: the dialog "Close without saving?" shows first (R11-Q2). When the organizer
clicks "Close", the edits are lost and the saved round n+1 starts unchanged, as above. When the
organizer clicks "Keep editing", nothing changes and the changeover still waits.

**RND-07** — "×" leaves edit mode without saving (changed 2026-10-17: R2-Q6; 2026-10-20: R11-Q2, F03, F14)
Given the page is in edit mode for round n+1 and a change was made since edit mode opened
When the organizer clicks "×" at the far right of the edit strip
Then a dialog asks "Close without saving?". The buttons are "Close" and "Keep editing" (R11-Q2,
F03). The dialog follows the confirm pattern (F14, below).
When the organizer clicks "Keep editing"
Then nothing changes, and edit mode stays open with its changes.
The dialog text is "Your changes to round {n+1} are lost." (as built in 8.5, 2026-10-21; no
doc gave a body). A phase change does not close this dialog.
When the organizer clicks "Close"
Then the page leaves edit mode. The changes made since edit mode opened are lost.
And if round n+1 was saved before, the saved lineup stays saved. If it was not saved, the
lineup is dropped and the strip reads "Round {n+1} not saved" (in TIME UP, RND-15 applies).
And the live round and its clock do not change.
Given the page is in edit mode for round n+1 and no change was made since edit mode opened
When the organizer clicks "×"
Then no dialog shows, and the page leaves edit mode as above (F03).
Confirm pattern (F14): every confirm dialog on the Courts tab ("Close without saving?",
"End round {n} now?" RND-04, "Discard round {n}?" RND-16, "End session?" RND-20) is an alert dialog with a title and a
description that screen readers read. The initial focus is on the cancel button ("Keep
editing" or "Cancel"), and Esc is the same as the cancel button. A phase change while the
"End round {n} now?", "Discard round {n}?" or "End session?" dialog shows closes it with no
action (F18, R12-Q1, RND-04, RND-16, RND-20).

**RND-08** — One next round at a time (changed 2026-10-17)
Given round n+1 exists (saved, or open in edit mode)
Then the app has no control to make a second next round. "Make round {n+1}" and the strip
"Save round {n+1}" (R12-Q2) show only when no round n+1 exists.

**RND-09** — Round sub-label and mode (changed 2026-10-17: R4-Q8, R6-Q12; 2026-10-20: R11-Q5, F04, F08)
Given round mode is "Time-based"
Then the sub-label under "ROUND {n}" reads:
- READY: "Not started"
- RUNNING: no sub-label ("Ends 19:42" is removed, R4-Q8)
- PAUSED: "Clock paused"
- TIME UP: "Clock stopped at 0:00" (it stays; F08 puts the round cue on the cards, RND-15)
- CHANGEOVER: "Players to courts"
And the chips read "PAUSED" and "TIME UP" (R6-Q12; the design said "STOPPED").
And the TIME UP chip is red `#b91c1c` with white text `#ffffff`, and the TIME UP time is
`#ff6a2b`, on the round bar and on the session bar (R11-Q5, F04).
And the Sessions tab's duration control is shown. The top nav reads "Session" over "{duration}
rounds" (NAV-01).
Given round mode is "Game-based" (not reachable in the release build, see §1)
Then no round bar is rendered at all and the Sessions tab's duration control is hidden.
Note: switching mode does not by itself start or end a round.

**RND-10** — Edit mode shows and edits the next round (changed 2026-10-17: R2-Q6, R4-Q9)
Given the page is in edit mode for round n+1
Then every court card has a 2 px dashed dark-orange border and a "NEXT" tag.
And a 48 px amber strip reads "Editing round {n+1}" with "Discard & regenerate", "Save round
{n+1}" and "×" at the right (RND-14, RND-07).
And the round bar shows the round n clock and "Pause" only (R4-Q9).
And the waitlist lists the players who sit out round n+1, so no player is on two courts.
And place, swap, re-roll and the slot "⋯" menu change round n+1, never the live courts.

**RND-11** — The next round does not go stale (changed 2026-10-17: R2-Q9, UX-04, R7-Q7; 2026-10-20: tag text)
Given round n+1 is saved
When a player in round n+1 is checked out, deleted, or set to Disabled
Then the app removes the player from round n+1 and fills the slot by the fill rule (§1) from
the players who sit out round n+1.
And if nobody can fill it, the court stays one player short and shows the tag "{count}
players" with the number of players on the court, for example "3 players" (UX-04; ICU plural).
When a player is checked in late
Then the player is not added to round n+1 and waits on the waitlist (CHK-02, R7-Q7).
When a player's details are edited
Then round n+1 shows the updated details.

**RND-12** — No lineup: "Generate round 1" (added 2026-10-17: R2-Q1; 2026-10-20: F22)
Given no court holds a player (session start, or after End session)
Then the round bar reads "ROUND 1", chip "READY", time = the full duration (for example
"10:00"), and one primary button "Generate round 1".
And the waitlist panel lists every checked-in player in check-in order, earliest first, with
no "Next in" tag (F22, WL-01). With no player checked in it shows "No one waiting".
When the organizer clicks "Generate round 1" and 4 or more players are checked in
Then the app fills the courts with the matchmaker and the state becomes READY with a draft
(RND-13). The clock does not start.
When fewer than 4 players are checked in
Then nothing changes and a message reads "Check in at least 4 players. {count} checked in."
(R45-39). The button stays enabled.

**RND-13** — Draft round 1: "Start round 1" (added 2026-10-17: R2-Q1, R2-Q2, R7-Q1; 2026-10-20: R9-Q2)
Was "Save and start round 1".
Given a round 1 lineup exists and its clock has not started (READY, sub-label "Not started")
Then the round bar shows "Discard & regenerate" and the primary "Start round 1".
There is no "COURTS − 4 +" stepper (R2-Q2).
And the organizer can place, swap, re-roll and use the slot "⋯" menu on every court.
When the organizer clicks "Discard & regenerate"
Then the app replaces the draft with a new matchmaker lineup. The clock stays stopped.
When the organizer clicks "Start round 1"
Then round 1 is saved, the state becomes RUNNING at once and the clock starts from the full
duration. Round 1 has no changeover (R9-Q2).
Nothing is logged. No Undo message shows (RND-21 is on hold).

**RND-14** — Save or regenerate the next round in edit mode (added 2026-10-17: R2-Q6, R4-Q9, R6-Q3; 2026-10-20: R9-Q4, R9-Q5, R11-Q3)
Given the page is in edit mode for round n+1
When the organizer clicks "Save round {n+1}"
Then round n+1 is saved, the page leaves edit mode, and the strip reads "Round {n+1} saved".
When the organizer clicks "Discard & regenerate"
Then the app replaces the round n+1 lineup with a new matchmaker lineup, and the page stays in
edit mode.
And while edit mode is open and round n is RUNNING, the round bar shows "Pause" only: no "Start
round {n+1}" and no "Discard round {n} and start again" (R4-Q9).
Given edit mode is open and round n+1 is not saved
When round n reaches 00:00
Then the state becomes TIME UP and edit mode stays open with its changes (R6-Q3).
When the organizer then clicks "Save round {n+1}"
Then round n+1 is saved and the changeover starts (RND-03, R6-Q3).
Given edit mode is open and round n+1 is saved
When round n reaches 00:00
Then the changeover starts (RND-03) and edit mode stays open (R7-Q4). If the edits are not
saved when the changeover reaches 00:00, the changeover waits for "Save round {n+1}" (RND-06,
R9-Q4).
Given edit mode is open and round n is RUNNING
When the organizer clicks "Pause"
Then the chip reads "PAUSED", edit mode stays open, and the round bar shows "Start round {n+1}"
and the primary "Resume round {n}", as on the canvas board "Courts · Paused" (R9-Q5). It shows no
"Discard round {n} and start again".
When the organizer clicks "Resume round {n}"
Then the clock continues from the paused time (RND-17), and edit mode stays open.
When the organizer clicks "Start round {n+1}"
Then round n+1 is saved with the lineup in edit mode, its edits included, the page leaves edit
mode, and RND-04 applies (changeover for round n+1). The edits that were not saved are saved,
not dropped (R11-Q3).

**RND-15** — 0:00 with no saved next round: TIME UP (added 2026-10-17: R2-Q4, R3-Q9, R6-Q4; 2026-10-20: F08)
Given round n is RUNNING and round n+1 is not saved
When the time reaches 00:00
Then the clock stops at 00:00 and the chip reads "TIME UP". Nothing is logged.
And the next-round strip does not show (R6-Q4).
And the court grid and the waitlist show the planned round n+1: the matchmaker makes it at
0:00. Round n keeps its lineup for the log.
And every court card shows the tag "ROUND {n+1}", so the organizer does not read the planned
lineup as round n (F08). The sub-label stays "Clock stopped at 0:00" (RND-09).
And the organizer can change the planned round (place, swap, re-roll, slot "⋯", COURT-14).
These changes, and a check-out, change the planned round only, never the round n lineup.
And the round bar shows "Discard round {n} and start again" and the primary "Start round
{n+1}" (RND-16, RND-04). Both go through the changeover.
Given edit mode was open at 00:00
Then RND-14 applies: edit mode stays open and "Save round {n+1}" starts the changeover.

**RND-16** — "Discard round {n} and start again" (added 2026-10-17: R2-Q5, R3-Q8, R6-Q1, R7-Q1; 2026-10-20: R9-Q1, R9-Q3, F10, F14, F18)
Was "Discard and start new round", then "Discard round {n} and start round {n+1}" (R7-Q1,
replaced by R9-Q1).
Given round n is RUNNING, PAUSED or TIME UP and the page is not in edit mode
When the organizer clicks "Discard round {n} and start again"
Then a dialog asks "Discard round {n}?" and says "Round {n} is not logged. The next lineup goes
on the courts and round {n} starts again." The buttons are "Discard round" and "Cancel" (R9-Q3).
This text is the text of the dialog; the board text "Discard and start again" is not used
(F14). The dialog follows the confirm pattern (RND-07): initial focus on "Cancel", Esc =
"Cancel".
The clock does not stop while the dialog shows.
When the organizer clicks "Cancel" or presses Esc
Then nothing changes.
When the phase changes while the dialog shows (for example the time reaches 00:00)
Then the dialog closes with no action, and nothing is discarded (F18).
When the full label does not fit in the round bar, in any state that shows it, the button
reads "Discard round {n}" (F16; as built in 8.5, 2026-10-21, F16 is applied to every state, not
only PAUSED).
When the organizer clicks "Discard round"
Then the app does not log round n, now or later.
And the new round uses the saved next-round lineup, or in TIME UP the planned round, or else a
new matchmaker lineup. The state becomes CHANGEOVER, as in RND-04 (R6-Q1).
And the new round uses the number n again (R2-Q5, R9-Q1): in the changeover the round label
reads "ROUND {n}" and the button reads "Start round {n} now" (RND-19).
And no Undo message shows (RND-21 is on hold).
And in that changeover the strip reads "Round {n} discarded · new lineup for round {n}" (F10,
RND-22), not "Round {n} ended".

**RND-17** — "Pause" and "Resume round {n}" (added 2026-10-17: R3-Q1, R6-Q14)
Given round n is RUNNING
When the organizer clicks "Pause"
Then the time stops, the chip reads "PAUSED", and the time shows in grey (not amber, RND-02).
And the round bar shows "Discard round {n} and start again", "Start round {n+1}"
(R6-Q14, so the committee can end a round early with the clock paused) and the primary "Resume
round {n}". In edit mode it shows only "Start round {n+1}" and "Resume round {n}" (RND-14,
R9-Q5).
And the next-round strip stays (RND-22).
When the organizer clicks "Resume round {n}"
Then the clock continues from the paused time, and the chip reads "RUNNING".
And nothing is logged by Pause or Resume.

**RND-18** — Pause during the changeover (added 2026-10-17: R4-Q5, R6-Q12; 2026-10-20: F17)
Given the state is CHANGEOVER for round n+1
When the organizer clicks "Pause"
Then the changeover time stops and the chip reads "PAUSED".
And the round bar shows "Resume changeover" (R6-Q12).
And the courts follow the PAUSED rules for round n+1 (F17, COURT-14): every court card shows
"Re-roll", and swap, place and the full slot "⋯" menu work on the round n+1 lineup.
When the organizer clicks "Resume changeover"
Then the changeover continues from the paused time, and the chip reads "CHANGEOVER".
And the courts keep the round n+1 lineup all the time. Round n is still not logged.

**RND-19** — "Start round {n+1} now" (added 2026-10-17)
Given the state is CHANGEOVER for round n+1
When the organizer clicks "Start round {n+1} now"
Then the changeover ends at once and RND-06 applies (round n logged, round n+1 RUNNING).

**RND-20** — End session (added 2026-10-17: R2-Q16, UX-06, R6-Q5; 2026-10-20: dialog text, F09, F14, F18)
Given the Courts tab is active
When the organizer clicks the round menu "⋯" and then "End session"
Then a dialog asks "End session?". The buttons are "End session" and "Cancel". The text names
the round that is logged (F09):
- RUNNING, PAUSED or TIME UP: "Round {n} goes into the history. Everyone is checked out."
- CHANGEOVER for round n (not after a discard): "Round {n−1} goes into the history. Everyone
  is checked out." (the round label reads "ROUND {n}"; round n−1 is the round that ended)
- READY, no lineup, or the changeover after a discard: "Nothing is logged. Everyone is checked
  out."
And the dialog follows the confirm pattern (RND-07): initial focus on "Cancel", Esc = "Cancel"
(F14).
When the organizer clicks "Cancel" or presses Esc
Then nothing changes.
When the phase changes while the dialog shows (for example the changeover ends)
Then the dialog closes with no action, and the session does not end (F18).
When the organizer clicks "End session"
Then the app logs round n once, stops the clock, and checks out every player.
And round n is the round that started last: RUNNING or PAUSED, or the round that ended in TIME
UP or before the CHANGEOVER (R6-Q5). A round that has not started (the planned or saved round
n+1) is not logged. A discarded round is not logged.
And the courts are empty, the round number is 1, and the state is as in RND-12.
And the rounds played of every Player start again at 0 for the next Session. The disk keeps
the log (as built in 8.2, 2026-10-21; `TODO(Nathan)`: confirm).
And no Undo message shows (RND-21 is on hold).
Given the state is READY (round 1 not started)
Then End session logs nothing.
Given no lineup exists (as built in 8.5, 2026-10-21)
When the organizer confirms "End session"
Then nothing is logged and every player is checked out. `GameData.endSession()` refuses the
no-lineup state, so the Courts tab checks out each player itself.

**RND-21** — On hold (R6-Q6): Undo on the Courts tab for "Start round {n+1}", "Discard round
{n} and start again" and "End session" is not in this build (R4-Q2 is paused). Note for
later: R4-Q2 and the R6 answers asked for a 10 s bottom message "Round {n} started. Undo" that
restores the session and the clock time at the click, deletes the log entry the action wrote,
and closes when any other change happens. The only Undo in this build is the swap Undo
(COURT-17). The Players scan Undo is removed (R9-Q8, PLY-20).

**RND-22** — Next-round strip (added 2026-10-17: R2-Q4, R3-Q7, R6-Q2, R6-Q4; 2026-10-20: F10; 2026-10-21: R12-Q2, F28)
Given round n is RUNNING or PAUSED and the page is not in edit mode
Then a 48 px strip shows under the round bar.
When round n+1 is not saved
Then it reads "Round {n+1} not saved" (amber title) and "Clock stops at 0:00 if not saved."
And in RUNNING it has two buttons, "Save round {n+1}" and "Make round {n+1}" (R12-Q2, F28,
RND-05). In PAUSED it has the button "Make round {n+1}" only.
When round n+1 is saved
Then it reads "Round {n+1} saved" (green title) and "Starts 20 s after round {n} ends.", with
the button "Edit round {n+1}".
Given the state is CHANGEOVER for round n+1
Then the strip reads "Round {n} ended" (R6-Q2). Round n is logged when round n+1 starts.
Given the state is CHANGEOVER after "Discard round {n} and start again" (RND-16)
Then the strip reads "Round {n} discarded · new lineup for round {n}" (F10).
Given the state is TIME UP, READY, or no lineup exists
Then the strip does not show (R6-Q4).

---

## 3a. Dashboard tab — game-based mode

> **Release build:** GB-01…07 are hidden in the release build (`GameMode.enabled=false`).
> They are covered by tests with the flag on.

In game-based mode there is no clock. A committee member drives each court by hand:
Regenerate → re-roll a court → Save → the court shows PLAYING → re-roll when the real game
finishes → Save again.

**GB-01** — No countdown
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given round mode is "Game-based"
When the Dashboard is viewed
Then no round bar, countdown, "Rotate now", or "Pre-make next round" control is rendered, and no
rotation timer is started.

**GB-02** — Generate once
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given round mode is "Game-based" and no court holds any player
Then the "Generate Game" button is shown, and it fills every court in one action.
Given at least one court holds players
Then the Generate / Regenerate button is hidden — courts are driven individually from then on.

**GB-03** — No global Save
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given round mode is "Game-based"
Then the Dashboard action bar shows no global "Save" button; saving happens per court.

**GB-04** — Per-court Save
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given a court holds a full lineup of 4 and is not already playing
Then that court's header shows a "Save" button.
When the organizer taps it
Then the match is written to history and the analytics session log, the four players stay on the
court, and the court is marked as playing.

**GB-05** — PLAYING indication
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given a court has been saved
Then its header shows a "PLAYING" badge, its "Save" button is hidden, and its "Re-roll" button
remains available.

**GB-06** — A playing lineup is locked
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given a court is playing
When the organizer selects a waitlisted player and taps a slot on that court
Then nothing changes — the saved lineup cannot be edited, because it is already recorded.

**GB-07** — Re-roll ends the game
*Hidden in release build (GameMode.enabled=false); covered by tests with the flag on.*
Given a court is playing
When the organizer taps "Re-roll" on it
Then the PLAYING badge clears, four players are drawn from those not currently on any court, and
the "Save" button returns. Players on other courts — including ones currently playing — are never
drawn into the new lineup.

**COURT-01** — Court display (changed 2026-10-17: UX-21, R2-Q18)
Given the Courts tab is viewed
Then each court card shows the title "Court {k}" (16 px, weight 600), the level gap as plain
muted text (see §1 label rules; 4-tier gap, `Game.tierGap()`), the "Re-roll" button when
COURT-14 allows it, and 4 slot rows.
And a filled slot shows the player name (14 px, weight 600) and the level tier name at the
right (14 px, weight 400, muted). A slot never shows an Elo code.
And an empty slot reads "Open slot" (R2-Q19).
When the pointer is over a filled slot
Then the slot gets a light fill and shows "⋯" at the right (COURT-15).

**COURT-02** — Re-roll rebalances a court
Given a court has occupants and there is at least one other eligible player (another court occupant
counted together with the full waitlist pool totals more than 4 candidates)
When the organizer taps "Re-roll ⟲" on that court
Then the app evaluates multiple random 4-player combinations drawn from that court's current
occupants plus the entire checked-in waitlist, selects the combination with the lowest level gap,
seats those 4 on the court, returns everyone else in the pool to the waitlist, and increments the
club's re-roll count (visible in Analytics, and in the stat strip on tablet and phone). The count
covers only re-rolls on the live round, not on the next round in edit mode.

**COURT-03** — Re-roll no-op when nobody else is available
Given a full court whose occupants plus the full waitlist total 4 players (or any court when the
total is below 4)
When the organizer taps "Re-roll ⟲" on that court
Then nothing changes (no reshuffle, no re-roll count increment) — there is no one to rotate in.
The dashboard stays silent: no dialog and no error message.
A court with an open slot is still filled when the total is exactly 4.

**COURT-04** — Selecting a waitlisted player to place/swap
Given at least one player is on the waitlist and the courts on screen can take a player
(COURT-14 states)
When the organizer taps a waitlisted player
Then that player is visually highlighted as "selected," and a hint reads "Placing {name} — tap a
court slot"; court slots become visually interactive (hover/tap affordance) while a player is
selected.

**COURT-05** — Switching selection
Given waitlisted player A is currently selected
When the organizer taps waitlisted player B
Then the selection moves directly to B (A is deselected, B is highlighted) — no need to deselect A
first.

**COURT-06** — Deselecting
Given waitlisted player A is currently selected
When the organizer taps player A again
Then the selection clears and the hint reverts to "Tap a waitlisted player, then a court slot to
place or swap them in."

**COURT-07** — Placing a selected player into an empty slot
Given a waitlisted player is selected
When the organizer taps an "Open slot" on a court that can take a player (COURT-14 states)
Then the selected player is seated in that slot, removed from the waitlist, and the selection
clears.

**COURT-08** — Swapping a selected player into an occupied slot
Given a waitlisted player is selected
When the organizer taps an occupied slot on a court that can take a player (COURT-14 states)
Then the two players trade places: the selected player takes the slot, and the slot's previous
occupant is moved to the waitlist; the selection clears.
And the swap Undo message shows (COURT-17).

**COURT-09** — Empty court slots inert with no selection (changed 2026-10-12)
Given no player is currently selected
When the organizer taps an empty court slot
Then nothing happens. (Tapping an occupied slot selects that player, see COURT-10.)

**COURT-10** — Swapping players between courts (changed 2026-10-17: R3-Q11; 2026-10-20: F11)
Given a court that can take a player (COURT-14 states, and not a saved game-based court)
When the organizer taps an occupied slot (the tap selects for a swap, R3-Q11)
Then that player is highlighted as selected (tapping the same slot again clears the selection).
When the organizer then taps a slot on another such court
Then the two players trade places; if the target slot is empty, the player moves there. Nobody
drops to the waitlist, and the selection clears.
And when two players traded places, the swap Undo message shows (COURT-17).
Given a live court while the clock runs (RUNNING or CHANGEOVER, R7-Q4), and the page is not in
edit mode
Then a tap on its slot selects nothing, and it cannot give or take a player (R3-Q11, UX-11).
The slot is not a button for a tap (screen readers read it as not available); only its "⋯"
works (COURT-15) (F11).
And the waitlist entries cannot be pressed, and the waitlist hint reads "Courts change at the
next round" (F11, WL-01).

**COURT-11** — Removed (2026-10-17 design): the "×" remove button is removed (R3-Q11). The
slot "⋯" menu item "Move to waitlist" replaces it (COURT-15).

**COURT-12** — Removed (2026-10-17 design): Re-roll does not show on a live court while the
clock runs (R3-Q10, COURT-14), so the warning dialog has no trigger.

**COURT-13** — Removed (2026-10-17 design): the action bar "Regenerate" is removed in time
mode. "Discard & regenerate" shows only in READY and edit mode, where no round runs
(RND-13, RND-14). "Discard round {n} and start again" goes through the changeover
(RND-16).

**COURT-14** — Where Re-roll and editing show (added 2026-10-17: R3-Q10, R7-Q4; 2026-10-20: F17)
Given the state is READY (draft), PAUSED, TIME UP, or edit mode for the next round
Then every court card shows "Re-roll", and place, swap and the full slot "⋯" menu work.
And a paused changeover is PAUSED for this rule: the round n+1 courts show "Re-roll", and
place, swap and the full slot "⋯" menu work on them (F17, RND-18).
Given a live court while the clock runs (RUNNING, CHANGEOVER)
Then its card shows no "Re-roll", and its slots offer only "Check out" (COURT-15).
And CHANGEOVER counts as "the clock runs", although the courts show round n+1 then (R7-Q4).
The exception is edit mode for the new round: then the edit-mode rules apply.

**COURT-15** — Slot "⋯" menu (added 2026-10-17: R3-Q11, R7-Q6; 2026-10-20: R11-Q4, F06)
Given a filled slot on a court that COURT-14 allows to edit
When the organizer clicks "⋯" on the slot
Then a menu shows "Move to waitlist" and "Check out".
When the organizer selects "Move to waitlist"
Then the player goes to the waitlist and stays checked in.
And the app fills the place by the fill rule (§1) from the other players who sit out that
round (R7-Q6): fewest rounds; on a tie, the smallest level gap on that court (R10-Q2). If nobody can fill it, the slot shows "Open slot".
When the organizer selects "Check out"
Then CHK-05 applies.
Given a filled slot on a live court while the clock runs
When the organizer clicks "⋯"
Then the menu shows "Check out" only.
Given a checked-out player on a live court while the clock runs (COURT-16)
Then the slot has no "⋯" (R11-Q4).
Keyboard (F06): the "⋯" shows on pointer hover and also when the slot or the "⋯" has keyboard
focus. Its hit area is 40×40 px (F27). In the open menu, the arrow keys move between the items,
Enter selects the item, and Esc closes the menu. When the menu closes, focus goes back to the
"⋯".

**COURT-16** — Check out from a live court while the clock runs (added 2026-10-17: R2-Q8, UX-11, R7-Q5; 2026-10-20: R11-Q4)
Given a player is on a live court and the clock runs (RUNNING)
When the organizer checks the player out (slot "⋯" "Check out", a row tap or a scan)
Then the checked-in count drops by 1 at once (R2-Q8).
And the player stays on the live court until the round ends. The slot shows no "leaving"
marker (R2-Q8).
And the player is removed from the saved next round, and the fill rule fills that slot
(RND-11).
And when the round is logged, the log holds the player, because the player played the round.
And a check-out on the Courts tab shows no bottom message; the count drop is enough (R7-Q5).
Given the state is CHANGEOVER for round n+1
When a player in round n+1 is checked out
Then RND-11 applies: round n+1 is the saved next round, so the app removes the player and
fills the slot by the fill rule. The round n log still holds the player.
Given a player who is checked out stays on a live court while the clock runs
Then the slot shows no "⋯" button for that player (R11-Q4), so "Check out" is not offered again.

**COURT-17** — Undo a swap on the Courts tab (added 2026-10-17: R6-Q6, R7-Q2; 2026-10-20: R9-Q8)
Given the organizer swapped two players A and B on the Courts tab (COURT-08, COURT-10)
Then a bottom message shows "Swapped {A} and {B}. Undo" for 10 s.
When the organizer clicks "Undo" in the message
Then A and B go back to their places before the swap, and the message closes.
When 10 s pass, or any other change is made (a new swap, a scan, a check-out, a round change)
Then the message closes and Undo is no longer possible (R6-Q6: any other change cancels the
Undo). A new swap shows its own message. Only one level of Undo exists.
And no key (Ctrl+Z or Cmd+Z) runs this Undo (R7-Q2).
And a move of one player into an open slot is not a swap and shows no message.
And this is the only Undo in this build: a scan on the Players tab has no Undo (R9-Q8).

**WL-01** — Waitlist ordering & display (changed 2026-10-17: R3-Q12, UX-14; 2026-10-20: R10-Q2, F11, F22)
Given one or more checked-in players are waitlisted
Then the 280 px waitlist panel shows the title "Waitlist" and the count.
And it lists the players in the waitlist order (§1): fewest rounds played first. On a tie, the
player who gives the smallest level gap on the first court that has an open place; when no court
has an open place, check-in order, earliest first (R10-Q2). It shows no position numbers
(R3-Q12).
And each entry shows the name, and under it "{tier} · {n} rounds" (for example "Intermediate
· 1 round"; singular for 1).
And an entry shows the green tag "Next in" when the player is in the saved next round (R3-Q12).
Given no lineup exists (RND-12)
Then the panel lists every checked-in player in check-in order, earliest first, with no "Next
in" tag (F22).
Given the live round's clock runs (RUNNING or CHANGEOVER) and the page is not in edit mode
Then the entries cannot be pressed, and the hint reads "Courts change at the next round" (F11).
Given no one is waitlisted
Then "No one waiting" shows in place of the list (R2-Q19).

**WL-02** — Fill rule on check-out (changed 2026-10-17: R2-Q9, UX-01, UX-11; 2026-10-20: R10-Q1, R10-Q2)
Given a slot opens because a player is checked out, deleted or set Disabled
Then the app fills it from the players who sit out that round, by the fill rule (§1): fewest
rounds played this session; on a tie, the player who gives the smallest level gap on that court
(R10-Q2).
And the app fills the slot in the round that can change: the saved next round (also in
CHANGEOVER), the planned next round in TIME UP (RND-15), or the live round when its clock does
not run (READY, PAUSED). It never changes a live court while the clock runs (COURT-16).
And "Move to waitlist" (COURT-15) opens a slot too, and the same rule fills it (R7-Q6).
And it fills only the freed slot (WL-03). No organizer action is needed.
And the fill rule fills one place only. A full lineup comes from the matchmaker (§1), never
from the fill rule (R10-Q1).

**WL-03** — Promotion fills only the freed court
Given a court player leaves (check-out, delete or set Disabled) and players are waitlisted
Then only the court that lost the player is refilled from the waitlist, by the fill rule; other
empty or part-full courts are not filled. A court that is PLAYING (saved game-based lineup) is never
refilled: it stays one player short, and its saved match does not change.

**WL-04** — Waitlist search (added 2026-10-17: UX-14)
Given the waitlist panel shows
Then a field with the caps label "SEARCH WAITLIST" and the placeholder "Name or sign-in ID"
shows above the list. It has no filter chips.
When the organizer types text
Then the list shows only the waitlisted players whose name or sign-in ID contains the text
(case-insensitive substring, as PLY-04).
When no waitlisted player matches
Then the list area reads "No one matches “{text}”" (R6-Q12).
When the organizer clears the field
Then the full waitlist shows again.

---

## 4. Players tab (includes integrated check-in — CHK-01…06)

Note: the CSV Import button is hidden in the release build (`PlayersPage.showImportButton=false`). It has no UAT ID.

Note (2026-10-17): the items that the approved design does not draw stay, restyled to the new
design (R2-Q19): the pending registrations card, the level chips (UX-17), the at-capacity
banner, the profile panel and the empty-list text. Their position does not change (UX-30 is not
reviewed). The capacity progress bar is removed (R6-Q11, CHK-01). The level chips are 4 tier
chips (Amateur, Intermediate, Advanced, Professional) in place of the 8 Elo-code chips; they
filter the list by tier (R6-Q13). The More panel is as drawn on the canvas board "Players ·
More panel" (R5-Q1, R6-Q17, PLY-09).

**PLY-01** — Pending self-registration approvals
Given one or more self-registrations are pending approval
When the Players tab is viewed
Then a card at the top lists each pending applicant's name, estimated level, and contact info, with
"Approve" and "Reject" actions. The card is hidden entirely when there are zero pending applicants.

**PLY-02** — Approve a pending applicant
Given a pending applicant is listed
When the organizer taps "Approve"
Then a new active player is created with their name and estimated tier as their starting level,
membership defaulted to "Casual," not checked in and not assigned to a court, and the applicant is
removed from the pending list. The new player immediately appears in the searchable player list.

**PLY-03** — Reject a pending applicant
Given a pending applicant is listed
When the organizer taps "Reject"
Then the applicant is removed from the pending list; no player record is created.

**PLY-04** — Search/filter
Given the search box contains text
When the Players tab list renders
Then only players whose name OR sign-in ID contains the search text (case-insensitive, substring
match) are shown; level is not searched. Clearing the box shows all players again.

**PLY-05** — Level adjustment stepper (changed 2026-10-17: R2-Q17, R2-Q18, R6-Q17)
Given a player's More panel is open
Then the panel shows the level stepper "−", the tier name with the Elo code (for example
"Intermediate (B1)"), and "+". The row itself shows only the tier name in the LEVEL column.
When the organizer clicks "+" or "−"
Then the level moves up/down by exactly one of the 8 levels (C2, C1, B2, B1, A2, A1, S2, S1),
clamped within [C2…S1] (the lowest Amateur level and the highest Professional level); "−" is
disabled (visually dimmed, non-functional) at C2, and "+" is disabled at S1.

**PLY-06** — Membership cycle (Member → Casual → Disabled) (changed 2026-10-17: R2-Q17, R6-Q17; 2026-10-20: F23)
Given a player's More panel is open
Then the panel holds the membership control, drawn as "Member / Casual / Disabled" (R6-Q17).
The row has no membership pill. Its TYPE column is blank for "Member" and reads "Casual" or
"Disabled" for the other two. (Phone and tablet keep the pill in the row, NAV-08.)
And the row's "More" is a button that tells screen readers whether its panel is expanded and
which panel it controls (`aria-expanded` / `aria-controls` on the board; Flutter `Semantics`
`expanded`) (F23).
And choosing "Disabled" for a checked-in player asks for confirmation first, as below; the
canvas board "Players · More panel" draws that dialog (F23).
Given a player's membership is "Member"
When the organizer taps their membership control
Then it advances to "Casual".
Given a player's membership is "Casual"
When the organizer taps their membership control
Then it advances to "Disabled" — if the player is currently checked in, a confirmation dialog
first warns that they'll be checked out and removed from their court/waitlist immediately (see
WL-02 auto-promotion); if they're not checked in, no confirmation is needed. Disabled players
stay in the Players list, but a tap on their row does not check them in (CHK-06).
Given a player's membership is "Disabled"
When the organizer taps their membership control
Then it advances back to "Member"; this does not automatically check them back in.
As built on desktop (2026-10-21, IMPLEMENTATION 8.7.8): the More panel control is the segmented
"Member / Casual / Disabled" of the board (R6-Q17), so a tap picks that state directly, not the
next one. Disabled for a checked-in player asks "Disable {name}?" ("{name} is checked in.
Disabled checks the player out now and removes the player from the court or the waitlist.",
"Disable" / "Cancel", the one alert-dialog pattern); for a player who is not checked in it sets
at once. Phone and tablet keep the cycle above.

**PLY-07** — Delete player
Given a player's expanded profile card is shown
When the organizer taps the delete (bin) icon
Then a confirmation dialog warns the action cannot be undone; on confirm, the player is removed
from the roster and, if currently checked in, from their court/waitlist (WL-02 auto-promotion
triggered); on cancel, nothing changes. The player record is anonymised, not erased, so past games
keep a valid player id (ADR-0001).

**CHK-01** — Check-in count (changed 2026-10-17: R2-Q19, R6-Q11)
Given the Players tab is active
Then at the right of the scan field the count reads "{checkedIn} / {capacity} in" (the number
at 28 px) and under it "{remaining} places left" ("1 place left" for 1).
And no capacity progress bar shows (R6-Q11, as the design draws). Desktop only; phone and
tablet stay as now (R6-Q7).

**CHK-02** — Late check-in waits on the waitlist (changed 2026-10-17: R7-Q7, overrides R2-Q7; 2026-10-20: R10-Q3)
Given a player is not checked in and the session is below capacity
When the organizer checks the player in (row tap or scan)
Then the player becomes checked in and is never put on a live court.
And the player goes to the waitlist (the pool). The app does not add the player to a saved next
round, also when it has an open slot (R7-Q7). The next lineup the app makes can use the player.
And in READY (draft round 1, not saved) and in TIME UP (planned round) the player goes to the
waitlist too.
And the player starts at 0 rounds played. The app gives no credit for the rounds before the
check-in (R10-Q3), so the fill rule and the matchmaker's weighted pick favour the player.

**CHK-03** — At-capacity block
Given checked-in count already equals session capacity
When the organizer attempts to check in another player
Then the check-in is refused (no state change). A scan shows the SESSION FULL result
(PLY-14). A row tap shows the bottom message with the capacity text (R4-Q1). The UI must not
allow bypassing capacity from the row tap.

**CHK-04** — At-capacity banner
Given checked-in count ≥ session capacity
When the Players tab is viewed
Then a banner reads "Session at capacity — new check-ins are blocked." (CHK-03 refuses them.)

**CHK-05** — Check out (changed 2026-10-17: R2-Q8, R2-Q9, UX-11)
Given a player is checked in
When the organizer taps their row again, scans the card again (outside the PLY-19 guard), or
selects "Check out" in a slot "⋯" menu
Then the player becomes not checked in, and the checked-in count drops by 1 at once.
And if the player is on a live court while the clock runs, COURT-16 applies (the player stays
there until the round ends).
And if the player is on a court whose clock does not run, or in the saved next round, the app
removes the player there and fills the slot by the fill rule (WL-02).
And in TIME UP and CHANGEOVER the finished round n keeps the player for its log; the round n+1
courts on screen lose the player and the fill rule fills the slot (IMPLEMENTATION 8.4.7).
And if the player is on the waitlist, the app removes the player from it.

**CHK-06** — Only non-Disabled players listed (can toggle check-in for Member/Casual players only)
Given a player's membership is "Disabled"
Then a tap on their row does not check them in, the row shows no hover, and a bottom message
reads "{name} is disabled — cannot check in" (R45-38, R4-Q1); only Member/Casual players can be
checked in. A scan shows the DISABLED result instead (PLY-14).

**PLY-08** — Player row (changed 2026-10-17: UX-16, R2-Q17, R2-Q18, R3-Q3; 2026-10-20: F13)
Given a player row is shown for a Member or Casual player on desktop
Then the row is 48 px tall and has the columns NAME (16 px, weight 600), SIGN-IN ID (14 px,
weight 400; empty when the player has no ID), LEVEL (tier name, 14 px, weight 400), TYPE (blank
for Member, else "Casual" or "Disabled", muted) and a "More" button (NAV-08).
And the row has no level stepper and no membership pill (R2-Q17).
And the row tap is the check-in toggle (tap = in, tap again = out) and performs CHK-02/CHK-03/CHK-05
behavior directly. There is no In/Out pill and no "Checked in" column.
And a checked-in row has a green fill, a 1 px green border and a 6 px green bar at the left
(UX-16). A row that is not checked in has the card fill and a light border.
And a successful row tap shows no message, and it does not change the scan result box
(R3-Q3). Only a refused row tap shows a bottom message (R4-Q1).
Given a Disabled player's row is shown
Then its name, sign-in ID and level are `#6f6352` (5.45:1 on the card fill), not a paler
colour, so the organizer can read the name. The "Disabled" label in TYPE and the forbidden
cursor show the state (F13).

**PLY-13** — Add player (changed 2026-10-17: UX-21)
Given the organizer clicks the orange "Add player" button at the right of the scan field
Then an Add-player dialog opens over the app.
When the form is completed and submitted
Then the dialog closes, the new player is saved, and **the Players tab is still on screen** — the
dialog must never tear down the tab beneath it.
When "Cancel" is tapped, or the form is submitted with a missing field
Then no player is created, and the Players tab is likewise still on screen (an invalid form keeps
the dialog open).
Note: the dialog closes itself, returning the new player through its own result. A caller must not
close it — a dialog opens on the root navigator while a caller's context resolves to the per-tab
navigator, so closing from the caller removes the tab and leaves a blank screen.

**PLY-14** — Barcode scan check-in (changed 2026-10-17: UX-02, UX-08, R4-Q3; 2026-10-20: F01, F19, F21)
Given the Players tab opens
Then the scan field is focused, so a barcode scanner can type into it. The field has the caps
label "CHECK IN", a scan icon, and the placeholder "Scan card or search name". It is 52 px tall
with a 2 px border, and its text is 20 px, weight 600.
And the field gets focus again after a row tap, a level chip, More, Add player, a closed profile
and a closed dialog, unless another text field (such as the Sign In ID field) has focus. A row
tap also clears a half-typed query. (This rule stays for the scanner, F21.)
When the organizer presses Esc anywhere on the Players tab (and no dialog or menu is open)
Then focus goes back to the scan field (F21).
When text is typed and Enter is sent (a scanner types the sign-in ID, then sends Enter)
Then the app first looks for the one player whose sign-in ID equals the text (trimmed,
case-insensitive) among **all** listed players: the level chips and the search text do not
apply to this match (F01). So a card scanned while a level chip is on checks its player in, also
when that player's level is not selected. The level chips stay as they are; a scan does not
clear them.
If no ID equals the text, the target is the only player in the list (search and level chips
applied), so a partial ID or a name also works when it leaves one result.
And the target's check-in is toggled: checked in (the capacity and Disabled rules apply) or checked
out. The result box shows CHECKED IN (PLY-17) or CHECKED OUT (PLY-18).
And in every case below except MANY MATCHES, the text stays, all of it is selected, and the field
keeps focus. The list still shows the result, so the organizer can see the new state. The next
scan replaces the text.
In MANY MATCHES the text stays, the caret goes to the end of the text and nothing is selected,
so the organizer can type more (F19).
When the target is Disabled
Then nobody changes, and the result box shows DISABLED: "{name} is disabled · enable the
player in More to check in."
When the session is at capacity and the target is not checked in
Then nobody changes, and the result box shows SESSION FULL: "Session full · {in} / {capacity}
in · {name} is not checked in."
When the list is empty
Then the result box shows NOT FOUND: "No match for “{text}”. Check the card, or add the player."
When the list shows more than one player and no ID equals the text
Then nobody changes, and the result box shows MANY MATCHES: "{count} players match “{text}” ·
nothing changed. Tap a row, or type more."
When more than one listed player has that exact ID (duplicates already saved)
Then nobody changes, and the result box shows DUPLICATE ID: "ID {id} is used by {count}
players · nothing changed. Fix the ID in More." (R6-Q12).
When Enter is sent while an IME composition is active
Then nothing happens (Enter confirms the composition). Two fast scans in a row are both handled.
When the field is empty and Enter is sent
Then nothing happens.
As built (2026-10-21, IMPLEMENTATION 8.7.8): phone and tablet keep the PR 45 flow, with the
result in a bottom message, no PLY-19 guard and all text selected also after many matches. The
exact-ID rule (F01) and Esc (F21) apply on every size.

**PLY-15** — Edit sign-in ID, and add-player checks (changed 2026-10-20: F23, F30)
Given a player's profile panel is open
Then it shows a Sign In ID field and a Save button on the top row of the panel, with the
membership label on the left and the delete and close buttons on the right. The delete button
is a red outline button (`btn.danger-outline`, F23).
When the Sign In ID field gets focus
Then all its text is selected, so a card scanned by mistake into the field replaces the text
and shows, and does not add to the end of it (F30).
When the organizer saves a changed ID
Then the ID is trimmed and saved, and no other player field changes. An empty ID means no ID.
When the ID is already used by another listed player
Then the save is refused with a message that names that player: "ID {id} is used by {name}."
(for example "ID BC-104 is used by Zoe Alvarez.", F23).
When a player is added (PLY-13)
Then the name and the ID are trimmed. A blank name, a duplicate name, or a duplicate ID is refused.
As built on desktop (2026-10-21): after a save the panel reads "Saved." under the field, and no
bottom message shows. The Add-player dialog keeps its own duplicate-ID text.

**PLY-16** — Scan result box (added 2026-10-17: UX-02, R3-Q3; 2026-10-20: R9-Q8)
Given the Players tab is active
Then a result box (at least 52 px tall, full width) shows directly under the scan field. It has a
round icon, a name in 20 px weight 600, and text in 16 px weight 400. Screen readers read it as a
status (polite live region).
And before the first scan it shows READY: "Ready to scan · Scan a card, or type a name and press
Enter."
When a scan (Enter in the scan field) gives a result
Then the box shows that result (PLY-14, PLY-17 … PLY-19) and keeps it until the next scan.
When the organizer taps a row
Then the box does not change (R3-Q3).
And the box has no "Undo" button in any state (R9-Q8). The only action button is "Check out" in
SCANNED TWICE (PLY-19).
And each state has its own colour and icon: IN green ✓, OUT grey ←, SCANNED TWICE amber !, NOT
FOUND red ×, MANY MATCHES amber ?, SESSION FULL amber !, DISABLED red ×, DUPLICATE ID amber !,
READY neutral ›.

**PLY-17** — CHECKED IN result text (added 2026-10-17: R4-Q3, R7-Q7; 2026-10-20: R9-Q8)
Given a scan checks a player in
Then the player goes to the waitlist (CHK-02), and the box reads "{name} is in · waits for
round {n}". It has no "Undo" button (R9-Q8). Here {n} is the first round that has no saved
lineup: the next round to start, or the round after a saved next round (1 before the first
round starts).
And the R4-Q3 text "{name} is in · joins round {n} on Court {k}" is no longer used: a late
check-in never joins a saved round (R7-Q7).
As built (2026-10-21): in READY {n} is the draft round (1), because the draft is not saved. In
TIME UP {n} is n+1, because the planned round is not saved. In CHANGEOVER {n} is the round after
the one that starts.

**PLY-18** — CHECKED OUT result text (added 2026-10-17: R2-Q8, R4-Q3; 2026-10-20: R9-Q8)
Given a scan checks a player out
When the fill rule puts player X into the freed slot of round {n} (WL-02)
Then the box reads "{name} is out · {X} takes Court {k} in round {n}".
When nobody takes a slot (the player was on the waitlist, or nobody can fill it)
Then the box reads "{name} is out".
And neither text has an "Undo" button (R9-Q8). To reverse a scan, the organizer scans or taps
the player again.
As built (2026-10-21): when one check-out fills two places (PAUSED: round n and a saved round
n+1), the text names the earliest round, then the lowest court.

**PLY-19** — Scanned twice guard (added 2026-10-17: UX-01, R2-Q11, R6-Q15; 2026-10-20: F20)
Given player A is the last player checked in by a scan (no time limit, R6-Q15)
When the same target is scanned again (a card, or a typed name and Enter)
Then nothing changes. The box shows SCANNED TWICE: "{name} is already in (same card as the
last scan). Nothing changed.", with a "Check out" button.
When the organizer clicks "Check out"
Then A is checked out as in CHK-05, and the box shows CHECKED OUT (PLY-18) for A, with the
refill text when a player takes A's slot. The box does not go back to READY (F20).
Given another player B was scanned in after A
When A is scanned again
Then the guard does not apply (it holds only the last card, R2-Q11), and A is checked out.
And a row tap is never guarded.

**PLY-20** — Removed (2026-10-20, R9-Q8): there is no Undo after a scan on the Players tab
(overrides R2-Q10 and the scan part of R3-Q2). The result box has no "Undo" button (PLY-16 …
PLY-18). The only Undo in this build is the swap Undo on the Courts tab (COURT-17).

**PLY-09** — Expand player profile (changed 2026-10-17: R2-Q17, R5-Q1, R6-Q17)
Given a player row is shown
When the organizer taps the "More" button (72×36 px outline button) and no other profile is
currently expanded
Then a panel expands inline directly beneath that row (not a modal/drawer — this design was
explicitly chosen after modal/drawer positioning proved unreliable, see design history). The row
and the panel sit in one rounded panel, so they read as one accordion item. A row tap does
not open the profile (it toggles check-in, PLY-08). More and the panel controls never
toggle check-in, and a dimmed −/+ does nothing. The panel shows:
membership status and the membership control (PLY-06), the level stepper with the Elo code
(PLY-05), 3 stat tiles (Current
Level, Matches, Diversity %), a Sign In ID field with a Save button on its top row (PLY-15), up to 3 most-frequent playing partners
with match counts, and a session-attendance history summary (or "No sessions logged yet" if none).
Definitions: Matches = saved games that hold the player. Diversity % = distinct other players met in
those games ÷ other listed players on the roster. Partners = every other player in a game (a game
does not record who partnered whom). A session = one calendar day with a saved session log. The
profile has no level progression sparkline, because no level history is stored.
And the layout is as drawn on the canvas board "Players · More panel" (R6-Q17): an accordion
under the row; the sign-in ID field with Save; the level stepper "− Intermediate (B1) +"; the
membership control "Member / Casual / Disabled"; delete and close; then the stats, partners and
attendance. The panel has two columns (Nathan, 2026-10-22): the controls that edit the player
on the left, the stats, partners and attendance on the right. Choosing Disabled asks for
confirmation, then checks the player out (PLY-06).

**PLY-10** — Only one profile expanded at a time
Given player A's profile is expanded
When the organizer taps player B's More button
Then A's profile collapses and B's profile expands in its place.

**PLY-11** — Collapse profile
Given a player's profile is expanded
When the organizer taps the "✕" in the profile panel (or taps the same player's More button again)
Then the panel collapses.

**PLY-12** — Profile stats reflect session history, not live court state
Given a player has historical session records
Then "Matches," "Diversity," "top partners," and "attendance history" in their profile are computed
from that player's logged session history — they are unaffected by re-rolls or check-ins happening
in the *current* live session until that session is itself logged into history. They are read
from the saved games and session logs, so they survive a restart and update when a round is
logged. (An Undo that deletes a log entry is on hold, RND-21.)

---

## 5. Sessions tab

> **Sessions tab redesign: built on desktop** (R7-Q3, IMPLEMENTATION 8.10, 2026-10-21). At
> 1080 px and more the tab shows two cards with no page scroll: "Round settings" (round
> duration, session capacity, number of courts when `CourtCount.editable` is on, the fixed
> changeover "20 s · fixed") with "−" / "+" steppers, and "Session templates" (save, list with
> "Load" and delete). Nathan reviews it in a separate task. Phone and tablet keep the PR 45
> layout; the rules below apply to every size unless a case names desktop.

**SESS-01** — Round mode selection
Given the Sessions tab is active
Then the release build is time-based only: the round-mode toggle and its description are hidden,
and the duration field is always shown.
Note: game-based selection (buttons, description, duration hidden per RND-09) exists in code behind
`GameMode.enabled=false`. It is covered by tests with the flag on.

**SESS-02** — Round duration (`mm:ss`) (changed 2026-10-17: R2-Q24, R2-Q4; 2026-10-20: R9-Q6)
Given round mode is Time-based
Then the default duration is 10:00 (R2-Q24).
When the organizer edits the minute or second field of the `mm:ss` duration control
Then: (a) clicking either field selects that whole segment so the next keystroke replaces it, and
`Tab` moves focus from minutes to seconds; (b) minutes are clamped to 0–99 and seconds to 0–59;
(c) a total of 0:00 is rejected and the previous duration is restored; (d) the Courts round
countdown recalculates against the new duration at once. If the new duration is now less than
the time already elapsed in a RUNNING round, the round reaches 0:00 at once, and RND-03 or
RND-15 applies (no automatic rotation). In PAUSED the new duration applies at once, by the same
rule as RUNNING (R9-Q6): the time shows the new duration minus the time already elapsed, and
"Resume round {n}" continues from there. If the new duration is now less than the elapsed time,
the round reaches 0:00 at once, and RND-03 or RND-15 applies. In READY and TIME UP the
remaining time becomes the new duration at once. The top nav text follows the new duration
(NAV-01). Loading a template (SESS-06) applies the same rule. The changeover stays 20 s (R3-Q7).
Desktop (8.10): "−" and "+" change the duration by one minute and apply at once by the same
rule; "−" is off at 1:00 or less, "+" at 99:59. The note under "Round duration" says when the
length applies: "Applies now · round {n} has {mm:ss} left" in RUNNING and PAUSED, "Applies from
round {n+1}" in TIME UP, "Applies from round {n}" in CHANGEOVER (the round that starts next),
and "Applies now to every round" before round 1.

**SESS-03** — Session capacity change
Given the organizer changes the "Session capacity" number field (minimum enforced value: 4)
Then the stat strip / check-in count reflect the new capacity immediately (desktop has no
capacity bar, R6-Q11), "at capacity"
behavior (CHK-03/CHK-04) recalculates against it, but **no currently checked-in player is bumped**
even if the new capacity is now lower than the current checked-in count — the limit only applies to
future check-ins.
When the organizer enters a number below 4 (or leaves the field empty or non-numeric)
Then the value is **clamped up to 4** — never raised back to the default of 20 — and the field
shows the clamped number, so it never displays a value the session did not accept.
The same applies to a session template that carries a capacity below 4 (SESS-06): loading it
yields 4. An empty or non-numeric "Number of courts" entry clamps to 1 in the same way.
Desktop (8.10): "−" and "+" change the capacity by one (4…200; "−" is off at 4). The note says
"{in} checked in · min 4", or "{in} checked in · no one is checked out" when the capacity is
below the checked-in count.

**SESS-04** — Courts count change (changed 2026-10-20: F25, dialog text)
Release note (R45-36, 2026-10-14): hidden in the release build (`CourtCount.editable=false`). The
Dashboard stepper and the Sessions "Number of courts" field are not shown, and the club always
uses 4 courts. The rules below apply when the flag is on. The 2026-10-17 design also removes
the "COURTS − 4 +" stepper from the draft round bar (R2-Q2), so with the flag on only the
Sessions field changes the count. The Courts tab always has 4 fixed courts. The Sessions tab
redesign adds a court count control, shown only when `CourtCount.editable` is on (R7-Q3; built,
IMPLEMENTATION 8.10): a read-only number with "−" and "+" (1…8), and the note "Changing it
reshuffles all courts".
Given the organizer changes "Number of courts" (range 1–8; the default is 4, `GameData.defaultCourtCount`, and it is not persisted; the Dashboard stepper is clamped to 1–8 too)
Then every currently checked-in player is unassigned and the whole checked-in pool is
re-distributed across the new number of courts using the same level-sorted, courts-of-4 assignment
logic as an initial session start — this is a full reshuffle, not an incremental add/remove of one
court.
When round {n} of a time-based session has started (RUNNING, PAUSED, TIME UP or CHANGEOVER,
changed 2026-10-21, 8.10) and a court holds players, a confirmation shows first, on every size. It
uses the 2026-10-17 round model (F25): the title is "Discard round {n}?", the text is "Round {n}
is discarded and not logged. Everyone is placed again on {count} courts.", and the buttons are
"Reshuffle" and "Cancel". Cancel keeps everything, including the court count. When no court holds players, or fewer than 4 players are checked in, nothing is generated
(the courts are only padded, and a court added to the grid gets an empty slot, also after a Save or a template load); when the count is reduced, players on the removed courts return to the waitlist. A staged next round is planned again for the new count. A re-roll or a court-count change clears the selected player.

**SESS-05** — Save a session template
Given the organizer enters a non-blank template name and taps "Save current"
Then a new template is added to the list capturing the current duration, session
capacity, and courts count, summarized as e.g. "4 courts · cap 20" (no mode); the name field
clears. Saving with a blank/whitespace-only name is a no-op.
Desktop (8.10): "Save current" is off while the name is blank, and Enter in the name field
saves. The summary also names the duration, "10 min · 4 courts · cap 20" (whole minutes as
"{m} min", else `m:ss`); with `CourtCount.editable` off it leaves out the courts, "10 min ·
cap 20", because a Load keeps 4 courts. The line under the field, "Saves {summary}", shows what
"Save current" keeps.

**SESS-06** — Load a template (changed 2026-10-20: F25)
Given at least one saved template exists
When the organizer taps "Load" on a template
Then the session's duration and session capacity are overwritten from the template at once,
with no dialog: the duration by the SESS-02 rule (the live round keeps its lineup, and the time
recalculates), the capacity by the SESS-03 rule (F25). The template round mode is ignored.
And only when the template's courts count differs from the current count (possible only with
`CourtCount.editable` on; in the release build the courts count is ignored and stays 4,
R45-36), the SESS-04 full reshuffle applies, with the same confirmation.
When the organizer deletes a template (desktop: the bin button of the row, 8.10; tablet and
phone have no delete button)
Then a dialog asks "Delete template “{name}”?" with the text "The template is deleted. The
current settings do not change." and the buttons "Delete" and "Cancel" (F25).
"Delete" removes the template; "Cancel" keeps it.
Loading a game-based template stops the countdown (GB-01; hidden in the release build, `GameMode.enabled=false`).

---

## 6. Schedule tab

**REMOVED (2026-10-10).** The Schedule tab is removed. Session templates (§5, SESS-05/06) hold
the predefined session configurations instead. `/schedule` redirects to `/sessions`.

~~**SCHED-01** — Recurring session list (read-only)~~
Given the Schedule tab is active
Then a static list of recurring sessions is shown (day, time window, descriptive note, and an
"Auto check-in opens 30 min prior" badge per entry). No interactive controls exist on this tab in
this build — creating, editing, or deleting a recurring session is out of scope (known gap, see
§1 Excluded from scope).

---

## 7. Analytics tab (merged combined screen)

Per scoping decision, this tab is the full-featured merged view (superset of the app's original
built-in tab and the standalone Analytics Dashboard prototype), rewritten so **no raw ELO numbers
are ever shown** — every ELO-flavored metric from the standalone prototype is restated in terms of
the 4 tiers / tier-gap.

**ANA-01** — Time-range switcher
Given the Analytics tab is active
Then a 3-way switcher (4 wks / 12 wks / 26 wks) is shown, defaulting to 12 wks; selecting a
different range recomputes every chart/KPI below against that window, compared to the equivalent
prior window for "vs. prior period" deltas.

**ANA-02** — KPI strip
Then 6 KPI tiles are shown: Active players, Avg attendance %, Retention (4wk) %, Court utilization
%, Avg waitlist (per session), Re-rolls per session — each with a labeled value and a delta/context
line vs. the prior period. The delta line shows "—" when the prior period has no players or sessions. The Retention value and delta show "—" when there is no base.

**ANA-03** — Attendance trend
Then a per-session bar chart shows attendance rate (checked-in ÷ capacity) over the selected range,
with the most recent session visually emphasized; a growth note (e.g. "+X%") summarizes
month-over-month change.

**ANA-04** — Waitlist pressure
Then a bar chart shows waitlisted-player counts per session over the range, with a contextual note
recommending capacity/schedule changes when average waitlist is high (≥ ~2.5/session) vs. a
reassuring note when it's low. With no sessions, the card reads "Not enough sessions logged yet."

**ANA-05** — Matchmaking fairness — level-gap trend
Then a bar chart shows, per session, the mean level-gap of its courts over the selected range
(values expressed as tier-gap, e.g. "1.2," not raw ELO; tier-gap = stored Elo-step gap ÷ 2), with a note stating whether the trend is improving (gap
shrinking) or not.

**ANA-06** — Matchmaking fairness — per-court comparison
*Hidden in release build (`AnalyticsPage.showHiddenCards=false`).*
Then a horizontal bar-per-court list shows each court's average level-gap over the range, flagging
courts that run consistently wider gaps (e.g. courts that regularly absorb overflow). A court is
flagged when it appears in at least 3 sessions, is wider than its session's mean on at least 60% of
them, and averages above 1.25× the club average. "Court N" is the Nth court that held a game in a
session (session logs store no court number).

**ANA-07** — Court utilization
Then a horizontal bar-per-court list shows each court's fill rate (share of sessions in which that
court held a game when the session was saved); a summary line reports overall "full-4 fill rate"
(share of sessions with checked-in ≥ courts × 4) and the average number of idle courts per session.
Idle-court *time* is not available: session logs store no court start/end times.

**ANA-08** — Re-rolls per session
Then a bar chart shows re-roll counts per session over the range, with a note connecting re-roll
spikes to high-attendance/high-level-spread nights.

**ANA-09** — Level distribution
Then a 4-bar chart shows player counts per tier (Amateur/Intermediate/Advanced/Professional) across
the whole club, with a summary noting the median tier and overall trend direction.
The "N players flat 6+ sessions" warning is removed (bars, median and trend note stay).
Limit: no tier history is stored (see ANA-10). The trend direction compares the mean current tier of
players active in the range with the prior range.

**ANA-10** — removed. Games store player ids only (issue #42); "elo at play time" required two
snapshots of the same player embedded in different games, which the removal of `Game.players` as
a stored value made impossible to represent honestly. `GameRepository` already only ever resolved
historical rosters to the *current* player row, so the feature never showed a real delta in
production — see ADR-0001.

**ANA-11** — At-risk players
Then a list shows regular attendees (historically ≥2 session days a month; two games on one day count once) not seen in 3+ weeks, each with their
usual frequency and time since last seen, plus a total "lapsed" count.

**ANA-12** — Player mixing
*Hidden in release build (`AnalyticsPage.showHiddenCards=false`).*
Then a horizontal bar-per-player list shows a 0–1 mixing score (distinct partners ÷ games played)
for a sample of players, tagged "connector" (high, bridges the club), "clique" (low, narrow circle),
or "isolated" (very low) where applicable, with a summary note.

**ANA-13** — New player integration
Then a list shows recently joined players (within the "new" window, fixed at 60 days until a
setting exists) with when they
joined, sessions attended, and a "% of games played with regulars" status, styled favorably (≥50%)
or as needing attention (<50%), with a contextual note. A new player with no games in the range is
not counted in the "pair them up" warning, and the "playing alongside regulars" line is hidden if
nobody played.

**ANA-14** — Responsive reflow
Given the Analytics tab is active
Then the KPI strip shows 6 columns on desktop, 3 on tablet and 1 on phone; chart rows are
side by side on desktop and stack to a single column below desktop — consistent with the breakpoints
in §1. In the release build 8 cards are visible, 2 per row on desktop: Attendance + Waitlist,
Level gap + Court utilization, Re-rolls + Level distribution, At-risk + New player integration.

---

## 8. Settings tab

~~**SET-01** — Notification toggles~~ **REMOVED (2026-10-10):** the app runs offline and cannot
send notifications.
Given the Settings tab is active
Then 3 independent on/off toggles are shown: Session reminders, Court assignment alerts, General
announcements; each toggle immediately flips its own state and label ("On"/"Off") when tapped, with
no dependency between the three.

**SET-02** — Membership summary
Then a read-only total-members count is shown, computed live from the current player roster. The
fees-outstanding count is removed (2026-10-10): no fee data exists.

**SET-03** — Signup preview
*Hidden in release build (`SettingsPage.showSignupPreview=false`); the `/register` route is kept.*
Then a "Preview signup page →" link opens the Self-Registration page. The invite link field is
removed (2026-10-10): the app runs offline and has no server.

**SET-04** — Level calibration note
Then explanatory text is shown: new players self-estimate their level at signup, and organizers may
override any estimate from the Players tab (cross-referencing PLY-05).

**SET-05** — Language (added 2026-10-10)
Then each supported language (English, Français, 简体中文, 繁體中文) is shown by its native name,
and the current one is selected. When the user selects a language, all UI text changes to that
language and the choice stays after a restart (same `language` preference key as main).

---

## 9. Self-Registration (public page, linked from Settings)

Note: REG-* is not reachable from the UI in the release build (the Settings link is hidden, SET-03). The `/register` route is kept.

**REG-01** — Initial state
Given a prospective member opens the self-registration link
Then a form is shown with: full-name input, email/phone input, and 4 level-tier options (Amateur,
Intermediate, Advanced, Professional) each with a one-line description of who that tier fits;
Intermediate is pre-selected by default; the "Submit for approval" button is disabled until both
required fields are non-blank.

**REG-02** — Field validation gates submission
Given either the name or contact field is blank or whitespace-only
Then "Submit for approval" remains disabled; there is no other inline validation message in this
build (known gap — no email/phone format validation exists).

**REG-03** — Selecting a tier
When the applicant taps a tier option
Then that option becomes visually selected (dark fill) and any previous selection is deselected;
exactly one tier is always selected (defaults to Intermediate, never "none").

**REG-04** — Submission
Given name and contact are both filled in
When the applicant taps "Submit for approval"
Then the form is replaced with a confirmation state: "Thanks, {first name}!" and a message
confirming their starting level was set to the selected tier, noting an organizer may adjust it
after their first few sessions. There is no way to edit/resubmit from this state in this build.

**REG-05** — Pending review framing
Given the form has not yet been submitted
Then a note is shown: "An organizer reviews every new sign-up before you're added to the roster" —
setting the expectation that submission does not grant immediate access.

**REG-06** — Integration point (implementation note, not a UAT assertion)
The prototype's submission does not feed into the Players-tab pending-approval queue (§5 PLY-01) —
they are disconnected, separately-seeded data in the design file. The real implementation must wire
REG-04's submission into the same pending-approvals list that PLY-01/02/03 operate on.

**REG-07** — Responsive
Given any viewport width from phone to desktop
Then the form remains a single centered column (max-width ~520px), fully usable with no horizontal
scrolling or overlapping controls at any width.

---

## 10. Summary checklist (traceability)

| Area | IDs |
|---|---|
| Navigation & responsive | NAV-01…11, START-01 |
| Courts: round lifecycle (time-based) | RND-01…22 (RND-21 on hold) |
| Courts: game-based mode | GB-01…07 (hidden in release) |
| Courts: courts & waitlist | COURT-01…17 (COURT-11…13 removed), WL-01…04 |
| Players (with integrated check-in) | PLY-01…20 (PLY-20 removed), CHK-01…06 |
| Sessions | SESS-01…06 |
| ~~Schedule~~ (removed) | ~~SCHED-01~~ |
| Analytics | ANA-01…14 |
| Settings | SET-01…05 |
| Self-Registration | REG-01…07 |

Total: **121** case IDs. **7** are removed (SCHED-01, SET-01, ANA-10, COURT-11, COURT-12,
COURT-13, PLY-20) and **1** is on hold (RND-21, R6-Q6), so **113** acceptance cases are active
in this build; 7 of them (GB-01…07) are hidden in the release build. The 2026-10-17 design build
added 24 IDs (NAV-09…11, RND-12…22, COURT-14…17, WL-04, PLY-16…20), removed 3 and put 1 on hold.
The 2026-10-20 decisions (R9-Q1 … R10-Q3) removed PLY-20 (R9-Q8) and added no ID.
The 2026-10-20 decisions R11-Q1 … R11-Q6 and the design review (F01 … F30) changed cases
in place and added or removed no ID. The 2026-10-21 decisions R12-Q1 and R12-Q2 (F05, F28)
changed RND-04, RND-05, RND-07, RND-08 and RND-22 in place and added no ID.
Before it: 97 IDs, 94 active (the old line said 77; that count was out of date).
