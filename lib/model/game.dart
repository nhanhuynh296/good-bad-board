import 'package:collection/collection.dart';
import 'package:good_bad_board/model/Player.dart';

class Game {
  static const int playerPerCourt = 4;

  final List<Player> players;

  Game(this.players) : assert(players.length == playerPerCourt);

  int eloGap() {
    final sortedPlayers = players.sortedBy((player) => player.elo.index);
    return (sortedPlayers.last.elo.index - sortedPlayers.first.elo.index).abs();
  }
}
