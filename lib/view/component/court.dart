import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/view/component/overlay.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:provider/provider.dart';

const _spaceHorizontal = space32;
const _spaceVertical = _spaceHorizontal / 2;

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
            Image.asset(PersistentSetting.instance.getBackground()),
            if (isInvalidDragHovering) const InvalidDropTargetOverlay(),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _spaceHorizontal,
                  vertical: _spaceVertical,
                ),
                child: switch (players.length) {
                  4 => _CourtDifferentSide(
                    children: [
                      _CourtSameSide(
                        children: [
                          DraggablePlayerComponent(
                            data: sortedPlayer.first,
                            onDragToTarget: (draggedToPlayer) => onDragToTarget(
                              sortedPlayer.first,
                              draggedToPlayer,
                            ),
                          ),
                          DraggablePlayerComponent(
                            data: sortedPlayer.last,
                            onDragToTarget: (draggedToPlayer) => onDragToTarget(
                              sortedPlayer.last,
                              draggedToPlayer,
                            ),
                          ),
                        ],
                      ),
                      _CourtSameSide(
                        children: [
                          DraggablePlayerComponent(
                            data: sortedPlayer[2],
                            onDragToTarget: (draggedToPlayer) => onDragToTarget(
                              sortedPlayer[2],
                              draggedToPlayer,
                            ),
                          ),
                          DraggablePlayerComponent(
                            data: sortedPlayer[1],
                            onDragToTarget: (draggedToPlayer) => onDragToTarget(
                              sortedPlayer[1],
                              draggedToPlayer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  2 => _CourtDifferentSide(
                    children: players
                        .map(
                          (player) => DraggablePlayerComponent(
                            data: player,
                            onDragToTarget: (draggedToPlayer) =>
                                onDragToTarget(player, draggedToPlayer),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  1 => _CourtDifferentSide(
                    children: [
                      // This would be on the left so that the player can be dragged easily
                      const SizedBox(),
                      DraggablePlayerComponent(
                        data: players.first,
                        onDragToTarget: (draggedToPlayer) =>
                            onDragToTarget(players.first, draggedToPlayer),
                      ),
                    ],
                  ),
                  _ when players.isNotEmpty => _CourtSameSide(
                    children: players
                        .map(
                          (player) => DraggablePlayerComponent(
                            data: player,
                            onDragToTarget: (draggedToPlayer) =>
                                onDragToTarget(player, draggedToPlayer),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  _ => const SizedBox(),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CourtSameSide extends StatelessWidget {
  final List<Widget> children;

  const _CourtSameSide({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _spaceVertical,
      children: children
          .map((child) => Expanded(child: child))
          .toList(growable: false),
    );
  }
}

class _CourtDifferentSide extends StatelessWidget {
  final List<Widget> children;

  const _CourtDifferentSide({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: _spaceHorizontal,
      children: children
          .map((child) => Expanded(child: child))
          .toList(growable: false),
    );
  }
}
