import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/Player.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:trotter/trotter.dart';

class GameData extends ChangeNotifier {
  final int numberOfCourt = 2;

  final List<Player> players = [
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

  final List<List<Game>> history = [];
  int currentGameIndex = 0;

  /// Candidate to be added to history
  List<Game> currentMatches = [];

  void makeGame() {
    assert(players.isNotEmpty && numberOfCourt > 0);
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
    history.add(currentMatches);
    currentMatches = [];
    notifyListeners();
  }

  Iterable<Player> _choosePlayer() {
    final playerHistory = getPlayersHistory();
    final averageMatchPlayed = getPlayerAverageMatchPlayed(playerHistory);

    final weights = players
        .map((player) {
          final modifier =
              1 / exp(2 * ((playerHistory[player]! - averageMatchPlayed)));
          return modifier / players.length;
        })
        .toList(growable: false);
    return playerHistory.keys
        .toList(growable: false)
        .choices(weights, count: numberOfCourt * Game.playerPerCourt);
  }

  Map<Player, int> getPlayersHistory() {
    final Map<Player, int> matchCount = {for (var player in players) player: 0};
    final playerHistory = history.expand(
      (games) => games.expand((game) => game.players),
    );
    for (final player in playerHistory) {
      matchCount[player] = matchCount.update(
        player,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
    }
    return matchCount;
  }

  double getPlayerAverageMatchPlayed([Map<Player, int>? cachedHistory]) {
    final history = cachedHistory ?? getPlayersHistory();
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
    final allPlayer = players.toSet();
    final currentPlayer = currentMatches.expand((game) => game.players).toSet();
    return allPlayer.difference(currentPlayer);
  }
}
