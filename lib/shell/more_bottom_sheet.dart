import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A tab entry in the "More" bottom sheet.
class MoreSheetTab {
  const MoreSheetTab({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;
}

/// A slide-up bottom sheet for secondary tabs on phone layouts.
///
/// Appears when the user taps "More" in the [BottomTabBar].
/// Lists tabs that don't fit in the primary bottom bar:
/// Sessions, Schedule, Analytics, Settings.
///
/// Uses a semi-transparent backdrop and a rounded top panel
/// matching the design-spec bottom sheet style.
class MoreBottomSheet extends StatelessWidget {
  const MoreBottomSheet({
    super.key,
    required this.tabs,
    required this.isOpen,
    required this.onClose,
  });

  /// The secondary tab items to display.
  final List<MoreSheetTab> tabs;

  /// Whether the sheet is currently visible.
  final bool isOpen;

  /// Called when the user dismisses the sheet (backdrop tap or swipe).
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: AppColors.overlayBackdrop),
          ),
        ),
        // Sheet — anchored to bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: AppRadii.sheetTopRadius,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: _DragHandle(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Tab list
                  ...tabs.map(_buildSheetItem),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetItem(MoreSheetTab tab) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          tab.onTap?.call();
          onClose();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tab.label,
                  style: AppTypography.md.copyWith(
                    color: tab.isActive
                        ? AppColors.accentPrimary
                        : AppColors.textPrimary,
                    fontWeight:
                        tab.isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: tab.isActive
                    ? AppColors.accentPrimary
                    : AppColors.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The drag handle indicator at the top of a bottom sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.dragHandle,
        borderRadius: AppRadii.fullRadius,
      ),
    );
  }
}
