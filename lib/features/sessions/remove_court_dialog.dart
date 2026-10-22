import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Shows "Remove which court?" (R13-Q9) and returns the 0-based index of the
/// court to remove, or `null` on Cancel or Esc.
///
/// [playerCounts] has one entry per court: the number of players on it.
Future<int?> showRemoveCourtDialog(
  BuildContext context, {
  required List<int> playerCounts,
}) => showDialog<int>(
  context: context,
  builder: (_) => RemoveCourtDialog(playerCounts: playerCounts),
);

/// The court picker for "−" on the Sessions tab (R13-Q9). It follows the
/// confirm pattern (F14): an alert dialog with a title and a description,
/// initial focus on "Cancel", and Esc = "Cancel". The last court is
/// selected first. It pops itself once, so a double click never pops the
/// page under it (R6-Q18).
class RemoveCourtDialog extends StatefulWidget {
  const RemoveCourtDialog({super.key, required this.playerCounts});

  final List<int> playerCounts;

  @override
  State<RemoveCourtDialog> createState() => _RemoveCourtDialogState();
}

class _RemoveCourtDialogState extends State<RemoveCourtDialog> {
  late int _selected = widget.playerCounts.length - 1;
  bool _closed = false;

  void _close(int? result) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _close(null),
      },
      child: AlertDialog(
        key: const Key('remove-court-dialog'),
        backgroundColor: AppColors.pageBg,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
        title: Text(
          l10n.sessions_remove_court_title,
          style: AppTypography.title,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.sessions_remove_court_body, style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (index, count) in widget.playerCounts.indexed)
                        _CourtOption(
                          key: Key('remove-court-option-$index'),
                          label: l10n.sessions_remove_court_option(
                            index + 1,
                            count,
                          ),
                          selected: index == _selected,
                          onTap: () => setState(() => _selected = index),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            key: const Key('remove-court-cancel'),
            autofocus: true,
            onPressed: () => _close(null),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: AppColors.textPrimary,
              backgroundColor: AppColors.pageBg,
              side: const BorderSide(color: AppColors.controlBorder),
              textStyle: AppTypography.button,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.mdRadius,
              ),
            ),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('remove-court-action'),
            onPressed: () => _close(_selected),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              textStyle: AppTypography.button,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.mdRadius,
              ),
            ),
            child: Text(l10n.sessions_remove_court_action),
          ),
        ],
      ),
    );
  }
}

/// One court in the picker: a 44 px row with a check mark when selected.
class _CourtOption extends StatelessWidget {
  const _CourtOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.accentStrong,
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? AppTypography.body.copyWith(
                          fontWeight: AppTypography.semibold,
                        )
                      : AppTypography.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
