import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:intl/intl.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class PlayerStatisticPage extends StatefulWidget {
  const PlayerStatisticPage({super.key});

  @override
  State<PlayerStatisticPage> createState() => _PlayerStatisticPageState();
}

class _PlayerStatisticPageState extends State<PlayerStatisticPage> {
  DateTime? startTime;

  DateTime endTime = DateTime.now();

  List<Game> allGames = List.empty();
  List<Game> games = List.empty();

  @override
  void initState() {
    super.initState();
    GameRepository.instance.getAll().then((value) {
      allGames = value.toUnmodifiableList();
      onFilterDayChanged();
    });
  }

  void onFilterDayChanged() {
    setState(() {
      games = allGames
          .where((game) => game.players.isNotEmpty)
          .where(
            (game) =>
                (startTime == null || game.createdDate.isAfter(startTime!)) &&
                game.createdDate.isBefore(endTime),
          )
          .sortedBy((game) => game.createdDate)
          .reversed
          .toUnmodifiableList();
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
      icon: Icons.star_outline,
      title:
          '${AppLocalizations.of(context)!.most_games_played}: ${record?.$2}',
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
      title:
          '${AppLocalizations.of(context)!.most_sessions_attended}: ${record?.$2}',
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
          title: AppLocalizations.of(context)!.active_player,
          caption: Text('${activePlayer.length}/${player?.length ?? "--"}'),
        );
      },
    );
  }

  Widget leastActiveUser(List<Game> games) {
    final now = DateTime.now();
    final playerLastPlayed = {
      for (var k in games.map((game) => game.players).flattenedToSet)
        k: Duration.zero,
    };
    for (var game in games) {
      for (var player in game.players) {
        if (!playerLastPlayed.containsKey(player)) continue;
        final lastPlayedDuration = playerLastPlayed[player]!;
        final lastPlayedNewDuration = now.difference(game.createdDate);

        if (lastPlayedDuration > lastPlayedNewDuration) continue;
        playerLastPlayed[player] = lastPlayedNewDuration;
      }
    }

    final neverPlayed = playerLastPlayed.entries
        .where((entry) => entry.value == Duration.zero)
        .map((entry) => entry.key.name())
        .toUnmodifiableList();

    if (neverPlayed.isNotEmpty) {
      return HighlightWidget(
        icon: Icons.person_off_outlined,
        title: 'Player never played',
        caption: ListView.builder(
          itemCount: neverPlayed.length,
          itemBuilder: (context, i) => Text(neverPlayed[i]),
        ),
      );
    }

    final leastActive = playerLastPlayed.entries
        .where((entry) => entry.value != Duration.zero)
        .sortedBy((entry) => entry.value)
        .reversed;

    return HighlightWidget(
      icon: Icons.person_off_outlined,
      title:
          'Player quit: (${leastActive.map((entry) => entry.value).lastOrNull?.inDays ?? "--"}+ days ago)',
      caption: ListView.builder(
        itemCount: leastActive.length,
        itemBuilder: (context, i) => Text(leastActive.elementAt(i).key.name()),
      ),
    );
  }

  Widget totalGames(List<Game> games) {
    return HighlightWidget(
      icon: Icons.info,
      title: 'Total games ',
      caption: Text(
        games.length.toString(),
        textAlign: TextAlign.left,
        style: TextStyle(
          color: context.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: context.colorScheme.primary,
    );
  }

  Widget placeholder() {
    return HighlightWidget(
      icon: Icons.warning_amber_rounded,
      title: AppLocalizations.of(context)!.coming_soon,
      caption: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          4,
          (_) => const Icon(Icons.construction_rounded, size: 64),
        ).toUnmodifiableList(),
      ),
    );
  }

  String dateToString(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final startTimeText = startTime == null
        ? AppLocalizations.of(context)!.the_beginning
        : dateToString(startTime!);
    final endTimeText = DateUtils.isSameDay(DateTime.now(), endTime)
        ? AppLocalizations.of(context)!.today
        : dateToString(endTime);
    final headerTextStyle = context.textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: context.colorScheme.onSurface,
    );
    return Scaffold(
      appBar: Header(context, backgroundColor: context.colorScheme.primary),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: space64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: spaceDefault,
          children: [
            IntrinsicHeight(
              child: Row(
                spacing: space8,
                children: [
                  Text("Overview", style: headerTextStyle),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.player_statistic,
                    style: context.textTheme.titleLarge,
                  ),
                  Text("from", style: context.textTheme.titleLarge),
                  Button(
                    padding: EdgeInsets.zero,
                    child: Text(
                      startTimeText,
                      style: context.textTheme.titleLarge,
                    ),
                    onPressed: () async {
                      final result = await showDatePicker(
                        context: context,
                        initialDate: startTime,
                        firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                        lastDate: DateTime.now(),
                      );
                      if (result == null) return;
                      startTime = result;
                      onFilterDayChanged();
                    },
                  ),
                  Text("to", style: context.textTheme.titleLarge),
                  Button(
                    padding: EdgeInsets.zero,
                    child: Text(
                      endTimeText,
                      style: context.textTheme.titleLarge,
                    ),
                    onPressed: () async {
                      final result = await showDatePicker(
                        context: context,
                        initialDate: endTime,
                        firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                        lastDate: DateTime.now(),
                      );
                      if (result == null) return;
                      endTime = result;
                      onFilterDayChanged();
                    },
                  ),
                  VerticalDivider(
                    thickness: space16,
                    width: BottomBar.border.width,
                    color: context.colorScheme.secondary,
                  ),
                ],
              ),
            ),
            StaggeredGridView.count(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              crossAxisCount: 6,
              mainAxisSpacing: space32,
              crossAxisSpacing: space32,
              staggeredTiles: const [
                StaggeredTile.count(1, 1),
                StaggeredTile.count(2, 1),
                StaggeredTile.count(2, 1),
                StaggeredTile.count(1, 2),
                StaggeredTile.count(2, 1),
                StaggeredTile.count(1, 1),
                StaggeredTile.count(2, 1),
              ],
              children: [
                totalGames(allGames),
                mostGamePlayed(games),
                mostConsistent(games),
                Button(
                  type: ButtonType.outlined,
                  backgroundColor: context.colorScheme.tertiary,

                  padding: const EdgeInsets.all(space32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.game_history,
                        style: headerTextStyle,
                      ),
                      Expanded(
                        child: SvgPicture.asset("asset/image/hour-glass.svg"),
                      ),
                    ],
                  ),
                ),
                placeholder(),
                regularUser(games),
                leastActiveUser(allGames),
              ],
            ),
            // const Expanded(child: Placeholder()),
            // if (games.isNotEmpty)
            //   Text(
            //     AppLocalizations.of(context)!.game_history,
            //     style: context.textTheme.titleLarge,
            //   ),
            // Expanded(
            //   child: ListView.separated(
            //     itemBuilder: (context, index) {
            //       final game = games[index];
            //       final players = game.players
            //           .sortedBy<num>((player) => player.elo.index)
            //           .map((e) => e.name());
            //       return ListTile(
            //         title: Text(players.join(', ')),
            //         titleTextStyle: context.theme.textTheme.titleMedium,
            //         subtitle: Text(
            //           DateFormat.yMMMd().add_jm().format(game.createdDate),
            //         ),
            //
            //         subtitleTextStyle: context.theme.textTheme.bodyMedium,
            //       );
            //     },
            //     separatorBuilder: (_, _) => const Divider(height: space16),
            //     itemCount: games.length,
            //   ),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        children: [BackButtonBottomBar()],
        backgroundColor: context.colorScheme.primary,
      ),
    );
  }
}

class HighlightWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? caption;
  final Color? backgroundColor;

  const HighlightWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.caption,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ShadedContainer(
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: space8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: space8,
            children: [
              Icon(icon),
              Text(title, style: context.textTheme.titleLarge),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (subtitle != null)
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        subtitle!,
                        style: context.textTheme.headlineLarge?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ),
                if (caption != null)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultTextStyle(
                        style:
                            (context.textTheme.headlineLarge ??
                                    const TextStyle())
                                .copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                        child: caption!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OverviewPanel extends StatelessWidget {
  final List<Widget> children;
  final double maxCrossAxisExtent;
  final double spacing;

  const OverviewPanel({
    super.key,
    required this.children,
    required this.maxCrossAxisExtent,
    this.spacing = spaceDefault,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      scrollDirection: Axis.horizontal,
      maxCrossAxisExtent: maxCrossAxisExtent,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 1 / goldenRatio,
      children: children,
    );
  }
}
