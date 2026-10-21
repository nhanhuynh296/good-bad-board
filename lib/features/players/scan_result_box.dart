import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/players/scan_result.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// The scan result box under the scan field (ARCHITECTURE §2.5, UAT PLY-16).
///
/// It shows the last scan until the next scan; a row tap never changes it
/// (R3-Q3). Screen readers read it as a polite live region. The only action
/// is "Check out" in SCANNED TWICE (PLY-19); there is no Undo (R9-Q8).
class ScanResultBox extends StatelessWidget {
  const ScanResultBox({super.key, required this.result, this.onCheckOut});

  final ScanResult result;

  /// The "Check out" button of SCANNED TWICE.
  final VoidCallback? onCheckOut;

  static const double minHeight = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final look = _Look.of(result.kind);
    final (name, text) = _texts(l10n);
    return Semantics(
      container: true,
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: DecoratedBox(
          key: const Key('scan-result-decoration'),
          decoration: BoxDecoration(
            color: look.fill,
            borderRadius: AppRadii.lgRadius,
            border: Border.all(color: look.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: look.iconFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(look.icon, size: 16, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MergeSemantics(
                    child: Wrap(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: AppTypography.title.copyWith(color: look.text),
                        ),
                        Text(
                          text,
                          style: AppTypography.body.copyWith(
                            fontSize: AppTypography.sizeSubtitle,
                            color: look.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (result.kind == ScanKind.scannedTwice) ...[
                  const SizedBox(width: AppSpacing.md),
                  CourtsButton(
                    key: const Key('scan-result-check-out'),
                    label: l10n.players_scan_check_out,
                    onPressed: onCheckOut,
                    height: 36,
                    background: Colors.transparent,
                    foreground: look.text,
                    borderColor: look.text,
                    ringColor: AppColors.focusOnLight,
                    horizontalPadding: 14,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The name part (20/600) and the text part (16/400) of the box.
  (String, String) _texts(AppLocalizations l10n) {
    final name = result.player?.name() ?? '';
    return switch (result.kind) {
      ScanKind.ready => (
        l10n.players_scan_ready_title,
        l10n.players_scan_ready_body,
      ),
      ScanKind.checkedIn => (name, l10n.players_scan_in_waits(result.round)),
      ScanKind.checkedOut => (
        name,
        switch (result.fill) {
          final fill? => l10n.players_scan_out_takes(
            fill.player.name(),
            fill.courtIndex + 1,
            fill.round,
          ),
          null => l10n.players_scan_out,
        },
      ),
      ScanKind.scannedTwice => (name, l10n.players_scan_twice),
      ScanKind.notFound => (
        l10n.players_scan_not_found_title,
        l10n.players_scan_not_found(result.text),
      ),
      ScanKind.manyMatches => (
        l10n.players_scan_many_title(result.count),
        l10n.players_scan_many(result.text),
      ),
      ScanKind.sessionFull => (
        l10n.players_scan_full_title,
        l10n.players_scan_full(result.checkedIn, result.capacity, name),
      ),
      ScanKind.disabled => (name, l10n.players_scan_disabled_more),
      ScanKind.duplicateId => (
        l10n.players_scan_duplicate_title(result.text),
        l10n.players_scan_duplicate_body(result.count),
      ),
    };
  }
}

/// The colours and icon of one state (ARCHITECTURE §2.5 table).
class _Look {
  const _Look(this.fill, this.text, this.border, this.iconFill, this.icon);

  final Color fill;
  final Color text;
  final Color border;
  final Color iconFill;
  final IconData icon;

  static const _amberIcon = AppColors.accentStrong;

  static _Look of(ScanKind kind) => switch (kind) {
    ScanKind.ready => const _Look(
      AppColors.cardBg,
      AppColors.textMuted,
      AppColors.cardBorder,
      AppColors.textMuted,
      Icons.chevron_right_rounded,
    ),
    ScanKind.checkedIn => const _Look(
      AppColors.checkedInBg,
      AppColors.successText,
      AppColors.success,
      AppColors.success,
      Icons.check_rounded,
    ),
    ScanKind.checkedOut => const _Look(
      AppColors.neutralBg,
      AppColors.textPrimary,
      AppColors.controlBorder,
      AppColors.controlBorder,
      Icons.chevron_left_rounded,
    ),
    ScanKind.scannedTwice ||
    ScanKind.sessionFull ||
    ScanKind.duplicateId => const _Look(
      AppColors.warningBg,
      AppColors.warningText,
      AppColors.accentStrong,
      _amberIcon,
      Icons.priority_high_rounded,
    ),
    ScanKind.manyMatches => const _Look(
      AppColors.warningBg,
      AppColors.warningText,
      AppColors.accentStrong,
      _amberIcon,
      Icons.question_mark_rounded,
    ),
    ScanKind.notFound || ScanKind.disabled => const _Look(
      AppColors.errorBg,
      AppColors.errorText,
      AppColors.error,
      AppColors.error,
      Icons.close_rounded,
    ),
  };
}
