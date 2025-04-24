import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/court.dart';
import 'package:good_bad_board/view/component/list_renderer.dart';
import 'package:good_bad_board/view/component/overlay.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:good_bad_board/view/sign_in_page.dart';
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
      getPlayerFromGames(gameData.stagingMatches),
    );
    final inactivePlayers = gameData.player
        .difference(playingPlayers)
        .where(
          (player) => '${player.name}${player.elo}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .sortedBy((player) => player.name);

    const spaceX = spaceDefault;

    return _InactivePlayerDraggable(
      child: Column(
        spacing: spaceComponent,
        children: [
          if (query.isEmpty)
            Text(
              'Inactive Players',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spaceX),
            child: SearchBar(
              hintText: 'Search for name, elo...',
              leading: query.isEmpty ? const Icon(Icons.search) : null,
              onChanged: (i) {
                setState(() {
                  query = i;
                });
              },
              trailing: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Add New Player',
                ),
              ],
            ),
          ),
          (inactivePlayers.isNotEmpty)
              ? Expanded(
                child: ListRenderer(
                  items: inactivePlayers,
                  itemBuilder:
                      (BuildContext context, int index) =>
                          DraggablePlayerComponent(
                            data: inactivePlayers[index],
                            shouldAcceptIncomingDragPlayer:
                                // Disallow dragging to other inactive player
                                (player) => !inactivePlayers.contains(player),
                            onDragToTarget: (player) {
                              gameData.swapPlayer(
                                player,
                                inactivePlayers[index],
                              );
                            },
                          ),
                ),
              )
              : Text(
                'No player with that name, or elo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
        ],
      ),
    );
  }
}

class _InactivePlayerDraggable extends StatelessWidget {
  final Widget child;

  const _InactivePlayerDraggable({required this.child});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final playingPlayers = Set.unmodifiable(
      getPlayerFromGames(gameData.stagingMatches),
    );
    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) {
        final player = details.data;
        return playingPlayers.contains(player);
      },
      builder:
          (context, candidateItems, rejectedItems) => Stack(
            children: [
              child,
              if (rejectedItems.isNotEmpty) const InvalidDropTargetOverlay(),
            ],
          ),
    );
  }
}

class StagingGameComponent extends StatelessWidget {
  final List<Game> games;

  const StagingGameComponent(this.games, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListRenderer(
      itemBuilder:
          (BuildContext context, int index) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: const EdgeInsets.all(spaceComponent),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Court ${index + 1}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.start,
                ),
              ),
              CourtComponent(players: games[index].players),
            ],
          ),
      items: games,
      separatorExtent: space32,
    );
  }
}
