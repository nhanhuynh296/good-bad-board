import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/game_view.dart';
import 'package:good_bad_board/view/player_view.dart';
import 'package:provider/provider.dart';

class GameMaker extends StatelessWidget {
  const GameMaker({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Column(
      spacing: gutter,
      children: [
        Expanded(
          child: Row(
            spacing: gutter,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Inactive Players',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Expanded(child: InactivePlayerView()),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Courts',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Expanded(child: CurrentGameView()),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: gutter,
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    gameData.makeGame();
                  },
                  child: Text(
                    gameData.currentMatches.isEmpty
                        ? 'Generate Game'
                        : 'Re-Generate Game',
                  ),
                ),
              ),
              if (gameData.currentMatches.isNotEmpty)
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      gameData.saveCurrentGame();
                    },
                    child: const Text('Save'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class InactivePlayerView extends StatelessWidget {
  const InactivePlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final inactivePlayer = gameData
        .getInactivePlayer()
        .sortedBy((player) => player.name)
        .toList(growable: false);

    return ListView.builder(
      itemCount: inactivePlayer.length,
      itemBuilder:
          (BuildContext context, int index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: gutter,
              vertical: gutter / 2,
            ),
            child: PlayerView(inactivePlayer[index]),
          ),
    );
  }
}

class CourtGameView extends StatelessWidget {
  final List<Game> games;

  const CourtGameView(this.games, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: games.length,

      itemBuilder:
          (BuildContext context, int index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: gutter,
              vertical: gutter / 2,
            ),
            child: GameView(players: games[index].players),
          ),
      separatorBuilder: (_, _) => const SizedBox(),
    );
  }
}

class CurrentGameView extends StatefulWidget {
  const CurrentGameView({super.key});

  @override
  State<CurrentGameView> createState() => _CurrentGameViewState();
}

class _CurrentGameViewState extends State<CurrentGameView> {
  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final numberOfTabs = 1 + gameData.history.length;
    // When history is not none and staging is empty, then show the history
    // Otherwise showing the stage
    final shouldShowStagingTab =
        gameData.currentMatches.isEmpty && gameData.history.isNotEmpty;
    return DefaultTabController(
      key: ValueKey(gameData.currentMatches.isEmpty),
      initialIndex: (numberOfTabs - 1) - (shouldShowStagingTab ? 1 : 0),
      length: numberOfTabs,
      child: Scaffold(
        bottomNavigationBar: TabBar(
          isScrollable: true,
          tabs: [
            ...gameData.history.mapIndexed(
              (i, game) => Tab(text: 'Game ${i + 1}'),
            ),
            const Tab(text: 'Current Game'),
          ],
        ),
        body: TabBarView(
          children: [
            ...gameData.history.map((game) => CourtGameView(game)),
            CourtGameView(gameData.currentMatches),
          ],
        ),
      ),
    );
  }
}
