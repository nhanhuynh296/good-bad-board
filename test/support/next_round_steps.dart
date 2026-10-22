import 'dart:async';

import 'package:good_bad_board/state/game_data.dart';

/// Test steps for round n+1 (R13-Q3).
///
/// The quick save is removed. To save round n+1 the organizer clicks
/// "Generate next round", then "Save round n+1" in edit mode. These steps do
/// the same in one call, for an arrange step.
extension NextRoundSteps on GameData {
  /// Makes round n+1 with the matchmaker and saves it with no change. Does
  /// nothing when round n+1 exists or edit mode is open. In TIME UP the save
  /// also starts the changeover (RND-14).
  void saveNewNextRound() {
    if (nextLineup != null || isEditingNext) return;
    if (!generateNextRound()) return;
    // The save changes the state at once; the future only reports it.
    unawaited(saveNextRound());
  }

  /// "Start round n+1" after round n+1 is saved: saves a new round n+1
  /// first when none exists (RND-04, R13-Q5).
  bool saveAndStartNextRound() {
    saveNewNextRound();
    return startNextRound();
  }
}
