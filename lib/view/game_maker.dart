import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:good_bad_board/view/component/game_editor.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:provider/provider.dart';

class GameMaker extends StatelessWidget {
  const GameMaker({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Scaffold(
      body: Column(
        spacing: gutter,
        children: [
          Expanded(
            child: Row(
              spacing: gutter,
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
      floatingActionButton: IconButton.filled(
        onPressed: () {
          showAdaptiveDialog(
            context: context,
            builder: (_) => const AddPlayerDialog(),
          );
        },
        icon: const Icon(Icons.person_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
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
