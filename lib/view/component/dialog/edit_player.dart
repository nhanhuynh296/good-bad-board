import 'package:flutter/material.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/button.dart';

class EditPlayerDialog extends StatefulWidget {
  final Player player;
  final ValueChanged<Player>? onSubmit;

  const EditPlayerDialog({super.key, this.onSubmit, required this.player});

  @override
  State<EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late Elo elo;
  late String? signInId;

  @override
  void initState() {
    super.initState();
    name = widget.player.name;
    elo = widget.player.elo;
    signInId = widget.player.signInId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit player'),
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
              widget.player.copyWith(name: name, elo: elo, signInId: signInId),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}
