import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:trotter/trotter.dart';

class GameData extends ChangeNotifier {
  int numberOfCourt = 2;

  final Set<Player> _players = {
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

    // Mock player
    // C2 Tier (Newbie)
    Player(name: "Alice", elo: Elo.c2),
    Player(name: "Bob", elo: Elo.c2),
    Player(name: "Cathy", elo: Elo.c2),
    Player(name: "David", elo: Elo.c2),
    Player(name: "Ella", elo: Elo.c2),
    Player(name: "Finn", elo: Elo.c2),
    Player(name: "Gina", elo: Elo.c2),

    // C1 Tier
    Player(name: "Henry", elo: Elo.c1),
    Player(name: "Ivy", elo: Elo.c1),
    Player(name: "Jack", elo: Elo.c1),
    Player(name: "Katie", elo: Elo.c1),
    Player(name: "Leo", elo: Elo.c1),
    Player(name: "Mia", elo: Elo.c1),
    Player(name: "Nina", elo: Elo.c1),

    // B2 Tier
    Player(name: "Oscar", elo: Elo.b2),
    Player(name: "Paul", elo: Elo.b2),
    Player(name: "Quinn", elo: Elo.b2),
    Player(name: "Rachel", elo: Elo.b2),
    Player(name: "Sam", elo: Elo.b2),
    Player(name: "Tina", elo: Elo.b2),
    Player(name: "Uma", elo: Elo.b2),

    // B1 Tier
    Player(name: "Vince", elo: Elo.b1),
    Player(name: "Wendy", elo: Elo.b1),
    Player(name: "Xander", elo: Elo.b1),
    Player(name: "Yara", elo: Elo.b1),
    Player(name: "Zack", elo: Elo.b1),
    Player(name: "Ava", elo: Elo.b1),
    Player(name: "Ben", elo: Elo.b1),

    // A2 Tier
    Player(name: "Cindy", elo: Elo.a2),
    Player(name: "Daniel", elo: Elo.a2),
    Player(name: "Eva", elo: Elo.a2),
    Player(name: "Frank", elo: Elo.a2),
    Player(name: "Grace", elo: Elo.a2),
    Player(name: "Hank", elo: Elo.a2),
    Player(name: "Iris", elo: Elo.a2),

    // A1 Tier
    Player(name: "Jake", elo: Elo.a1),
    Player(name: "Kara", elo: Elo.a1),
    Player(name: "Liam", elo: Elo.a1),
    Player(name: "Mason", elo: Elo.a1),
    Player(name: "Noah", elo: Elo.a1),
    Player(name: "Olivia", elo: Elo.a1),
    Player(name: "Parker", elo: Elo.a1),

    // S2 Tier
    Player(name: "Quincy", elo: Elo.s2),
    Player(name: "Riley", elo: Elo.s2),
    Player(name: "Sophia", elo: Elo.s2),
    Player(name: "Taylor", elo: Elo.s2),
    Player(name: "Ulysses", elo: Elo.s2),
    Player(name: "Victoria", elo: Elo.s2),
    Player(name: "Wyatt", elo: Elo.s2),

    // S1 Tier (Highest)
    Player(name: "Xena", elo: Elo.s1),
    Player(name: "Yvonne", elo: Elo.s1),
    Player(name: "Zane", elo: Elo.s1),
    Player(name: "Alex", elo: Elo.s1),
    Player(name: "Bella", elo: Elo.s1),
    Player(name: "Cody", elo: Elo.s1),
    Player(name: "Diana", elo: Elo.s1),
  };

  Set<Player> get player => Set.unmodifiable(_players);

  final List<List<Game>> history = [];

  /// Current view of the game
  List<Game> _currentView = [];

  List<Game> get currentView => _currentView;

  void setCurrentView(List<Game> newView) {
    _currentView = newView;
    notifyListeners();
  }

  /// Candidate to be added to history
  List<Game> stagingMatches = [];

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
    stagingMatches =
        candidatePlayer.slices(4).map((players) => Game(players)).toList();
    assert(stagingMatches.isNotEmpty);
    _improveEloSpread();
    _currentView = stagingMatches;
    print('Match elo spread: ${eloSpread()}');
    notifyListeners();
  }

  void saveCurrentGame() {
    if (stagingMatches.isEmpty) return;
    history.add(stagingMatches);
    _currentView = history.last;
    stagingMatches = [];
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
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
    return stagingMatches.map((match) => match.eloGap()).max;
  }

  void _improveEloSpread({int targetSpread = 1}) {
    // If the current spread is too high, try to swap players with other groups
    int currentSpread = eloSpread();
    debugPrint('current spread $currentSpread');
    if (currentSpread < targetSpread) return;
    final combinations = Combinations(2, stagingMatches);
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

  Map<Player, List<int>> getPlayerIndexOfCurrentView() {
    final Map<Player, List<int>> out = {};
    for (var i = 0; i < currentView.length; i++) {
      for (var j = 0; j < currentView[i].players.length; j++) {
        out[currentView[i].players[j]] = [i, j];
      }
    }
    return out;
  }

  void swapPlayer(Player player1, Player player2) {
    final indices = getPlayerIndexOfCurrentView();
    // At least one player has to be from the current view
    assert(
      indices.containsKey(player1) || indices.containsKey(player2),
      "This should not be happen, can not swap between inactive players",
    );

    final [playerToBeReplaced, otherPlayer] =
        indices.containsKey(player1) ? [player1, player2] : [player2, player1];

    currentView[indices[playerToBeReplaced]![0]]
            .players[indices[playerToBeReplaced]![1]] =
        otherPlayer;

    // If the other player is also in the current view, swap them too.
    // But if not, they are inactive player, so do nothing
    if (indices.containsKey(otherPlayer)) {
      currentView[indices[otherPlayer]![0]].players[indices[otherPlayer]![1]] =
          playerToBeReplaced;
    }
    notifyListeners();
  }
}

Iterable<Player> getPlayerFromGames(List<Game> games) =>
    games.expand((game) => game.players);
