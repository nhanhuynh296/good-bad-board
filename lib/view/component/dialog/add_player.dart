import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/spacing.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';

class AddPlayerDialog extends StatefulWidget {
  final ValueChanged<Player>? onSubmit;

  const AddPlayerDialog({super.key, this.onSubmit});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  String? firstName;
  String? lastName;
  Elo? elo;
  String? signInId;

  void resetForm() {
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.add_player),
      content: Form(
        key: _formKey,
        child: Column(
          spacing: spaceDefault,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: firstName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.first_name,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter first name';
                }
                firstName = value;
                return null;
              },
            ),
            TextFormField(
              initialValue: lastName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.last_name,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter last name';
                }
                lastName = value;
                return null;
              },
            ),
            DropdownButtonFormField(
              value: elo,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.elo,
              ),
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.sign_in_id,
              ),
              textInputAction: TextInputAction.next,
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
          child: Text(AppLocalizations.of(context)!.reset),
          onPressed: () {
            resetForm();
          },
        ),
        Button(
          type: ButtonType.filled,
          onPressed: () {
            // Validate returns true if the form is valid, or false otherwise.
            if (!_formKey.currentState!.validate()) {
              context.showErrorToast('Please fill out all fields correctly.');
              return;
            }
            widget.onSubmit?.call(
              Player.create(
                firstName: firstName!,
                lastName: lastName!,
                elo: elo!,
                signInId: signInId,
              ),
            );
            resetForm();
          },
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
