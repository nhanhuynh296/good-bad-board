import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/model/game.dart';
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

            Positioned.fill(
              child: Container(
                foregroundDecoration:
                    (isInvalidDragHovering)
                        ? BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                        )
                        : null,
                padding: const EdgeInsets.symmetric(horizontal: space32),
                child:
                    (players.length == Game.playerPerCourt)
                        ? Row(
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
                        )
                        : (players.isNotEmpty &&
                            players.length != Game.playerPerCourt)
                        ? Column(
                          spacing: space32,
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
            if (isInvalidDragHovering)
              const Positioned.fill(child: Placeholder()),
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
      spacing: space16,
      children: children,
    );
  }
}
