# Good Badminton Board

## What This Is

A Flutter-based court and session organiser for badminton clubs, used by committee members to manage player rotation, court assignments, and ELO-balanced matchmaking during sessions. The app handles the full session lifecycle — from player sign-in through game generation to session history — on a single shared device run by the club committee.

## Core Value

The committee can run a session end-to-end — sign in players, generate balanced courts, and rotate fairly — with minimal taps and no manual calculation.

## Requirements

### Validated

- ✓ Player management (add, search, bulk import/export via CSV) — existing
- ✓ ELO-based court matchmaking (`makeGame`, `_improveEloSpread`) — existing
- ✓ Time-based session mode (countdown timer per game, auto-rotation signal) — existing
- ✓ Game history tracking (`GameRepository`, `PlayerStatisticPage`) — existing
- ✓ Persistent settings (game type, duration, language, background, auto-make) — existing
- ✓ Add-all-players shortcut — existing
- ✓ Player statistics page — existing

### Active

#### Session Management
- [ ] **Game-based mode**: Alternate session type where each court has a manual "Done" button; no timer — admin taps done per court when players finish (e.g. first to 21), then creates the next game for that court
- [ ] **Click-to-move players**: Tap a player to select/highlight them, tap a target court slot to move them; clear visual selection state throughout the interaction
- [ ] **Mark player unavailable**: Mid-session action to pull a player from rotation when they leave early; does not delete the player, just removes from active queue

#### Player Administration
- [ ] **Membership type**: Classify each player as Full / Half / Guest
- [ ] **Last Played**: Automatically record the date a player last participated in a session
- [ ] **Player Avatar**: Auto-generated initials avatar by default; optional photo upload per player
- [ ] **Paying tracker**: Per-session flag for who has paid court fees tonight; plus membership dues status (linked to membership type)

#### Theme & Branding
- [ ] **Club logo**: Display the club's logo within the app (header / splash)
- [ ] **Theme export/import**: Save and restore the full theme config (colours, logo reference) as a JSON file for sharing between devices
- [ ] **Palette from logo**: Auto-extract a colour palette from the uploaded club logo and apply it as the app theme

#### Infrastructure
- [ ] **SQLite migration**: Replace current JSON flat-file storage with SQLite (`sqflite`); include a migration path that reads existing JSON data and imports it into the new schema on first launch
- [ ] **ELO optimizer off UI thread**: Move the `_improveEloSpread` computation to an isolate to prevent UI jank during game generation

#### Analytics
- [ ] **Committee statistics dashboard**: Brainstorm and implement club-level statistics useful to the committee (attendance trends, court utilisation, active vs inactive member counts, peak session sizes, etc.) — propose additional data capture points where beneficial; player-facing stats are out of scope

#### Other
- [ ] **About page**: App info page (version, club details)

### Out of Scope

- **Live score tracking** — admin-heavy; game-based mode ends by manual "done" tap, not score entry
- **Per-player statistics dashboard** — committee-level analytics only; individual player stats pages deferred
- **Cloud sync / remote backup** — SQLite lays the groundwork; cloud management is a future milestone
- **Authentication / multi-user roles** — single shared device model; no login required
- **Undo for player deletion** — not mentioned; standard delete pattern sufficient for now

## Context

- **Existing stack**: Flutter + Provider (`ChangeNotifier`) + `go_router`; models use `freezed` + `json_serializable`; storage is singleton repositories backed by JSON files in app documents directory
- **Existing technical debt**: monolithic 416-line `GameData` ChangeNotifier; synchronous ELO optimizer blocks UI thread; `intl: any` unconstrained; mixed GoRouter/imperative navigation; several dead code paths (`organizer.dart`, unused `product<T,U>` helper, commented-out sign-in ID column)
- **Users**: Club committee members operating a shared device during sessions; typical session 10–40 players
- **SQLite migration note**: Existing users have data in JSON files (`players.json`, `games.json`); migration must be silent and automatic on first launch after upgrade — no data loss acceptable
- **Game-based mode note**: No score input UI; players track their own score; admin simply taps "Done" on the court widget when they're ready to rotate

## Constraints

- **Tech stack**: Flutter (Dart) — no platform change; target mobile (Android/iOS) first
- **Storage migration**: Must preserve all existing player and game history data when migrating to SQLite; zero data loss
- **UX principle**: Admin-first, minimal taps — avoid features that require continuous input during play (no live scoring, no play-by-play)
- **State management**: Stay on Provider/ChangeNotifier unless SQLite migration creates a clear reason to revisit; avoid scope creep into Riverpod/BLoC refactor

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Game-based mode = manual "done" per court, no score tracking | Score entry is admin-heavy; committee just needs rotation signal | — Pending |
| SQLite via `sqflite` replaces JSON flat files | Relational queries needed for player admin features; better performance with 50+ players; groundwork for future cloud sync/backup | — Pending |
| Statistics = committee dashboard only (not per-player) | Per-player stats add complexity; committee use case is the immediate need | — Pending |
| Avatar = initials default, optional photo upload | Zero-friction baseline; photo upload for clubs that want richer profiles | — Pending |
| Paying tracker covers both session fees and membership status | Both are committee concerns; combining avoids two separate UIs | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-16 after initialization*
