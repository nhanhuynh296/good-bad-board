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
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trotter/trotter.dart';

typedef GameContainer = List<Game>;

const int maxIteration = 1000;

/// Which round the court grid shows.
///
/// The organizer switches between the round being played and the pre-made
/// next round, and edits whichever one is on screen.
enum RoundView {
  /// The round currently being played.
  current,

  /// The pre-made lineup that starts at the next rotation.
  next,
}

class GameData extends ChangeNotifier {
  /// [random] feeds the weighted player draws; tests pass a seeded one.
  GameData({Random? random}) : _random = random;

  final Random? _random;

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

  int numberOfCourt = 2;

  /// Sets the number of courts (SESS-04).
  ///
  /// When the current lineup has players, this is a full reshuffle of the
  /// checked-in pool over the new count — the same assignment as [makeGame].
  /// See [wouldReshuffleLineup].
  void setNumberOfCourt(int value) {
    if (value <= 0) return;
    numberOfCourt = value;
    _applyCourtCount();
    notifyListeners();
  }

  /// Whether a change of court count (or a template load) would replace the
  /// current lineup: it holds players and there are enough to fill a court.
  bool get wouldReshuffleLineup =>
      hasAnyCourtLineup && _checkedInPlayers.length >= Game.playerPerCourt;

  /// Brings the lineup in step with [numberOfCourt]. Does not notify.
  void _applyCourtCount() {
    if (wouldReshuffleLineup) {
      _generateLineup();
      // A pre-made round was built for the old count — plan it again.
      if (_stagedLineup != null) _stagedLineup = _computeFreshLineup();
      return;
    }
    // Nothing to redistribute. Keep the pre-made round in step with the grid,
    // so every court the organizer can see is one they can drop a player onto.
    final staged = _stagedLineup;
    if (staged != null) _padToCourtCount(staged);
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
  /// Keyed on the lineup on screen: a staged court has a brand-new [Game] id,
  /// so a pre-made round never reports a court as playing.
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

  /// Pre-computed lineup for the next round, or `null` if nothing is staged.
  GameContainer? _stagedLineup;

  /// The currently staged lineup, if any.
  GameContainer? get stagedLineup => _stagedLineup;

  /// Whether a round is currently staged.
  bool get isStaged => _stagedLineup != null;

  /// Human-readable summary of the staged round (e.g.,
  /// "16 players placed across 4 courts").
  String get stagedSummary {
    final staged = _stagedLineup;
    if (staged == null) return '';
    final playerCount = staged.fold<int>(
      0,
      (sum, g) => sum + g.playerIds.length,
    );
    final courtCount = staged.where((g) => g.playerIds.isNotEmpty).length;
    return '$playerCount players placed across $courtCount courts';
  }

  /// Which round the court grid is showing.
  RoundView _roundView = RoundView.current;

  /// The round the court grid is showing — the live round, or the pre-made
  /// next round.
  RoundView get roundView => _roundView;

  /// Selects the round the court grid shows.
  ///
  /// Selecting [RoundView.next] with nothing staged is a no-op: there is no
  /// next round to show.
  void setRoundView(RoundView view) {
    if (view == RoundView.next && _stagedLineup == null) return;
    if (view == _roundView) return;
    _roundView = view;
    notifyListeners();
  }

  /// The lineup the court grid renders — the staged round when the next view
  /// is selected, otherwise the live round.
  ///
  /// All court edits ([placePlayerInSlot], [makeSingleCourt],
  /// [removePlayerFromCourt]) apply to this container, so the organizer edits
  /// exactly what is on screen.
  GameContainer get visibleMatches =>
      _roundView == RoundView.next && _stagedLineup != null
      ? _stagedLineup!
      : stagingMatches;

  /// Runs [action] with [target] installed as the live lineup, then restores
  /// the original.
  ///
  /// Lineup-scoped helpers ([_choosePlayer], [gameContainingPlayer],
  /// [placePlayerInSlot], ...) all read [stagingMatches]. This lets them work
  /// against the staged round without duplicating them.
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

    // RND-05: staging must not change the live courts, so the draw runs
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

  /// Pre-computes a fresh level-balanced lineup for the next round
  /// without changing the live court assignments, and shows it on the courts.
  ///
  /// Only one round can be staged at a time — if a round is already
  /// staged this is a no-op.
  void stageNextRound() {
    if (_stagedLineup != null) return; // RND-08
    final lineup = _computeFreshLineup();
    // Nothing to plan (no players, no courts) — leave the bar as it was.
    if (lineup.isEmpty) return;
    _stagedLineup = lineup;
    // Pressing the button means "show me the plan".
    _roundView = RoundView.next;
    notifyListeners();
  }

  /// Cancels the currently staged round.
  ///
  /// This clears the staged lineup without affecting the live courts
  /// or the current round number, and returns the grid to the live round.
  void cancelStagedRound() {
    _stagedLineup = null;
    _roundView = RoundView.current;
    notifyListeners();
  }

  /// Ends the current round and starts the next one immediately.
  ///
  /// The finished round is logged to the history and the session log — a
  /// rotation is how a time-based round ends, so nothing is lost. If a staged
  /// round exists it is adopted as edited; otherwise a fresh level-balanced
  /// court assignment is computed. The round number is always incremented and
  /// the grid returns to the live round.
  Future<void> rotateNow() async {
    // Every court that holds players is logged as played, including an
    // incomplete one — the clock running out must never be blocked by a
    // half-filled court. (Saving by hand still validates; see
    // [saveCurrentGame].)
    final finished = stagingMatches
        .where((game) => game.playerIds.isNotEmpty)
        .toList();
    if (finished.isNotEmpty) {
      await _logRound(finished);
    }

    if (_stagedLineup != null) {
      // Adopt the staged lineup (RND-06)
      stagingMatches = _stagedLineup!;
      _stagedLineup = null;
    } else {
      // Compute a fresh assignment (RND-03)
      stagingMatches = _computeFreshLineup();
    }

    _roundView = RoundView.current;
    _roundNumber++;
    _prunePlayingGameIds();
    notifyListeners();
  }

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

  /// Drops [player] from the pre-made next round, if one is staged.
  ///
  /// A player who has left cannot be on the plan — otherwise the round
  /// rotates onto a court with a ghost on it.
  void _removeFromStagedLineup(Player player) {
    for (final game in _stagedLineup ?? const <Game>[]) {
      game.playerIds.remove(player.id);
    }
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
    if (numberOfCourt <= 0) throw Exception('There are no court available');
    if (_checkedInPlayers.isEmpty) throw Exception('There are no player');
    if (_checkedInPlayers.length < Game.playerPerCourt) {
      throw Exception(
        'Not enough players, need at least ${Game.playerPerCourt}, got ${_checkedInPlayers.length}',
      );
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
  void makeSingleCourt(int courtIndex) =>
      _onLineup(visibleMatches, () => _makeSingleCourt(courtIndex));

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

  void _makeSingleCourt(int courtIndex) {
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
    _sessionRerollCount++;
    notifyListeners();
  }

  Future<void> saveCurrentGame() async {
    if (stagingMatches.isEmpty) throw Exception("No game to save");
    final invalidGames = stagingMatches.where(
      (match) => match.playerIds.isNotEmpty && !match.isPlayable(),
    );
    if (invalidGames.isNotEmpty) {
      throw Exception(
        'PLAYERS ARE NOT BALANCED ON COURT ${invalidGames.map((game) => stagingMatches.indexOf(game) + 1).join(', ')}',
      );
    }
    await _logRound(stagingMatches);

    stagingMatches = List.empty(growable: false);
    _prunePlayingGameIds();
    notifyListeners();
  }

  /// Records [courts] as a played round: history, game repository, and a
  /// [SessionLog] snapshot.
  ///
  /// Shared by [saveCurrentGame] (which validates first) and [rotateNow]
  /// (which does not — a rotation must never be blocked).
  Future<void> _logRound(GameContainer courts) async {
    history.add(courts);
    await GameRepository.instance.addAll(courts);
    await _logSessionSnapshot(courts);
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
    if (game.playerIds.isEmpty) throw Exception("No game to save");
    if (!game.isPlayable()) {
      throw Exception(
        'PLAYERS ARE NOT BALANCED ON COURT ${stagingMatches.indexOf(game) + 1}',
      );
    }
    history.add([game]);
    await GameRepository.instance.add(game);
    await _logSessionSnapshot(stagingMatches);
    _playingGameIds.add(game.id);
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
  }

  /// Builds and persists a [SessionLog] snapshot from the current live
  /// session state, then resets the per-round re-roll counter.
  Future<void> _logSessionSnapshot(GameContainer courts) async {
    final log = SessionLog.create(
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
    await SessionLogRepository.instance.add(log);
    _sessionRerollCount = 0;
  }

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
      if (isCourtPlaying(stagingMatches.indexOf(game))) return;
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
  /// This has to follow [visibleMatches]: while the organizer edits the
  /// pre-made next round, a sidebar built from the live round would let the
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
  /// Returns `true` on success. Returns `false` if the player's membership
  /// is [MembershipStatus.disabled], or if the session is at capacity (the
  /// player is not yet checked in).
  ///
  /// Checking in is self-sufficient — the player is added to
  /// [checkedInPlayers] if not already present, no separate activation step
  /// is required.
  ///
  /// On successful check-in the player is placed on the first non-full court
  /// (by index order). If all courts are full the player is waitlisted.
  bool checkInPlayer(Player player) {
    // Disabled players cannot be checked in
    if (player.membership == MembershipStatus.disabled) return false;

    // Already checked in — no-op success
    if (_checkedInPlayers.containsKey(player.id)) return true;

    // At-capacity block: refuse new check-ins
    if (_checkedInPlayers.length >= sessionCapacity) return false;

    _checkedInPlayers[player.id] = player;

    // Try to place on the first non-full court
    for (final game in stagingMatches) {
      if (game.playerIds.length < Game.playerPerCourt) {
        game.playerIds.add(player.id);
        notifyListeners();
        return true;
      }
    }

    // All courts full — player is waitlisted
    notifyListeners();
    return true;
  }

  /// Checks [player] out of the session.
  ///
  /// The player is removed from [checkedInPlayers], their court
  /// (or waitlist), and their checked-in status is cleared. Triggers WL-02
  /// auto-promotion if a court slot opens up.
  void checkOutPlayer(Player player) {
    _removeAndRefillCourt(player);
    notifyListeners();
  }

  /// Takes [player] out of the session and refills the court they left.
  void _removeAndRefillCourt(Player player) {
    final freedCourt = gameContainingPlayer(player);
    _checkedInPlayers.remove(player.id);
    freedCourt?.playerIds.remove(player.id);
    _removeFromStagedLineup(player);
    if (freedCourt != null) _autoPromoteFromWaitlist(freedCourt);
  }

  /// Fills open slots on [court] with the highest-level waitlisted players
  /// (WL-03).
  ///
  /// Only the court that lost a player is refilled. Other open courts stay
  /// open, and a court that is playing keeps its saved lineup.
  void _autoPromoteFromWaitlist(Game court) {
    if (isCourtPlaying(stagingMatches.indexOf(court))) return;
    while (court.playerIds.length < Game.playerPerCourt) {
      final candidates = waitlistedPlayers.toList();
      if (candidates.isEmpty) return;
      // Highest level (index) first
      candidates.sort((a, b) => b.elo.index.compareTo(a.elo.index));
      court.playerIds.add(candidates.first.id);
    }
  }

  // ── Session Templates ──────────────────────────────────────

  /// Saves a session template with the given configuration.
  ///
  /// [name] must be non-blank (whitespace-only names are rejected).
  /// [mode] accepts either an [int] (0 = gameBased, 1 = timeBased) or a
  /// [GameType] enum value.
  /// [duration] accepts either an [int] (minutes) or a [Duration].
  ///
  /// The returned future completes when the template is on disk. It yields
  /// `true` when a template was saved, `false` when the input was rejected.
  Future<bool> saveTemplate(
    String name,
    dynamic mode,
    dynamic duration,
    int capacity,
    int courts,
  ) async {
    if (name.trim().isEmpty) return false;
    if (capacity < minSessionCapacity || courts < 1 || courts > 8) {
      return false;
    }
    final modeIndex = mode is GameType
        ? (mode == GameType.timeBased ? 1 : 0)
        : mode as int;
    final total = duration is Duration
        ? duration
        : Duration(minutes: duration as int);
    final written = SessionTemplateRepository.instance.add(
      SessionTemplate.create(
        name: name,
        modeIndex: modeIndex,
        durationMinutes: total.inMinutes,
        durationSeconds: total.inSeconds.remainder(Duration.secondsPerMinute),
        capacity: capacity,
        courts: courts,
      ),
    );
    notifyListeners();
    await written;
    return true;
  }

  /// Applies the settings from [template] to the current session.
  void loadTemplate(SessionTemplate template) {
    _sessionCapacity = template.capacity < minSessionCapacity
        ? minSessionCapacity
        : template.capacity;
    numberOfCourt = template.courts;
    // Restore game type and duration from the template. The release build
    // ignores the template mode: it only runs time-based.
    if (GameMode.enabled) {
      PersistentSetting.instance.setGameType(
        template.modeIndex == 1 ? GameType.timeBased : GameType.gameBased,
      );
    }
    PersistentSetting.instance.setGameDuration(template.duration);
    // SESS-06: same full reshuffle as a court-count change (SESS-04).
    _applyCourtCount();
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
