import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/core/importer.dart';
import 'package:good_bad_board/core/iterable_extension.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/container.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:good_bad_board/view/component/dialog/edit_player.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:good_bad_board/view/component/list_renderer.dart';
import 'package:good_bad_board/view/component/player.dart';
import 'package:good_bad_board/view/landing_page.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(context, backgroundColor: context.colorScheme.tertiary),
      body: Padding(
        padding: const EdgeInsets.all(space64),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          spacing: spaceCard,
          children: [
            if (context.breakpoint.largerThan('lg'))
              Expanded(child: buildMainSection(context)),
            Expanded(
              flex: context.breakpoint.largerThan('lg') ? 2 : 1,
              child: switch (index) {
                0 => const PlayerList(),
                1 => const AddPlayerDialog(),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        backgroundColor: context.colorScheme.tertiary,
        children: [const BackButtonBottomBar()],
      ),
    );
  }

  Widget buildMainSection(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.headlineLarge!.fontSize;
    return ShadedContainer(
      shaded: false,
      padding: const EdgeInsets.symmetric(
        horizontal: space64,
        vertical: space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: space64,
        children: [
          Text(
            "WELCOME BACK!",
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: space64,
            ),
          ),
          Expanded(
            child: Button(
              type: ButtonType.outlined,
              textStyle: TextStyle(fontSize: fontSize),
              onPressed: () => setState(() {
                index = 1;
              }),
              child: Padding(
                padding: const EdgeInsets.all(space8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: space32,
                  children: [
                    Icon(Icons.login, size: fontSize),
                    Text(
                      "Sign in",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Button(
              type: ButtonType.outlined,
              textStyle: TextStyle(fontSize: fontSize),
              child: Padding(
                padding: const EdgeInsets.all(space8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: space32,
                  children: [
                    Icon(Icons.person_add, size: fontSize),
                    Text(
                      AppLocalizations.of(context)!.add_player,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              onPressed: () => setState(() {
                index = 0;
              }),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildAddPlayerSection(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AddPlayerDialog(
          onSubmit: (player) {
            setState(() {
              PlayerRepository.instance.add(player);
            });
          },
        ),
        Button(
          type: ButtonType.filled,
          onPressed: () async {
            final records = await importFromCsv();
            if (!context.mounted) return;

            final existingPlayersName = {
              for (final player in gameData.players.values)
                player.name(): player,
            };

            // Todo ability to delete player row
            // Name in file should be unique
            final parsedNames = {
              for (final parsedName in records) parsedName.name(): parsedName,
            };
            if (parsedNames.length != records.length) {
              context.showErrorToast('Duplicate name found in file');
              return;
            }

            // Name should not have conflict, might need to rename or something
            final duplicateNames = parsedNames.keys.toSet().intersection(
              existingPlayersName.keys.toSet(),
            );
            if (duplicateNames.isNotEmpty) {
              context.showErrorToast(
                "Conflict name with existing player: ${duplicateNames.join(', ')}",
              );
              return;
            }

            // Player whose name not already are in the system
            final uniqueParsedPlayers = parsedNames.keys
                .whereNot(duplicateNames.contains)
                .map(
                  (playerName) => Player.create(
                    firstName: parsedNames[playerName]!.firstName,
                    lastName: parsedNames[playerName]!.lastName,
                    elo: parsedNames[playerName]!.elo ?? Elo.c2,
                  ),
                );

            final bool? confirmedSelection = await showAdaptiveDialog<bool?>(
              context: context,
              barrierDismissible: true,
              builder: (_) => PlayerBulkEdit(
                players: uniqueParsedPlayers.toList(growable: false),
              ),
            );
            if (confirmedSelection != true) return;

            setState(() {
              PlayerRepository.instance.addAll(uniqueParsedPlayers);
            });
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: space8,
            children: [Icon(Icons.upload_file), Text("Import from CSV")],
          ),
        ),
      ],
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
  late final searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void selectSearchText() {
    textController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final players = PlayerRepository.instance.getAllCachedPlayers();
    // if none is selected, show all of them
    final eloFilters = (this.eloFilters.isEmpty) ? Elo.values : this.eloFilters;
    final filteredPlayers = players
        .where(
          (player) =>
              eloFilters.contains(player.elo) &&
              (player.name().toUpperCase().contains(query) ||
                  player.elo.name.toUpperCase().contains(query) ||
                  (player.signInId?.toUpperCase().contains(query) ?? false)),
        )
        .sortedBy((player) => player.name())
        .toUnmodifiableList();
    final gameData = Provider.of<GameData>(context);
    final playingPlayers = gameData.players;

    Future<void> onSingleResultTapped(Player player) async {
      if (playingPlayers.containsKey(player.id)) {
        gameData.removePlayer(player);
      } else {
        gameData.addFullPricedPlayer(player);
      }
      searchFocusNode.requestFocus();
      selectSearchText();
    }

    return ShadedContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: space64,
        vertical: space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: space32,
        children: [
          Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) return;
              selectSearchText();
            },
            child: SearchBar(
              controller: textController,
              focusNode: searchFocusNode,
              hintText: 'Search for name, elo...',
              leading: query.isEmpty ? const Icon(Icons.search) : null,
              onChanged: (i) => setState(() {
                /* The query changed. */
              }),
              onSubmitted: (_) {
                final player = filteredPlayers.singleOrNull;
                if (player == null) {
                  searchFocusNode.requestFocus();
                  return;
                }
                onSingleResultTapped(player);
              },
              trailing: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      textController.clear();
                    });
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
          Expanded(
            child: ShadedContainer(
              shaded: false,
              child: (filteredPlayers.isNotEmpty)
                  ? ListRenderer(
                      key: ValueKey(query),
                      itemBuilder: (BuildContext context, int index) {
                        final isAlreadyInGame = playingPlayers.containsKey(
                          filteredPlayers[index].id,
                        );

                        final player = filteredPlayers[index];
                        return Row(
                          children: [
                            Expanded(
                              key: ObjectKey(player),
                              child: ClickablePlayerComponent(
                                inMatch: false,
                                data: player,
                                filled: isAlreadyInGame,
                                onTap: () {
                                  onSingleResultTapped(player);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                      items: filteredPlayers,
                    )
                  : Center(
                      child: Text(
                        'No player ${query.isEmpty ? 'added yet' : 'with that name, or elo'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
