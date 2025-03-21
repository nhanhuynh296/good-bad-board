import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/Player.dart';
import 'package:good_bad_board/view/player_view.dart';

class GameView extends StatelessWidget {
  final List<Player> players;

  const GameView({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final sortedPlayer = players.sortedBy((player) => player.elo.index);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Row(
                spacing: gutter,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerView(sortedPlayer.first),
                  PlayerView(sortedPlayer.last),
                ],
              ),
            ),
            const Divider(
              thickness: 5,
              height: gutter,
              color: Colors.black,
              indent: gutter,
              endIndent: gutter,
            ),
            Flexible(
              child: Row(
                spacing: gutter,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerView(sortedPlayer[1]),
                  PlayerView(sortedPlayer[2]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
