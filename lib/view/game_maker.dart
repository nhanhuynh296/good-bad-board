import 'package:flutter/widgets.dart';
import 'package:good_bad_board/model/Player.dart';
import 'package:good_bad_board/view/player.dart';

class GameMaker extends StatelessWidget {
  const GameMaker({super.key});

  static final players = [
    Player(name: "Howard", elo: Elo.b1),
    Player(name: "Yong", elo: Elo.b2),
    Player(name: "Ryan", elo: Elo.b2),
    Player(name: "Ethan", elo: Elo.b2),
    Player(name: "Sherry", elo: Elo.c1),
    Player(name: "Wei", elo: Elo.b1),
    Player(name: "Jordan", elo: Elo.a2),
    Player(name: "Justin", elo: Elo.a1),
    Player(name: "Trinity", elo: Elo.c1),
    Player(name: "Victor", elo: Elo.a2),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('adassda'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [PlayerView(players[1]), PlayerView(players[2])],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [PlayerView(players[3]), PlayerView(players[4])],
          ),
        ],
      ),
    );
  }
}
