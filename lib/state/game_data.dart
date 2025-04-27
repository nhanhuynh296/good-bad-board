import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:good_bad_board/core/random.dart';
import 'package:good_bad_board/dto/player.dart';
import 'package:good_bad_board/dto/session.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trotter/trotter.dart';

typedef GameContainer = List<Game>;
typedef PlayerContainer = List<Player>;

class GameData extends ChangeNotifier {
  int numberOfCourt = 2;

  void setNumberOfCourt(int value) {
    if (value <= 0) return;
    numberOfCourt = value;
    notifyListeners();
  }

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
    //
    // // Mock player
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

  final List<GameContainer> history = [];

  /// Candidate to be added to history
  GameContainer stagingMatches = [];

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
    final playerToRemove = _players.firstWhere((p) => p.id == newPlayer.id);
    _players.remove(playerToRemove);
    _players.add(newPlayer);
    PlayerRepository.instance.updatePlayer(newPlayer);
    notifyListeners();
  }

  void removePlayer(Player player, {bool byId = false}) {
    final playerToRemove = _players.firstWhere((p) => p.id == player.id);
    _players.remove(playerToRemove);
    _fractionalAverageGamePlayer.remove(playerToRemove);
    notifyListeners();
  }

  Future<String?> makeGame() async {
    if (numberOfCourt <= 0) return 'There are no court available';
    if (_players.isEmpty) return 'There are no player';
    if (_players.length < Game.playerPerCourt) {
      return 'Not enough players, need at least ${Game.playerPerCourt}, got ${_players.length}';
    }
    final candidatePlayer = _choosePlayer().shuffled();
    assert(
      candidatePlayer.isNotEmpty &&
          candidatePlayer.length % Game.playerPerCourt == 0,
      'Candidate player is empty or not a multiple of 4, ${candidatePlayer.length}',
    );
    stagingMatches =
        candidatePlayer.slices(4).map((players) => Game(players)).toList();
    assert(stagingMatches.isNotEmpty);
    stagingMatches = await compute(
      _improveEloSpread,
      GameContainer.from(stagingMatches),
    );

    debugPrint('Match elo spread: ${eloSpread(stagingMatches)}');
    if (stagingMatches.length < numberOfCourt) {
      stagingMatches.addAll(
        List.filled(numberOfCourt - stagingMatches.length, PlaceholderGame([])),
      );
    }
    stagingMatches = stagingMatches;
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
    stagingMatches = [];
    notifyListeners();
    debugPrint(
      'Average match every should have played: ${getCurrentPlayerAverageMatchPlayed().toStringAsFixed(2)}',
    );
    return null;
  }

  Iterable<Player> _choosePlayer() {
    final numberOfCourt = min(_players.length ~/ 4, this.numberOfCourt);
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

  static Iterable<int> eloSpread(GameContainer games) {
    return games.map((match) => match.eloGap());
  }

  static GameContainer _improveEloSpread(
    GameContainer games, {
    int targetSpread = 1,
  }) {
    if (games.length < 2) {
      debugPrint('Only 1 court, no optimization needed');
      return games;
    }
    // If the current spread is too high, try to swap players with other groups
    double currentSpread = GameData.eloSpread(games).average;
    debugPrint('current spread $currentSpread');
    if (currentSpread < targetSpread) {
      debugPrint('Current spread is already satisfied');
      return games;
    }
    final combinations = Combinations(2, games);
    for (final [match1, match2] in combinations()) {
      print('match ${games.indexOf(match1)}, ${games.indexOf(match2)}');
      for (var [p1, p2]
          in Amalgams(2, List.generate(Game.playerPerCourt, (k) => k))()) {
        var temp = match1.players[p1];
        match1.players[p1] = match2.players[p2];
        match2.players[p2] = temp;

        debugPrint('${match1.players[p1].name} <-> ${match2.players[p2].name}');
        final newSpread = GameData.eloSpread(games).average;
        debugPrint('\tnew spread $newSpread');
        if (newSpread < targetSpread) {
          debugPrint('new spread satisfied, ending');
          //  just enough spread
          return games;
        }
        if (newSpread < currentSpread) {
          currentSpread = newSpread;
          debugPrint('\tgood swap, next');
          continue;
        }
        debugPrint('\tnah, swap back');
        temp = match1.players[p1];
        match1.players[p1] = match2.players[p2];
        match2.players[p2] = temp;
      }
    }
    return games;
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
    notifyListeners();
    return null;
  }

  /// Add a player to the court. If player is already in the court, remove them
  void addPlayerToCourt(Player player, PlayerContainer courtPtr) {
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
    final dto = SessionDto(players: _players, games: history);

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
    await file.writeAsString(jsonEncode(dto.toJson()));
    return file;
  }
}

Iterable<Player> getPlayerFromGames(GameContainer games) =>
    games.expand((game) => game.players);

Iterable<(T, U)> product<T, U>(Iterable<T> a, Iterable<U> b) sync* {
  for (final x in (a)) {
    for (final y in b) {
      yield (x, y);
    }
  }
}
