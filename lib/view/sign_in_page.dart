import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:good_bad_board/view/component/list_renderer.dart';
import 'package:good_bad_board/view/component/reusable.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  List<Player> players = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Padding(
        padding: pageSpacing,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          spacing: spaceCard,
          children: [
            Expanded(
              child:
                  (players.isEmpty)
                      ? GestureDetector(
                        onTap: () async {
                          final loadedPlayers = await loadPlayersFromFile();
                          setState(() {
                            players = loadedPlayers;
                          });
                        },
                        child: const LandingPageOption(label: 'Load players'),
                      )
                      : PlayerList(players: players),
            ),
            const Expanded(child: AddPlayerDialog()),
          ],
        ),
      ),
    );
  }
}

class PlayerList extends StatefulWidget {
  final List<Player> players;

  const PlayerList({super.key, required this.players});

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  String query = '';
  Set<Elo> eloFilters = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if none is selected, show all of them
    final eloFilters = (this.eloFilters.isEmpty) ? Elo.values : this.eloFilters;
    final filteredPlayers =
        widget.players
            .where(
              (player) =>
                  eloFilters.contains(player.elo) &&
                  (player.name.toUpperCase().contains(query) ||
                      player.elo.name.toUpperCase().contains(query) ||
                      (player.signInId?.toUpperCase().contains(query) ??
                          false)),
            )
            .sortedBy((player) => player.name)
            .toList();
    return Column(
      spacing: spaceDefault,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: spaceComponent),
          child: SearchBar(
            hintText: 'Search for name, elo...',
            leading: query.isEmpty ? const Icon(Icons.search) : null,
            onChanged: (i) {
              setState(() {
                query = i.toUpperCase();
              });
            },
            trailing: [
              IconButton(
                onPressed: () {
                  query = '';
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Discard file',
              ),
            ],
          ),
        ),
        Wrap(
          spacing: spaceXBetweenChip,
          children: Elo.values
              .map(
                (elo) => FilterChip(
                  label: Text(elo.toDisplayName()),
                  selected: this.eloFilters.contains(elo),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        this.eloFilters.add(elo);
                      } else {
                        this.eloFilters.remove(elo);
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
        (filteredPlayers.isNotEmpty)
            ? Expanded(
              child: ListRenderer(
                itemBuilder: (BuildContext context, int index) {
                  final gameData = Provider.of<GameData>(
                    context,
                    listen: false,
                  );
                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          child: Text(filteredPlayers[index].toDisplayString()),
                        ),
                      ),
                      (gameData.player.contains(filteredPlayers[index]))
                          ? IconButton(
                            onPressed: () {
                              setState(() {
                                gameData.removePlayer(filteredPlayers[index]);
                              });
                            },
                            icon: const Icon(Icons.delete),
                          )
                          : IconButton(
                            onPressed: () {
                              setState(() {
                                gameData.addFullPricedPlayer(
                                  filteredPlayers[index],
                                );
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                    ],
                  );
                },
                items: filteredPlayers,
              ),
            )
            : Text(
              'No player with that name, or elo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      ],
    );
  }
}
