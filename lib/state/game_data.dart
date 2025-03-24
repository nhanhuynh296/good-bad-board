import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:trotter/trotter.dart';

class GameData extends ChangeNotifier {
  final int numberOfCourt = 2;

  final List<Player> _players = [
    Player(name: "Howard", elo: Elo.b1),
    Player(name: "Yong", elo: Elo.b2),
    Player(name: "Ryan", elo: Elo.b2),
    Player(name: "Ethan", elo: Elo.b2),
    Player(name: "Sherry", elo: Elo.c1),
    Player(name: "Wei", elo: Elo.b1),
    Player(name: "Jordan", elo: Elo.a2),
    Player(name: "Justin", elo: Elo.a1),
    Player(name: "Trinity", elo: Elo.c1),
    Player(name: "Lizzy", elo: Elo.c1),
    Player(name: "Victor", elo: Elo.a1),
    Player(name: "Daniel", elo: Elo.a2),
    Player(name: "Nathan", elo: Elo.a1),
  ];

  List<Player> get player => List.unmodifiable(_players);

  final List<List<Game>> history = [];

  /// Candidate to be added to history
  List<Game> currentMatches = [];

  Iterable<Player> get currentMatchesPlayers =>
      currentMatches.expand((game) => game.players);

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

  void removePlayer(Player player) {
    _players.remove(player);
    _fractionalAverageGamePlayer.remove(player);
    notifyListeners();
  }

  void makeGame() {
    if (_players.isEmpty || numberOfCourt <= 0) return;
    final candidatePlayer = _choosePlayer().shuffled();
    assert(
      candidatePlayer.isNotEmpty && candidatePlayer.length % 4 == 0,
      'Candidate player is empty or not a multiple of 4, ${candidatePlayer.length}',
    );
    currentMatches =
        candidatePlayer.slices(4).map((players) => Game(players)).toList();
    assert(currentMatches.isNotEmpty);
    _improveEloSpread();
    print('Match elo spread: ${eloSpread()}');
    notifyListeners();
  }

  void saveCurrentGame() {
    if (currentMatches.isEmpty) return;
    history.add(currentMatches);
    currentMatches = [];
    notifyListeners();
    print(getCurrentPlayerAverageMatchPlayed());
  }

  Iterable<Player> _choosePlayer() {
    final playerHistory = getCurrentPlayersHistory();
    final averageMatchPlayed = getCurrentPlayerAverageMatchPlayed();

    final weights = _players
        .map((player) {
          final modifier =
              1 / exp(2 * ((playerHistory[player]! - averageMatchPlayed)));
          return modifier / _players.length;
        })
        .toList(growable: false);
    return playerHistory.keys
        .toList(growable: false)
        .choices(weights, count: numberOfCourt * Game.playerPerCourt);
  }

  /// Only using the currently active player to calculate the average.
  ///
  /// Prevent scenario where a player leaves and still got chosen to play.
  Map<Player, double> getCurrentPlayersHistory() {
    final Map<Player, double> matchCount = {
      for (var player in _players) player: 0,
    };
    final currentPlayerHistory = history.expand(
      (games) => games.expand((game) => game.players).where(_players.contains),
    );
    for (final player in currentPlayerHistory) {
      matchCount[player] = matchCount.update(player, (value) => value + 1);
    }

    _fractionalAverageGamePlayer.forEach(
      (player, nMatchPlayed) =>
          matchCount[player] = matchCount.update(
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

  int eloSpread() {
    return currentMatches.map((match) => match.eloGap()).max;
  }

  void _improveEloSpread({int targetSpread = 1}) {
    // If the current spread is too high, try to swap players with other groups
    int currentSpread = eloSpread();
    debugPrint('current spread $currentSpread');
    if (currentSpread < targetSpread) return;
    final combinations = Combinations(2, currentMatches);
    for (final [match1, match2] in combinations()) {
      for (final [i, j] in Amalgams(2, List.generate(4, (k) => k))()) {
        var temp = match1.players[i];
        match1.players[i] = match2.players[j];
        match2.players[j] = temp;
        debugPrint('${match1.players[i].name} <-> ${match2.players[j].name}');
        final newSpread = eloSpread();
        debugPrint('\tnew spread $newSpread');
        if (newSpread < targetSpread) {
          debugPrint('new spread satisfied, ending');
          //  just enough spread
          return;
        }
        if (newSpread < currentSpread) {
          currentSpread = newSpread;
          debugPrint('\tgood swap, next');
          continue;
        }
        debugPrint('\tnah, swap back');
        temp = match1.players[i];
        match1.players[i] = match2.players[j];
        match2.players[j] = temp;
      }
    }
  }

  Iterable<Player> getInactivePlayer() {
    final allPlayer = _players.toSet();
    final currentPlayer = currentMatchesPlayers.toSet();
    return allPlayer.difference(currentPlayer);
  }

  Map<Player, List<int>> getIndexOfPlayers() {
    final Map<Player, List<int>> out = {};
    for (var i = 0; i < currentMatches.length; i++) {
      for (var j = 0; j < currentMatches[i].players.length; j++) {
        out[currentMatches[i].players[j]] = [i, j];
      }
    }
    return out;
  }

  void swapActivePlayer(Player player1, Player player2) {
    final indices = getIndexOfPlayers();
    var tmp =
        currentMatches[indices[player1]![0]].players[indices[player1]![1]];

    currentMatches[indices[player1]![0]].players[indices[player1]![1]] =
        currentMatches[indices[player2]![0]].players[indices[player2]![1]];
    currentMatches[indices[player2]![0]].players[indices[player2]![1]] = tmp;
    notifyListeners();
  }

  void swapWithInactivePlayer(Player activePlayer, Player inactivePlayer) {
    final indices = getIndexOfPlayers();
    currentMatches[indices[activePlayer]![0]]
            .players[indices[activePlayer]![1]] =
        inactivePlayer;
    notifyListeners();
  }
}
