import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A tab used in the hamburger menu overlay.
class HamburgerTab {
  const HamburgerTab({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;
}

/// Fullscreen dark overlay navigation for phone layouts.
///
/// Slides in from the right (or fades) with a semi-transparent backdrop.
/// Contains a "NAVIGATE" heading and a vertical list of all tab items.
///
/// Active tab: accent background, dark text.
/// Inactive tab: transparent background, white text.
class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({
    super.key,
    required this.tabs,
    required this.isOpen,
    required this.onClose,
  });

  /// The list of all tab items.
  final List<HamburgerTab> tabs;

  /// Whether the menu is currently visible.
  final bool isOpen;

  /// Called when the user taps the backdrop or a close action to dismiss.
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
            child: Container(color: AppColors.overlayBackdropLighter),
          ),
        ),
        // Menu panel
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: 280,
          child: Container(
            color: AppColors.headerBg,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: "NAVIGATE" label + close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NAVIGATE',
                          style: AppTypography.helperBold.copyWith(
                            color: AppColors.headerSub,
                          ),
                        ),
                        SizedBox(
                          width: 38,
                          height: 38,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onClose,
                              borderRadius: AppRadii.mdRadius,
                              child: const Icon(
                                Icons.close,
                                color: AppColors.headerText,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: AppColors.darkCardBorder,
                    height: 1,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Tab list
                  ...tabs.map((tab) => _HamburgerItem(
                        label: tab.label,
                        isActive: tab.isActive,
                        onTap: () {
                          tab.onTap?.call();
                          onClose();
                        },
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HamburgerItem extends StatelessWidget {
  const _HamburgerItem({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accentPrimary : Colors.transparent,
              borderRadius: AppRadii.mdRadius,
            ),
            child: Text(
              label,
              style: AppTypography.md.copyWith(
                color: isActive
                    ? AppColors.accentOnPrimary
                    : AppColors.headerText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
