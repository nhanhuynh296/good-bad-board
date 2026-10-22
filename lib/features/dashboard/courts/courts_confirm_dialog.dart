import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

/// Shows the one confirm dialog of the Courts tab (IMPLEMENTATION 8.5.6,
/// F14) and returns `true` when the organizer picks [actionLabel].
///
/// With [closeOnPhaseChange], a change of [GameData.phase] while the dialog
/// shows closes it with no action (F18, R12-Q1): "End round n now?",
/// "Discard round n?" and "End session?" use it.
Future<bool> showCourtsConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String cancelLabel,
  required String actionLabel,
  bool closeOnPhaseChange = true,
}) async {
  final gameData = closeOnPhaseChange ? context.read<GameData>() : null;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => CourtsConfirmDialog(
      title: title,
      body: body,
      cancelLabel: cancelLabel,
      actionLabel: actionLabel,
      watch: gameData,
    ),
  );
  return confirmed ?? false;
}

/// An alert dialog with a title and a description, initial focus on the
/// cancel button and Esc = cancel. It pops itself with its own context
/// (ARCHITECTURE §4.6), once: a second tap on a button does nothing, so a
/// double click never pops the page under it (R6-Q18).
class CourtsConfirmDialog extends StatefulWidget {
  const CourtsConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.actionLabel,
    this.watch,
  });

  final String title;
  final String body;
  final String cancelLabel;
  final String actionLabel;

  /// When set, a phase change closes the dialog with no action (F18).
  final GameData? watch;

  @override
  State<CourtsConfirmDialog> createState() => _CourtsConfirmDialogState();
}

class _CourtsConfirmDialogState extends State<CourtsConfirmDialog> {
  RoundPhase? _phase;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _phase = widget.watch?.phase;
    widget.watch?.addListener(_onGameData);
  }

  @override
  void dispose() {
    widget.watch?.removeListener(_onGameData);
    super.dispose();
  }

  void _onGameData() {
    if (widget.watch?.phase != _phase) _close(false);
  }

  void _close(bool result) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _close(false),
      },
      child: AlertDialog(
        key: const Key('courts-confirm-dialog'),
        backgroundColor: AppColors.pageBg,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlRadius),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
        title: Text(widget.title, style: AppTypography.title),
        content: Text(widget.body, style: AppTypography.body),
        actions: [
          OutlinedButton(
            key: const Key('courts-confirm-cancel'),
            autofocus: true,
            onPressed: () => _close(false),
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
            child: Text(widget.cancelLabel),
          ),
          FilledButton(
            key: const Key('courts-confirm-action'),
            onPressed: () => _close(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              textStyle: AppTypography.button,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.mdRadius,
              ),
            ),
            child: Text(widget.actionLabel),
          ),
        ],
      ),
    );
  }
}
