import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_log.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_template_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/state/lineup_error.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/round_phase.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trotter/trotter.dart';
import 'package:uuid/uuid.dart';

export 'package:good_bad_board/state/lineup_error.dart';
export 'package:good_bad_board/state/round_phase.dart';

typedef GameContainer = List<Game>;

const int maxIteration = 1000;

/// The outcome of [GameData.checkInPlayer] (R45-38).
enum CheckInResult {
  checkedIn,

  /// The player's membership is [MembershipStatus.disabled].
  disabled,

  /// The session is at capacity.
  sessionFull,
}

/// One place that the fill rule filled (IMPLEMENTATION 8.4.4): [player]
/// took a slot on the court at [courtIndex] (0 = Court 1) in round [round].
/// The CHECKED OUT scan text names it (PLY-18).
typedef SlotFill = ({Player player, int courtIndex, int round});

/// Release flag for the court-count controls (R45-36).
///
/// On (R13-Q1, Nathan 2026-10-22): the Sessions tab shows the court count
/// control (minimum 1, no upper limit, R13-Q12), and a template Load applies
/// its court count. The Courts tab has no stepper, also with the flag on
/// (R2-Q2). With the flag off the club always uses
/// [GameData.defaultCourtCount] courts and a template Load keeps the court
/// count.
abstract final class CourtCount {
  static bool editable = true;
}

class GameData extends ChangeNotifier {
  /// [random] feeds the weighted player draws; tests pass a seeded one.
  ///
  /// [timer] is the round clock the round state machine drives. `main.dart`
  /// passes the one [TimerData] it provides, so the round bar watches the
  /// same clock. Without one, GameData makes and owns its own.
  ///
  /// [clock] tells the time for the swap Undo window; tests pass a fake one.
  GameData({Random? random, TimerData? timer, DateTime Function()? clock})
    : _random = random,
      _timer = timer ?? TimerData(),
      _ownsTimer = timer == null,
      _clock = clock ?? DateTime.now;

  final Random? _random;
  final DateTime Function() _clock;

  final TimerData _timer;
  final bool _ownsTimer;

  /// The round clock (IMPLEMENTATION 8.2.3).
  TimerData get timer => _timer;

  @override
  void dispose() {
    if (_ownsTimer) _timer.dispose();
    super.dispose();
  }

  /// Number of random 4-player combinations a re-roll compares (COURT-02).
  static const int rerollSampleCount = 100;

  /// Default session capacity (20 players).
  static const int defaultSessionCapacity = 20;

  /// Smallest session capacity the organizer can set — one full court.
  static const int minSessionCapacity = 4;

  int _sessionCapacity = defaultSessionCapacity;

  /// Sets the session capacity, clamped to [minSessionCapacity].
  ///
  /// A value below the minimum becomes the minimum — it does not fall back to
  /// the default, which would silently raise the capacity the organizer asked
  /// for rather than lower it.
  ///
  /// Does not evict currently checked-in players even if the new capacity
  /// is lower than the current count — the limit only applies to future
  /// check-ins.
  void setSessionCapacity(int capacity) {
    _sessionCapacity = capacity < minSessionCapacity
        ? minSessionCapacity
        : capacity;
    notifyListeners();
  }

  /// Maximum number of players that can be checked in for the session.
  /// Enforces a floor of [minSessionCapacity].
  int get sessionCapacity => _sessionCapacity < minSessionCapacity
      ? minSessionCapacity
      : _sessionCapacity;

  /// Players currently checked into the session, keyed by id.
  final Map<String, Player> _checkedInPlayers = {};

  /// Unmodifiable view of the checked-in players, keyed by id.
  Map<String, Player> get checkedInPlayers =>
      Map.unmodifiable(_checkedInPlayers);

  /// Number of players currently checked in.
  int get checkedInCount => _checkedInPlayers.length;

  /// Remaining capacity before the session is full.
  int get remainingCapacity {
    final cap = sessionCapacity;
    return (cap - _checkedInPlayers.length).clamp(0, cap);
  }

  /// Whether the session has reached or exceeded capacity.
  bool get isAtCapacity => _checkedInPlayers.length >= sessionCapacity;

  /// Saved session configuration templates, in the order they were saved.
  List<SessionTemplate> get templates =>
      List.unmodifiable(SessionTemplateRepository.instance.getAll());

  /// Default number of courts for a fresh session (the club has 4).
  static const int defaultCourtCount = 4;

  /// Number of courts. Not persisted: every session starts at
  /// [defaultCourtCount], and a template can set its own.
  int numberOfCourt = defaultCourtCount;

  /// Sets the number of courts (SESS-04, R13-Q1).
  ///
  /// The change applies to the current courts only and never reshuffles the
  /// lineup: an added court is empty, and the players of a removed court go
  /// to the waitlist. The round phase and the clock do not change.
  void setNumberOfCourt(int value) {
    if (value <= 0) return;
    numberOfCourt = value;
    _applyCourtCount();
    notifyListeners();
  }

  /// Brings every lineup in step with [numberOfCourt]: the live round, a
  /// saved round n+1 and the lineup in edit mode. Does not notify.
  ///
  /// It never reshuffles (R13-Q1). A court beyond the new count leaves the
  /// grid, so its players go back to the waitlist. A new court is empty.
  void _applyCourtCount() {
    _dropCourtsBeyondCount();
    // A court added to a grid that already shows courts needs a slot to
    // take a tap and a re-roll.
    if (stagingMatches.isNotEmpty) {
      stagingMatches = [...stagingMatches];
      _padToCourtCount(stagingMatches);
    }
    final next = _nextLineup;
    if (next != null) _fitToCourtCount(next);
    final edit = _editLineup;
    if (edit != null && !identical(edit, next)) _fitToCourtCount(edit);
    // The edit base gets the same change, so the count change alone is not
    // an unsaved edit (R11-Q2).
    final base = _editBase;
    if (base != null) {
      if (base.length > numberOfCourt) {
        base.removeRange(numberOfCourt, base.length);
      }
      while (base.length < numberOfCourt) {
        base.add(<String>[]);
      }
    }
  }

  /// Drops the courts of [lineup] beyond [numberOfCourt] and pads it with
  /// empty courts, in place.
  void _fitToCourtCount(GameContainer lineup) {
    if (lineup.length > numberOfCourt) {
      lineup.removeRange(numberOfCourt, lineup.length);
    }
    _padToCourtCount(lineup);
  }

  /// Removes the court at [index] (0 = Court 1) from every lineup: the
  /// live round, a saved round n+1 and the lineup in edit mode (R13-Q9).
  ///
  /// Its players go to the waitlist. The courts after it move up one
  /// number. The round phase and the clock do not change. Returns `false`
  /// and changes nothing for the last court or an index out of range.
  bool removeCourt(int index) {
    if (numberOfCourt <= 1 || index < 0 || index >= numberOfCourt) {
      return false;
    }
    void dropFrom(GameContainer? lineup) {
      if (lineup != null && index < lineup.length) lineup.removeAt(index);
    }

    stagingMatches = [...stagingMatches];
    dropFrom(stagingMatches);
    final next = _nextLineup;
    dropFrom(next);
    final edit = _editLineup;
    if (!identical(edit, next)) dropFrom(edit);
    final base = _editBase;
    if (base != null && index < base.length) base.removeAt(index);
    numberOfCourt--;
    _prunePlayingGameIds();
    _applyCourtCount();
    notifyListeners();
    return true;
  }

  /// Removes the courts beyond [numberOfCourt] from the live round.
  void _dropCourtsBeyondCount() {
    if (stagingMatches.length > numberOfCourt) {
      stagingMatches = stagingMatches.take(numberOfCourt).toList();
      _prunePlayingGameIds();
    }
  }

  final List<GameContainer> history = [];

  /// Candidate to be added to history
  GameContainer stagingMatches = GameContainer.empty();

  /// Ids of the [Game]s whose lineup has been saved and is now being played
  /// (game-based mode).
  ///
  /// Keyed on [Game.id] rather than court index so the flag invalidates
  /// itself: [makeGame] and [makeSingleCourt] build fresh [Game] objects with
  /// new ids, so a regenerated or re-rolled court is never marked as playing.
  final Set<String> _playingGameIds = {};

  /// Whether the court at [courtIndex] holds a saved game that is in play.
  ///
  /// Keyed on the lineup on screen: a court of round n+1 has a brand-new
  /// [Game] id, so round n+1 never reports a court as playing.
  bool isCourtPlaying(int courtIndex) =>
      courtIndex >= 0 &&
      courtIndex < visibleMatches.length &&
      _playingGameIds.contains(visibleMatches[courtIndex].id);

  /// Whether any court currently holds players.
  ///
  /// Drives the game-based "Generate Game" button, which is only offered
  /// until the first lineup exists.
  bool get hasAnyCourtLineup =>
      stagingMatches.any((game) => game.playerIds.isNotEmpty);

  /// Drops playing flags for [Game]s that are no longer on a court, so the
  /// set does not grow across a session.
  void _prunePlayingGameIds() {
    final live = _liveMatches.map((game) => game.id).toSet();
    _playingGameIds.retainWhere(live.contains);
  }

  /// The live round, even while [_onLineup] has another lineup installed in
  /// [stagingMatches].
  GameContainer get _liveMatches => _displacedLive ?? stagingMatches;

  /// Set by [_onLineup] while another lineup stands in for [stagingMatches].
  GameContainer? _displacedLive;

  /// Number of re-rolls performed since the last logged round.
  int _sessionRerollCount = 0;

  /// Number of re-rolls performed since the last logged round.
  int get sessionRerollCount => _sessionRerollCount;

  // ── Round Rotation State ─────────────────────────────────────

  /// Current round number (starts at 1).
  int _roundNumber = 1;

  /// The current round number.
  int get roundNumber => _roundNumber;

  /// The lineup the court grid renders: in edit mode the edit lineup; in
  /// the changeover the saved round (RND-03); else the live round. TIME UP
  /// shows round n: 0:00 makes no round n+1 (R13-Q4).
  ///
  /// All court edits ([placePlayerInSlot], [makeSingleCourt],
  /// [removePlayerFromCourt]) apply to this container, so the organizer edits
  /// exactly what is on screen.
  GameContainer get visibleMatches {
    final edit = _editLineup;
    if (edit != null) return edit;
    final next = _nextLineup;
    if (next != null && _inChangeover) return next;
    return stagingMatches;
  }

  /// Runs [action] with [target] installed as the live lineup, then restores
  /// the original.
  ///
  /// Lineup-scoped helpers ([_choosePlayer], [gameContainingPlayer],
  /// [placePlayerInSlot], ...) all read [stagingMatches]. This lets them work
  /// against round n+1 without duplicating them.
  T _onLineup<T>(GameContainer target, T Function() action) {
    if (identical(target, stagingMatches)) return action();
    final saved = stagingMatches;
    stagingMatches = target;
    _displacedLive = saved;
    try {
      return action();
    } finally {
      stagingMatches = saved;
      _displacedLive = null;
    }
  }

  /// Computes a level-balanced court assignment from the full player pool.
  ///
  /// This mirrors [makeGame] but returns a fresh [GameContainer] instead of
  /// mutating [stagingMatches] directly. It runs against an empty lineup so
  /// [_choosePlayer] selects from all players.
  GameContainer _computeFreshLineup() {
    if (_checkedInPlayers.isEmpty || numberOfCourt <= 0) return [];

    // RND-05: round n+1 must not change the live courts, so the draw runs
    // against an empty lineup rather than the live one.
    return _onLineup(<Game>[], () {
      final candidatePlayers = _choosePlayer().toList(growable: true);
      final result = candidatePlayers
          .slices(Game.playerPerCourt)
          .map((players) => Game.create(players.toList()))
          .toList();
      _improveEloSpread(result);
      _padToCourtCount(result);
      return result;
    });
  }

  /// Pads [courts] with empty games so every court has a slot in the grid.
  void _padToCourtCount(GameContainer courts) {
    while (courts.length < numberOfCourt) {
      courts.add(Game.create([]));
    }
  }

  /// The one-at-a-time flag of every path that logs a round (R45-01,
  /// 8.2.1, 8.2.4).
  bool _isRotating = false;

  /// Logs the live round ([stagingMatches]) through [_logRound].
  ///
  /// Every court that holds players is logged as played, including an
  /// incomplete one — the clock running out must never be blocked by a
  /// half-filled court. Empty courts are left out: that rule stays until
  /// ADR-0002 adds the round id.
  Future<void> _logLiveRound() async {
    final finished = stagingMatches
        .where((game) => game.playerIds.isNotEmpty)
        .toList();
    if (finished.isNotEmpty) await _logRound(finished);
  }

  // ── Round state machine (IMPLEMENTATION 8.2) ─────────────────

  RoundPhase _phase = RoundPhase.noLineup;

  /// Where the session is in its round. The UI reads this, never the timer.
  RoundPhase get phase => _phase;

  RoundPhase? _pausedFrom;

  /// The phase that [resume] returns to: [RoundPhase.running] or
  /// [RoundPhase.changeover]. `null` when not paused.
  RoundPhase? get pausedFrom =>
      _phase == RoundPhase.paused ? _pausedFrom : null;

  /// Round n+1: made by "Generate next round" (in edit mode) or saved. It
  /// never exists before that click (R13-Q3).
  GameContainer? _nextLineup;
  bool _nextSaved = false;

  /// The round n+1 lineup, saved or not, or `null` when none exists.
  GameContainer? get nextLineup => _nextLineup;

  /// Whether round n+1 is saved (committed) and starts after round n.
  bool get isNextRoundSaved => _nextLineup != null && _nextSaved;

  /// The working copy of round n+1 while edit mode is open.
  GameContainer? _editLineup;

  /// The rosters of [_editLineup] when edit mode opened.
  List<List<String>>? _editBase;

  /// Whether edit mode for round n+1 is open. A flag beside the phase, kept
  /// through Pause (F02).
  bool get isEditingNext => _editLineup != null;

  /// Whether the edit lineup changed since edit mode opened (R11-Q2, F03).
  /// The "×" asks "Close without saving?" only when this is true.
  bool get hasUnsavedEdits {
    final edit = _editLineup;
    final base = _editBase;
    if (edit == null || base == null) return false;
    return !const DeepCollectionEquality().equals(_rosters(edit), base);
  }

  bool _discarded = false;

  /// Whether the changeover follows a discard: round n is never logged and
  /// the new round keeps number n (R2-Q5, R9-Q1).
  bool get discarded => _inChangeover && _discarded;

  bool _waitingForEdit = false;

  /// Whether the changeover reached 0:00 while edit mode had unsaved
  /// changes; it waits for [saveNextRound] or [exitEditNext] (R9-Q4).
  bool get waitingForEdit => _waitingForEdit;

  Object? _roundLogError;

  /// The error of the last round log that failed, or `null`. Round n+1 did
  /// not start; [startNextNow] tries again (R45-01, RND-06).
  Object? get roundLogError => _roundLogError;

  /// The round start that the changeover clock began, if one is in flight.
  Future<void>? _pendingStart;

  /// Waits for a round start that the clock began at 0:00.
  @visibleForTesting
  Future<void> settle() async => _pendingStart;

  bool get _inChangeover =>
      _phase == RoundPhase.changeover ||
      (_phase == RoundPhase.paused && _pausedFrom == RoundPhase.changeover);

  /// RUNNING, or PAUSED with the round clock (not the changeover).
  bool get _roundClockLive =>
      _phase == RoundPhase.running ||
      (_phase == RoundPhase.paused && _pausedFrom == RoundPhase.running);

  /// The number on the round bar: in the changeover the round that starts
  /// next (n+1, or n again after a discard), else [roundNumber].
  int get displayRoundNumber =>
      _inChangeover && !_discarded ? _roundNumber + 1 : _roundNumber;

  /// The round that a player checked in now waits for (PLY-17): the first
  /// round with no saved lineup. That is the next round to start, or the
  /// round after a saved next round. Before the first round starts, and in
  /// READY (round 1 is a draft), it is [roundNumber].
  int get waitsForRound {
    if (_inChangeover) return displayRoundNumber + 1;
    return switch (_phase) {
      RoundPhase.noLineup || RoundPhase.ready => _roundNumber,
      _ => _roundNumber + (isNextRoundSaved ? 2 : 1),
    };
  }

  /// The round that [endSession] logs, for the dialog text (F09): the
  /// round that started last, or `null` when nothing is logged (READY, no
  /// lineup, a changeover after a discard).
  int? get roundToLog {
    if (_roundClockLive || _phase == RoundPhase.timeUp) return _roundNumber;
    if (_inChangeover && !_discarded) return _roundNumber;
    return null;
  }

  /// Time left on the clock, for the "End round n now? mm:ss left." text.
  Duration get timeLeft => _timer.remaining;

  /// Whether "Start round n+1" asks "End round n now?" first: RUNNING with
  /// time left only; never in PAUSED or TIME UP (R12-Q1, F05).
  bool get startNeedsConfirm =>
      _phase == RoundPhase.running &&
      !isEditingNext &&
      _timer.remaining > Duration.zero;

  /// Whether the courts on screen can change: place, swap, Re-roll and the
  /// full slot menu (COURT-14). False while the clock runs (RUNNING, and
  /// CHANGEOVER, R7-Q4), except in edit mode for round n+1. A paused
  /// changeover follows the PAUSED rules (F17). TIME UP shows the round n
  /// that was played, so it is locked too (R13-Q4).
  bool get canEditCourts {
    if (isEditingNext) return true;
    return _phase != RoundPhase.running &&
        _phase != RoundPhase.changeover &&
        _phase != RoundPhase.timeUp;
  }

  /// Ids of the courts that the organizer fills by hand while the clock runs
  /// (R13-Q7). A court gets in when it has no players and the organizer
  /// puts the first player on it. It stays open until its round ends, so
  /// the organizer can fill all 4 places.
  final Set<String> _handFillCourtIds = {};

  /// Whether the organizer can put a waitlist player on the court at
  /// [courtIndex] of the round on screen while the courts are locked
  /// (R13-Q7, R13-Q8): RUNNING, TIME UP or CHANGEOVER, on a court with no
  /// players, or a court that was empty and is being filled by hand.
  /// Courts with players stay locked (COURT-10). When [canEditCourts] is
  /// true the normal rules apply, so this is `false`.
  bool canHandFillCourt(int courtIndex) {
    if (canEditCourts || _phase == RoundPhase.noLineup) return false;
    final lineup = visibleMatches;
    if (courtIndex < 0 || courtIndex >= lineup.length) return false;
    final court = lineup[courtIndex];
    if (_playingGameIds.contains(court.id)) return false;
    if (court.playerIds.length >= Game.playerPerCourt) return false;
    return court.playerIds.isEmpty || _handFillCourtIds.contains(court.id);
  }

  /// Whether any court on screen takes a hand fill now ([canHandFillCourt]).
  bool get hasHandFillCourt =>
      [for (var i = 0; i < visibleMatches.length; i++) i].any(canHandFillCourt);

  /// Puts [player] from the waitlist into the open [slotIndex] of the court
  /// at [courtIndex] while the clock runs (R13-Q7). The round log takes the
  /// players on the court when the round ends.
  ///
  /// Returns `false` and changes nothing when the court does not take a
  /// hand fill, when [player] is not checked in or is on a court on screen.
  bool handFillSlot(Player player, int courtIndex, int slotIndex) {
    if (!canHandFillCourt(courtIndex) || !isPlayerCheckedIn(player)) {
      return false;
    }
    final lineup = visibleMatches;
    if (_courtOf(lineup, player) != null) return false;
    final court = lineup[courtIndex];
    _handFillCourtIds.add(court.id);
    final slot = slotIndex.clamp(0, court.playerIds.length);
    court.playerIds.insert(slot, player.id);
    notifyListeners();
    return true;
  }

  /// "Generate round 1": a matchmaker lineup, clock stopped (RND-12).
  ///
  /// Throws [NotEnoughPlayers] with fewer than 4 checked in (R45-39), and
  /// [NoCourts] with no court. Does nothing outside [RoundPhase.noLineup].
  void generateFirstRound() {
    if (_phase != RoundPhase.noLineup) return;
    if (numberOfCourt <= 0) throw const NoCourts();
    if (_checkedInPlayers.length < Game.playerPerCourt) {
      throw NotEnoughPlayers(count: _checkedInPlayers.length);
    }
    _generateLineup();
    _phase = RoundPhase.ready;
    notifyListeners();
  }

  /// "Discard & regenerate" on the draft: a new lineup, clock stopped
  /// (RND-13).
  bool regenerateDraft() {
    if (_phase != RoundPhase.ready) return false;
    if (_checkedInPlayers.length < Game.playerPerCourt) return false;
    _generateLineup();
    notifyListeners();
    return true;
  }

  /// "Start round 1": round 1 runs at once from the full duration, with no
  /// changeover (R9-Q2). Logs nothing.
  bool startFirstRound() {
    if (_phase != RoundPhase.ready) return false;
    _phase = RoundPhase.running;
    _timer.startRound(onExpired: _onClockZero);
    notifyListeners();
    return true;
  }

  /// "Generate next round (n+1)": a matchmaker lineup for round n+1 in edit
  /// mode, in RUNNING, PAUSED or TIME UP (R13-Q3, R13-Q4, R13-Q5). The live
  /// courts do not change (RND-05). One next round at a time (RND-08).
  bool generateNextRound() {
    final allowed = _roundClockLive || _phase == RoundPhase.timeUp;
    if (!allowed || isEditingNext || _nextLineup != null) return false;
    final lineup = _computeFreshLineup();
    if (lineup.isEmpty) return false;
    _nextLineup = lineup;
    _nextSaved = false;
    _openEdit(lineup);
    notifyListeners();
    return true;
  }

  /// "Edit round n+1": edit mode with the saved lineup (RND-05).
  bool editNextRound() {
    final saved = _nextLineup;
    if (!_roundClockLive || isEditingNext || saved == null || !_nextSaved) {
      return false;
    }
    _openEdit(saved);
    notifyListeners();
    return true;
  }

  /// "Save round n+1" in edit mode (RND-14).
  ///
  /// Saves the edit lineup and leaves edit mode. In TIME UP it also starts
  /// the changeover (R6-Q3). While the changeover waits at 0:00 it starts
  /// round n+1 (R9-Q4): round n is logged first, so the future fails when
  /// the write fails. A second click is a no-op (8.2.4).
  Future<bool> saveNextRound() async {
    if (!isEditingNext) return false;
    final wasWaiting = _waitingForEdit;
    _commitEdit();
    if (wasWaiting) return _beginNextRound();
    if (_phase == RoundPhase.timeUp) _enterChangeover(discarded: false);
    notifyListeners();
    return true;
  }

  /// "Discard & regenerate" in edit mode: a new round n+1 lineup; edit mode
  /// stays open, and a waiting changeover keeps waiting (RND-14, R9-Q4).
  bool regenerateNext() {
    if (!isEditingNext) return false;
    final lineup = _computeFreshLineup();
    if (lineup.isEmpty) return false;
    _editLineup = lineup;
    notifyListeners();
    return true;
  }

  /// "×" in edit mode: drops the edits (RND-07). The UI calls it after
  /// "Close without saving?", or at once when [hasUnsavedEdits] is false.
  ///
  /// A saved round n+1 stays saved. An unsaved one is dropped, also in
  /// TIME UP: the strip then offers "Generate next round" again (R13-Q4).
  /// While the changeover waits, the saved round n+1 starts unchanged
  /// (R11-Q2).
  Future<bool> exitEditNext() async {
    if (!isEditingNext) return false;
    _closeEdit();
    if (!_nextSaved && !_inChangeover) {
      _nextLineup = null;
    }
    if (_waitingForEdit) {
      _waitingForEdit = false;
      return _beginNextRound();
    }
    notifyListeners();
    return true;
  }

  /// "Pause": freezes the round or the changeover (R3-Q1, R4-Q5). Edit mode
  /// stays as it is (F02). A changeover that waits at 0:00 has no time to
  /// freeze.
  bool pause() {
    final canPause =
        _phase == RoundPhase.running ||
        (_phase == RoundPhase.changeover && !_waitingForEdit);
    if (!canPause) return false;
    _pausedFrom = _phase;
    _phase = RoundPhase.paused;
    _timer.pause();
    notifyListeners();
    return true;
  }

  /// "Resume round n" / "Resume changeover": continues from the paused time.
  bool resume() {
    final from = _pausedFrom;
    if (_phase != RoundPhase.paused || from == null) return false;
    _phase = from;
    _pausedFrom = null;
    _timer.resume();
    notifyListeners();
    return true;
  }

  /// "Start round n+1" (RND-04): starts the changeover (R6-Q1) with the
  /// saved round n+1. In paused edit mode of a saved round it saves the
  /// edits first (R11-Q3). Logs nothing at the click.
  ///
  /// It works only after round n+1 is saved (R13-Q5): with no saved round
  /// n+1 it does nothing. TIME UP never has a saved round n+1, because a
  /// save there starts the changeover at once.
  ///
  /// In RUNNING the UI asks "End round n now?" first ([startNeedsConfirm]).
  /// A second click is a no-op: the phase is CHANGEOVER (8.2.4).
  bool startNextRound() {
    if (!isNextRoundSaved || !_roundClockLive) return false;
    final pausedEdit = _phase == RoundPhase.paused && isEditingNext;
    if (isEditingNext && !pausedEdit) return false;
    if (pausedEdit) _commitEdit();
    _enterChangeover(discarded: false);
    notifyListeners();
    return true;
  }

  /// "Discard round n and start again" (RND-16), after its confirm dialog
  /// (R9-Q3): the changeover starts as in [startNextRound], round n is never
  /// logged, and the new round keeps number n (R2-Q5, R9-Q1).
  bool discardAndStartNext() {
    final allowed =
        (_roundClockLive || _phase == RoundPhase.timeUp) && !isEditingNext;
    if (!allowed) return false;
    _adoptNextLineup();
    _enterChangeover(discarded: true);
    notifyListeners();
    return true;
  }

  /// "Start round n+1 now": ends the changeover at once (RND-19). Round n is
  /// logged (unless discarded) and round n+1 runs.
  ///
  /// Does nothing while edit mode has unsaved changes (the changeover then
  /// waits for the save, R9-Q4). The future fails when the write fails, and
  /// round n+1 does not start (R45-01).
  Future<bool> startNextNow() async {
    if (_phase != RoundPhase.changeover || _waitingForEdit) return false;
    if (isEditingNext && hasUnsavedEdits) return false;
    return _beginNextRound();
  }

  /// "End session" (RND-20), after its confirm dialog: logs [roundToLog]
  /// once (R6-Q5), stops the clock, checks out every player, and returns to
  /// [RoundPhase.noLineup] at round 1.
  ///
  /// The session's in-memory history ends with it; the disk keeps the log.
  /// The future fails when the write fails, and the session does not end.
  Future<bool> endSession() async {
    if (_phase == RoundPhase.noLineup || _isRotating) return false;
    final logs = roundToLog != null;
    final wasRunning = _timer.isRunning;
    _isRotating = true;
    _timer.pause();
    try {
      if (logs) await _logLiveRound();
    } catch (_) {
      if (wasRunning) _timer.resume();
      rethrow;
    } finally {
      _isRotating = false;
    }
    _timer.reset();
    _checkedInPlayers.clear();
    history.clear();
    stagingMatches = [];
    _padToCourtCount(stagingMatches);
    _nextLineup = null;
    _nextSaved = false;
    _closeEdit();
    _discarded = false;
    _waitingForEdit = false;
    _roundLogError = null;
    _playingGameIds.clear();
    _handFillCourtIds.clear();
    _sessionRerollCount = 0;
    _roundNumber = 1;
    _pausedFrom = null;
    _phase = RoundPhase.noLineup;
    notifyListeners();
    return true;
  }

  // ── Swap Undo (IMPLEMENTATION 8.3, COURT-17) ─────────────────

  /// How long the swap Undo stays available (R6-Q6).
  static const Duration swapUndoWindow = Duration(seconds: 10);

  /// The one Undo slot. Only [swapPlayers] sets it; every other change
  /// clears it, because every change calls [notifyListeners] (R6-Q6).
  _SwapMemento? _swapUndo;

  /// Set while [swapPlayers] notifies, so its own notification keeps the
  /// memento that it just set.
  bool _keepSwapUndo = false;

  @override
  void notifyListeners() {
    if (!_keepSwapUndo) _swapUndo = null;
    super.notifyListeners();
  }

  /// Whether "Undo" in the "Swapped {A} and {B}" message still works: a swap
  /// was the last change and less than [swapUndoWindow] passed.
  bool get canUndoSwap {
    final memento = _swapUndo;
    return memento != null && _clock().difference(memento.at) < swapUndoWindow;
  }

  /// The two players of the swap that Undo can reverse, for the message
  /// text, or `null`.
  (Player, Player)? get lastSwap {
    final memento = _swapUndo;
    return canUndoSwap ? (memento!.first, memento.second) : null;
  }

  /// Swaps [first] and [second] in the round on screen (COURT-08, COURT-10):
  /// two court players trade slots; a waitlisted player takes the slot of a
  /// court player, who goes to the waitlist. Sets the swap Undo (COURT-17).
  ///
  /// Returns `false` and changes nothing when the courts cannot change now
  /// ([canEditCourts]), when neither player is on a court, or when a court
  /// of the swap holds a saved game-based game.
  bool swapPlayers(Player first, Player second) {
    if (!canEditCourts || first.id == second.id) return false;
    final lineup = visibleMatches;
    final firstCourt = _courtOf(lineup, first);
    final secondCourt = _courtOf(lineup, second);
    if (firstCourt == null && secondCourt == null) return false;
    for (final court in [firstCourt, secondCourt].nonNulls) {
      if (_playingGameIds.contains(court.id)) return false;
    }
    if (firstCourt == null && !isPlayerCheckedIn(first)) return false;
    if (secondCourt == null && !isPlayerCheckedIn(second)) return false;

    final memento = _SwapMemento(
      lineup: lineup,
      rosters: _rosters(lineup),
      first: first,
      second: second,
      at: _clock(),
    );
    final firstSlot = firstCourt?.playerIds.indexOf(first.id);
    final secondSlot = secondCourt?.playerIds.indexOf(second.id);
    if (firstCourt != null) firstCourt.playerIds[firstSlot!] = second.id;
    if (secondCourt != null) secondCourt.playerIds[secondSlot!] = first.id;

    _keepSwapUndo = true;
    try {
      _swapUndo = memento;
      notifyListeners();
    } finally {
      _keepSwapUndo = false;
    }
    return true;
  }

  /// "Undo" in the swap message: both players go back to their slots.
  /// Returns `false` when [canUndoSwap] is false.
  bool undoSwap() {
    if (!canUndoSwap) return false;
    final memento = _swapUndo!;
    for (final (index, game) in memento.lineup.indexed) {
      game.playerIds
        ..clear()
        ..addAll(memento.rosters[index]);
    }
    notifyListeners();
    return true;
  }

  static Game? _courtOf(GameContainer lineup, Player player) =>
      lineup.firstWhereOrNull((game) => game.playerIds.contains(player.id));

  /// The clock reached 0:00 (RND-03, RND-06, RND-15). Also called when a
  /// duration change while paused puts the round past its end (SESS-02).
  void _onClockZero() {
    final from = _phase == RoundPhase.paused ? _pausedFrom : _phase;
    if (from == RoundPhase.running) {
      _pausedFrom = null;
      if (isNextRoundSaved) {
        _enterChangeover(discarded: false);
      } else {
        // TIME UP: the clock stops and no round n+1 is made (R13-Q4). The
        // strip offers "Generate next round". Edit mode stays as it is
        // (R6-Q3).
        _phase = RoundPhase.timeUp;
      }
      notifyListeners();
      return;
    }
    if (from == RoundPhase.changeover) {
      if (isEditingNext && hasUnsavedEdits) {
        _waitingForEdit = true;
        notifyListeners();
        return;
      }
      // The error is kept in [roundLogError] for the UI; nothing else
      // waits on this future.
      _pendingStart = _beginNextRound().then<void>((_) {}, onError: (_) {});
    }
  }

  /// Saves round n+1 for "Discard round n and start again": the saved round,
  /// or else a new matchmaker lineup (RND-16).
  void _adoptNextLineup() {
    _nextLineup ??= _computeFreshLineup();
    _nextSaved = true;
  }

  void _enterChangeover({required bool discarded}) {
    _phase = RoundPhase.changeover;
    _pausedFrom = null;
    _discarded = discarded;
    _waitingForEdit = false;
    _timer.startChangeover(onExpired: _onClockZero);
  }

  /// Ends the changeover: logs round n (unless discarded, 8.2.1), then
  /// round n+1 runs from the full duration. One at a time (8.2.4).
  Future<bool> _beginNextRound() async {
    if (_isRotating || !_inChangeover) return false;
    _isRotating = true;
    try {
      if (!_discarded) await _logLiveRound();
    } catch (error) {
      _roundLogError = error;
      notifyListeners();
      rethrow;
    } finally {
      _isRotating = false;
    }
    _roundLogError = null;
    if (!_discarded) _roundNumber++;
    stagingMatches = _nextLineup ?? [];
    _padToCourtCount(stagingMatches);
    _nextLineup = null;
    _nextSaved = false;
    _closeEdit();
    _discarded = false;
    _waitingForEdit = false;
    _pausedFrom = null;
    _phase = RoundPhase.running;
    _prunePlayingGameIds();
    _pruneHandFillCourtIds();
    _timer.startRound(onExpired: _onClockZero);
    notifyListeners();
    return true;
  }

  /// Keeps the hand-fill ids of the courts that are still on screen.
  void _pruneHandFillCourtIds() {
    final live = {for (final game in visibleMatches) game.id};
    _handFillCourtIds.retainWhere(live.contains);
  }

  void _openEdit(GameContainer source) {
    _editLineup = [
      for (final game in source)
        Game(
          playerIds: List.of(game.playerIds),
          id: game.id,
          createdDate: game.createdDate,
        ),
    ];
    _editBase = _rosters(source);
  }

  /// Saves the edit lineup as round n+1 and leaves edit mode.
  void _commitEdit() {
    _nextLineup = _editLineup;
    _nextSaved = true;
    _closeEdit();
    _waitingForEdit = false;
  }

  void _closeEdit() {
    _editLineup = null;
    _editBase = null;
  }

  static List<List<String>> _rosters(GameContainer lineup) => [
    for (final game in lineup) List.of(game.playerIds),
  ];

  /// Alias for [checkInPlayer] — the only door into session membership.
  ///
  /// Kept so the many unit-test arrange steps that read as "add a player"
  /// keep compiling and inherit the real check-in rules.
  void addFullPricedPlayer(Player player) => checkInPlayer(player);

  void onUpdatePlayer(Player newPlayer) {
    final oldPlayer = PlayerRepository.instance.byId(newPlayer.id);
    if (oldPlayer == null) return;

    PlayerRepository.instance.add(newPlayer);

    if (_checkedInPlayers.containsKey(oldPlayer.id)) {
      _checkedInPlayers.update(oldPlayer.id, (_) => newPlayer);
    }

    notifyListeners();
  }

  /// Anonymises [player] (ADR-0001): erases their name and sign-in id and
  /// sets [Player.deletedDate], but keeps the id, the Elo and the created
  /// date. The row is never removed — a Game they played still resolves
  /// their id to this (anonymised) row, so the roster stays intact.
  Future<void> deletePlayer(Player player) async {
    removePlayer(player);
    await PlayerRepository.instance.add(
      player.copyWith(
        firstName: '',
        lastName: '',
        signInId: null,
        deletedDate: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Remove a playing who is currently in a session.
  ///
  /// A freed court slot is filled from the waitlist (WL-02).
  void removePlayer(Player player) {
    _removeAndRefillCourt(player);
    notifyListeners();
  }

  /// Updates [player]'s club-membership status and persists it.
  ///
  /// Setting [MembershipStatus.disabled] also checks the player out of the
  /// current session (removed from their court/waitlist, triggering WL-02
  /// auto-promotion) — Disabled players cannot be checked in.
  void setMembership(Player player, MembershipStatus status) {
    if (status == MembershipStatus.disabled) {
      checkOutPlayer(player);
    }
    onUpdatePlayer(player.copyWith(membership: status));
  }

  Future<void> makeGame() async {
    if (numberOfCourt <= 0) throw const NoCourts();
    if (_checkedInPlayers.length < Game.playerPerCourt) {
      throw NotEnoughPlayers(count: _checkedInPlayers.length);
    }
    _generateLineup();
    notifyListeners();
  }

  /// Unassigns every player and deals the checked-in pool across the courts,
  /// level-balanced. Does not notify.
  void _generateLineup() {
    stagingMatches = List.empty();
    final candidatePlayer = _choosePlayer().shuffled();
    assert(
      candidatePlayer.isNotEmpty &&
          candidatePlayer.length % Game.playerPerCourt == 0,
      'Candidate player is empty or not a multiple of 4, ${candidatePlayer.length}',
    );
    stagingMatches = candidatePlayer
        .slices(4)
        // Need to be growable: true as we need to add/remove player
        .map((players) => Game.create(players.toList()))
        .toList();
    assert(stagingMatches.isNotEmpty);
    _improveEloSpread(stagingMatches);

    debugPrint(
      'Match elo spread: AVG: ${eloSpread(stagingMatches).average}, MAX ${eloSpread(stagingMatches).max}',
    );
    // One new Game per empty court — a shared instance would let a player
    // placed on one empty court appear on all of them.
    _padToCourtCount(stagingMatches);
    _prunePlayingGameIds();
  }

  /// Refresh one single court with new players.
  ///
  /// Applies to whichever round is on screen — see [visibleMatches].
  void makeSingleCourt(int courtIndex) {
    // Only a re-roll on the live round counts (F6); round n+1
    // is a plan, not a played round.
    final onLiveRound = identical(visibleMatches, stagingMatches);
    _onLineup(
      visibleMatches,
      () => _makeSingleCourt(courtIndex, countsAsReroll: onLiveRound),
    );
  }

  /// Whether re-rolling the court at [courtIndex] can change anything.
  ///
  /// COURT-03: a full court whose occupants plus the whole waitlist total 4
  /// has nobody to rotate in. A court with an open slot can still be filled
  /// from a pool of exactly 4.
  bool canRerollCourt(int courtIndex) =>
      _onLineup(visibleMatches, () => _canReroll(courtIndex));

  bool _canReroll(int courtIndex) {
    final pool = _rerollPoolSize(courtIndex);
    final inTargetCourt =
        stagingMatches.elementAtOrNull(courtIndex)?.playerIds.length ?? 0;
    if (pool < Game.playerPerCourt) return false;
    return pool > Game.playerPerCourt || inTargetCourt < Game.playerPerCourt;
  }

  /// Occupants of the court plus every player off all courts.
  int _rerollPoolSize(int courtIndex) {
    final inTargetCourt =
        stagingMatches.elementAtOrNull(courtIndex)?.playerIds.length ?? 0;
    return _checkedInPlayers.length -
        getPlayerFromGames(stagingMatches).length +
        inTargetCourt;
  }

  /// Level gap of [players]: the [SkillTier] spread, then the finer Elo spread
  /// to break ties inside one tier.
  static (int, int) _levelGap(List<Player> players) {
    final tiers = players.map((p) => p.elo.skillTier.index);
    final elos = players.map((p) => p.elo.index);
    return (
      tiers.reduce(max) - tiers.reduce(min),
      elos.reduce(max) - elos.reduce(min),
    );
  }

  static bool _isLowerGap((int, int) a, (int, int) b) =>
      a.$1 != b.$1 ? a.$1 < b.$1 : a.$2 < b.$2;

  void _makeSingleCourt(int courtIndex, {required bool countsAsReroll}) {
    if (courtIndex >= numberOfCourt || courtIndex < 0) {
      throw Exception('Invalid court index');
    }
    // COURT-03: no one to rotate in, so nothing changes and nothing counts.
    if (!_canReroll(courtIndex)) return;

    // Free the court so its occupants join the pool.
    stagingMatches[courtIndex] = Game.create(List.empty());
    // COURT-02: compare several weighted-random combinations and keep the one
    // with the lowest level gap.
    List<Player>? best;
    (int, int)? bestGap;
    for (var i = 0; i < rerollSampleCount; i++) {
      final candidate = _choosePlayer(Game.playerPerCourt).toList();
      final gap = _levelGap(candidate);
      if (bestGap == null || _isLowerGap(gap, bestGap)) {
        best = candidate;
        bestGap = gap;
      }
    }
    stagingMatches[courtIndex] = Game.create(best!);
    // The court now holds a brand-new Game, so any earlier PLAYING flag for
    // this court is gone — re-rolling is how a game-based round ends.
    _prunePlayingGameIds();
    if (countsAsReroll) _sessionRerollCount++;
    notifyListeners();
  }

  /// Records [courts] as a played round: history, game repository, and a
  /// [SessionLog] snapshot.
  ///
  /// Shared by every path that ends a time-based round; it does not
  /// validate, because the end of a round must never be blocked.
  ///
  /// Writes to disk first and adds to [history] last, so a failed write
  /// leaves [history] unchanged (R45-01). A retry writes the same game ids
  /// again, which replaces them on disk.
  Future<void> _logRound(GameContainer courts) async {
    await GameRepository.instance.addAll(courts);
    await _logSessionSnapshot(courts);
    history.add(courts);
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
  }

  /// Save a single court's lineup to the history and mark that court as being
  /// played. For use in game based mode.
  ///
  /// The players stay on the court so the room can see who is on it. They are
  /// therefore excluded from other courts' re-rolls until this court is
  /// re-rolled, which is how the organizer signals the game has finished.
  Future<void> saveSingleGame(Game game) async {
    if (game.playerIds.isEmpty) throw const NothingToSave();
    if (!game.isPlayable()) {
      throw UnbalancedCourts(courtNumbers: [stagingMatches.indexOf(game) + 1]);
    }
    // Disk first, as in [_logRound] (R45-01).
    await GameRepository.instance.add(game);
    await _logSessionSnapshot(stagingMatches);
    history.add([game]);
    _playingGameIds.add(game.id);
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
  }

  /// Builds and persists a [SessionLog] snapshot from the current live
  /// session state, then resets the per-round re-roll counter.
  Future<void> _logSessionSnapshot(GameContainer courts) async {
    // A failed write leaves its row in the repository cache. The next
    // snapshot reuses that id, so it replaces the row instead of adding a
    // second one (R45-01).
    final log = SessionLog(
      id: _unsavedLogId ?? const Uuid().v4(),
      loggedAt: DateTime.now(),
      capacity: sessionCapacity,
      checkedInCount: checkedInCount,
      waitlistCount: waitlistedPlayers.length,
      rerollCount: _sessionRerollCount,
      courtLevelGaps: courts
          .where((game) => game.playerIds.isNotEmpty)
          .map((game) => game.eloGap())
          .toList(),
      courtCount: numberOfCourt,
    );
    _unsavedLogId = log.id;
    await SessionLogRepository.instance.add(log);
    _unsavedLogId = null;
    _sessionRerollCount = 0;
  }

  /// The id of a session log whose write failed. See [_logSessionSnapshot].
  String? _unsavedLogId;

  Iterable<Player> _choosePlayer([int? n]) {
    final numberOfPlayers =
        n ??
        min(_checkedInPlayers.length ~/ 4, numberOfCourt) * Game.playerPerCourt;
    final playerHistory = getCurrentPlayersHistory();
    final averageMatchPlayed = getCurrentPlayerAverageMatchPlayed();

    final onCourtPlayers = getPlayerFromGames(stagingMatches).toSet();
    final playerOffCourt = _checkedInPlayers.values.toSet().difference(
      onCourtPlayers,
    );

    final weights = playerOffCourt.map((player) {
      final modifier =
          1 / exp(2 * ((playerHistory[player]! - averageMatchPlayed)));
      return modifier / _checkedInPlayers.length;
    }).toUnmodifiableList();
    return playerOffCourt.toUnmodifiableList().choices(
      weights,
      count: numberOfPlayers,
      random: _random,
    );
  }

  /// Only using the currently active player to calculate the average.
  ///
  /// Prevent scenario where a player leaves and still got chosen to play.
  Map<Player, double> getCurrentPlayersHistory() {
    final Map<Player, double> matchCount = {
      for (var player in _checkedInPlayers.values) player: 0,
    };
    final currentPlayers = _checkedInPlayers.values.toSet();
    final currentPlayerHistory = history.expand(
      (games) => getPlayerFromGames(games).where(currentPlayers.contains),
    );
    for (final player in currentPlayerHistory) {
      matchCount[player] = matchCount.update(player, (value) => value + 1);
    }

    return matchCount;
  }

  double getCurrentPlayerAverageMatchPlayed() {
    final history = getCurrentPlayersHistory();
    final playerMatches = history.values;
    if (playerMatches.isEmpty) return 0;
    return playerMatches.average;
  }

  static Iterable<int> eloSpread(GameContainer games) {
    return games.map((match) => match.eloGap());
  }

  @visibleForTesting
  static void improveEloSpreadForTesting(GameContainer games) =>
      _improveEloSpread(games);

  /// A greedy solution that will ended up with a local minimum. Swap 2 players at a time
  ///
  /// Only full courts take part in the swapping. A court holding fewer than
  /// [Game.playerPerCourt] players is left exactly as the organizer left it —
  /// the swap loop addresses all four slots by index, so a short court would
  /// otherwise throw a `RangeError` and break the rotation that called this.
  static void _improveEloSpread(GameContainer games, {int targetSpread = 0}) {
    Iterable<num> costFunctionInfo() => GameData.eloSpread(games);
    num costFunction() =>
        costFunctionInfo().average * 0.1 + costFunctionInfo().max;

    // Indices of the courts that can take part in a swap.
    final fullCourts = <int>[
      for (var i = 0; i < games.length; i++)
        if (games[i].playerIds.length == Game.playerPerCourt) i,
    ];

    if (fullCourts.length < 2) {
      log('Fewer than 2 full courts, no optimization needed');
      return;
    }
    // If the current spread is too high, try to swap players with other groups
    num currentSpread = costFunction();
    printGames(games);
    log('current spread ${costFunctionInfo()} => $currentSpread');
    if (currentSpread < targetSpread) {
      log('Current spread is already satisfied');
      return;
    }
    final stopwatch = Stopwatch()..start();

    bool changed = true;
    int iteration = 0;
    while (iteration < maxIteration && changed) {
      iteration++;
      changed = false;
      log("iteration $iteration");
      // =======================================================================
      for (var [match1Index, match2Index] in Combinations(2, fullCourts)()) {
        for (var [p1, p2] in Amalgams(
          2,
          List.generate(Game.playerPerCourt, (k) => k),
        )()) {
          final match1 = games[match1Index];
          final match2 = games[match2Index];
          var temp = match1.playerIds[p1];
          match1.playerIds[p1] = match2.playerIds[p2];
          match2.playerIds[p2] = temp;

          log('${match1.players[p1].name()} <-> ${match2.players[p2].name()}');
          final newSpread = costFunction();
          log(
            '\tnew spread ${costFunctionInfo()} => ${newSpread.toStringAsFixed(2)}..current $currentSpread',
          );

          if (newSpread >= currentSpread) {
            log('\tnah, swap back');
            temp = match1.playerIds[p1];
            match1.playerIds[p1] = match2.playerIds[p2];
            match2.playerIds[p2] = temp;
          }

          if (newSpread < targetSpread) {
            log('new spread satisfied, ending');
            //  just enough spread
            break;
          }
          if (newSpread < currentSpread) {
            currentSpread = newSpread;
            log('\tgood swap, next');
            printGames(games);
            changed = true;
            break;
          }
        }
      }
    }
    // =======================================================================
    stopwatch.stop();
    final timeElapsed = stopwatch.elapsed;
    log(
      "OPTIMIZATION DONE, $iteration pass, total ${timeElapsed.inMilliseconds} ms",
    );
    printGames(games);
    return;
  }

  Game? gameContainingPlayer(Player player) {
    return stagingMatches.firstWhereOrNull(
      (game) => game.playerIds.contains(player.id),
    );
  }

  void swapPlayer(Player player1, Player player2) {
    final game1 = gameContainingPlayer(player1);
    final game2 = gameContainingPlayer(player2);
    // At least one player has to be from the current view
    if (game1 == null && game2 == null) {
      throw Exception("Neither player is on a court");
    }

    if (game1 != null) {
      game1.playerIds
        ..remove(player1.id)
        ..add(player2.id);
    }

    if (game2 != null) {
      game2.playerIds
        ..remove(player2.id)
        ..add(player1.id);
    }
    log(
      'Match elo spread: AVG: ${eloSpread(stagingMatches).average}, MAX ${eloSpread(stagingMatches).max}',
    );
    notifyListeners();
  }

  /// Removes [player] from the court they are on in the round on screen.
  void removePlayerFromCourt(Player player) {
    _onLineup(visibleMatches, () {
      final game = gameContainingPlayer(player);
      if (game == null) return;
      // A saved lineup is already in the history — re-roll to end it first.
      if (_playingGameIds.contains(game.id)) return;
      game.playerIds.remove(player.id);
    });
    notifyListeners();
  }

  /// Players not currently assigned to any court in the live round.
  ///
  /// Always the live round — this feeds auto-promotion, the session log and
  /// the Players tab. For what the sidebar shows, use
  /// [visibleWaitlistedPlayers].
  Iterable<Player> get waitlistedPlayers =>
      _checkedInPlayers.values.where((p) => gameContainingPlayer(p) == null);

  /// Players off-court in the round on screen — what the waitlist sidebar
  /// shows.
  ///
  /// This has to follow [visibleMatches]: while the organizer edits
  /// round n+1, a sidebar built from the live round would let the
  /// same player be placed twice, or leave a player off the plan entirely.
  Iterable<Player> get visibleWaitlistedPlayers {
    final onCourt = getPlayerFromGames(visibleMatches).toSet();
    return _checkedInPlayers.values.where((p) => !onCourt.contains(p));
  }

  /// Returns true if [player] is checked into the session.
  bool isPlayerCheckedIn(Player player) =>
      _checkedInPlayers.containsKey(player.id);

  /// Checks [player] into the session.
  ///
  /// Returns [CheckInResult.checkedIn] on success, also when the player is
  /// already checked in. Otherwise returns why the check-in was refused:
  /// [CheckInResult.disabled] or [CheckInResult.sessionFull].
  ///
  /// Checking in is self-sufficient — the player is added to
  /// [checkedInPlayers] if not already present, no separate activation step
  /// is required.
  ///
  /// In time mode the player goes to the waitlist and never joins a court:
  /// not a live court, not a draft, not a planned or saved round n+1, also
  /// when one has an open slot (CHK-02, R7-Q7). The player starts at 0
  /// rounds played (R10-Q3), so the next lineup favours them.
  ///
  /// In game-based mode (hidden in the release build) the player is placed
  /// on the first non-full court, by index order, as before.
  CheckInResult checkInPlayer(Player player) {
    // Disabled players cannot be checked in
    if (player.membership == MembershipStatus.disabled) {
      return CheckInResult.disabled;
    }

    // Already checked in — no-op success
    if (_checkedInPlayers.containsKey(player.id)) {
      return CheckInResult.checkedIn;
    }

    // At-capacity block: refuse new check-ins
    if (_checkedInPlayers.length >= sessionCapacity) {
      return CheckInResult.sessionFull;
    }

    _checkedInPlayers[player.id] = player;

    if (PersistentSetting.instance.getGameType() == GameType.timeBased) {
      notifyListeners();
      return CheckInResult.checkedIn;
    }

    // Game-based: place on the first non-full court.
    for (final game in stagingMatches) {
      if (game.playerIds.length < Game.playerPerCourt) {
        game.playerIds.add(player.id);
        notifyListeners();
        return CheckInResult.checkedIn;
      }
    }

    // All courts full — player is waitlisted
    notifyListeners();
    return CheckInResult.checkedIn;
  }

  /// Checks [player] out of the session (CHK-05, IMPLEMENTATION 8.4.4).
  ///
  /// The checked-in count drops at once (R2-Q8). A player on a live court
  /// while its clock runs (RUNNING), or on round n while it waits for its
  /// log (TIME UP, CHANGEOVER), stays there with no marker: the log holds
  /// them (COURT-16). Round n+1 (saved, planned, or in edit mode) and a
  /// live round whose clock does not run (READY, PAUSED) lose the player,
  /// and the fill rule fills that one place (WL-02).
  ///
  /// Returns the places that the fill rule filled, for the PLY-18 text.
  /// The edit-mode copy of round n+1 is not in it.
  List<SlotFill> checkOutPlayer(Player player) {
    final fills = _removeAndRefillCourt(player);
    notifyListeners();
    return fills;
  }

  /// Whether [player] is checked out but still on the live round, because
  /// its clock ran at the check-out (COURT-16). The slot then has no "⋯"
  /// (R11-Q4).
  bool isCheckedOutOnLiveCourt(Player player) =>
      !isPlayerCheckedIn(player) &&
      _liveMatches.any((game) => game.playerIds.contains(player.id));

  /// "Move to waitlist" in the slot "⋯" menu (COURT-15, IMPLEMENTATION
  /// 8.4.5): [player] leaves the court on screen and stays checked in. The
  /// fill rule fills the place from the other players who sit out that
  /// round (R7-Q6). With nobody to fill it, the slot stays open.
  ///
  /// Returns `false` and changes nothing when the courts cannot change now
  /// ([canEditCourts]), when [player] is not on a court on screen, or when
  /// the court holds a saved game-based game.
  bool moveToWaitlist(Player player) {
    if (!canEditCourts || !isPlayerCheckedIn(player)) return false;
    final lineup = visibleMatches;
    final court = _courtOf(lineup, player);
    if (court == null || _playingGameIds.contains(court.id)) return false;
    final slot = court.playerIds.indexOf(player.id);
    court.playerIds.removeAt(slot);
    final pick = pickForSlot(
      court,
      _sittingOut(lineup).where((other) => other.id != player.id),
    );
    if (pick != null) court.playerIds.insert(slot, pick.id);
    notifyListeners();
    return true;
  }

  /// The fill rule for one open place on [court] (IMPLEMENTATION 8.4.1,
  /// R10-Q2): the candidate with the fewest rounds played this session
  /// ([getCurrentPlayersHistory]). On a tie, the one that gives [court] the
  /// smallest level gap (tier gap, then Elo gap); then the earliest
  /// check-in. `null` when there is no candidate.
  ///
  /// It fills one place only. A full round comes from the matchmaker
  /// ([_choosePlayer], [_improveEloSpread]), never from this (R10-Q1).
  Player? pickForSlot(Game court, Iterable<Player> candidates) =>
      _inFillOrder(court, candidates).firstOrNull;

  /// The waitlist panel order (WL-01, R10-Q2): the order [pickForSlot]
  /// uses for the next open place, the first court on screen (Court 1
  /// first) with an open slot. With no open slot, or no lineup (F22), ties
  /// go by check-in order, earliest first.
  List<Player> get waitlistOrder {
    final waiting = visibleWaitlistedPlayers.toList();
    if (_phase == RoundPhase.noLineup && !hasAnyCourtLineup) return waiting;
    final openCourt = visibleMatches.firstWhereOrNull(
      (game) =>
          game.playerIds.length < Game.playerPerCourt &&
          !_playingGameIds.contains(game.id),
    );
    return _inFillOrder(openCourt, waiting);
  }

  List<Player> _inFillOrder(Game? court, Iterable<Player> candidates) {
    final rounds = getCurrentPlayersHistory();
    final checkInOrder = {
      for (final (index, id) in _checkedInPlayers.keys.indexed) id: index,
    };
    final onCourt = court?.players ?? const <Player>[];
    (int, int) gapWith(Player player) =>
        court == null ? (0, 0) : _levelGap([...onCourt, player]);
    return candidates.sorted((a, b) {
      final byRounds = (rounds[a] ?? 0).compareTo(rounds[b] ?? 0);
      if (byRounds != 0) return byRounds;
      final gapA = gapWith(a);
      final gapB = gapWith(b);
      if (gapA != gapB) return _isLowerGap(gapA, gapB) ? -1 : 1;
      return (checkInOrder[a.id] ?? checkInOrder.length).compareTo(
        checkInOrder[b.id] ?? checkInOrder.length,
      );
    });
  }

  /// Checked-in players who hold no slot in [lineup].
  Iterable<Player> _sittingOut(GameContainer lineup) {
    final seated = {for (final game in lineup) ...game.playerIds};
    return _checkedInPlayers.values.where((p) => !seated.contains(p.id));
  }

  /// Whether round n keeps a player who leaves: its clock runs, or it
  /// waits for its log (TIME UP, CHANGEOVER). See [checkOutPlayer].
  bool get _liveRoundKeepsLeaver =>
      _phase == RoundPhase.running ||
      _phase == RoundPhase.timeUp ||
      _inChangeover;

  /// The number of round n+1 for the [SlotFill] text.
  int get _nextRoundNumber =>
      _inChangeover ? displayRoundNumber : _roundNumber + 1;

  /// Takes [player] out of the session and fills the places they leave.
  List<SlotFill> _removeAndRefillCourt(Player player) {
    _checkedInPlayers.remove(player.id);
    final fills = <SlotFill>[];
    if (!_liveRoundKeepsLeaver) {
      final fill = _vacate(stagingMatches, player, round: _roundNumber);
      if (fill != null) fills.add(fill);
    }
    final next = _nextLineup;
    if (next != null) {
      final fill = _vacate(next, player, round: _nextRoundNumber);
      if (fill != null) fills.add(fill);
    }
    final edit = _editLineup;
    if (edit != null && !identical(edit, next)) {
      _vacate(edit, player, round: _nextRoundNumber, base: _editBase);
    }
    return fills;
  }

  /// Removes [player] from [lineup] and fills that one place by
  /// [pickForSlot] from the players who sit out [lineup] (WL-02, WL-03).
  /// Only that court changes.
  ///
  /// A court with a saved game-based game stays one player short (WL-03).
  /// The check reads the court's own game id, not the court on screen
  /// (8.4.2: `isCourtPlaying` read [visibleMatches], which can be another
  /// round).
  ///
  /// [base] is the edit-mode base ([_editBase]). It gets the same change, so
  /// a fill alone does not count as an unsaved edit (R11-Q2).
  SlotFill? _vacate(
    GameContainer lineup,
    Player player, {
    required int round,
    List<List<String>>? base,
  }) {
    final courtIndex = lineup.indexWhere(
      (game) => game.playerIds.contains(player.id),
    );
    final baseRoster = courtIndex == -1
        ? null
        : base?.elementAtOrNull(courtIndex);
    final baseSlot = baseRoster?.indexOf(player.id) ?? -1;
    for (final roster in base ?? const <List<String>>[]) {
      roster.remove(player.id);
    }
    if (courtIndex == -1) return null;
    final court = lineup[courtIndex];
    final slot = court.playerIds.indexOf(player.id);
    court.playerIds.removeAt(slot);
    if (_playingGameIds.contains(court.id)) return null;

    final pick = pickForSlot(court, _sittingOut(lineup));
    if (pick == null) return null;
    court.playerIds.insert(slot, pick.id);
    if (baseSlot != -1) baseRoster!.insert(baseSlot, pick.id);
    return (player: pick, courtIndex: courtIndex, round: round);
  }

  // ── Session Templates ──────────────────────────────────────

  /// Saves a session template with the given configuration.
  ///
  /// [name] must be non-blank (whitespace-only names are rejected).
  ///
  /// The returned future completes when the template is on disk. It yields
  /// `true` when a template was saved, `false` when the input was rejected.
  Future<bool> saveTemplate(
    String name,
    GameType mode,
    Duration duration,
    int capacity,
    int courts,
  ) async {
    if (name.trim().isEmpty) return false;
    // No upper limit on the court count (R13-Q12).
    if (capacity < minSessionCapacity || courts < 1) {
      return false;
    }
    final written = SessionTemplateRepository.instance.add(
      SessionTemplate.create(
        name: name,
        gameType: mode,
        durationMinutes: duration.inMinutes,
        durationSeconds: duration.inSeconds.remainder(
          Duration.secondsPerMinute,
        ),
        capacity: capacity,
        courts: courts,
      ),
    );
    notifyListeners();
    await written;
    return true;
  }

  /// Applies the settings from [template] to the current session.
  ///
  /// A new court count applies as in [setNumberOfCourt]: no reshuffle
  /// (SESS-06, R13-Q1).
  void loadTemplate(SessionTemplate template) {
    _sessionCapacity = template.capacity < minSessionCapacity
        ? minSessionCapacity
        : template.capacity;
    final courtsChange =
        CourtCount.editable && template.courts != numberOfCourt;
    if (courtsChange) numberOfCourt = template.courts;
    // Restore game type and duration from the template. The release build
    // ignores the template mode: it only runs time-based.
    if (GameMode.enabled) {
      PersistentSetting.instance.setGameType(template.gameType);
    }
    PersistentSetting.instance.setGameDuration(template.duration);
    if (courtsChange) _applyCourtCount();
    notifyListeners();
  }

  /// Removes the template at [index].
  ///
  /// The returned future completes when the change is on disk.
  Future<void> deleteTemplate(int index) {
    final all = templates;
    if (index < 0 || index >= all.length) return Future.value();
    final written = SessionTemplateRepository.instance.delete(all[index].id);
    notifyListeners();
    return written;
  }

  /// Place [player] into a specific court and slot position.
  ///
  /// If the slot is already occupied, the existing player is displaced
  /// (becomes waitlisted). If the player was on another court, they are
  /// removed from that court first.
  ///
  /// [courtIndex] must be in the range `[0, numberOfCourt)`. The court must
  /// already exist in [stagingMatches] (i.e., `makeGame` must have been called
  /// first). [slotIndex] is clamped to `[0, playerPerCourt)`.
  ///
  /// Applies to whichever round is on screen — see [visibleMatches].
  void placePlayerInSlot(Player player, int courtIndex, int slotIndex) =>
      _onLineup(
        visibleMatches,
        () => _placePlayerInSlot(player, courtIndex, slotIndex),
      );

  void _placePlayerInSlot(Player player, int courtIndex, int slotIndex) {
    // Validate and clamp slot index
    final effectiveSlot = slotIndex.clamp(0, Game.playerPerCourt - 1);

    // Only allow placement into courts that already exist in stagingMatches.
    // Creating new courts here would produce orphaned games invisible to the UI
    // (numberOfCourt governs what is displayed).
    if (courtIndex >= stagingMatches.length) return;

    // A saved lineup is already in the history — it must not change underneath
    // that record. Re-roll the court to end the game first.
    if (isCourtPlaying(courtIndex)) return;

    final targetCourt = stagingMatches[courtIndex];

    // Already in this exact position — no-op
    if (effectiveSlot < targetCourt.playerIds.length &&
        targetCourt.playerIds[effectiveSlot] == player.id) {
      return;
    }

    final sourceCourt = gameContainingPlayer(player);

    if (sourceCourt == targetCourt) {
      // Same-court move: swap positions without dropping any player.
      // Removing the player first would shrink the list and shift indices,
      // causing the player at the end of the list to be lost.
      final sourceIndex = targetCourt.playerIds.indexOf(player.id);
      if (effectiveSlot < targetCourt.playerIds.length) {
        // Swap with existing occupant
        final temp = targetCourt.playerIds[sourceIndex];
        targetCourt.playerIds[sourceIndex] =
            targetCourt.playerIds[effectiveSlot];
        targetCourt.playerIds[effectiveSlot] = temp;
      } else if (sourceIndex != -1) {
        // Moving to a slot beyond the list — just reposition
        targetCourt.playerIds.removeAt(sourceIndex);
        targetCourt.playerIds.add(player.id);
      }
    } else if (sourceCourt != null) {
      // Different court: a saved source lineup must not change either.
      final sourceCourtIndex = stagingMatches.indexOf(sourceCourt);
      if (isCourtPlaying(sourceCourtIndex)) return;

      final sourceIndex = sourceCourt.playerIds.indexOf(player.id);
      if (effectiveSlot < targetCourt.playerIds.length) {
        // Swap: the occupant takes the moved player's old slot, so nobody
        // drops to the waitlist.
        sourceCourt.playerIds[sourceIndex] =
            targetCourt.playerIds[effectiveSlot];
        targetCourt.playerIds[effectiveSlot] = player.id;
      } else {
        sourceCourt.playerIds.removeAt(sourceIndex);
        targetCourt.playerIds.add(player.id);
      }
    } else {
      // From the waitlist: displace any existing occupant to the waitlist.
      if (effectiveSlot < targetCourt.playerIds.length) {
        targetCourt.playerIds[effectiveSlot] = player.id;
      } else {
        targetCourt.playerIds.add(player.id);
      }
    }

    notifyListeners();
  }

  /// [dialogTitle] is the (localised) title for the file picker.
  Future<File?> saveGame({required String dialogTitle}) async {
    final Directory? downloadsDir = await getDownloadsDirectory();

    final timeString = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String? targetFilePath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      initialDirectory: downloadsDir?.path,
      fileName: 'game_data_$timeString.json',
      type: FileType.custom,
      allowedExtensions: [".json"],
    );
    if (targetFilePath == null) return null;

    final file = File(targetFilePath);
    return file;
  }
}

/// The state before a swap: the rosters of the one lineup it changed
/// (IMPLEMENTATION 8.3). A swap changes nothing else, and any other change
/// clears the memento, so the rosters are all Undo must restore.
class _SwapMemento {
  _SwapMemento({
    required this.lineup,
    required this.rosters,
    required this.first,
    required this.second,
    required this.at,
  });

  final GameContainer lineup;
  final List<List<String>> rosters;
  final Player first;
  final Player second;
  final DateTime at;
}

Iterable<Player> getPlayerFromGames(Iterable<Game> games) =>
    games.expand((game) => game.players);

void printGames(GameContainer games) {
  for (var game in games) {
    log(
      'Game ${games.indexOf(game) + 1}: ${game.players.map((p) => "${p.name()} ${p.elo.index}".padRight(10)).join(', ')}',
    );
  }
}

Iterable<(T, U)> product<T, U>(Iterable<T> a, Iterable<U> b) sync* {
  for (final x in (a)) {
    for (final y in b) {
      yield (x, y);
    }
  }
}
