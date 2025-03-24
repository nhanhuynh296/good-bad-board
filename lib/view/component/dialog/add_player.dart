import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late Elo elo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Player'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                name = value;
                return null;
              },
            ),
            DropdownButtonFormField(
              items: Elo.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(growable: false),
              onChanged: (Elo? value) {
                if (value == null) return;
                elo = value;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: () {
            // Validate returns true if the form is valid, or false otherwise.
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Provider.of<GameData>(
              context,
              listen: false,
            ).addFullPricedPlayer(Player(name: name, elo: elo));
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
