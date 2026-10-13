# UAT Spec — Badminton App

Source of truth: `Badminton App.dc.html` (primary), `Self Registration.dc.html`
(linked public flow), `Analytics Dashboard.dc.html` (merged into the Analytics tab per
decisions below), `Responsive Layouts.dc.html` (breakpoint/device reference only, not a
separate screen). `Dashboard Options.dc.html` and `Calming Wireframes.dc.html`
are superseded explorations — excluded (see "Excluded from scope").

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
| Court size | 4 players per court |
| Default courts | 4 (organizer-adjustable, range **1–8**) |
| Default session capacity | 20 (organizer-adjustable, minimum **4**) |
| Default round mode | Game-based |
| Default rotation duration | 20 min (organizer-adjustable **10–45 min, step 5**, time-based only) |
| Minimum enforced round duration | 30 sec (floor, not reachable via the UI slider) |
| Responsive breakpoints | Phone `< 720px` · Tablet `720–1079px` · Desktop `≥ 1080px` |
| Reference device widths | Desktop 1280px · iPad landscape 1194px (**renders as desktop layout**) · iPad portrait 834px (tablet layout) · Phone 390px |
| Phone nav variants | `tabbar` (default) — bottom bar + "More" sheet; `hamburger` — full-screen menu |
| Level-up/down step | ±1 tier per click, clamped to [0,3] |

**No raw ELO is ever displayed to any user (organizer or player).** Internally a numeric "elo" field
may exist for tie-breaking/sorting, but every acceptance case below is written in terms of the 4
named tiers and tier-index gaps only. This applies to the Analytics tab as well (see §9), overriding
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
- **`phoneNav` and `density`** are prototype component props only. The app has no such setting:
  phones always show the bottom tab bar and the ☰ menu together (NAV-03, NAV-05), at one density.

---

## 2. Cross-cutting: Navigation & Responsive Layout

**NAV-01** — Desktop/tablet top nav visible
Given viewport width ≥ 720px
When the app loads
Then a top header bar is shown with 5 tabs (Dashboard, Players, Sessions, Analytics, Settings)
and no club name; the compact phone header and
bottom bar/hamburger are not shown.

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

**NAV-06** — Stat strip reflow
Given the app is on the Dashboard/any tab
(All breakpoints in NAV-06…08 and ANA-14 use the viewport width, not the width left after the shell
padding.)
When viewport width is desktop (≥1080px)
Then the stat strip shows 6 cells in one row: Checked In, Remaining Slots, Waitlist, Avg Level, Avg
Level Gap, Re-rolls.
When viewport width is tablet (720–1079px)
Then the same 6 stats are shown, wrapped 3-per-row.
When viewport width is phone (<720px)
Then only 4 stats are shown in a 2×2 grid: Checked In, Waitlist, Avg Level, Remaining.

**NAV-07** — Dashboard layout reflow
Given the Dashboard tab is active
When viewport width is desktop (≥1080px, including the 1194px iPad-landscape reference)
Then courts render as a grid alongside a fixed-width waitlist sidebar to its right. The grid
uses the column count that gives the largest courts that fit the free height (as on main), and
the courts grow to fill that height. A court is never narrower than 320px, never flatter than
1.6:1 and never taller than it is wide. The 4 player slots share the card height, so there is no
empty band below the last slot.
When the courts cannot fit at that minimum size, the grid uses the most columns and **scrolls**,
so every court stays reachable. The waitlist sidebar scrolls independently.
When viewport width is tablet or phone (<1080px)
Then the waitlist renders as a horizontally-wrapping chip row above the courts, and courts stack
below it at the minimum proportion (2 columns on tablet, 1 column on phone); the page scrolls.

**NAV-08** — Table header rows hidden on phone
Given the Players tab is active (with integrated check-in and capacity bar)
When viewport width ≥ 720px
Then a column-header row is shown above the list, reading NAME / ID · LEVEL · MEMBERSHIP ·
CHECKED IN.
When viewport width < 720px
Then the header row is omitted; only data rows are shown, and each row fits the width without
clipping its controls (the level, membership and check-in columns drop their fixed widths so the
name keeps the remaining space).

---

## 3. Dashboard tab — round rotation & courts

> **Scope note:** RND-01…11 describe **Time-based** mode only. Game-based mode
> has no countdown and no automatic rotation — see GB-01…07 below.

**RND-01** — Countdown display
Given a round is in progress with rotation duration D minutes and a known start time
When the Dashboard is viewed
Then a round bar shows "ROUND {n}", the mode label, a live `mm:ss` countdown of time remaining
until rotation, and a depleting progress bar whose fill width equals remaining/D as a percentage;
the countdown updates at least once per second.

**RND-02** — Final-minute urgency styling
Given the round countdown reaches ≤60 seconds remaining
When the Dashboard is viewed
Then the countdown text and progress-bar fill switch to the amber "urgent" color (from white/orange).

**RND-03** — Auto-rotation at zero
Given the round countdown reaches 0:00 and no round is staged
When the next tick occurs
Then the app automatically computes a fresh level-balanced court assignment from all currently
checked-in players, increments the round number by 1, and restarts the countdown at the full
rotation duration — with no organizer action required.

**RND-04** — Manual "Rotate now"
Given a round is in progress (any time remaining)
When the organizer taps "Rotate now"
Then the current round ends and is **logged** (added to the history and written as a session-log
snapshot, exactly as a Save would), rotation happens immediately: round number increments, court
assignments are recomputed (or the staged lineup is adopted — see RND-06), and the countdown
restarts at the full duration.
Note: a court holding fewer than 4 players is logged as it stands — the clock running out must
never be blocked by a half-filled court. Saving by hand still refuses an unbalanced lineup.

**RND-05** — Pre-make next round
Given a round is in progress and no round is currently staged
When the organizer taps "Pre-make next round"
Then: (a) a fresh level-balanced lineup is computed and stored as "staged" without changing the
current live court assignments; (b) the "Pre-make next round" button is replaced by a second panel
below the main round bar labeled "NEXT ROUND · READY", holding a summary ("N players placed across
M courts"), a striped progress bar that **fills up** (rather than depletes) as the current round
elapses, and the "Cancel next" button; (c) the next round is selected (RND-10) so **the court grid
immediately shows the planned lineup**.

**RND-10** — Round selector: the courts show the selected round
Given a round is staged
Then the two panels of the round bar act as radio buttons — exactly one is selected, and the
selected one is the round the court grid shows.
When the organizer taps the "Current round" panel
Then the court grid, the waitlist sidebar and the stat strip show the round being played.
When the organizer taps the "Next round" panel
Then the court grid shows the pre-made lineup, each court card carries a "NEXT" badge, and the
lineup is **fully editable**: click-to-place and per-court re-roll apply to the plan, not to the
live courts.
And the waitlist sidebar lists the players off-court **in the round on screen**, so no player can
be placed on two courts at once and no player can be dropped from the plan unnoticed.
And the global "Save" and "Generate" actions are hidden while the next round is selected — a plan
is not a round that can be saved; to redraw it, cancel it and pre-make again.

**RND-06** — Staged round becomes live
Given a round is staged
When the live countdown reaches 0:00 (auto-rotation) or the organizer taps "Rotate now"
Then the previously staged lineup — **including any edits the organizer made to it** — becomes the
live court assignment; the staged panel disappears; the selector returns to "Current round"; the
round number increments and the countdown restarts. No new round is staged automatically.

**RND-07** — Cancel staged round
Given a round is staged
When the organizer taps "Cancel next"
Then the staged panel disappears, the selector returns to "Current round", and "Pre-make next
round" becomes available again; the live round and its countdown are unaffected.

**RND-08** — Only one staged round at a time
Given a round is already staged
Then "Pre-make next round" is not shown (only "Cancel next", inside the next-round panel, is
available) until the current staged round is cancelled or becomes live.

**RND-11** — The staged round does not go stale
Given a round is staged
When a player is checked out, removed, or set to Disabled
Then they are dropped from the staged lineup as well as the live one.
When a player's details are edited
Then the staged lineup shows the updated details.
When the court count is raised
Then the staged lineup gains the extra empty courts, so every court on screen can take a player.

**RND-09** — Mode label vs. behavior
Given round mode is "Time-based"
Then the round bar subtitle reads "Time-based · {mm:ss} rounds" and the Sessions tab's duration
control is shown.
Given round mode is "Game-based"
Then no round bar is rendered at all and the Sessions tab's duration control is hidden.
Note: switching mode does not by itself force an immediate rotation.

---

## 3a. Dashboard tab — game-based mode

In game-based mode there is no clock. A committee member drives each court by hand:
Regenerate → re-roll a court → Save → the court shows PLAYING → re-roll when the real game
finishes → Save again.

**GB-01** — No countdown
Given round mode is "Game-based"
When the Dashboard is viewed
Then no round bar, countdown, "Rotate now", or "Pre-make next round" control is rendered, and no
rotation timer is started.

**GB-02** — Generate once
Given round mode is "Game-based" and no court holds any player
Then the "Generate Game" button is shown, and it fills every court in one action.
Given at least one court holds players
Then the Generate / Regenerate button is hidden — courts are driven individually from then on.

**GB-03** — No global Save
Given round mode is "Game-based"
Then the Dashboard action bar shows no global "Save" button; saving happens per court.

**GB-04** — Per-court Save
Given a court holds a full lineup of 4 and is not already playing
Then that court's header shows a "Save" button.
When the organizer taps it
Then the match is written to history and the analytics session log, the four players stay on the
court, and the court is marked as playing.

**GB-05** — PLAYING indication
Given a court has been saved
Then its header shows a "PLAYING" badge, its "Save" button is hidden, and its "Re-roll" button
remains available.

**GB-06** — A playing lineup is locked
Given a court is playing
When the organizer selects a waitlisted player and taps a slot on that court
Then nothing changes — the saved lineup cannot be edited, because it is already recorded.

**GB-07** — Re-roll ends the game
Given a court is playing
When the organizer taps "Re-roll" on it
Then the PLAYING badge clears, four players are drawn from those not currently on any court, and
the "Save" button returns. Players on other courts — including ones currently playing — are never
drawn into the new lineup.

**COURT-01** — Court display
Given the Dashboard is viewed
Then each court shows its number, a level-gap badge (see §1 label rules) computed from its current
occupants, up to 4 player rows (each showing name + level tier), and empty slots labeled "Open
slot" in italics for any unfilled positions.

**COURT-02** — Re-roll rebalances a court
Given a court has occupants and there is at least one other eligible player (another court occupant
counted together with the full waitlist pool totals more than 4 candidates)
When the organizer taps "Re-roll ⟲" on that court
Then the app evaluates multiple random 4-player combinations drawn from that court's current
occupants plus the entire checked-in waitlist, selects the combination with the lowest level gap,
seats those 4 on the court, returns everyone else in the pool to the waitlist, and increments the
club's re-roll count (visible in the stat strip and Analytics).

**COURT-03** — Re-roll no-op when nobody else is available
Given a full court whose occupants plus the full waitlist total 4 players (or any court when the
total is below 4)
When the organizer taps "Re-roll ⟲" on that court
Then nothing changes (no reshuffle, no re-roll count increment) — there is no one to rotate in.
The dashboard stays silent: no dialog and no error message.
A court with an open slot is still filled when the total is exactly 4.

**COURT-04** — Selecting a waitlisted player to place/swap
Given at least one player is on the waitlist
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
When the organizer taps an "Open slot" on any court
Then the selected player is seated in that slot, removed from the waitlist, and the selection
clears.

**COURT-08** — Swapping a selected player into an occupied slot
Given a waitlisted player is selected
When the organizer taps an occupied slot on any court
Then the two players trade places: the selected player takes the slot, and the slot's previous
occupant is moved to the waitlist; the selection clears.

**COURT-09** — Empty court slots inert with no selection (changed 2026-10-12)
Given no player is currently selected
When the organizer taps an empty court slot
Then nothing happens. (Tapping an occupied slot selects that player, see COURT-10.)

**COURT-10** — Swapping players between courts (added 2026-10-12)
Given a court that is not in play
When the organizer taps an occupied slot
Then that player is highlighted as selected (tapping the same slot again clears the selection).
When the organizer then taps a slot on another court that is not in play
Then the two players trade places; if the target slot is empty, the player moves there. Nobody
drops to the waitlist, and the selection clears. A court in play (game-based, saved) cannot give
or take a player.

**COURT-11** — Removing a player from an incomplete court (added 2026-10-12)
Given a court has fewer than 4 players and is not in play
Then each player on it shows a remove (×) button.
When the organizer taps it
Then the player moves to the waitlist. Full courts and courts in play show no remove button.

**COURT-12** — Warning before re-rolling a running court (added 2026-10-12)
Given time-based mode and the round clock is running
When the organizer taps "Re-roll ⟲" on a court with players
Then a dialog "Discard this court's game?" explains that the game is not saved to history and that
some players then get more court time. "Cancel" keeps the court; "Re-roll" re-rolls it.

**COURT-13** — Warning before regenerating a running round (added 2026-10-12)
Given time-based mode, the round clock is running and a lineup exists
When the organizer taps "Regenerate"
Then a dialog "Discard the current round?" explains that the round is not saved to history and that
some players then get more court time. "Cancel" keeps the round; "Regenerate" makes a new one.
(Restored from main's "Game is currently running" warning.)

**WL-01** — Waitlist ordering & display
Given one or more checked-in players are waitlisted
Then they are listed in waitlist order with a position number, name, and level tier; if none are
waitlisted, "No one waiting" is shown in place of the list.

**WL-02** — Auto-promotion on check-out
Given a court is full and at least one player is waitlisted
When any checked-in player on that (or any) court checks out (see CHK-02) or is set Disabled
When a court slot opens up as a result
Then the highest-level waitlisted player(s) are automatically promoted to fill the open slot(s),
highest tier first, without organizer action. Only the court that lost the player is refilled
(WL-03).

**WL-03** — Promotion fills only the freed court
Given a court player leaves (check-out, delete or set Disabled) and players are waitlisted
Then only the court that lost the player is refilled from the waitlist, highest level first; other
empty or part-full courts are not filled. A court that is PLAYING (saved game-based lineup) is never
refilled: it stays one player short, and its saved match does not change.

---

## 4. Players tab (includes integrated check-in — CHK-01…06)

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
Then only players whose name contains the search text (case-insensitive, substring match) are
shown; clearing the box shows all players again.

**PLY-05** — Level adjustment stepper
Given a player row is shown
When the organizer taps "+" or "−" next to their level
Then their level moves up/down by exactly one of the 8 levels (C2, C1, B2, B1, A2, A1, S2, S1),
clamped within [C2…S1] (the lowest Amateur level and the highest Professional level); "−" is
disabled (visually dimmed, non-functional) at C2, and "+" is disabled at S1.

**PLY-06** — Membership cycle (Member → Casual → Disabled)
Given a player's membership is "Member"
When the organizer taps their membership control
Then it advances to "Casual".
Given a player's membership is "Casual"
When the organizer taps their membership control
Then it advances to "Disabled" — if the player is currently checked in, a confirmation dialog
first warns that they'll be checked out and removed from their court/waitlist immediately (see
WL-02 auto-promotion); if they're not checked in, no confirmation is needed. Disabled players
stay in the Players list, but their check-in control is disabled (CHK-06).
Given a player's membership is "Disabled"
When the organizer taps their membership control
Then it advances back to "Member"; this does not automatically check them back in.

**PLY-07** — Delete player
Given a player's expanded profile card is shown
When the organizer taps the delete (bin) icon
Then a confirmation dialog warns the action cannot be undone; on confirm, the player is removed
from the roster and, if currently checked in, from their court/waitlist (WL-02 auto-promotion
triggered); on cancel, nothing changes. The player record is anonymised, not erased, so past games
keep a valid player id (ADR-0001).

**CHK-01** — Capacity bar and remaining count
Given the Players tab is active
Then a progress bar at the top shows checked-in ÷ session capacity, and text reads "{checkedIn} / {capacity} · {remaining} left".

**CHK-02** — Mark present (check in) — inline in Players tab
Given a player is not checked in and the session is below capacity
When the organizer taps their check-in control
Then the player becomes checked in; if any court has fewer than 4 occupants, they are placed on the
first such court (by court index order); otherwise they are added to the waitlist.

**CHK-03** — At-capacity block
Given checked-in count already equals session capacity
When the organizer attempts to check in another player
Then the check-in is refused (no state change) — the UI must not allow bypassing capacity from this control.

**CHK-04** — At-capacity banner
Given checked-in count ≥ session capacity
When the Players tab is viewed
Then a banner reads "Session at capacity — new check-ins are blocked." (CHK-03 refuses them.)

**CHK-05** — Mark absent (check out) — inline in Players tab
Given a player is checked in
When the organizer taps their check-in control again
Then the player becomes not checked in, is removed from their court or the waitlist, and WL-02
auto-promotion is triggered if this opened a court slot.

**CHK-06** — Only non-Disabled players listed (can toggle check-in for Member/Casual players only)
Given a player's membership is "Disabled"
Then their check-in control is disabled or unavailable; only Member/Casual players can be checked in.

**PLY-08** — Check-in toggle from Players tab
Given a player row is shown for a Member or Casual player
Then the check-in control performs CHK-02/CHK-03/CHK-05 behavior directly (no separate Check-in tab).

**PLY-13** — Add player
Given the organizer taps "Add" on the Players tab
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

**PLY-09** — Expand player profile
Given a player's row is tapped anywhere outside its controls (level −/+, membership, check-in)
When no other profile is currently expanded
Then a panel expands inline directly beneath that row (not a modal/drawer — this design was
explicitly chosen after modal/drawer positioning proved unreliable, see design history). The row
and the panel sit in one rounded panel, so they read as one accordion item. Each row has a
trailing arrow: down when the profile is hidden, up when it is shown. The panel shows:
membership status, 3 stat tiles (Current
Level, Matches, Diversity %), a level-progression sparkline, up to 3 most-frequent playing partners
with match counts, and a session-attendance history summary (or "No sessions logged yet" if none).
Definitions: Matches = saved games that hold the player. Diversity % = distinct other players met in
those games ÷ other listed players on the roster. Partners = every other player in a game (a game
does not record who partnered whom). A session = one calendar day with a saved session log. The
sparkline repeats the current level once per game, because no level history is stored.

**PLY-10** — Only one profile expanded at a time
Given player A's profile is expanded
When the organizer taps player B's row
Then A's profile collapses and B's profile expands in its place.

**PLY-11** — Collapse profile
Given a player's profile is expanded
When the organizer taps the "✕" in the profile panel (or taps the same player's row again)
Then the panel collapses.

**PLY-12** — Profile stats reflect session history, not live court state
Given a player has historical session records
Then "Matches," "Diversity," "top partners," and "attendance history" in their profile are computed
from that player's logged session history — they are unaffected by re-rolls or check-ins happening
in the *current* live session until that session is itself logged into history. They are read
from the saved games and session logs, so they survive a restart and update when a round is saved.

---

## 5. Sessions tab

**SESS-01** — Round mode selection
Given the Sessions tab is active
When the organizer selects "Game-based" or "Time-based"
Then the active button is visually highlighted, the round-mode description text updates
accordingly, and (per RND-09) the duration control shows only for Time-based.

**SESS-02** — Rotation duration (`mm:ss`)
Given round mode is Time-based
When the organizer edits the minute or second field of the `mm:ss` duration control
Then: (a) clicking either field selects that whole segment so the next keystroke replaces it, and
`Tab` moves focus from minutes to seconds; (b) minutes are clamped to 0–99 and seconds to 0–59;
(c) a total of 0:00 is rejected and the previous duration is restored; (d) the Dashboard round
countdown recalculates against the new duration on its next tick — including triggering an
immediate rotation if the new duration is now less than the time already elapsed in the current
round.

**SESS-03** — Session capacity change
Given the organizer changes the "Session capacity" number field (minimum enforced value: 4)
Then the stat strip / Check-in capacity bar reflect the new capacity immediately, "at capacity"
behavior (CHK-03/CHK-04) recalculates against it, but **no currently checked-in player is bumped**
even if the new capacity is now lower than the current checked-in count — the limit only applies to
future check-ins.
When the organizer enters a number below 4 (or leaves the field empty or non-numeric)
Then the value is **clamped up to 4** — never raised back to the default of 20 — and the field
shows the clamped number, so it never displays a value the session did not accept.
The same applies to a session template that carries a capacity below 4 (SESS-06): loading it
yields 4. An empty or non-numeric "Number of courts" entry clamps to 1 in the same way.

**SESS-04** — Courts count change
Given the organizer changes "Number of courts" (range 1–8)
Then every currently checked-in player is unassigned and the whole checked-in pool is
re-distributed across the new number of courts using the same level-sorted, courts-of-4 assignment
logic as an initial session start — this is a full reshuffle, not an incremental add/remove of one
court.
When a time-based round is running and a court holds players, a "Discard the current round?"
confirmation shows first, with a "Reshuffle" button; Cancel keeps everything, including the court
count. When no court holds players, or fewer than 4 players are checked in, nothing is generated
(the courts are only padded). A staged next round is planned again for the new count.

**SESS-05** — Save a session template
Given the organizer enters a non-blank template name and taps "Save current"
Then a new template is added to the list capturing the current round mode, duration, session
capacity, and courts count, summarized as e.g. "4 courts · game-based · cap 20"; the name field
clears. Saving with a blank/whitespace-only name is a no-op.

**SESS-06** — Load a template
Given at least one saved template exists
When the organizer taps "Load" on a template
Then the session's round mode, duration, session capacity, and courts count are all overwritten
from the template, and the same full-reshuffle behavior as SESS-04 is applied to redistribute
currently checked-in players across the (possibly new) courts count, with the same confirmation.
Loading a game-based template stops the countdown (GB-01).

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
line vs. the prior period.

**ANA-03** — Attendance trend
Then a per-session bar chart shows attendance rate (checked-in ÷ capacity) over the selected range,
with the most recent session visually emphasized; a growth note (e.g. "+X%") summarizes
month-over-month change.

**ANA-04** — Waitlist pressure
Then a bar chart shows waitlisted-player counts per session over the range, with a contextual note
recommending capacity/schedule changes when average waitlist is high (≥ ~2.5/session) vs. a
reassuring note when it's low.

**ANA-05** — Matchmaking fairness — level-gap trend
Then a bar chart shows, per session, the mean level-gap of its courts over the selected range
(values expressed as tier-gap, e.g. "1.2," not raw ELO; tier-gap = stored Elo-step gap ÷ 2), with a note stating whether the trend is improving (gap
shrinking) or not.

**ANA-06** — Matchmaking fairness — per-court comparison
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
the whole club, with a summary noting the median tier and overall trend direction, and — when
applicable — a stagnation callout ("N players flat 6+ sessions").
Limit: no tier history is stored (see ANA-10). The trend direction compares the mean current tier of
players active in the range with the prior range. Stagnation = 6+ sessions in the range; "tier
unchanged" cannot be checked.

**ANA-10** — removed. Games store player ids only (issue #42); "elo at play time" required two
snapshots of the same player embedded in different games, which the removal of `Game.players` as
a stored value made impossible to represent honestly. `GameRepository` already only ever resolved
historical rosters to the *current* player row, so the feature never showed a real delta in
production — see ADR-0001.

**ANA-11** — At-risk players
Then a list shows regular attendees (historically ≥2×/month) not seen in 3+ weeks, each with their
usual frequency and time since last seen, plus a total "lapsed" count.

**ANA-12** — Player mixing
Then a horizontal bar-per-player list shows a 0–1 mixing score (distinct partners ÷ games played)
for a sample of players, tagged "connector" (high, bridges the club), "clique" (low, narrow circle),
or "isolated" (very low) where applicable, with a summary note.

**ANA-13** — New player integration
Then a list shows recently joined players (within the "new" window, fixed at 60 days until a
setting exists) with when they
joined, sessions attended, and a "% of games played with regulars" status, styled favorably (≥50%)
or as needing attention (<50%), with a contextual note.

**ANA-14** — Responsive reflow
Given the Analytics tab is active
Then the KPI strip shows 6 columns on desktop, 3 on tablet and 1 on phone; chart rows are
side by side on desktop and stack to a single column below desktop — consistent with the breakpoints
in §1.

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
| Navigation & responsive | NAV-01…08 |
| Dashboard: round rotation (time-based) | RND-01…11 |
| Dashboard: game-based mode | GB-01…07 |
| Dashboard: courts & waitlist | COURT-01…13, WL-01…02 |
| Players (with integrated check-in) | PLY-01…12, CHK-01…06 |
| Sessions | SESS-01…06 |
| ~~Schedule~~ (removed) | ~~SCHED-01~~ |
| Analytics | ANA-01…14 |
| Settings | SET-01…05 |
| Self-Registration | REG-01…07 |

Total: **74** acceptance cases (Check-in folded into Players tab; ANA-10 removed, issue #42).
