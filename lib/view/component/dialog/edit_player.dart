import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/view/component/button.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.players_bulk_edit),
      actions: [
        Button(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        Button(
          type: ButtonType.filled,
          child: Text(AppLocalizations.of(context)!.done),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      content: Container(
        padding: const EdgeInsets.all(0),

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
                    columns: <DataColumn>[
                      DataColumn(
                        label: Text(
                          l10n.players_name,
                          style: AppTypography.smBold.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          l10n.elo,
                          style: AppTypography.smBold.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          l10n.sign_in_id,
                          style: AppTypography.smBold.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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
