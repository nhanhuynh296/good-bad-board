import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
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
        title: Text(
          "GAME ${gameData.history.length + 1}",
          style: context.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final savedFile = await gameData.saveGame();
              if (!context.mounted) return;
              if (savedFile == null) return;
              final snackBar = SnackBar(
                content: Text('Game saved at ${savedFile.path}'),
                showCloseIcon: true,
              );
              context.showSnackBar(snackBar);
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: spacePageX),
        child: Row(
          spacing: spaceDefault,
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
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacePageX,
          vertical: spaceDefault,
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
      spacing: spaceDefault,
      children: [
        Button(
          type: ButtonType.outlined,
          onPressed:
              () => gameData.setNumberOfCourt(gameData.numberOfCourt - 1),
          icon: Icon(Icons.remove, size: textStyle?.fontSize),
        ),
        Text(buffer.toString(), style: textStyle),
        Button(
          type: ButtonType.outlined,
          onPressed:
              () => gameData.setNumberOfCourt(gameData.numberOfCourt + 1),
          icon: Icon(Icons.add, size: textStyle?.fontSize),
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
    final generateActive = gameData.stagingMatches.isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: spaceDefault,
      children: [
        Expanded(
          child: Button(
            type: generateActive ? ButtonType.outlined : ButtonType.filled,
            onPressed: () async {
              final error = await gameData.makeGame();
              if (!context.mounted) return;
              if (error != null) {
                context.showErrorToast(error);
                return;
              }
            },
            child: Text(generateActive ? 'Re-Generate Game' : 'Generate Game'),
          ),
        ),
        if (generateActive)
          Expanded(
            child: Button(
              type: ButtonType.filled,
              onPressed: () {
                final invalidGames = gameData.stagingMatches.where(
                  (match) => match.players.isNotEmpty && !match.isPlayable(),
                );
                if (invalidGames.isNotEmpty) {
                  context.showErrorToast(
                    'PLAYER IS NOT BALANCE ON COURT ${invalidGames.map((game) => gameData.stagingMatches.indexOf(game) + 1).join(', ')}',
                  );
                  return;
                }
                final errorOrNull = gameData.saveCurrentGame();
                if (errorOrNull != null) {
                  context.showErrorToast(errorOrNull);
                  return;
                }
              },
              child: const Text('Save'),
            ),
          ),
      ],
    );
  }
}
