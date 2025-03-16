import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
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
                      'Current Game',
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
                  child: const Text('Generate Game'),
                ),
              ),
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

class CurrentGameView extends StatelessWidget {
  const CurrentGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: gutter,
        vertical: gutter / 2,
      ),
      child: Column(
        spacing: gutter,
        children: gameData.currentMatches
            .map((game) => Flexible(child: GameView(players: game.players)))
            .toList(growable: false),
      ),
    );
  }
}
