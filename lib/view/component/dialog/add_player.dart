import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/view/component/button.dart';
import 'package:good_bad_board/view/component/dialog/toasts.dart';

/// The Add-player form, shown with `showDialog<Player>`.
///
/// The dialog closes itself and returns the new [Player] through the
/// `showDialog` future; the caller only reads that result. Callers must not
/// pop it themselves — `showDialog` puts this route on the **root** Navigator,
/// while a caller's own `BuildContext` inside the shell resolves to the
/// per-tab Navigator, so popping from there tears down the tab and leaves a
/// blank screen.
class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

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

  /// Why the new player cannot be added, or null when they can: the same
  /// name, or the same sign-in ID, as a player already listed.
  String? _duplicateMessage() {
    final l10n = AppLocalizations.of(context)!;
    final name = '$firstName $lastName'.toLowerCase();
    final listed = PlayerRepository.instance.listedPlayers().toList();
    final sameName = listed.firstWhereOrNull(
      (p) => p.name().trim().toLowerCase() == name,
    );
    if (sameName != null) {
      return l10n.players_already_exists(sameName.name());
    }
    final id = signInId?.toLowerCase();
    if (id == null) return null;
    final sameId = listed.firstWhereOrNull(
      (p) => p.signInId?.trim().toLowerCase() == id,
    );
    if (sameId == null) return null;
    return l10n.players_sign_in_id_taken(signInId!, sameId.name());
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
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.players_enter_first_name;
                }
                firstName = value.trim();
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
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.players_enter_last_name;
                }
                lastName = value.trim();
                return null;
              },
            ),
            DropdownButtonFormField(
              initialValue: elo,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.elo,
              ),
              validator: (value) {
                if (value != null) return null;
                return AppLocalizations.of(context)!.players_select_elo;
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
                final trimmed = value?.trim() ?? '';
                signInId = trimmed.isEmpty ? null : trimmed;
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Button(
          key: const Key('add-player-cancel'),
          type: ButtonType.text,
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          // Closes with no player — the caller's `result` is null.
          onPressed: () => Navigator.of(context).pop(),
        ),
        Button(
          type: ButtonType.text,
          child: Text(AppLocalizations.of(context)!.reset),
          onPressed: () {
            resetForm();
          },
        ),
        Button(
          key: const Key('add-player-submit'),
          type: ButtonType.filled,
          onPressed: () {
            // Validate returns true if the form is valid, or false otherwise.
            if (!_formKey.currentState!.validate()) {
              context.showErrorToast(
                AppLocalizations.of(context)!.players_fill_all_fields,
              );
              return;
            }
            if (_duplicateMessage() case final message?) {
              context.showErrorToast(message);
              return;
            }
            // This context sits below the dialog route on the root Navigator,
            // so this pops the dialog — and only the dialog.
            Navigator.of(context).pop(
              Player.create(
                firstName: firstName!,
                lastName: lastName!,
                elo: elo!,
                signInId: signInId,
              ),
            );
          },
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
