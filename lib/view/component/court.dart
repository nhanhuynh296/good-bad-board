import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/overlay.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:provider/provider.dart';

const _spaceAll = space32;

class CourtComponent extends StatelessWidget {
  final PlayerContainer players;

  const CourtComponent({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    void onDragToTarget(Player player, Player draggedToPlayer) {
      final gameData = Provider.of<GameData>(context, listen: false);
      gameData.swapPlayer(player, draggedToPlayer);
    }

    final sortedPlayer = players.sortedBy((player) => player.elo.index);
    final gameData = Provider.of<GameData>(context);
    return DragTarget<Player>(
      onWillAcceptWithDetails: (detail) {
        if (players.contains(detail.data)) return false;
        if (players.length >= Game.playerPerCourt) return false;
        return true;
      },
      onAcceptWithDetails: (detail) {
        gameData.addPlayerToCourt(detail.data, players);
      },
      builder: (context, candidateItems, rejectedItems) {
        final bool isInvalidDragHovering = rejectedItems.isNotEmpty;

        return Stack(
          children: [
            Image.asset('asset/image/court_small.webp'),
            if (isInvalidDragHovering) const InvalidDropTargetOverlay(),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(_spaceAll),
                child:
                    (players.length == Game.playerPerCourt)
                        ? Row(
                          spacing: _spaceAll,
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
                        )
                        : (players.isNotEmpty &&
                            players.length != Game.playerPerCourt)
                        ? Column(
                          spacing: _spaceAll,
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: players
                              .map(
                                (player) => DraggablePlayerComponent(
                                  data: player,
                                  onDragToTarget:
                                      (draggedToPlayer) => onDragToTarget(
                                        player,
                                        draggedToPlayer,
                                      ),
                                ),
                              )
                              .toList(growable: false),
                        )
                        : const SizedBox(),
              ),
            ),
          ],
        );
      },
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
      spacing: _spaceAll,
      children: children
          .map((child) => Expanded(child: child))
          .toList(growable: false),
    );
  }
}
