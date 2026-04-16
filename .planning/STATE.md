# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-16)

**Core value:** The committee can run a session end-to-end — sign in players, generate balanced courts, and rotate fairly — with minimal taps and no manual calculation.
**Current focus:** Phase 2 — Player Selection

## Current Position

Phase: 2 of 3 (Player Selection)
Plan: 0 of ? in current phase
Status: Ready to plan
Last activity: 2026-04-16 — Roadmap created for v2.0 Click-to-Move

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 4 (from v1.0)
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01. Infrastructure | 4 | — | — |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

- v2.0: Click-to-move coexists with drag-and-drop (both input methods serve different user preferences)

### Key Technical Context

- Existing drag-and-drop: `swapPlayer`, `addPlayerToCourt`, `removePlayerFromCourt` in `GameData` (ChangeNotifier)
- Player widgets: `ClickablePlayerComponent` (tap), `DraggablePlayerComponent` (drag+drop), both extend `_PlayerComponent`
- Court widget: `CourtComponent` is a `DragTarget<Player>` with court background image
- Inactive player area: `InactivePlayerComponent` contains both `DraggablePlayerComponent` items and a `DragTarget` wrapper
- Selection state needs to be shared across courts and inactive player list

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-04-16
Stopped at: Roadmap created for v2.0
Resume file: None
