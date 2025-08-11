import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/court.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
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
    final playingPlayers = getPlayerFromGames(gameData.stagingMatches).toSet();
    final playerStatistic = gameData.getCurrentPlayersHistory();
    final inactivePlayers = gameData.players.values
        .toSet()
        .difference(playingPlayers)
        .where(
          (player) => '${player.name()}${player.elo}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .sortedBy((player) => playerStatistic[player] ?? 0);

    return _InactivePlayerDraggable(
      child: Column(
        spacing: spaceComponent,
        children: [
          if (query.isEmpty)
            Text(
              AppLocalizations.of(context)!.inactive_player,
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
                  tooltip: AppLocalizations.of(context)!.add_player,
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
                    itemBuilder: (BuildContext context, int index) =>
                        DraggablePlayerComponent(
                          data: inactivePlayers[index],
                          size: const Size.fromHeight(50),
                          shouldAcceptIncomingDragPlayer:
                              // Disallow dragging to other inactive player
                              (player) => !inactivePlayers.contains(player),
                          onDragToTarget: (player) {
                            gameData.swapPlayer(player, inactivePlayers[index]);
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
      builder: (context, candidateItems, rejectedItems) => Stack(
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
    itemCount,
  ) {
    final constraintMaxWidth = constraints.maxWidth - padding.horizontal;
    final constrainMaxHeight = constraints.maxHeight - padding.vertical;
    const itemMinWidth = 420;
    final maxNumberOfColumns = max(1, constraintMaxWidth ~/ itemMinWidth);

    double maxArea = 0;

    int idealNumberOfColumns = maxNumberOfColumns;

    for (int column = 1; column <= maxNumberOfColumns; column++) {
      final row = (itemCount / column).ceil();
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
    const gutter = spaceDefault;
    const padding = EdgeInsets.only(right: space16);
    final games = context.watch<GameData>().stagingMatches;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GridView.builder(
          shrinkWrap: true,
          itemCount: games.length,
          padding: padding,
          itemBuilder: (BuildContext context, int index) {
            final game = games[index];
            return ShadedContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: CourtHeader(game: game, courtNumber: index),
                  ),
                  CourtComponent(players: game.players),
                ],
              ),
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: getIdealNumberOfColumn(
              constraints,
              gutter,
              padding,
              games.length,
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

class CourtHeader extends StatefulWidget {
  final int courtNumber;
  final Game game;

  const CourtHeader({super.key, required this.courtNumber, required this.game});

  @override
  State<CourtHeader> createState() => _CourtHeaderState();
}

class _CourtHeaderState extends State<CourtHeader>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool isPlaying = false;

  Widget startStopPlayingIcon() {
    if (!isPlaying) {
      return Button(
        icon: const Icon(Icons.play_arrow, color: Colors.green),
        onPressed: () {
          if (!widget.game.isPlayable()) {
            context.showErrorToast('Not enough players to make a court');
            return;
          }
          setState(() => isPlaying = true);
        },
      );
    } else {
      return Button(
        icon: const Icon(Icons.stop, color: Colors.red),
        child: const Text("Finish", style: TextStyle(color: Colors.red)),
        onPressed: () async {
          setState(() => isPlaying = false);
          try {
            await context.read<GameData>().saveSingleGame(widget.game);
            if (PersistentSetting.instance.getAutoMakeGame()) {
              onPressGenerateGame();
            }
          } catch (e) {
            if (mounted) {
              context.showErrorToast(e.toString());
              return;
            }
          }
        },
      );
    }
  }

  void onPressGenerateGame() {
    final gameData = Provider.of<GameData>(context, listen: false);
    if (widget.game.players.isEmpty &&
        gameData.players.length -
                getPlayerFromGames(gameData.stagingMatches).length <
            Game.playerPerCourt) {
      context.showErrorToast('Not enough players to make a court');
      return;
    }
    try {
      gameData.makeSingleCourt(widget.courtNumber);
    } catch (error) {
      // If the error is not null and the widget is still mounted, show the error toast
      if (mounted) {
        context.showErrorToast(error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;
    super.build(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        LinearProgressIndicator(
          value: isPlaying ? null : 0,
          color: context.colorScheme.secondaryContainer,
          backgroundColor: Colors.transparent,
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: spaceComponent,
            horizontal: spaceDefault,
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            spacing: spaceComponent,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.court_n(widget.courtNumber + 1),
                style: textStyle,
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.skill_gap_n(widget.game.eloGap()),
                style: textStyle,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (PersistentSetting.instance.getGameType() ==
                      GameType.gameBased)
                    startStopPlayingIcon(),
                  if (!isPlaying)
                    Button(
                      icon: const Icon(Icons.sync),
                      onPressed: onPressGenerateGame,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive =>
      PersistentSetting.instance.getGameType() == GameType.gameBased;
}
