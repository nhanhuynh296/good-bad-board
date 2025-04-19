import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
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
      body: Row(
        spacing: spaceXBetweenChip,
        children: [
          const Expanded(
            child: Column(
              spacing: spaceComponent,
              children: [
                CountdownTimer(),
                Divider(),
                Expanded(child: InactivePlayerComponent()),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              spacing: spaceDefault,
              mainAxisSize: MainAxisSize.min,
              children: [
                const CourtModifier(),
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

class CourtModifier extends StatelessWidget {
  const CourtModifier({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final StringBuffer buffer = StringBuffer('${gameData.numberOfCourt} Court');
    if (gameData.numberOfCourt > 1) {
      buffer.write('s');
    }
    final textStyle = Theme.of(context).textTheme.headlineSmall;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: space8,
      children: [
        IconButton.outlined(
          onPressed:
              () => gameData.setNumberOfCourt(gameData.numberOfCourt - 1),
          icon: const Icon(Icons.remove),
          iconSize: textStyle?.fontSize,
        ),
        Text(
          buffer.toString(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton.outlined(
          onPressed:
              () => gameData.setNumberOfCourt(gameData.numberOfCourt + 1),
          icon: const Icon(Icons.add),
          iconSize: textStyle?.fontSize,
        ),
      ],
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
              final error = gameData.makeGame();
              if (error != null) {
                showErrorToast(context, error);
                return;
              }
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
