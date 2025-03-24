import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:provider/provider.dart';

class CourtComponent extends StatelessWidget {
  final List<Player> players;

  const CourtComponent({super.key, required this.players});

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
      padding: const EdgeInsets.all(gutter),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Row(
                spacing: gutter,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: DraggablePlayerComponent(
                      data: sortedPlayer.first,
                      onDragToTarget:
                          (draggedToPlayer) => onDragToTarget(
                            sortedPlayer.first,
                            draggedToPlayer,
                          ),
                    ),
                  ),
                  Expanded(
                    child: DraggablePlayerComponent(
                      data: sortedPlayer.last,
                      onDragToTarget:
                          (draggedToPlayer) => onDragToTarget(
                            sortedPlayer.last,
                            draggedToPlayer,
                          ),
                    ),
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
                  Expanded(
                    child: DraggablePlayerComponent(
                      data: sortedPlayer[2],
                      onDragToTarget:
                          (draggedToPlayer) =>
                              onDragToTarget(sortedPlayer[2], draggedToPlayer),
                    ),
                  ),
                  Expanded(
                    child: DraggablePlayerComponent(
                      data: sortedPlayer[1],
                      onDragToTarget:
                          (draggedToPlayer) =>
                              onDragToTarget(sortedPlayer[1], draggedToPlayer),
                    ),
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
