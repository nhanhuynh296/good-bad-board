import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Asks the organizer to confirm before a running round is thrown away.
///
/// Returns `true` when the organizer confirms, `false` on Cancel or when the
/// dialog is dismissed. Shared by the Dashboard (Regenerate, Re-roll) and the
/// Sessions tab (court count, Load).
Future<bool> confirmDiscard(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
