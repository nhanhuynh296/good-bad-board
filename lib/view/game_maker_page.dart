import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/game_editor.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:good_bad_board/view/component/timer.dart';
import 'package:provider/provider.dart';

class GameMakerPage extends StatelessWidget {
  const GameMakerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [
          IconButton(
            onPressed: () async {
              final savedFile = await gameData.saveGame();
              if (savedFile == null) return;
              final snackBar = SnackBar(
                content: Text('Game saved at ${savedFile.path}'),
                showCloseIcon: true,
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        spacing: spaceComponent,
        children: [
          const CountdownTimer(),
          Expanded(
            child: Row(
              spacing: spaceXBetweenChip,
              children: [
                const Expanded(child: InactivePlayerComponent()),
                Expanded(
                  flex: 2,
                  child: Column(
                    spacing: spaceDefault,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${gameData.numberOfCourt} Court(s)',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Expanded(
                        child: CurrentGameView(
                          key: ValueKey(gameData.stagingMatches.isEmpty),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.symmetric(
          vertical: spaceDefault,
          horizontal: spacePageX,
        ),
        child: BottomActionBar(),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          const snackBar = SnackBar(
            content: Text('To be Implemented'),
            duration: Durations.extralong4,
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        },
        child: const Icon(Icons.apps),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniStartDocked,
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context, listen: true);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: spaceDefault,
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              gameData.makeGame();
            },
            child: Text(
              gameData.stagingMatches.isEmpty
                  ? 'Generate Game'
                  : 'Re-Generate Game',
            ),
          ),
        ),
        if (gameData.stagingMatches.isNotEmpty)
          Expanded(
            child: FilledButton(
              onPressed: () {
                gameData.saveCurrentGame();
              },
              child: const Text('Save'),
            ),
          ),
      ],
    );
  }
}
