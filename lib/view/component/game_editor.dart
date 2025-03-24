import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/inactive_player.dart';
import 'package:provider/provider.dart';

class CurrentGameView extends StatelessWidget {
  const CurrentGameView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    final numberOfTabs =
        gameData.history.length + (gameData.stagingMatches.isNotEmpty ? 1 : 0);
    // When history is not none and staging is empty, then show the history
    // Otherwise showing the staging
    return DefaultTabController(
      length: numberOfTabs,
      child: Scaffold(
        body: TabBarView(
          children: [
            ...gameData.history.map((game) => StagingGameComponent(game)),
            if (gameData.stagingMatches.isNotEmpty)
              StagingGameComponent(gameData.stagingMatches),
          ],
        ),
        bottomNavigationBar: TabBar(
          onTap: (index) {
            print(index);
            final bool isStagingView = index > (gameData.history.length - 1);
            if (isStagingView) {
              gameData.currentView = gameData.stagingMatches;
            } else {
              gameData.currentView = gameData.history[index];
            }
          },

          isScrollable: true,
          tabs: [
            ...gameData.history.mapIndexed(
              (i, game) => Tab(text: 'Game ${i + 1}'),
            ),
            if (gameData.stagingMatches.isNotEmpty)
              const Tab(text: 'Current Game'),
          ],
        ),
      ),
    );
  }
}
