import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/Player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/player_view.dart';
import 'package:provider/provider.dart';

class GameView extends StatelessWidget {
  final List<Player> players;

  const GameView({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    void onDragToTarget(Player player, Player draggedToPlayer) {
      final gameData = Provider.of<GameData>(context, listen: false);
      if (gameData.getInactivePlayer().contains(draggedToPlayer)) {
        gameData.swapWithInactivePlayer(player, draggedToPlayer);
      } else {
        gameData.swapActivePlayer(player, draggedToPlayer);
      }
    }

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
                  DraggablePlayerView(
                    data: sortedPlayer.first,
                    onDragToTarget:
                        (draggedToPlayer) =>
                            onDragToTarget(sortedPlayer.first, draggedToPlayer),
                  ),
                  DraggablePlayerView(
                    data: sortedPlayer.last,
                    onDragToTarget:
                        (draggedToPlayer) =>
                            onDragToTarget(sortedPlayer.last, draggedToPlayer),
                  ),
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
                  DraggablePlayerView(
                    data: sortedPlayer[2],
                    onDragToTarget:
                        (draggedToPlayer) =>
                            onDragToTarget(sortedPlayer[2], draggedToPlayer),
                  ),
                  DraggablePlayerView(
                    data: sortedPlayer[1],
                    onDragToTarget:
                        (draggedToPlayer) =>
                            onDragToTarget(sortedPlayer[1], draggedToPlayer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
