import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';
import 'package:provider/provider.dart';

class EditPlayerDialog extends StatefulWidget {
  final Player player;
  final ValueChanged<Player>? onSubmit;

  /// Whether to pop after removing the player from the session
  final bool persistAfterInactive;

  const EditPlayerDialog({
    super.key,
    this.onSubmit,
    required this.player,
    this.persistAfterInactive = false,
  });

  @override
  State<EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  late String firstName;
  late String lastName;
  late Elo elo;
  late String? signInId;

  @override
  void initState() {
    super.initState();
    firstName = widget.player.firstName;
    lastName = widget.player.lastName;
    elo = widget.player.elo;
    signInId = widget.player.signInId;
  }

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameData>(context);
    return AlertDialog(
      title: Row(
        spacing: spaceComponent,
        children: [
          Text('Edit player', style: context.textTheme.headlineMedium),
          const Spacer(),
          gameData.player.contains(widget.player)
              ? Button(
                  icon: Icon(
                    Icons.no_accounts,
                    color: context.colorScheme.surface,
                  ),
                  onPressed: () {
                    gameData.removePlayer(widget.player);
                    if (!widget.persistAfterInactive) {
                      Navigator.of(context).pop();
                    }
                  },
                  type: ButtonType.filled,
                  backgroundColor: context.colorScheme.onSurfaceVariant,
                  child: const Text("Break"),
                )
              : Button(
                  onPressed: () async {
                    final bool confirmDelete = await showAdaptiveDialog(
                      context: context,
                      builder: (context) => const ConfirmDeleteDialog(),
                    );
                    if (!context.mounted || !confirmDelete) return;
                    context.showToast("Player ${widget.player.name()} deleted");
                    Provider.of<GameData>(
                      context,
                      listen: false,
                    ).deletePlayer(widget.player);

                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete),
                  type: ButtonType.filled,
                  backgroundColor: context.colorScheme.errorContainer,
                ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          spacing: spaceDefault,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                firstName = value;
                return null;
              },
            ),
            TextFormField(
              initialValue: lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                lastName = value;
                return null;
              },
            ),
            DropdownButtonFormField(
              value: elo,
              decoration: const InputDecoration(labelText: 'Elo'),
              validator: (value) {
                if (value != null) return null;
                return 'Please select elo';
              },
              items: Elo.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (Elo? value) {
                if (value == null) return;
                elo = value;
              },
            ),
            TextFormField(
              initialValue: signInId,
              decoration: const InputDecoration(labelText: 'Sign In ID'),
              validator: (value) {
                signInId = value;
                return null;
              },
            ),
            TextFormField(
              initialValue: widget.player.id,
              enabled: false,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'ID'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Button(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Button(
          type: ButtonType.filled,
          onPressed: () {
            // Validate returns true if the form is valid, or false otherwise.
            if (!_formKey.currentState!.validate()) {
              return;
            }
            widget.onSubmit?.call(
              widget.player.copyWith(
                firstName: firstName,
                lastName: lastName,
                elo: elo,
                signInId: signInId,
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete player'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete this player?'),
          Text("This action can not be undone!"),
        ],
      ),
      actions: <Widget>[
        Button(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        Button(
          type: ButtonType.filled,
          backgroundColor: Theme.of(context).colorScheme.error,
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class PlayerBulkEdit extends StatefulWidget {
  final List<Player> players;

  const PlayerBulkEdit({super.key, required this.players});

  @override
  State<PlayerBulkEdit> createState() => _PlayerBulkEditState();
}

class _PlayerBulkEditState extends State<PlayerBulkEdit> {
  late final List<bool> selected;

  int editingIndex = -1;

  @override
  void initState() {
    super.initState();
    selected = List.filled(widget.players.length, false, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Bulk Edit"),
      actions: [
        Button(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        Button(
          type: ButtonType.filled,
          child: const Text("Done"),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      content: Container(
        padding: const EdgeInsets.all(0),

        // width: 450,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spaceComponent,
            children: [
              Center(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: spaceXBetweenChip,
                  runSpacing: spaceXBetweenChip,
                  children: Elo.values
                      .map(
                        (elo) => FilterChip(
                          label: Text(elo.toDisplayName()),
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() {
                              selected.forEachIndexed((index, boolean) {
                                if (!boolean) return;
                                widget.players[index] = widget.players[index]
                                    .copyWith(elo: elo);
                              });
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  primary: true,
                  padding: const EdgeInsets.symmetric(horizontal: spaceDefault),
                  child: DataTable(
                    border: TableBorder.all(),
                    showCheckboxColumn: true,
                    sortColumnIndex: 0,
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Name',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Elo',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      // DataColumn(
                      //   label: Text(
                      //     'Sign in ID',
                      //     style: TextStyle(fontStyle: FontStyle.italic),
                      //   ),
                      // ),
                    ],
                    rows: widget.players
                        .mapIndexed(
                          (index, player) => DataRow(
                            key: ObjectKey(player),
                            selected: selected[index],
                            cells: [
                              DataCell(Text(player.name())),
                              DataCell(Text(player.elo.name.toUpperCase())),
                              // DataCell(
                              //   (editingIndex == index)
                              //       ? TextFormField(
                              //         // initialValue: name,
                              //       )
                              //       : Text(player.signInId ?? '--'),
                              //   showEditIcon: true,
                              //   onTap:
                              //       () => setState(() {
                              //         editingIndex = index;
                              //       }),
                              // ),
                            ],
                            onSelectChanged: (value) => setState(() {
                              selected[index] = value!;
                            }),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
