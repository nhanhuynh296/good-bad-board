# State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-16 — Milestone v2.0 started

## Accumulated Context

- Phase 01 (infrastructure) completed — 4 plans executed successfully
- Existing drag-and-drop system uses `swapPlayer`, `addPlayerToCourt`, `removePlayerFromCourt` in `GameData`
- Player widgets: `ClickablePlayerComponent` (tap), `DraggablePlayerComponent` (drag+drop), both extend `_PlayerComponent`
- Court widget: `CourtComponent` is a `DragTarget<Player>` with court background image
- Inactive player area: `InactivePlayerComponent` contains both `DraggablePlayerComponent` items and a `DragTarget` wrapper
