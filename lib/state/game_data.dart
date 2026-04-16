import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

typedef GameContainer = List<Game>;
typedef PlayerContainer = List<Player>;

// Plain-data payload for isolate — all fields are sendable across isolate boundary
typedef _EloPayload = ({List<List<int>> courtElos, int maxIteration});
typedef _EloResult =
    List<List<int>>; // Optimized ELO index assignments per court

const int maxIteration = 1000;

class GameData extends ChangeNotifier {
  int numberOfCourt = 2;

  void setNumberOfCourt(int value) {
    if (value <= 0) return;
    numberOfCourt = value;
    notifyListeners();
  }

  final Map<String, Player> _players = {};

  Map<String, Player> get players => Map.unmodifiable(_players);

  final List<GameContainer> history = [];

  /// Candidate to be added to history
  GameContainer stagingMatches = GameContainer.empty();

  /// When a player came after the late and paid a fractional price.
  /// Use a average count of all player, multiply by total game to represent the
  /// number of "matches" that the player had played.
  /// This create fairness so that the one come really late would not have a
  /// very high chance of playing for the rest of the session.
  ///
  /// If paying full price then just adding to the list as usual
  final Map<Player, double> _fractionalAverageGamePlayer = {};

  void addFractionalPricedPlayer(Player player) {
    _players[player.id] = player;
    _fractionalAverageGamePlayer[player] =
        getCurrentPlayerAverageMatchPlayed() * history.length;
    notifyListeners();
  }

  void addFullPricedPlayer(Player player) {
    _players[player.id] = player;
    notifyListeners();
  }

  void onUpdatePlayer(Player newPlayer) async {
    final oldPlayer = await PlayerRepository.instance.get(newPlayer.id);
    if (oldPlayer == null) return;

    await PlayerRepository.instance.update(newPlayer.id, newPlayer);

    if (_players.containsKey(oldPlayer.id)) {
      _players.update(oldPlayer.id, (_) => newPlayer);
    }

    for (var game in stagingMatches) {
      if (game.players.contains(oldPlayer)) {
        game.players[game.players.indexOf(oldPlayer)] = newPlayer;
      }
    }

    for (var games in history) {
      for (var game in games) {
        if (game.players.contains(oldPlayer)) {
          game.players[game.players.indexOf(oldPlayer)] = newPlayer;
        }
      }
    }

    notifyListeners();
  }

  Future<void> deletePlayer(Player player) async {
    removePlayer(player);
    await PlayerRepository.instance.delete(player.id);
    notifyListeners();
  }

  /// Remove a playing who is currently in a session
  void removePlayer(Player player) {
    _players.remove(player.id);
    gameContainingPlayer(player)?.players.remove(player);
    notifyListeners();
  }

  Future<void> makeGame() async {
    if (numberOfCourt <= 0) throw Exception('There are no court available');
    if (_players.isEmpty) throw Exception('There are no player');
    if (_players.length < Game.playerPerCourt) {
      throw Exception(
        'Not enough players, need at least ${Game.playerPerCourt}, got ${_players.length}',
      );
    }
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
    // Extract ELO indices for isolate (plain ints — fully sendable)
    final courtElos = stagingMatches
        .map((g) => g.players.map((p) => p.elo.index).toList())
        .toList();
    final optimizedElos = await compute(_improveEloSpreadIsolate, (
      courtElos: courtElos,
      maxIteration: maxIteration,
    ));
    _applyOptimizedOrder(stagingMatches, optimizedElos);

    debugPrint(
      'Match elo spread: AVG: ${eloSpread(stagingMatches).average}, MAX ${eloSpread(stagingMatches).max}',
    );
    if (stagingMatches.length < numberOfCourt) {
      stagingMatches.addAll(
        List.filled(numberOfCourt - stagingMatches.length, Game.create([])),
      );
    }
    notifyListeners();
  }

  /// Refresh one single court with new players.
  void makeSingleCourt(int courtIndex) {
    if (courtIndex >= numberOfCourt || courtIndex < 0) {
      throw Exception('Invalid court index');
    }
    // available player should exclude the player in the current court itself
    final numberOfPlayerInTargetCourt =
        stagingMatches.elementAtOrNull(courtIndex)?.players.length ?? 0;
    // All player - all player on court + player on current court
    final playerAvailable =
        _players.length -
        getPlayerFromGames(stagingMatches).length +
        numberOfPlayerInTargetCourt;
    if (playerAvailable < Game.playerPerCourt) {
      throw Exception(
        'Not enough players, need at least ${Game.playerPerCourt}, got $playerAvailable',
      );
    }
    stagingMatches[courtIndex] = Game.create(List.empty());
    stagingMatches[courtIndex] = Game.create(
      // Has to be toList(growable: true) as we need to add/remove player
      _choosePlayer(Game.playerPerCourt).toList(growable: true),
    );
    notifyListeners();
  }

  Future<void> saveCurrentGame() async {
    if (stagingMatches.isEmpty) throw Exception("No game to save");
    final invalidGames = stagingMatches.where(
      (match) => match.players.isNotEmpty && !match.isPlayable(),
    );
    if (invalidGames.isNotEmpty) {
      throw Exception(
        'PLAYERS ARE NOT BALANCED ON COURT ${invalidGames.map((game) => stagingMatches.indexOf(game) + 1).join(', ')}',
      );
    }
    history.add(stagingMatches);
    await GameRepository.instance.addAll(stagingMatches);

    stagingMatches = List.empty(growable: false);
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
  }

  /// Save a single game to the history and remove it from the staging matches.
  /// For use in game based
  Future<void> saveSingleGame(Game game) async {
    if (game.players.isEmpty) throw Exception("No game to save");
    if (!game.isPlayable()) {
      throw Exception(
        'PLAYERS ARE NOT BALANCED ON COURT ${stagingMatches.indexOf(game) + 1}',
      );
    }
    final currentGameIndex = stagingMatches.indexOf(game);
    history.add([game]);
    await GameRepository.instance.add(game);
    // Remove game, but also add a new empty game to so the court do not jump
    stagingMatches[currentGameIndex] = Game.create(List<Player>.empty());
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
  }

  Iterable<Player> _choosePlayer([int? n]) {
    final numberOfPlayers =
        n ?? min(_players.length ~/ 4, numberOfCourt) * Game.playerPerCourt;
    final playerHistory = getCurrentPlayersHistory();
    final averageMatchPlayed = getCurrentPlayerAverageMatchPlayed();

    final onCourtPlayers = getPlayerFromGames(stagingMatches).toSet();
    final playerOffCourt = _players.values.toSet().difference(onCourtPlayers);

    final weights = playerOffCourt.map((player) {
      final modifier =
          1 / exp(2 * ((playerHistory[player]! - averageMatchPlayed)));
      return modifier / _players.length;
    }).toUnmodifiableList();
    return playerOffCourt.toUnmodifiableList().choices(
      weights,
      count: numberOfPlayers,
    );
  }

  /// Only using the currently active player to calculate the average.
  ///
  /// Prevent scenario where a player leaves and still got chosen to play.
  Map<Player, double> getCurrentPlayersHistory() {
    final Map<Player, double> matchCount = {
      for (var player in _players.values) player: 0,
    };
    final currentPlayers = _players.values.toSet();
    final currentPlayerHistory = history.expand(
      (games) => getPlayerFromGames(games).where(currentPlayers.contains),
    );
    for (final player in currentPlayerHistory) {
      matchCount[player] = matchCount.update(player, (value) => value + 1);
    }

    _fractionalAverageGamePlayer.forEach(
      (player, nMatchPlayed) => matchCount[player] = matchCount.update(
        player,
        (value) => value + nMatchPlayed,
      ),
    );
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

  /// Applies the optimized ELO index order from the isolate back to stagingMatches.
  /// The isolate returns reordered elo indices per court; we re-sort each court's
  /// players to match the optimized elo assignment.
  void _applyOptimizedOrder(GameContainer games, _EloResult optimizedElos) {
    for (
      int courtIdx = 0;
      courtIdx < games.length && courtIdx < optimizedElos.length;
      courtIdx++
    ) {
      final optimizedCourtElos = optimizedElos[courtIdx];
      final court = games[courtIdx];
      if (court.players.length != optimizedCourtElos.length) continue;
      // Sort players to match the optimized elo order returned by the isolate.
      // When two players share the same ELO rank, stabilize by original index.
      // Game.players is an EqualUnmodifiableListView (freezed), so we replace
      // the game object rather than mutating the list in place.
      final indexed = court.players
          .asMap()
          .entries
          .map((e) => (orig: e.key, player: e.value))
          .toList();
      indexed.sort((a, b) {
        final posA = optimizedCourtElos.indexOf(a.player.elo.index);
        final posB = optimizedCourtElos.indexOf(b.player.elo.index);
        if (posA != posB) return posA.compareTo(posB);
        return a.orig.compareTo(b.orig);
      });
      games[courtIdx] = Game(
        id: court.id,
        createdDate: court.createdDate,
        players: indexed.map((e) => e.player).toList(),
      );
    }
  }

  Game? gameContainingPlayer(Player player) {
    return stagingMatches.firstWhereOrNull(
      (game) => game.players.contains(player),
    );
  }

  void swapPlayer(Player player1, Player player2) {
    final game1 = gameContainingPlayer(player1);
    final game2 = gameContainingPlayer(player2);
    // At least one player has to be from the current view
    if (game1 == null && game2 == null) {
      throw Exception("CAN NOT SWAP BETWEEN INACTIVE PLAYERS");
    }

    if (game1 != null) {
      game1.players
        ..remove(player1)
        ..add(player2);
    }

    if (game2 != null) {
      game2.players
        ..remove(player2)
        ..add(player1);
    }
    log(
      'Match elo spread: AVG: ${eloSpread(stagingMatches).average}, MAX ${eloSpread(stagingMatches).max}',
    );
    notifyListeners();
  }

  /// Add a player to the court. If player is already in the court, remove them
  void addPlayerToCourt(Player player, PlayerContainer courtPtr) {
    removePlayerFromCourt(player);
    courtPtr.add(player);
    notifyListeners();
  }

  void removePlayerFromCourt(Player player) {
    final game = gameContainingPlayer(player);
    game?.players.remove(player);
    notifyListeners();
  }

  Future<File?> saveGame() async {
    final Directory? downloadsDir = await getDownloadsDirectory();

    final timeString = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String? targetFilePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
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

/// Top-level ELO optimizer for compute() — must be top-level for isolate serialization.
/// Operates only on plain int data (elo indices). No Player/Game objects cross the boundary.
///
/// Input:  payload.courtElos[courtIndex][playerIndex] = Elo.index (0–7)
/// Output: reordered courtElos after greedy swap optimization
_EloResult _improveEloSpreadIsolate(_EloPayload payload) {
  final courts = payload.courtElos.map((c) => List<int>.from(c)).toList();
  final int numCourts = courts.length;
  if (numCourts < 2) return courts; // Nothing to optimize

  // Cost function: average elo gap * 0.1 + max elo gap
  // elo gap per court = max(elos) - min(elos)
  int eloGap(List<int> court) {
    if (court.isEmpty) return 0;
    return court.reduce((a, b) => a > b ? a : b) -
        court.reduce((a, b) => a < b ? a : b);
  }

  double costFunction(List<List<int>> c) {
    final gaps = c.map(eloGap).toList();
    final avg = gaps.reduce((a, b) => a + b) / gaps.length;
    final max = gaps.reduce((a, b) => a > b ? a : b);
    return avg * 0.1 + max;
  }

  double currentCost = costFunction(courts);

  bool changed = true;
  int iteration = 0;
  while (iteration < payload.maxIteration && changed) {
    iteration++;
    changed = false;

    // Iterate all pairs of courts
    for (int ci = 0; ci < numCourts - 1; ci++) {
      for (int cj = ci + 1; cj < numCourts; cj++) {
        // Iterate all ordered pairs of player slots (including same slot, as original Amalgams)
        final int slots1 = courts[ci].length;
        final int slots2 = courts[cj].length;
        for (int p1 = 0; p1 < slots1; p1++) {
          for (int p2 = 0; p2 < slots2; p2++) {
            // Try swap
            final temp = courts[ci][p1];
            courts[ci][p1] = courts[cj][p2];
            courts[cj][p2] = temp;

            final newCost = costFunction(courts);
            if (newCost < currentCost) {
              currentCost = newCost;
              changed = true;
              break; // Take first improvement (greedy)
            } else {
              // Revert swap
              courts[cj][p2] = courts[ci][p1];
              courts[ci][p1] = temp;
            }
          }
          if (changed) break;
        }
        if (changed) break;
      }
      if (changed) break;
    }
  }

  return courts;
}
