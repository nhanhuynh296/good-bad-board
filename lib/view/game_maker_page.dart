import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final result = await showAdaptiveDialog(
              context: context,
              builder: (_) => const ConfirmExitDialog(),
            );

            if (result == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "GAME ${gameData.history.length + 1}",
          style: context.textTheme.titleLarge,
        ),
        actions: const [SaveDataIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: spacePageX),
        child: Row(
          spacing: spaceDefault,
          children: [
            Expanded(
              child: Column(
                spacing: spaceComponent,
                children: [
                  if (PersistentSetting.instance.getGameType() ==
                      GameType.timeBased) ...[
                    const CountdownTimer(),
                    const Divider(),
                  ],
                  const Expanded(child: InactivePlayerComponent()),
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
      bottomNavigationBar: const BottomActionBar(),

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

class SaveDataIconButton extends StatefulWidget {
  const SaveDataIconButton({super.key});

  @override
  State<SaveDataIconButton> createState() => _SaveDataIconButtonState();
}

class _SaveDataIconButtonState extends State<SaveDataIconButton> {
  bool isSaving = false;

  void onPressed() async {
    setState(() {
      isSaving = true;
    });
    Stopwatch stopwatch = Stopwatch()..start();
    await Future.wait([
      GameRepository.instance.save(),
      PlayerRepository.instance.save(),
    ]);
    stopwatch.stop();
    setState(() {
      isSaving = false;
    });
    if (!mounted) return;

    context.showSnackBar(
      SnackBar(
        content: Text(
          'Data saved (took ${stopwatch.elapsed.inMilliseconds} milliseconds)',
        ),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isSaving ? null : onPressed,
      icon: const Icon(Icons.save),
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
          onPressed: () =>
              gameData.setNumberOfCourt(gameData.numberOfCourt - 1),
          icon: Icon(Icons.remove, size: textStyle?.fontSize),
        ),
        Text(buffer.toString(), style: textStyle),
        Button(
          type: ButtonType.outlined,
          onPressed: () =>
              gameData.setNumberOfCourt(gameData.numberOfCourt + 1),
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: spacePageX,
        vertical: space16,
      ),
      height: space64,
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: Text(
                  generateActive ? 'Re-Generate Game' : 'Generate Game',
                ),
              ),
            ),
            if (generateActive)
              Expanded(
                child: Button(
                  type: ButtonType.filled,
                  onPressed: () {
                    final invalidGames = gameData.stagingMatches.where(
                      (match) =>
                          match.players.isNotEmpty && !match.isPlayable(),
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
        ),
      ),
    );
  }
}

class ConfirmExitDialog extends StatelessWidget {
  const ConfirmExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text('Confirm Exit'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Exit this screen will stop the timer.'),
          Text('Are you sure you want to exit?'),
        ],
      ),
      actions: [
        Button(
          type: ButtonType.text,
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        Button(
          type: ButtonType.filled,
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
