import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// The desktop check-in row of the Players tab (ARCHITECTURE §2.5
/// ScanField, IMPLEMENTATION 8.7.1): the "CHECK IN" scan field, the count
/// "{in} / {capacity} in" with "{n} places left", and the orange "Add
/// player" button. There is no capacity bar on desktop (R6-Q11).
class DesktopScanBar extends StatelessWidget {
  const DesktopScanBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onTapOutside,
    required this.onChanged,
    required this.checkedIn,
    required this.capacity,
    required this.remaining,
    required this.onAddPlayer,
    this.onImport,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Enter, or the done action: one scan (PLY-14).
  final VoidCallback onSubmitted;
  final VoidCallback onTapOutside;
  final VoidCallback onChanged;
  final int checkedIn;
  final int capacity;
  final int remaining;
  final VoidCallback onAddPlayer;

  /// The CSV import (hidden in the release build). No button when null.
  final VoidCallback? onImport;

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(
                  l10n.players_check_in_label,
                  style: AppTypography.statLabel,
                ),
              ),
              const SizedBox(height: 6),
              _ScanField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: onSubmitted,
                onTapOutside: onTapOutside,
                onChanged: onChanged,
                label: l10n.players_check_in_label,
                hint: l10n.players_scan_placeholder,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        SizedBox(
          key: const Key('players-count'),
          width: 140,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$checkedIn',
                      style: AppTypography.display.copyWith(
                        height: 1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        l10n.players_count_in(capacity),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontSize: AppTypography.sizeSubtitle,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.players_places_left(remaining),
                  style: AppTypography.sm,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        if (onImport != null) ...[
          CourtsButton(
            label: l10n.players_import,
            onPressed: onImport,
            height: height,
            background: AppColors.pageBg,
            foreground: AppColors.textPrimary,
            borderColor: AppColors.controlBorder,
            ringColor: AppColors.focusOnLight,
            icon: Icons.upload_file_rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        CourtsButton(
          key: const Key('players-add-player'),
          label: l10n.players_add_player,
          onPressed: onAddPlayer,
          height: height,
          background: AppColors.accentPrimary,
          foreground: AppColors.accentOnPrimary,
          ringColor: AppColors.focusOnLight,
          horizontalPadding: 20,
        ),
      ],
    );
  }
}

/// The 52 px scan field: 2 px `#6f6352` border, radius 10, white fill, a
/// scan icon, 20/600 text, and a 3 px `#c2410c` ring while it has focus.
class _ScanField extends StatelessWidget {
  const _ScanField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onTapOutside,
    required this.onChanged,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final VoidCallback onTapOutside;
  final VoidCallback onChanged;
  final String label;
  final String hint;

  static const _border = OutlineInputBorder(
    borderRadius: AppRadii.lgRadius,
    borderSide: BorderSide(color: AppColors.controlBorder, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: const Key('players-scan-field'),
      controller: controller,
      focusNode: focusNode,
      onSubmitted: (_) => onSubmitted(),
      onTapOutside: (_) => onTapOutside(),
      onChanged: (_) => onChanged(),
      textAlignVertical: TextAlignVertical.center,
      style: AppTypography.title,
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        constraints: const BoxConstraints.tightFor(
          height: DesktopScanBar.height,
        ),
        isDense: true,
        filled: true,
        fillColor: AppColors.white,
        hintText: hint,
        hintStyle: AppTypography.title.copyWith(
          fontWeight: AppTypography.regular,
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 12),
          child: Icon(
            Icons.qr_code_scanner_rounded,
            size: 22,
            color: AppColors.textMuted,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border,
      ),
    );
    return Semantics(
      label: label,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        // A scanner sends Enter after the ID. Some platforms deliver it as
        // the key, others as the done action; the page handles both.
        onKeyEvent: (_, event) {
          // Enter confirms an IME composition; it is not a scan.
          final composing = controller.value.composing;
          if (composing.isValid && !composing.isCollapsed) {
            return KeyEventResult.ignored;
          }
          final isEnter =
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter;
          if (isEnter && event is KeyDownEvent) {
            onSubmitted();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ListenableBuilder(
          listenable: focusNode,
          builder: (context, child) => Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (focusNode.hasFocus)
                const Positioned(
                  left: -5,
                  top: -5,
                  right: -5,
                  bottom: -5,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: Key('players-scan-focus-ring'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.focusOnLight, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          child: field,
        ),
      ),
    );
  }
}
