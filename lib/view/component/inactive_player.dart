import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/court.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:provider/provider.dart';

class InactivePlayerComponent extends StatefulWidget {
  const InactivePlayerComponent({super.key});

  @override
  State<InactivePlayerComponent> createState() =>
      _InactivePlayerComponentState();
}

class _InactivePlayerComponentState extends State<InactivePlayerComponent> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final playingPlayers = Set.unmodifiable(
      getPlayerFromGames(gameData.currentView),
    );
    final inactivePlayers = gameData.player
        .difference(playingPlayers)
        .where(
          (player) => '${player.name}${player.elo}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .sortedBy((player) => player.name);

    return Column(
      spacing: gutter / 2,
      children: [
        if (query.isEmpty)
          Text(
            'Inactive Players',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: gutter),
          child: SearchBar(
            leading: query.isEmpty ? const Icon(Icons.search) : null,
            onChanged: (i) {
              setState(() {
                query = i;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.separated(
            key: ValueKey([gameData.currentView, query]),
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
