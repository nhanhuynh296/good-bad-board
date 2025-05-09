import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
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
    final playerStatistic = gameData.getCurrentPlayersHistory();
    final inactivePlayers = gameData.player
        .difference(playingPlayers)
        .where(
          (player) => '${player.name}${player.elo}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .sorted((player1, player2) {
          if (playerStatistic[player1] != playerStatistic[player2]) {
            return playerStatistic[player1]!.toInt() -
                playerStatistic[player2]!.toInt();
          }
          return player1.name().compareTo(player2.name());
        });

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
            padding: const EdgeInsets.symmetric(horizontal: 0),
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
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    spaceDefault,
                    space32,
                    spaceDefault,
                  ),
                  items: inactivePlayers,
                  itemBuilder:
                      (BuildContext context, int index) =>
                          DraggablePlayerComponent(
                            data: inactivePlayers[index],
                            size: const Size.fromHeight(50),
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
      onAcceptWithDetails: (details) {
        gameData.removePlayerFromCourt(details.data);
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
  final GameContainer games;

  const StagingGameComponent(this.games, {super.key});

  int getIdealNumberOfColumn(
    BoxConstraints constraints,
    double gutter,
    EdgeInsets padding,
  ) {
    final constraintMaxWidth = constraints.maxWidth - padding.horizontal;
    final constrainMaxHeight = constraints.maxHeight - padding.vertical;
    const itemMinWidth = 420;
    final maxNumberOfColumns = max(1, constraintMaxWidth ~/ itemMinWidth);

    double maxArea = 0;

    int idealNumberOfColumns = maxNumberOfColumns;

    for (int column = 1; column <= maxNumberOfColumns; column++) {
      final row = (games.length / column).ceil();
      final itemWidth = (constraintMaxWidth - gutter * (column - 1)) / column;
      final itemHeight = itemWidth / goldenRatio;

      final heightTaken = row * itemHeight + (row - 1) * gutter;

      if (heightTaken > constrainMaxHeight) {
        continue;
      }

      final double area = itemWidth * itemHeight;
      if (area > maxArea) {
        maxArea = area;
        idealNumberOfColumns = column;
      }
    }
    return idealNumberOfColumns;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;
    const gutter = spaceDefault;
    const padding = EdgeInsets.only(right: space16);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GridView.builder(
          itemCount: games.length,
          padding: padding,
          itemBuilder: (BuildContext context, int index) {
            return ShadedContainer(
              // shaded: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      padding: const EdgeInsets.symmetric(
                        vertical: spaceComponent,
                        horizontal: spaceDefault,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        spacing: spaceComponent,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('COURT ${index + 1}', style: textStyle),
                          const Spacer(),
                          Text(
                            'SKILL GAP ${games[index].eloGap()}',
                            style: textStyle,
                          ),
                          Button(
                            icon: const Icon(
                              Icons.play_arrow_sharp,
                              color: Colors.green,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  CourtComponent(players: games[index].players),
                ],
              ),
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getIdealNumberOfColumn(
              constraints,
              gutter,
              padding,
            ),
            mainAxisSpacing: gutter,
            crossAxisSpacing: gutter,
            childAspectRatio: goldenRatio,
          ),
        );
      },
    );
  }
}
