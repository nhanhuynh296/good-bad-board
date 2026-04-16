# Roadmap: Good Badminton Board

## Milestones

- ✅ **v1.0 Infrastructure** - Phase 01 (shipped)
- 🚧 **v2.0 Click-to-Move** - Phases 2-3 (in progress)

## Phases

<details>
<summary>✅ v1.0 Infrastructure (Phase 01) - SHIPPED</summary>

### Phase 01: Infrastructure
**Goal**: Foundation setup for the project
**Plans**: 4 plans (complete)

</details>

### 🚧 v2.0 Click-to-Move (In Progress)

**Milestone Goal:** Add tap-to-select/tap-to-place player movement as an alternative to drag-and-drop on the game maker screen.

- [ ] **Phase 2: Player Selection** - Shared selection state with visual highlight across courts and inactive list
- [ ] **Phase 3: Tap-to-Move** - Move and swap players via tap targets, coexisting with drag-and-drop

## Phase Details

### Phase 2: Player Selection
**Goal**: Users can visually select and deselect any player across courts and the inactive list
**Depends on**: Phase 01 (infrastructure)
**Requirements**: SEL-01, SEL-02, SEL-03, SEL-04
**Success Criteria** (what must be TRUE):
  1. User can tap a player on any court and see a clear visual highlight indicating that player is selected
  2. User can tap a player in the inactive list and see the same visual highlight indicating selection
  3. User can tap the currently highlighted player again to remove the highlight (deselect)
  4. User can tap an empty area (not a player, not a court target) to clear the current selection
**Plans**: TBD
**UI hint**: yes

### Phase 3: Tap-to-Move
**Goal**: Users can move players between courts and the inactive list by tapping, with drag-and-drop fully preserved
**Depends on**: Phase 2
**Requirements**: MOV-01, MOV-02, COE-01
**Success Criteria** (what must be TRUE):
  1. User can select a player then tap a court background to place that player onto the court
  2. User can select a player then tap a different player to swap their positions (court↔court, court↔inactive, inactive↔court)
  3. Selection automatically clears after a successful move or swap
  4. Drag-and-drop continues to function identically — dragging a player to a court or onto another player works without regression
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:** Phases execute in numeric order: 2 → 3

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 01. Infrastructure | v1.0 | 4/4 | Complete | — |
| 2. Player Selection | v2.0 | 0/? | Not started | - |
| 3. Tap-to-Move | v2.0 | 0/? | Not started | - |
