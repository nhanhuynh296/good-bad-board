import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/game_editor.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:good_bad_board/view/timer.dart';
import 'package:provider/provider.dart';

class GameMaker extends StatelessWidget {
  const GameMaker({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badminton Game Generator'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.save))],
      ),
      body: Column(
        spacing: gutter,
        children: [
          const CountdownTimer(),
          Expanded(
            child: Row(
              spacing: gutter / 2,
              children: [
                const Expanded(child: InactivePlayerComponent()),
                Expanded(
                  flex: 2,
                  child: Column(
                    spacing: gutter,
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
        padding: EdgeInsets.all(gutter),
        child: BottomActionBar(),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          final snackBar = SnackBar(
            content: const Text('To be Implemented'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
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
      spacing: gutter,
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
