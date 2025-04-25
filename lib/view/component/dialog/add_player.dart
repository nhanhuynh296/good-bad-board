import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/button.dart';

class AddPlayerDialog extends StatefulWidget {
  final ValueChanged<Player>? onSubmit;

  const AddPlayerDialog({super.key, this.onSubmit});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  String? name;
  Elo? elo;
  String? signInId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Player'),
      content: Form(
        key: _formKey,
        child: Column(
          spacing: spaceDefault,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter name';
                }
                name = value;
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
          ],
        ),
      ),
      actions: <Widget>[
        Button(
          type: ButtonType.text,
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
            Navigator.of(context).pop();

            widget.onSubmit?.call(
              Player(name: name!, elo: elo!, signInId: signInId),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
