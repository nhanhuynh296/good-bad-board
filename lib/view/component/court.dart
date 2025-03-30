import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
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
      gameData.swapPlayer(player, draggedToPlayer);
    }

    final sortedPlayer = players.sortedBy((player) => player.elo.index);
    const spaceXBetweenPlayer = spaceComponent;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.all(spaceDefault),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Row(
                spacing: spaceXBetweenPlayer,
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
              height: spaceDefault,
              color: Colors.black,
              indent: spaceDefault,
              endIndent: spaceDefault,
            ),
            Flexible(
              child: Row(
                spacing: spaceXBetweenPlayer,
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
