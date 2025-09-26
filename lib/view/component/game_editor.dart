import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:provider/provider.dart';

class CurrentGameView extends StatelessWidget {
  final GameContainer games;

  const CurrentGameView({super.key, required this.games});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final stagingMatches = context.select(
      (GameData gameData) => gameData.stagingMatches,
    );
    if (stagingMatches.isEmpty) return const BlankGame();
    return StagingGameComponent(gameData.stagingMatches);
  }
}

class BlankGame extends StatelessWidget {
  const BlankGame({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!;
    return Row(
      spacing: textStyle.fontSize!,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, size: textStyle.fontSize!),
        Text(
          AppLocalizations.of(context)!.generate_some_game_to_start,
          style: textStyle,
        ),
      ],
    );
  }
}
