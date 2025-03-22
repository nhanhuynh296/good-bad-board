import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/dialog.dart';
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
                  spacing: gutter,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Inactive Players',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Expanded(child: InactivePlayerView()),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        showAdaptiveDialog(
                          context: context,
                          builder: (_) => const AddNewPlayer(),
                        );
                      },
                      label: const Text(
                        'Add New Player',
                        textAlign: TextAlign.center,
                      ),
                      icon: const Icon(Icons.person_add),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  spacing: gutter,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,

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

    return ListView.separated(
      itemCount: inactivePlayer.length,
      padding: const EdgeInsets.symmetric(horizontal: gutter),
      itemBuilder:
          (BuildContext context, int index) =>
              PlayerView(inactivePlayer[index]),
      separatorBuilder:
          (BuildContext context, int index) => const SizedBox(height: gutter),
    );
  }
}

class CourtGameView extends StatelessWidget {
  final List<Game> games;

  const CourtGameView(this.games, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: gutter),
      itemCount: games.length,

      itemBuilder:
          (BuildContext context, int index) =>
              GameView(players: games[index].players),
      separatorBuilder: (_, _) => const SizedBox(height: gutter),
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
