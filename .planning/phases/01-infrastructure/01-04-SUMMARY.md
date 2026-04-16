---
phase: 01-infrastructure
plan: 04
subsystem: infra
tags: [flutter, isolate, compute, elo, game_data, dart]

# Dependency graph
requires:
  - phase: 01-infrastructure/01-01
    provides: Wave 0 stub test file test/state/game_data_isolate_test.dart
provides:
  - makeGame() offloads ELO greedy optimizer to background isolate via compute()
  - _EloPayload and _EloResult typedefs for isolate boundary plain-int data
  - _improveEloSpreadIsolate top-level function (file scope, not class method)
  - _applyOptimizedOrder private method applying isolate result back to stagingMatches
  - 3 passing isolate tests in test/state/game_data_isolate_test.dart
affects:
  - Any phase that calls makeGame() (now async with background compute)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "compute() isolate pattern: top-level function + plain-data typedef payload; no Flutter/domain objects cross isolate boundary"
    - "Isolate result apply pattern: _applyOptimizedOrder re-sorts Player list from optimized int indices"

key-files:
  created: []
  modified:
    - lib/state/game_data.dart
    - test/state/game_data_isolate_test.dart

key-decisions:
  - "Removed _improveEloSpread legacy method instead of keeping it: unused_element warning is fatal under flutter analyze --fatal-infos; method was superseded by the isolate version"
  - "Removed import 'package:flutter/widgets.dart': redundant with foundation.dart import, fatal unnecessary_import lint"
  - "Removed trotter import and rewrote optimizer loops as plain for-loops: enables isolate boundary crossing (no external package references in isolate payload or function)"

patterns-established:
  - "Isolate payload typedef pattern: typedef _EloPayload = ({List<List<int>> courtElos, int maxIteration}) — record syntax, all fields sendable"
  - "compute() call site pattern: await compute(_topLevelFn, (field: value, ...)) with named record literal"

requirements-completed:
  - INFRA-03

# Metrics
duration: 10min
completed: 2026-04-16
---

# Phase 01 Plan 04: ELO Isolate Offload Summary

**ELO greedy optimizer offloaded to background Dart isolate via compute(), operating on plain List<List<int>> data with no Player/Game objects crossing the isolate boundary**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-16T01:41:00Z
- **Completed:** 2026-04-16T01:51:49Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- `makeGame()` now calls `await compute(_improveEloSpreadIsolate, payload)` instead of synchronous `_improveEloSpread(stagingMatches)` — UI thread unblocked during ELO optimization
- `_improveEloSpreadIsolate` added as file-scope top-level function with plain `List<List<int>>` data — fully serializable across isolate boundary
- `_applyOptimizedOrder` private method applies optimized int indices back to `stagingMatches` Player objects on the main isolate
- 3 isolate tests pass (previously Wave 0 stubs); all 5 pre-existing `game_data_test.dart` tests continue to pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Extract ELO optimizer to isolate and wire compute() into makeGame()** - `882c87f` (feat)

## Files Created/Modified

- `lib/state/game_data.dart` - Removed trotter import; added `_EloPayload`/`_EloResult` typedefs; replaced synchronous call with `compute()`; added `_applyOptimizedOrder`; added `_improveEloSpreadIsolate` top-level function; removed dead `_improveEloSpread` method and redundant `widgets.dart` import
- `test/state/game_data_isolate_test.dart` - Replaced 3 Wave 0 skip stubs with fully implemented tests for `makeGame()` with 4 players, varied ELOs, and player-count invariant

## Decisions Made

- **Removed `_improveEloSpread` legacy method**: The plan said to keep it for reference, but the method became dead code immediately after the refactor. `flutter analyze --fatal-infos` treats `unused_element` as a fatal warning. Removing it is the correct fix and doesn't lose any logic — the isolate version implements identical behavior.
- **Removed `import 'package:flutter/widgets.dart'`**: Redundant with `foundation.dart`; causes `unnecessary_import` info which is fatal under `--fatal-infos`. The file was already using `debugPrint` from `foundation.dart` only.
- **Removed trotter import and updated loop logic**: The plan already called for removing the trotter import. The legacy `_improveEloSpread` method used `Combinations`/`Amalgams` from trotter; since that method was removed, no trotter usage remains. `pubspec.yaml` retains the `trotter` dependency (removing package dependencies is out of scope per plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused `_improveEloSpread` method (fatal analyzer warning)**
- **Found during:** Task 1 (post-edit flutter analyze run)
- **Issue:** Plan Step 5 said to keep `_improveEloSpread` with a legacy comment, but after removing its call site the method became unused. `flutter analyze --fatal-infos` reports `unused_element` as a warning that fails with exit code 1 — fatal in CI.
- **Fix:** Removed the entire `_improveEloSpread` static method. Its logic is fully preserved in `_improveEloSpreadIsolate` which uses identical double-for-loop greedy swap algorithm.
- **Files modified:** lib/state/game_data.dart
- **Verification:** `flutter analyze --fatal-infos --no-pub lib/state/game_data.dart` → "No issues found!"
- **Committed in:** 882c87f (Task 1 commit)

**2. [Rule 1 - Bug] Removed redundant `flutter/widgets.dart` import (fatal lint)**
- **Found during:** Task 1 (post-edit flutter analyze run)
- **Issue:** `import 'package:flutter/widgets.dart'` was present in the original file alongside `import 'package:flutter/foundation.dart'`. After the trotter import was removed, the analyzer flagged `unnecessary_import` (info level → fatal under `--fatal-infos`).
- **Fix:** Removed the `flutter/widgets.dart` import line.
- **Files modified:** lib/state/game_data.dart
- **Verification:** `flutter analyze --fatal-infos --no-pub lib/state/game_data.dart` → "No issues found!"
- **Committed in:** 882c87f (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs — both fatal lint violations)
**Impact on plan:** Both auto-fixes necessary for CI compliance. No functional scope creep. The isolate version of the optimizer is behaviorally identical to the removed legacy method.

## Issues Encountered

None — build_runner was already run for generated model files from a prior Wave 2 worktree setup.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. All 3 Wave 0 stubs in `test/state/game_data_isolate_test.dart` have been replaced with passing tests.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The compute() call crosses the main→background isolate boundary with `({List<List<int>> courtElos, int maxIteration})` — plain int data only. This boundary is covered by T-04-01 (maxIteration cap) and T-04-02 (bounds check in _applyOptimizedOrder) from the plan's threat model.

## Next Phase Readiness

- `makeGame()` is async (was already `Future<void>`) — no call-site changes needed in the view layer
- Plans 02 and 03 (repository CRUD, MigrationRunner) are unaffected by this change
- No blockers for remaining Phase 01 plans or future phases

---
*Phase: 01-infrastructure*
*Completed: 2026-04-16*

## Self-Check: PASSED

- FOUND: lib/state/game_data.dart
- FOUND: test/state/game_data_isolate_test.dart
- FOUND: .planning/phases/01-infrastructure/01-04-SUMMARY.md
- FOUND commit: 882c87f
