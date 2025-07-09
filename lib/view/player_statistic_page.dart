import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/reusable.dart';
import 'package:intl/intl.dart';

class PlayerStatisticPage extends StatefulWidget {
  const PlayerStatisticPage({super.key});

  @override
  State<PlayerStatisticPage> createState() => _PlayerStatisticPageState();
}

class _PlayerStatisticPageState extends State<PlayerStatisticPage> {
  List<Game> games = [];

  @override
  void initState() {
    super.initState();
    GameRepository.instance.getAll().then((value) {
      setState(() {
        games = value.toUnmodifiableList();
      });
    });
  }

  /// Most game played by player
  Widget mostGamePlayed(List<Game> games) {
    final players = getPlayerFromGames(games);

    final record = players.mostPopular();

    final playerNameOrNull = record?.$1
        .map((player) => player.name())
        .join('\n');

    return HighlightWidget(
      icon: Icons.star,
      title: 'Most game played: ${record?.$2}',
      subtitle: playerNameOrNull ?? 'N/a',
    );
  }

  /// Player came to most session (by date)
  Widget mostConsistent(List<Game> games) {
    // group by date
    final gamesGroupByDate = games.groupSetsBy(
      (game) => DateUtils.dateOnly(game.createdDate),
    );

    final uniquePlayersGroupByDate = gamesGroupByDate.map(
      (dateTime, game) => MapEntry(dateTime, getPlayerFromGames(game).toSet()),
    );

    final record = uniquePlayersGroupByDate.values.flattenedToList
        .mostPopular();

    final playerNameOrNull = record?.$1
        .map((player) => player.name())
        .join('\n');

    return HighlightWidget(
      icon: Icons.diversity_3_outlined,
      title: 'Most attended session: ${record?.$2}',
      subtitle: playerNameOrNull ?? 'N/a',
    );
  }

  Widget regularUser(List<Game> games) {
    return FutureBuilder(
      future: PlayerRepository.instance.getAll(),
      builder: (context, snapshot) {
        final player = switch (snapshot.connectionState) {
          ConnectionState.none ||
          ConnectionState.waiting ||
          ConnectionState.active => null,
          ConnectionState.done => snapshot.data!,
        };
        final activePlayer = getPlayerFromGames(games).toSet();

        return HighlightWidget(
          icon: Icons.diversity_3_outlined,
          title: 'Active player',
          subtitle: '${activePlayer.length}/${player?.length ?? "--"}',
        );
      },
    );
  }

  Widget placeholder() {
    return const HighlightWidget(
      icon: Icons.info_outline,
      title: 'To be implemented',
    );
  }

  @override
  Widget build(BuildContext context) {
    const double height = 200;
    return Scaffold(
      appBar: AppBar(title: const Text('PLAYER STATISTIC')),
      body: Container(
        padding: pageSpacing,
        child: Column(
          spacing: spaceComponent,
          children: [
            SizedBox(
              height: height * 2,
              child: OverviewPanel(
                maxCrossAxisExtent: height,
                children: [
                  mostGamePlayed(games),
                  mostConsistent(games),
                  regularUser(games),
                  ...Iterable.generate(3, (_) => placeholder()),
                ],
              ),
            ),
            // const Expanded(child: Placeholder()),
            if (games.isNotEmpty)
              Text('Games History', style: context.textTheme.titleLarge),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final game = games[index];
                  final players = game.players
                      .sortedBy<num>((player) => player.elo.index)
                      .map((e) => e.name());
                  return ListTile(
                    title: Text(players.join(', ')),
                    titleTextStyle: context.theme.textTheme.titleMedium,
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(game.createdDate),
                    ),

                    subtitleTextStyle: context.theme.textTheme.bodyMedium,
                  );
                },
                separatorBuilder: (_, _) => const Divider(height: space16),
                itemCount: games.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HighlightWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? caption;

  const HighlightWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        margin: const EdgeInsets.all(space16),
        child: Row(
          spacing: space16,
          children: [
            Icon(icon),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: space8,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  if (subtitle != null)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          subtitle!,
                          style: context.textTheme.titleLarge,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  ?caption,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OverviewPanel extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;

  const OverviewPanel({
    super.key,
    required this.children,
    required this.maxCrossAxisExtent,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      scrollDirection: Axis.horizontal,
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: 1 / goldenRatio,
      children: children,
    );
  }
}
