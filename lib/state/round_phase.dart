/// Where a Time Based session is in its Round (IMPLEMENTATION 8.2, UAT §3).
///
/// [GameData.phase] holds it. The UI reads the phase only; it never derives
/// it from the timer. Edit mode for the next Round is a separate flag
/// ([GameData.isEditingNext]), never a phase (F02).
enum RoundPhase {
  /// No court holds a player: session start, or after End session (RND-12).
  noLineup,

  /// Round 1 is a draft and its clock has not started (RND-13).
  ready,

  /// The round clock counts down (RND-01).
  running,

  /// The round clock or the changeover clock is frozen (RND-17, RND-18).
  /// [GameData.pausedFrom] tells which.
  paused,

  /// The round reached 0:00 with no saved next Round (RND-15).
  timeUp,

  /// The 20 s changeover before the next Round starts (RND-03).
  changeover,
}
