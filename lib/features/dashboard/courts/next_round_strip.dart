import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_confirm_dialog.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

/// The next-round strip under the round bar (IMPLEMENTATION 8.5.3,
/// ARCHITECTURE §2.3 NextRoundStrip; UAT RND-05, RND-07, RND-10, RND-14,
/// RND-22).
///
/// [compact] is the phone and tablet form, a wrapping card (R2-Q23).
class NextRoundStrip extends StatelessWidget {
  const NextRoundStrip({super.key, this.compact = false});

  final bool compact;

  static const double height = 48;

  /// Whether the strip shows: in edit mode, in RUNNING and PAUSED, and in
  /// the changeover. Never in TIME UP (without edit mode), READY or with no
  /// lineup (R6-Q4).
  static bool showsFor(GameData gameData) {
    if (gameData.isEditingNext) return true;
    return switch (gameData.phase) {
      RoundPhase.running || RoundPhase.paused || RoundPhase.changeover => true,
      RoundPhase.noLineup || RoundPhase.ready || RoundPhase.timeUp => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    final l10n = AppLocalizations.of(context)!;
    final content = _stripContent(context, gameData, l10n);
    final background = gameData.isEditingNext
        ? AppColors.warningBg
        : AppColors.surfaceHover;
    final line = gameData.isEditingNext
        ? AppColors.accentStrong
        : AppColors.cardBorder;
    final title = Text(
      content.title,
      maxLines: compact ? null : 1,
      overflow: compact ? null : TextOverflow.ellipsis,
      style: AppTypography.md.copyWith(color: content.titleColour),
    );
    final text = content.text == null
        ? null
        : Text(
            content.text!,
            maxLines: compact ? null : 1,
            overflow: compact ? null : TextOverflow.ellipsis,
            style: AppTypography.body,
          );

    if (compact) {
      return Container(
        key: const Key('next-round-strip'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.xlRadius,
          border: Border.all(color: line),
        ),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [title, ?text, ...content.buttons],
        ),
      );
    }

    return Container(
      key: const Key('next-round-strip'),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          Flexible(flex: 0, child: title),
          if (text != null) ...[
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: text),
          ] else
            const Spacer(),
          for (final button in content.buttons) ...[
            const SizedBox(width: AppSpacing.md),
            button,
          ],
        ],
      ),
    );
  }

  _StripContent _stripContent(
    BuildContext context,
    GameData gameData,
    AppLocalizations l10n,
  ) {
    final phase = gameData.phase;
    final inChangeover =
        phase == RoundPhase.changeover ||
        (phase == RoundPhase.paused &&
            gameData.pausedFrom == RoundPhase.changeover);
    final live = gameData.roundNumber;
    final next = live + 1;

    if (gameData.isEditingNext) {
      // In the changeover the round bar already names the new round.
      final editNo = inChangeover ? gameData.displayRoundNumber : next;
      return _StripContent(
        title: l10n.courts_editing_round(editNo),
        titleColour: AppColors.warningText,
        buttons: [
          CourtsButton.stripAmber(
            label: l10n.courts_discard_and_regenerate,
            onPressed: gameData.regenerateNext,
          ),
          CourtsButton.stripPrimary(
            label: l10n.courts_save_round(editNo),
            onPressed: () => runRoundStart(gameData.saveNextRound),
          ),
          CourtsIconButton(
            key: const Key('edit-close-button'),
            icon: Icons.close_rounded,
            iconSize: 18,
            tooltip: l10n.courts_close_edit,
            color: AppColors.warningText,
            ringColor: AppColors.focusOnLight,
            onPressed: () => _close(context, gameData, l10n, editNo),
          ),
        ],
      );
    }

    if (inChangeover) {
      final discarded = gameData.discarded;
      return _StripContent(
        title: discarded
            ? l10n.courts_round_discarded(live)
            : l10n.courts_round_ended(live),
        titleColour: discarded ? AppColors.warningText : AppColors.success,
        buttons: const [],
      );
    }

    if (gameData.isNextRoundSaved) {
      return _StripContent(
        title: l10n.courts_next_saved(next),
        titleColour: AppColors.success,
        text: l10n.courts_next_starts_after(live),
        buttons: [
          CourtsButton.stripOutline(
            label: l10n.courts_edit_round(next),
            onPressed: gameData.editNextRound,
          ),
        ],
      );
    }

    return _StripContent(
      title: l10n.courts_next_not_saved(next),
      titleColour: AppColors.warningText,
      text: l10n.courts_next_clock_stops,
      buttons: [
        // RUNNING also offers the one-click save, no edit mode (R12-Q2).
        if (phase == RoundPhase.running)
          CourtsButton.stripPrimary(
            label: l10n.courts_save_round(next),
            onPressed: gameData.quickSaveNextRound,
          ),
        CourtsButton.stripOutline(
          label: l10n.courts_make_round(next),
          onPressed: gameData.makeNextRound,
        ),
      ],
    );
  }

  /// "×": asks "Close without saving?" only when the edit has changes
  /// (R11-Q2, F03).
  Future<void> _close(
    BuildContext context,
    GameData gameData,
    AppLocalizations l10n,
    int editNo,
  ) async {
    if (gameData.hasUnsavedEdits) {
      final confirmed = await showCourtsConfirm(
        context,
        title: l10n.courts_close_unsaved_title,
        body: l10n.courts_close_unsaved_body(editNo),
        cancelLabel: l10n.courts_keep_editing,
        actionLabel: l10n.courts_close_unsaved_close,
        closeOnPhaseChange: false,
      );
      if (!confirmed || !context.mounted) return;
    }
    runRoundStart(gameData.exitEditNext);
  }
}

class _StripContent {
  const _StripContent({
    required this.title,
    required this.titleColour,
    required this.buttons,
    this.text,
  });

  final String title;
  final Color titleColour;
  final String? text;
  final List<Widget> buttons;
}
