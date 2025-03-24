import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/court.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:provider/provider.dart';

class InactivePlayerComponent extends StatelessWidget {
  const InactivePlayerComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final playingPlayers = Set.unmodifiable(
      gameData.getCurrentMatchesPlayers(),
    );
    final inactivePlayers = gameData.player
        .difference(playingPlayers)
        .sortedBy((player) => player.name);

    return Column(
      spacing: gutter,
      children: [
        Text(
          'Inactive Players',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: inactivePlayers.length,
            padding: const EdgeInsets.symmetric(horizontal: gutter),
            itemBuilder:
                (BuildContext context, int index) => DraggablePlayerComponent(
                  data: inactivePlayers[index],
                  shouldAcceptIncomingDragPlayer:
                      // Disallow dragging to other inactive player
                      (player) => !inactivePlayers.contains(player),
                  onDragToTarget: (player) {
                    gameData.swapPlayer(player, inactivePlayers[index]);
                  },
                ),
            separatorBuilder:
                (BuildContext context, int index) =>
                    const SizedBox(height: gutter),
          ),
        ),
      ],
    );
  }
}

class StagingGameComponent extends StatelessWidget {
  final List<Game> games;

  const StagingGameComponent(this.games, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: gutter),
      itemCount: games.length,

      itemBuilder:
          (BuildContext context, int index) =>
              CourtComponent(players: games[index].players),
      separatorBuilder: (_, _) => const SizedBox(height: gutter),
    );
  }
}
