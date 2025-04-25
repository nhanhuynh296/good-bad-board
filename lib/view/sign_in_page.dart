import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/dto/player.dart';
import 'package:good_bad_board/global.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:good_bad_board/view/component/list_renderer.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:good_bad_board/view/component/reusable.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    final players = PlayerRepository.instance.getAllPlayers();

    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Padding(
        padding: pageSpacing,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          spacing: spaceCard,
          children: [
            const Expanded(child: PlayerList()),
            Expanded(
              child: AddPlayerDialog(
                onSubmit: (player) {
                  setState(() {
                    players.add(player);
                  });

                  PlayerRepository.instance.createPlayer(player);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerList extends StatefulWidget {
  const PlayerList({super.key});

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  String get query => textController.text.toUpperCase();
  Set<Elo> eloFilters = {};
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = PlayerRepository.instance.getAllPlayers();
    // if none is selected, show all of them
    final eloFilters = (this.eloFilters.isEmpty) ? Elo.values : this.eloFilters;
    final filteredPlayers =
        players
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
    final gameData = Provider.of<GameData>(context);
    final playerById = gameData.player.map((player) => player.id).toSet();

    return Column(
      spacing: spaceDefault,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: spaceComponent),
          child: SearchBar(
            controller: textController,
            hintText: 'Search for name, elo...',
            leading: query.isEmpty ? const Icon(Icons.search) : null,
            onChanged:
                (i) => setState(() {
                  /* The query changed. */
                }),
            trailing: [
              IconButton(
                onPressed: () {
                  textController.clear();
                },
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: spaceXBetweenChip,
          runSpacing: spaceXBetweenChip,
          children: Elo.values
              .map(
                (elo) => FilterChip(
                  label: Text(elo.toDisplayName()),
                  showCheckmark: false,
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
                  final isAlreadyInGame = playerById.contains(
                    filteredPlayers[index].id,
                  );
                  final player = filteredPlayers[index];
                  return Row(
                    children: [
                      Expanded(
                        key: ObjectKey(player),
                        child: ClickablePlayerComponent(
                          data: player,
                          filled: isAlreadyInGame,
                          onTap: () {
                            if (isAlreadyInGame) {
                              setState(() {
                                gameData.removePlayer(player);
                              });
                            } else {
                              setState(() {
                                gameData.addFullPricedPlayer(player);
                              });
                            }
                          },
                        ),
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
