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
import 'package:trotter/trotter.dart';

typedef GameContainer = List<Game>;
typedef PlayerContainer = List<Player>;

const int maxIteration = 1000;

class GameData extends ChangeNotifier {
  int numberOfCourt = 2;

  void setNumberOfCourt(int value) {
    if (value <= 0) return;
    numberOfCourt = value;
    notifyListeners();
  }

  final Set<Player> _players = {
    if (kDebugMode) ...[
      Player.create(firstName: "Howard", lastName: "", elo: Elo.b1),
      Player.create(firstName: "Yong", lastName: "", elo: Elo.b2),
      Player.create(firstName: "Ryan", lastName: "", elo: Elo.b2),
      Player.create(firstName: "Ethan", lastName: "", elo: Elo.b2),
      Player.create(firstName: "Sherry", lastName: "", elo: Elo.c1),
      Player.create(firstName: "Wei", lastName: "", elo: Elo.b1),
      Player.create(firstName: "Jordan", lastName: "", elo: Elo.a2),
      Player.create(firstName: "Justin", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Trinity", lastName: "", elo: Elo.c1),
      Player.create(firstName: "Lizzy", lastName: "", elo: Elo.c1),
      Player.create(firstName: "Victor", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Daniel", lastName: "", elo: Elo.a2),
      Player.create(firstName: "Nathan", lastName: "", elo: Elo.a1),

      // A1 Tier
      Player.create(firstName: "Jake", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Kara", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Liam", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Mason", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Noah", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Olivia", lastName: "", elo: Elo.a1),
      Player.create(firstName: "Parker", lastName: "", elo: Elo.a1),

      // S2 Tier
      Player.create(firstName: "Quincy", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Riley", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Sophia", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Taylor", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Ulysses", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Victoria", lastName: "", elo: Elo.s2),
      Player.create(firstName: "Wyatt", lastName: "", elo: Elo.s2),

      // S1 Tier (Highest)
      Player.create(firstName: "Xena", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Yvonne", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Zane", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Alex", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Bella", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Cody", lastName: "", elo: Elo.s1),
      Player.create(firstName: "Diana", lastName: "", elo: Elo.s1),
    ],
  };

  Set<Player> get player => _players;

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
    _players.add(player);
    _fractionalAverageGamePlayer[player] =
        getCurrentPlayerAverageMatchPlayed() * history.length;
    notifyListeners();
  }

  void addFullPricedPlayer(Player player) {
    _players.add(player);
    notifyListeners();
  }

  void onUpdatePlayer(Player newPlayer) {
    final playerToRemove = _players.firstWhereOrNull(
      (p) => p.id == newPlayer.id,
    );
    if (playerToRemove != null) {
      _players.remove(playerToRemove);
      _players.add(newPlayer);
    }
    PlayerRepository.instance.update(newPlayer.id, newPlayer);
    notifyListeners();
  }

  Future<void> deletePlayer(Player player) async {
    removePlayer(player);
    await PlayerRepository.instance.delete(player.id);
    notifyListeners();
  }

  /// Remove a playing who is currently in a session
  void removePlayer(Player player, {bool byId = false}) {
    final playerToRemove = (byId)
        ? _players.firstWhere((p) => p.id == player.id)
        : player;
    _players.remove(playerToRemove);
    gameContainingPlayer(playerToRemove)?.players.remove(playerToRemove);
    notifyListeners();
  }

  Future<String?> makeGame() async {
    if (numberOfCourt <= 0) return 'There are no court available';
    if (_players.isEmpty) return 'There are no player';
    if (_players.length < Game.playerPerCourt) {
      return 'Not enough players, need at least ${Game.playerPerCourt}, got ${_players.length}';
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
        .map((players) => Game.create(players))
        .toList();
    assert(stagingMatches.isNotEmpty);
    _improveEloSpread(stagingMatches);

    debugPrint(
      'Match elo spread: AVG: ${eloSpread(stagingMatches).average}, MAX ${eloSpread(stagingMatches).max}',
    );
    if (stagingMatches.length < numberOfCourt) {
      stagingMatches.addAll(
        List.filled(numberOfCourt - stagingMatches.length, Game.create([])),
      );
    }
    stagingMatches = stagingMatches;
    notifyListeners();
    return null;
  }

  /// Refresh one single court with new players.
  String? makeSingleCourt(int courtIndex) {
    if (courtIndex >= numberOfCourt || courtIndex < 0) {
      return 'Invalid court index';
    }
    final playerAvailable =
        _players.length - getPlayerFromGames(stagingMatches).length;
    if (playerAvailable < Game.playerPerCourt) {
      return 'Not enough players, need at least ${Game.playerPerCourt}, got $playerAvailable';
    }
    stagingMatches[courtIndex] = Game.create(List.empty());
    stagingMatches[courtIndex] = Game.create(
      _choosePlayer(Game.playerPerCourt).toFixedLengthList(),
    );
    notifyListeners();
    return null;
  }

  String? saveCurrentGame() {
    if (stagingMatches.isEmpty) return "No game to save";
    final invalidGames = stagingMatches.where(
      (match) => match.players.isNotEmpty && !match.isPlayable(),
    );
    if (invalidGames.isNotEmpty) {
      return 'PLAYER IS NOT BALANCE ON COURT ${invalidGames.map((game) => stagingMatches.indexOf(game) + 1).join(', ')}';
    }
    history.add(stagingMatches);
    GameRepository.instance.addAll(stagingMatches);

    stagingMatches = [];
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
    return null;
  }

  Iterable<Player> _choosePlayer([int? n]) {
    final numberOfPlayers =
        n ?? min(_players.length ~/ 4, numberOfCourt) * Game.playerPerCourt;
    final playerHistory = getCurrentPlayersHistory();
    final averageMatchPlayed = getCurrentPlayerAverageMatchPlayed();

    final onCourtPlayers = getPlayerFromGames(stagingMatches).toSet();
    final playerOffCourt = _players.difference(onCourtPlayers);

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
      for (var player in _players) player: 0,
    };
    final currentPlayerHistory = history.expand(
      (games) => getPlayerFromGames(games).where(_players.contains),
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

  /// A greedy solution that will ended up with a local minimum. Swap 2 players at a time
  static void _improveEloSpread(GameContainer games, {int targetSpread = 0}) {
    Iterable<num> costFunctionInfo() => GameData.eloSpread(games);
    num costFunction() =>
        costFunctionInfo().average * 0.1 + costFunctionInfo().max;

    if (games.length < 2) {
      log('Only 1 court, no optimization needed');
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
      for (var [match1Index, match2Index] in Combinations(
        2,
        List.generate(games.length, (k) => k),
      )()) {
        for (var [p1, p2] in Amalgams(
          2,
          List.generate(Game.playerPerCourt, (k) => k),
        )()) {
          final match1 = games[match1Index];
          final match2 = games[match2Index];
          var temp = match1.players[p1];
          match1.players[p1] = match2.players[p2];
          match2.players[p2] = temp;

          log('${match1.players[p1].name()} <-> ${match2.players[p2].name()}');
          final newSpread = costFunction();
          log(
            '\tnew spread ${costFunctionInfo()} => ${newSpread.toStringAsFixed(2)}..current $currentSpread',
          );

          if (newSpread >= currentSpread) {
            log('\tnah, swap back');
            temp = match1.players[p1];
            match1.players[p1] = match2.players[p2];
            match2.players[p2] = temp;
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
      (game) => game.players.contains(player),
    );
  }

  String? swapPlayer(Player player1, Player player2) {
    final game1 = gameContainingPlayer(player1);
    final game2 = gameContainingPlayer(player2);
    // At least one player has to be from the current view
    if (game1 == null || game2 == null) "CAN NOT SWAP BETWEEN INACTIVE PLAYERS";

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
    return null;
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
