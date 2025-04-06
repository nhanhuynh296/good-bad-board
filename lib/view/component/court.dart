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
    return Stack(
      children: [
        Image.asset('asset/image/court_small.webp'),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: space32),
            child: Row(
              spacing: space32,
              children: [
                Expanded(
                  child: _CourtSide(
                    children: [
                      DraggablePlayerComponent(
                        data: sortedPlayer.first,
                        onDragToTarget:
                            (draggedToPlayer) => onDragToTarget(
                              sortedPlayer.first,
                              draggedToPlayer,
                            ),
                      ),
                      DraggablePlayerComponent(
                        data: sortedPlayer.last,
                        onDragToTarget:
                            (draggedToPlayer) => onDragToTarget(
                              sortedPlayer.last,
                              draggedToPlayer,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _CourtSide(
                    children: [
                      DraggablePlayerComponent(
                        data: sortedPlayer[2],
                        onDragToTarget:
                            (draggedToPlayer) => onDragToTarget(
                              sortedPlayer[2],
                              draggedToPlayer,
                            ),
                      ),

                      DraggablePlayerComponent(
                        data: sortedPlayer[1],
                        onDragToTarget:
                            (draggedToPlayer) => onDragToTarget(
                              sortedPlayer[1],
                              draggedToPlayer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CourtSide extends StatelessWidget {
  final List<Widget> children;

  const _CourtSide({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: space16,
      children: children,
    );
  }
}
