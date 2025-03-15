import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/model/Player.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:trotter/trotter.dart';

class GameData extends ChangeNotifier {
  final int numberOfCourt = 0;
  final List<Player> players = [];
  final List<Game> history = [];

  /// Candidate to be added to history
  List<Game> currentMatches = [];

  void makeGame() {
    final candidatePlayer = _choosePlayer()..shuffled();
    currentMatches =
        candidatePlayer.slices(4).map((players) => Game(players)).toList();
    _improveEloSpread();
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
    final Map<Player, int> matchCount = {};
    for (final player in players) {
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
    return playerMatches.average;
  }

  int eloSpread() {
    return currentMatches.map((match) => match.eloGap()).max;
  }

  void _improveEloSpread({int targetSpread = 2}) {
    // If the current spread is too high, try to swap players with other groups
    var currentSpread = eloSpread();
    if (currentSpread < targetSpread) return;
    final combinations = Combinations(2, currentMatches);
    for (final [match1, match2] in combinations()) {
      for (final [i, j] in Amalgams(2, [1, 2, 3, 4])()) {
        var temp = match1.players[i];
        match1.players[i] = match2.players[j];
        match2.players[j] = temp;

        final newSpread = eloSpread();
        if (newSpread < targetSpread) {
          //  just enough spread
          return;
        }
        if (newSpread - targetSpread < currentSpread - targetSpread) {
          currentSpread = newSpread;
          break;
        }
        temp = match1.players[i];
        match1.players[i] = match2.players[j];
        match2.players[j] = temp;
      }
    }
  }
}
