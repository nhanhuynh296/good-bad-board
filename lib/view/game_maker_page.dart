import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:good_bad_board/view/component/game_editor.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:good_bad_board/view/component/timer.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:provider/provider.dart';

class GameMakerPage extends StatefulWidget {
  const GameMakerPage({super.key});

  @override
  State<GameMakerPage> createState() => _GameMakerPageState();
}

class _GameMakerPageState extends State<GameMakerPage>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    final timerData = Provider.of<TimerData>(context, listen: false);
    final gameDuration = PersistentSetting.instance.getGameDuration();
    controller = AnimationController(vsync: this, duration: gameDuration)
      ..value = timerData.elapsed.inMilliseconds / gameDuration.inMilliseconds;
    switchToStagingGame();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void switchToStagingGame() {
    final gameData = Provider.of<GameData>(context, listen: false);
    final allGames = gameData.history.followedBy([gameData.stagingMatches]);
    setState(() {
      tabIndex = allGames.length - 1;
    });
  }

  AppBar _buildAppBar() {
    return Header(
      context,
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

          if (result == true && mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(AppLocalizations.of(context)!.game_number(tabIndex + 1)),
      actions: [
        const AutoMakeNextGameIconButton(),
        const _OpenHistoryDrawerButton(),
      ],
      backgroundColor: context.colorScheme.secondary,
    );
  }

  Widget _buildSwitchToStagingGameButton() {
    return Button(
      type: ButtonType.text,
      backgroundColor: Colors.transparent,
      rounded: false,
      icon: const Icon(Icons.history),
      onPressed: switchToStagingGame,
      child: Text(AppLocalizations.of(context)!.to_current_session),
    );
  }

  bool isViewingStagingGame() {
    final gameData = Provider.of<GameData>(context, listen: false);
    final allGames = gameData.history.followedBy([gameData.stagingMatches]);
    return tabIndex == allGames.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final gameType = context.select(
      (PersistentSetting setting) => setting.getGameType(),
    );
    final history = context.select((GameData data) => data.history);
    final stagingMatches = context.select(
      (GameData data) => data.stagingMatches,
    );

    final allGames = history.followedBy([stagingMatches]).toUnmodifiableList();

    return Scaffold(
      appBar: _buildAppBar(),
      endDrawer: Drawer(
        child: ListView.builder(
          itemCount: allGames.length,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () => setState(() => tabIndex = index),
              title: Text(
                AppLocalizations.of(context)!.game_number(index + 1),
                style: context.textTheme.titleLarge,
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: spacePageX,
          vertical: spacePageY,
        ),
        child: Row(
          spacing: spacePageY,
          children: [
            Expanded(
              child: Column(
                spacing: spacePageY,
                children: [
                  if (gameType == GameType.timeBased) ...[
                    CountdownTimer(
                      controller: controller,
                      onExpired: () {
                        if (PersistentSetting.instance.getAutoMakeGame()) {
                          try {
                            context.read<GameData>()
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
                  ],
                  isViewingStagingGame()
                      ? const Expanded(child: InactivePlayerComponent())
                      : const Text(
                          "Inactive Players is not available in history view",
                        ),
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
                    child: (allGames.elementAt(tabIndex).isEmpty)
                        ? const BlankGame()
                        : StagingGameComponent(allGames.elementAt(tabIndex)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildFooter(context),

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

  Widget buildFooter(BuildContext context) {
    final history = context.select((GameData data) => data.history);
    final stagingMatches = context.select(
      (GameData data) => data.stagingMatches,
    );
    final generateActive = stagingMatches.isNotEmpty;
    final allGames = history.followedBy([stagingMatches]).toUnmodifiableList();

    return BottomBar(
      backgroundColor: context.colorScheme.secondary,
      children: (isViewingStagingGame())
          ? [
              const Expanded(child: BackButtonBottomBar()),
              const Spacer(flex: 3),
              Expanded(
                flex: generateActive ? 1 : 5,
                child: ConstrainedBox(
                  constraints: BottomBar.buttonConstraint,
                  child: Button(
                    rounded: false,
                    type: ButtonType.text,
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
                                    style: context.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
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
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.regenerate_game,
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
                        await context.read<GameData>().makeGame();
                        setState(() {
                          tabIndex = allGames.length - 1;
                        });
                      } catch (e) {
                        if (context.mounted) {
                          context.showErrorToast(e.toString());
                        }
                        return;
                      }
                    },
                    backgroundColor: generateActive
                        ? Colors.transparent
                        : context.colorScheme.primary,
                    child: Text(
                      generateActive
                          ? AppLocalizations.of(context)!.regenerate_game
                          : AppLocalizations.of(context)!.generate_game,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: context.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              if (generateActive)
                Expanded(
                  flex: 4,
                  child: ConstrainedBox(
                    constraints: BottomBar.buttonConstraint,
                    child: Button(
                      type: ButtonType.text,
                      backgroundColor: context.colorScheme.primary,
                      rounded: false,
                      onPressed: () async {
                        final invalidGames = stagingMatches.where(
                          (match) =>
                              match.players.isNotEmpty && !match.isPlayable(),
                        );
                        if (invalidGames.isNotEmpty) {
                          context.showErrorToast(
                            'PLAYERS ARE NOT BALANCED ON COURT ${invalidGames.map((game) => stagingMatches.indexOf(game) + 1).join(', ')}',
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
                                    child: Text(
                                      AppLocalizations.of(context)!.save,
                                    ),
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
                          if (!context.mounted) return;
                          await Future.wait([
                            context.read<GameData>().saveCurrentGame(),
                            controller.animateBack(
                              0,
                              duration: Durations.short3,
                            ),
                          ]);
                          // The allGames.length is not updated for some reason, just use
                          setState(() {
                            tabIndex = allGames.length;
                          });
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showErrorToast(e.toString());
                          return;
                        }
                      },
                      child: Text(
                        AppLocalizations.of(context)!.save,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ]
          : [
              Expanded(
                child: ConstrainedBox(
                  constraints: BottomBar.buttonConstraint,
                  child: _buildSwitchToStagingGameButton(),
                ),
              ),
            ],
    );
  }
}

class _OpenHistoryDrawerButton extends StatelessWidget {
  const _OpenHistoryDrawerButton();

  @override
  Widget build(BuildContext context) {
    return Button(
      type: ButtonType.text,
      rounded: false,
      icon: const Icon(Icons.history),
      textStyle: Header.getHeaderButtonTextStyle(context),
      child: Text(AppLocalizations.of(context)!.history),
      onPressed: () {
        Scaffold.of(context).openEndDrawer();
      },
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

    final textStyle = Header.getHeaderButtonTextStyle(context);
    return Button(
      type: selected ? ButtonType.filled : ButtonType.text,
      shaded: false,
      rounded: false,
      icon: selected
          ? const Icon(Icons.queue_play_next)
          : const Icon(Icons.add_to_queue),
      textStyle: textStyle?.copyWith(
        color: selected
            ? null
            : textStyle.color?.withAlpha(
                ((textStyle.color?.a ?? 1) * 255.0 / 2.0).toInt(),
              ),
      ),

      onPressed: () {
        final newState = !selected;
        PersistentSetting.instance.setAutoMakeGame(newState);
        context.showToast(
          AppLocalizations.of(context)!.auto_game_status(
            newState
                ? AppLocalizations.of(context)!.on
                : AppLocalizations.of(context)!.off,
          ),
        );
      },
      child: Text(AppLocalizations.of(context)!.auto_game),
    );
  }
}

class CourtModifier extends StatelessWidget {
  const CourtModifier({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final backgroundColor = context.colorScheme.secondary;
    final iconTextStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: context.colorScheme.onPrimary,
      fontWeight: FontWeight.bold,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: spaceDefault,
      children: [
        Button(
          type: ButtonType.outlined,
          rounded: false,
          backgroundColor: backgroundColor,
          onPressed: () =>
              gameData.setNumberOfCourt(gameData.numberOfCourt - 1),
          icon: const Icon(Icons.remove),
          textStyle: iconTextStyle,
        ),
        Text(
          AppLocalizations.of(context)!.n_court(gameData.numberOfCourt),
          style: iconTextStyle?.copyWith(color: backgroundColor),
        ),
        Button(
          type: ButtonType.outlined,
          rounded: false,
          backgroundColor: backgroundColor,
          onPressed: () =>
              gameData.setNumberOfCourt(gameData.numberOfCourt + 1),
          icon: const Icon(Icons.add),
          textStyle: iconTextStyle,
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
