# Phase 2: Player Selection - Research

**Researched:** 2025-07-19
**Domain:** Flutter state management + gesture handling for single-player selection UI
**Confidence:** HIGH

## Summary

Phase 2 adds a tap-to-select interaction to the existing GameMakerPage. Users tap any player (on courts or in the inactive list) to highlight them; tapping the highlighted player or tapping empty space deselects. This is a pure UI interaction layer — no new dependencies, no persistence, no new pages.

The existing codebase is well-structured for this change. `ClickablePlayerComponent` already accepts an `onTap` callback (currently unused in `DraggablePlayerComponent`). `ShadedContainer` already supports `borderColor` and `backgroundColor` overrides. `GameData` (ChangeNotifier) is the central session state and the natural home for selection state, with `context.select` enabling granular rebuilds. The main technical concern is the interplay between Flutter's `GestureDetector`, `Draggable`, and `DragTarget` gesture recognizers when wiring the "tap empty area to deselect" behavior.

**Primary recommendation:** Add `Player? selectedPlayer` field + `selectPlayer`/`clearSelection` methods to `GameData`. Pass `isSelected` through the existing `DraggablePlayerComponent` → `ClickablePlayerComponent` chain. Use `GestureDetector` on court backgrounds and the page body for deselect-on-background-tap.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEL-01 | User can tap a player on a court to select them (visual highlight) | `DraggablePlayerComponent` wraps `ClickablePlayerComponent` which has unused `onTap` — wire to `GameData.selectPlayer()`. Visual via `ShadedContainer.borderColor`/`backgroundColor`. |
| SEL-02 | User can tap an inactive player to select them (visual highlight) | Inactive list uses same `DraggablePlayerComponent` — identical implementation path. |
| SEL-03 | User can tap the selected player again to deselect them | Toggle logic in `selectPlayer()`: if already selected, call `clearSelection()`. |
| SEL-04 | User can tap a non-target area to deselect current selection | `GestureDetector(onTap: clearSelection)` on `CourtComponent` Stack and `GameMakerPage` body wrapper. Flutter gesture arena ensures child taps win over parent. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Selection state (which player is selected) | State layer (`GameData`) | — | ChangeNotifier is the project's state management pattern; selection must be shared across courts and inactive list |
| Selection visual (goldRush border/tint) | View layer (`player.dart`) | — | Pure visual concern handled by existing `ShadedContainer`/`Button` components |
| Tap-to-select wiring | View layer (`player.dart`) | — | `ClickablePlayerComponent.onTap` → `GameData.selectPlayer()` |
| Tap-to-deselect (background) | View layer (`court.dart`, `game_maker_page.dart`) | — | `GestureDetector.onTap` → `GameData.clearSelection()` |
| Semantics (accessibility) | View layer (`player.dart`) | — | `Semantics(selected: true)` wrapper on selected player widget |

## Standard Stack

### Core

No new dependencies. Everything is built with existing Flutter SDK + project packages.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter/material.dart` | SDK | `GestureDetector`, `Container`, `BoxDecoration`, `Semantics`, `Border` | First-party Flutter SDK — all selection visuals use built-in widgets |
| `provider` | ^6.1.2 | `context.select<GameData, Player?>((d) => d.selectedPlayer)` for granular rebuilds | Already in use throughout the app for state management |

[VERIFIED: pubspec.yaml and codebase inspection]

### Supporting

No supporting libraries needed. The selection feature is entirely self-contained within existing dependencies.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Adding to `GameData` | New `SelectionState` ChangeNotifier | Cleaner separation, but adds provider to `MultiProvider`, requires cross-provider coordination in Phase 3 for swap/move. More complexity for no real benefit since `context.select` provides granular rebuilds. |
| `GestureDetector` for background dismiss | `TapRegion`/`TapRegionSurface` | Flutter 3.7+ widget for "outside tap" detection. More semantic, but the project has no existing usage and `GestureDetector` is simpler and well-understood. |
| Comparing `selectedPlayer == data` (freezed equality) | Comparing `selectedPlayer?.id == data.id` | ID comparison is safer — avoids edge case where player fields change (e.g., `onUpdatePlayer`) but the same player should remain selected. |

## Architecture Patterns

### System Architecture Diagram

```
User Tap on Player
        │
        ▼
┌─────────────────────┐
│ ClickablePlayerComponent │
│   onTap callback     │
└─────────┬───────────┘
          │ calls
          ▼
┌─────────────────────┐
│   GameData           │
│   selectPlayer(p)    │──► if same player → clearSelection()
│   clearSelection()   │──► if different player → selectedPlayer = p
│   notifyListeners()  │
└─────────┬───────────┘
          │ rebuilds via context.select
          ▼
┌─────────────────────┐     ┌──────────────────────────┐
│ DraggablePlayerComponent│  │ CourtComponent / Body    │
│ reads: isSelected    │     │ GestureDetector.onTap    │
│ passes to child      │     │   → clearSelection()     │
└─────────┬───────────┘     └──────────────────────────┘
          │
          ▼
┌─────────────────────┐
│ ClickablePlayerComponent │
│ isSelected → visual  │
│ goldRush border/tint │
└─────────────────────┘
```

### Recommended Changes (no new files)

```
lib/
├── state/
│   └── game_data.dart          # ADD: selectedPlayer, selectPlayer(), clearSelection()
├── view/
│   ├── component/
│   │   ├── player.dart         # MODIFY: ClickablePlayerComponent (isSelected param, visual)
│   │   │                       #          DraggablePlayerComponent (read selection, wire onTap)
│   │   ├── court.dart          # MODIFY: GestureDetector on Stack for background tap
│   │   └── inactive_player.dart # NO CHANGE: inherits behavior from DraggablePlayerComponent
│   └── game_maker_page.dart    # MODIFY: GestureDetector wrapper on body for SEL-04
└── theme.dart                  # NO CHANGE: AppColors.goldRush already exists
```

### Pattern 1: Selection State in GameData

**What:** Add `Player? selectedPlayer` field with `selectPlayer(Player)` and `clearSelection()` methods to the existing `GameData` ChangeNotifier.

**When to use:** When selection state must be shared across multiple unrelated widget subtrees (courts + inactive list) and will be consumed by the same state object in Phase 3 (swap/move operations).

**Example:**
```dart
// Source: [project pattern from lib/state/game_data.dart]
// Added to GameData class:

Player? _selectedPlayer;

Player? get selectedPlayer => _selectedPlayer;

void selectPlayer(Player player) {
  if (_selectedPlayer?.id == player.id) {
    clearSelection();
    return;
  }
  _selectedPlayer = player;
  notifyListeners();
}

void clearSelection() {
  if (_selectedPlayer == null) return; // avoid unnecessary rebuilds
  _selectedPlayer = null;
  notifyListeners();
}
```

[VERIFIED: follows existing GameData patterns from codebase inspection]

### Pattern 2: Granular Rebuilds with context.select

**What:** Use `context.select` to subscribe only to the `selectedPlayer` field, preventing unnecessary widget rebuilds when other GameData fields change.

**When to use:** In `DraggablePlayerComponent.build()` to read selection state.

**Example:**
```dart
// Source: [project pattern — see game_maker_page.dart lines 101-106]
// In DraggablePlayerComponent.build():
final selectedPlayer = context.select(
  (GameData data) => data.selectedPlayer,
);
final isSelected = selectedPlayer?.id == data.id;
```

[VERIFIED: `context.select` is the established pattern in `GameMakerPage` — lines 101-106]

### Pattern 3: Selection Visual via Existing ShadedContainer

**What:** Use the existing `ShadedContainer` parameters (`borderColor`, `backgroundColor`) for the selection highlight. `ShadedContainer` already supports these overrides — no modification needed to the container itself.

**When to use:** In `ClickablePlayerComponent` when `isSelected == true`.

**Example:**
```dart
// Source: [codebase: lib/view/component/container.dart — ShadedContainer already supports borderColor/backgroundColor]
// In ClickablePlayerComponent — approach: wrap existing Button in ShadedContainer for selection chrome
// OR modify Button to pass borderColor/backgroundColor through

// Approach: Add isSelected to ClickablePlayerComponent, conditionally apply
// goldRush border via ShadedContainer wrapping
```

[VERIFIED: `ShadedContainer` accepts `borderColor` and `backgroundColor` — see container.dart lines 10-11]

### Pattern 4: GestureDetector for Background Dismiss (SEL-04)

**What:** Wrap court Stack and page body in `GestureDetector(onTap: clearSelection)`. Flutter's gesture arena ensures child tap handlers (player buttons) win over parent GestureDetectors.

**When to use:** For "tap empty area to deselect" behavior.

**Example:**
```dart
// Source: [Flutter framework gesture arena behavior]
// In CourtComponent — wrap the Stack:
GestureDetector(
  onTap: () {
    Provider.of<GameData>(context, listen: false).clearSelection();
  },
  child: Stack(
    children: [
      Image.asset(PersistentSetting.instance.getBackground()),
      // ... player widgets
    ],
  ),
)

// In GameMakerPage — wrap body:
GestureDetector(
  onTap: () {
    context.read<GameData>().clearSelection();
  },
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: spacePageX),
    child: Row(/* existing layout */),
  ),
)
```

[VERIFIED: CourtComponent currently has no GestureDetector — see court.dart. GestureDetector is used sparingly in codebase — only in setting.dart line 116]

### Anti-Patterns to Avoid

- **Storing selection as index instead of Player reference:** Court layouts sort players by ELO (`sortedBy((player) => player.elo.index)` in court.dart line 27). An index-based selection would point to the wrong player after sorting. Always reference by `Player.id`. [VERIFIED: court.dart line 27]
- **Using `Provider.of<GameData>(context)` (full rebuild) for selection reads:** This would rebuild the entire widget tree on any GameData change. Use `context.select((GameData d) => d.selectedPlayer)` for granular rebuild. [VERIFIED: project already uses this pattern in game_maker_page.dart]
- **Adding animation to selection toggle:** The UI-SPEC explicitly states "No animation for Phase 2 selection toggle. Instant visual change on tap." Reserve animation/scale for drag-hover (already at 1.2x). [VERIFIED: 02-UI-SPEC.md line 119]
- **Showing selection highlight on the drag feedback widget:** `_DraggingPlayerComponent` renders the player being dragged. It should NOT show the selection highlight — drag states and selection are mutually exclusive. [VERIFIED: 02-UI-SPEC.md lines 127-128]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Selection visual (border + tint) | Custom painter or BoxDecoration from scratch | `ShadedContainer(borderColor: goldRush, backgroundColor: goldRush.withValues(alpha: 0.15))` | Existing component already handles border radius, shadow, clipping |
| "Tap outside to dismiss" | Manual hit test calculation | `GestureDetector(onTap: clear)` on parent, relying on gesture arena | Flutter's gesture arena automatically routes taps to the most specific handler |
| Cross-widget state sharing | InheritedWidget, ValueNotifier, or callback drilling | `GameData` ChangeNotifier + `context.select` | Already the established pattern for all shared state in this app |
| Player identity comparison | `==` operator (freezed value equality) | `player.id` string comparison | Value equality breaks when player fields change mid-session via `onUpdatePlayer` |

**Key insight:** The existing widget infrastructure (`ShadedContainer`, `ClickablePlayerComponent.onTap`, `GameData` + Provider) already provides 90% of what's needed. Phase 2 is mostly wiring — not building.

## Common Pitfalls

### Pitfall 1: Draggable + Tap Gesture Conflict

**What goes wrong:** Wrapping a widget in `Draggable` can interfere with tap detection. If the user's finger moves slightly during a tap, `Draggable` interprets it as a drag start instead of a tap.

**Why it happens:** `Draggable` creates a `MultiDragGestureRecognizer` that competes in the gesture arena with `TapGestureRecognizer`. The arena uses a distance threshold to disambiguate.

**How to avoid:** The existing code already handles this correctly — `ClickablePlayerComponent` is a child of `Draggable`, and Flutter's `Button`/`FilledButton` widgets have their own `TapGestureRecognizer` that wins the arena for zero-displacement touches. Test on real devices to confirm the tap/drag threshold feels natural.

**Warning signs:** Players reporting they can't select by tapping (always initiates a drag). Check `Draggable`'s `affinity` parameter if this occurs.

[VERIFIED: existing DraggablePlayerComponent structure in player.dart lines 76-132]

### Pitfall 2: Stale Selection Reference After Game Operations

**What goes wrong:** User selects a player, then `makeGame()` / `saveSingleGame()` / `removePlayer()` runs. The selected player may no longer be on any court or may have moved. The highlight persists on a "ghost" reference.

**Why it happens:** `selectedPlayer` references a `Player` object. After game operations, the player's position changes but the reference remains.

**How to avoid:** Call `clearSelection()` inside `makeGame()`, `saveSingleGame()`, `saveCurrentGame()`, `makeSingleCourt()`, and `removePlayer()`. This is safe because these operations fundamentally change the board state.

**Warning signs:** A player appears highlighted after regenerating courts, or highlight appears on a player who moved to a different position.

### Pitfall 3: GestureDetector with `DragTarget` on Court Background

**What goes wrong:** Adding `GestureDetector(onTap: clearSelection)` around the court `Stack` may interfere with `DragTarget` drop acceptance, or the `GestureDetector` might not fire because `DragTarget`'s builder renders children that absorb hit tests.

**Why it happens:** `DragTarget` participates in the hit test tree. However, `DragTarget` does NOT handle tap gestures — it only handles drag-drop acceptance. So `GestureDetector.onTap` and `DragTarget` should not conflict.

**How to avoid:** Place the `GestureDetector` INSIDE the `DragTarget.builder`, wrapping the `Stack`, not outside the `DragTarget`. This way the GestureDetector handles taps while DragTarget handles drags independently.

**Warning signs:** Court background taps don't clear selection, or drag-to-court stops working after adding the GestureDetector.

[VERIFIED: CourtComponent structure — DragTarget wraps Stack, players are inside Stack. See court.dart lines 29-137]

### Pitfall 4: Double notifyListeners on Select-Then-Select

**What goes wrong:** User taps Player A (select), then taps Player B (should select B). If `selectPlayer(B)` calls `clearSelection()` then `selectPlayer(B)` internally, it triggers `notifyListeners()` twice, causing two rebuild cycles.

**Why it happens:** Naive implementation: clear old, then set new, each calling `notifyListeners()`.

**How to avoid:** Set `_selectedPlayer = player` directly and call `notifyListeners()` once. The toggle check (deselect if same player) should be the only branch that calls clear.

**Warning signs:** Visible flicker when switching selection between players (momentary un-highlight before re-highlight).

### Pitfall 5: Selection State Leaking to Non-GameMaker Pages

**What goes wrong:** `GameData` is provided at the app root level (`main.dart`). If the user navigates to the stats page or sign-in page, `selectedPlayer` remains set. If they return to GameMaker, a stale selection appears.

**Why it happens:** `GameData` persists across page transitions by design (it holds session state).

**How to avoid:** Either clear selection when GameMakerPage disposes (`dispose()` callback), or when GameMakerPage initializes (`initState`). The simpler approach: clear on `initState` — this is idempotent and handles all navigation paths.

**Warning signs:** Returning to the game maker page shows a player highlighted that the user didn't just select.

## Code Examples

### Example 1: GameData Selection State

```dart
// Source: [project pattern from lib/state/game_data.dart]
// Add to class GameData:

Player? _selectedPlayer;
Player? get selectedPlayer => _selectedPlayer;

/// Select a player, or deselect if the same player is tapped again.
void selectPlayer(Player player) {
  if (_selectedPlayer?.id == player.id) {
    clearSelection();
    return;
  }
  _selectedPlayer = player;
  notifyListeners();
}

/// Clear the current selection. No-op if nothing is selected.
void clearSelection() {
  if (_selectedPlayer == null) return;
  _selectedPlayer = null;
  notifyListeners();
}
```

### Example 2: DraggablePlayerComponent Reading Selection + Wiring onTap

```dart
// Source: [project pattern from lib/view/component/player.dart]
// Modified DraggablePlayerComponent.build():

@override
Widget build(BuildContext context) {
  final gameData = Provider.of<GameData>(context);
  final selectedPlayer = context.select(
    (GameData data) => data.selectedPlayer,
  );
  final isSelected = selectedPlayer?.id == data.id;
  // ... existing code ...
  child: ClickablePlayerComponent(
    inMatch: true,
    key: ValueKey(data.id),
    data: data,
    filled: true,
    disabled: isInvalidDragHovering,
    isSelected: isSelected,
    size: size,
    onTap: () {
      Provider.of<GameData>(context, listen: false).selectPlayer(data);
    },
  ),
}
```

### Example 3: ClickablePlayerComponent Selection Visual

```dart
// Source: [UI-SPEC contract + project patterns]
// Modified ClickablePlayerComponent:

class ClickablePlayerComponent extends _PlayerComponent {
  final bool filled;
  final VoidCallback? onTap;
  final bool disabled;
  final bool inMatch;
  final bool isSelected;  // NEW

  const ClickablePlayerComponent({
    super.key,
    super.size,
    required super.data,
    this.filled = false,
    this.disabled = false,
    this.inMatch = false,
    this.isSelected = false,  // NEW
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ... existing onSecondaryAction code ...

    Widget button = Button(
      type: filled ? ButtonType.filled : ButtonType.outlined,
      onPressed: onTap,
      onLongPress: onSecondaryAction,
      disabled: disabled,
      child: super.build(context),
    );

    if (isSelected) {
      button = Semantics(
        selected: true,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.goldRush, width: 3),
            borderRadius: outlinedBorderRadius,
            color: AppColors.goldRush.withValues(alpha: 0.15),
          ),
          child: button,
        ),
      );
    }

    return button;
  }
}
```

### Example 4: CourtComponent Background Tap (SEL-04)

```dart
// Source: [UI-SPEC tap target spec + project pattern]
// In CourtComponent.build(), inside DragTarget.builder:

return GestureDetector(
  onTap: () {
    Provider.of<GameData>(context, listen: false).clearSelection();
  },
  child: Stack(
    children: [
      Image.asset(
        PersistentSetting.instance.getBackground(),
        semanticLabel: 'court background',
      ),
      // ... existing positioned player widgets ...
    ],
  ),
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Color.withOpacity(0.15)` | `Color.withValues(alpha: 0.15)` | Flutter 3.27+ | `withOpacity` deprecated; UI-SPEC already uses `withValues(alpha:)` |
| `WidgetStateProperty.all()` | `WidgetStatePropertyAll()` | Flutter 3.19+ | Shorthand constructor; project already uses this |

[VERIFIED: UI-SPEC uses `withValues(alpha:)` syntax — line 78. Codebase uses both patterns — theme.dart line 73]

**Deprecated/outdated:**
- `Color.withOpacity()`: Deprecated in favor of `Color.withValues(alpha:)` in Flutter 3.27+. The codebase already uses `withValues` in some places (theme.dart line 73) but `withOpacity` may still appear. Use `withValues(alpha:)` for all new code. [VERIFIED: theme.dart]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Flutter gesture arena allows `GestureDetector.onTap` on parent to coexist with `Draggable` + `Button.onTap` on child without conflict — child wins for taps, parent fires on background | Pitfall 1 & Pattern 4 | If wrong, players can't be selected by tap when inside a `Draggable`. Would need `Listener` instead of `GestureDetector` or a different approach. |
| A2 | `DragTarget` does not consume tap gestures, only drag-accept gestures | Pitfall 3 | If wrong, `GestureDetector.onTap` inside DragTarget.builder won't fire on court background taps. |
| A3 | Clearing selection on game operations (makeGame, etc.) is the correct UX | Pitfall 2 | If wrong (user expects selection to persist through regeneration), would need to reconcile selection with new board state. Low risk — selection is cheap to re-apply. |

**Note:** A1 and A2 are standard Flutter framework behavior documented in the Flutter gesture system docs, but classified as ASSUMED because they were not verified via running tests in this session. They should be confirmed during implementation with a quick manual test.

## Open Questions

1. **Selection visual approach: Container wrapper vs. ShadedContainer modification**
   - What we know: UI-SPEC recommends using `ShadedContainer.borderColor`. But `Button` already wraps in `ShadedContainer`, creating a nesting issue. A plain `Container` with `BoxDecoration` is simpler.
   - What's unclear: Whether the double-`ShadedContainer` nesting creates visual artifacts (double shadows, misaligned borders).
   - Recommendation: Start with a plain `Container` wrapper (Example 3 above). If the visual doesn't match the spec, switch to modifying `Button` to pass through `borderColor`.

2. **Should selection clear when navigating away from GameMakerPage?**
   - What we know: `GameData` is app-wide, selection persists across navigation.
   - What's unclear: User expectation — should selection survive a round-trip to stats page?
   - Recommendation: Clear selection in `GameMakerPage.initState()` as a safe default.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `test` ^1.25.15 |
| Config file | None (uses default Dart test conventions) |
| Quick run command | `flutter test test/game_data_test.dart --no-pub -x` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEL-01 | Tap court player → selectedPlayer is set | unit | `flutter test test/state/selection_test.dart -x --no-pub` | ❌ Wave 0 |
| SEL-02 | Tap inactive player → selectedPlayer is set | unit | `flutter test test/state/selection_test.dart -x --no-pub` | ❌ Wave 0 |
| SEL-03 | Tap selected player → selectedPlayer is null | unit | `flutter test test/state/selection_test.dart -x --no-pub` | ❌ Wave 0 |
| SEL-04 | clearSelection sets selectedPlayer to null | unit | `flutter test test/state/selection_test.dart -x --no-pub` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/state/selection_test.dart --no-pub`
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/state/selection_test.dart` — covers SEL-01, SEL-02, SEL-03, SEL-04 (unit tests for GameData selection methods)
- [ ] No new framework install needed — existing `test` and `flutter_test` are sufficient

*(All selection logic tests can be pure unit tests on GameData — no widget test infrastructure needed for the state layer.)*

## Security Domain

Not applicable for Phase 2. This phase adds no authentication, no data persistence, no network calls, no user input processing, and no cryptographic operations. Selection is an ephemeral in-memory UI state on a single shared device.

## Sources

### Primary (HIGH confidence)

- **Codebase inspection** — `lib/view/component/player.dart`, `lib/view/component/court.dart`, `lib/view/component/container.dart`, `lib/view/component/inactive_player.dart`, `lib/view/game_maker_page.dart`, `lib/state/game_data.dart`, `lib/theme.dart`, `lib/main.dart` — all read in full
- **UI-SPEC** — `.planning/phases/02-player-selection/02-UI-SPEC.md` — visual contract, component inventory, tap target specification
- **REQUIREMENTS.md** — `.planning/REQUIREMENTS.md` — SEL-01 through SEL-04 definitions
- **STATE.md** — `.planning/STATE.md` — key technical context about existing drag-and-drop infrastructure

### Secondary (MEDIUM confidence)

- **Flutter gesture system** — general framework knowledge about `GestureDetector`, `Draggable`, `DragTarget`, and gesture arena behavior [ASSUMED — standard Flutter framework behavior]

### Tertiary (LOW confidence)

- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, all existing libraries verified in pubspec.yaml and codebase
- Architecture: HIGH — follows established project patterns (ChangeNotifier, Provider, context.select), verified against actual code
- Pitfalls: MEDIUM — gesture arena behavior is based on Flutter framework knowledge, not verified by running tests in this session
- Visual treatment: HIGH — UI-SPEC provides detailed contract, existing ShadedContainer/AppColors verified in code

**Research date:** 2025-07-19
**Valid until:** 2025-08-19 (stable — no moving parts, all first-party Flutter SDK)
