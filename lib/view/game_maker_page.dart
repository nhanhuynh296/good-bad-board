import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:good_bad_board/view/component/game_editor.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:good_bad_board/view/component/timer.dart';
import 'package:provider/provider.dart';

class GameMakerPage extends StatefulWidget {
  const GameMakerPage({super.key});

  @override
  State<GameMakerPage> createState() => _GameMakerPageState();
}

class _GameMakerPageState extends State<GameMakerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    final timerData = Provider.of<TimerData>(context, listen: false);
    final gameDuration = PersistentSetting.instance.getGameDuration();
    controller = AnimationController(vsync: this, duration: gameDuration)
      ..value = timerData.elapsed.inMilliseconds / gameDuration.inMilliseconds;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final gameType = context.select(
      (PersistentSetting setting) => setting.getGameType(),
    );
    final generateActive = gameData.stagingMatches.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (controller.status != AnimationStatus.forward) {
              return Navigator.of(context).pop();
            }

            final result = await showAdaptiveDialog<bool>(
              context: context,
              builder: (_) => const ConfirmExitDialog(),
            );

            if (result == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          AppLocalizations.of(
            context,
          )!.game_number(gameData.history.length + 1),
          style: context.textTheme.titleLarge,
        ),
        actions: [const AutoMakeNextGameIconButton()],
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
                  if (gameType == GameType.timeBased) ...[
                    CountdownTimer(
                      controller: controller,
                      onExpired: () {
                        if (PersistentSetting.instance.getAutoMakeGame()) {
                          try {
                            gameData
                              ..saveCurrentGame()
                              ..makeGame();
                          } catch (e) {
                            if (context.mounted) {
                              context.showErrorToast(e.toString());
                            }
                          }
                        }
                      },
                    ),
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
                      key: ObjectKey(gameData.stagingMatches),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: spacePageX,
          vertical: space16,
        ),
        height: space64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: spaceDefault,
          children: [
            Expanded(
              child: Button(
                type: generateActive ? ButtonType.outlined : ButtonType.filled,
                onPressed: () async {
                  if (controller.isForwardOrCompleted) {
                    showAdaptiveDialog(
                      barrierDismissible: true,
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.game_is_currently_running,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Regenerating the game will not count these games towards the history.",
                              ),
                              Text(
                                "This will lead to some player will be on court more than other players!",
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            Button(
                              type: ButtonType.text,
                              child: Text(AppLocalizations.of(context)!.cancel),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            Button(
                              type: ButtonType.filled,
                              child: Text(
                                AppLocalizations.of(context)!.regenerate_game,
                              ),
                              onPressed: () {
                                controller.stop();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  try {
                    await gameData.makeGame();
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorToast(e.toString());
                    }
                    return;
                  }
                },
                child: Text(
                  generateActive
                      ? AppLocalizations.of(context)!.regenerate_game
                      : AppLocalizations.of(context)!.generate_game,
                ),
              ),
            ),
            if (generateActive)
              Expanded(
                flex: 2,
                child: Button(
                  type: ButtonType.filled,
                  onPressed: () async {
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
                    if (controller.isDismissed) {
                      final result = await showAdaptiveDialog<bool?>(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Game is not running"),
                            content: const Text(
                              "Do you sure to save the game without running timer?",
                            ),
                            actions: [
                              Button(
                                type: ButtonType.text,
                                child: Text(
                                  AppLocalizations.of(context)!.cancel,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              Button(
                                type: ButtonType.filled,
                                child: Text(AppLocalizations.of(context)!.save),
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                              ),
                            ],
                          );
                        },
                      );

                      if (result != true) {
                        return;
                      }
                    }
                    try {
                      await Future.wait([
                        gameData.saveCurrentGame(),
                        controller.animateBack(0, duration: Durations.short3),
                      ]);
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorToast(e.toString());
                      }
                      return;
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          context.showToast(AppLocalizations.of(context)!.coming_soon);
        },
        child: const Icon(Icons.apps),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniStartDocked,
    );
  }
}

class AutoMakeNextGameIconButton extends StatelessWidget {
  const AutoMakeNextGameIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (PersistentSetting setting) => setting.getAutoMakeGame(),
    );
    return ShadedContainer(
      shaded: false,
      bordered: selected,
      child: Button(
        type: ButtonType.text,
        icon: selected
            ? const Icon(Icons.queue_play_next)
            : const Icon(Icons.add_to_queue),
        child: Opacity(
          opacity: selected ? 1 : 0.5,
          child: Text(AppLocalizations.of(context)!.auto_game),
        ),

        onPressed: () {
          final newState = !selected;
          PersistentSetting.instance.setAutoMakeGame(newState);
          context.showToast(
            AppLocalizations.of(context)!.auto_make_game_is_status(
              newState
                  ? AppLocalizations.of(context)!.on
                  : AppLocalizations.of(context)!.off,
            ),
          );
        },
      ),
    );
  }
}

class CourtModifier extends StatelessWidget {
  const CourtModifier({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
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
        Text(
          AppLocalizations.of(context)!.n_court(gameData.numberOfCourt),
          style: textStyle,
        ),
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

class ConfirmExitDialog extends StatelessWidget {
  const ConfirmExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.are_you_sure_you_want_to_exit),
      content: const Text('Exit this screen will stop the timer.'),
      actions: [
        Button(
          type: ButtonType.text,
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        Button(
          type: ButtonType.filled,
          child: Text(AppLocalizations.of(context)!.ok),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
