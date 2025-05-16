import 'package:flutter/material.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:provider/provider.dart';

class CurrentGameView extends StatelessWidget {
  const CurrentGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    if (gameData.stagingMatches.isEmpty) return const _BlankGame();

    return StagingGameComponent(gameData.stagingMatches);
  }
}

class _BlankGame extends StatelessWidget {
  const _BlankGame();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!;
    return Row(
      spacing: textStyle.fontSize!,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, size: textStyle.fontSize!),
        Text("Generate some game to start", style: textStyle),
      ],
    );
  }
}
