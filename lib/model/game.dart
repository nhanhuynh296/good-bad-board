import 'package:good_bad_board/model/Player.dart';

class Game {
  static const int playerPerCourt = 4;

  final List<Player> players;

  Game(this.players);

  int eloGap() => (players.first.elo.index - players.last.elo.index).abs();
}
