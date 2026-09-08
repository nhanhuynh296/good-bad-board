import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A single tab pill button for the navigation bar.
///
/// Two visual states:
/// - **Active**: accent background, onAccent text color
/// - **Inactive**: transparent background, headerSub text color
///
/// Used by [TopNavBar] and [HamburgerMenu] for tab navigation.
class AppTabButton extends StatelessWidget {
  const AppTabButton({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  /// The text label displayed on the tab.
  final String label;

  /// Whether this tab is the currently selected one.
  final bool isActive;

  /// Called when the tab is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          padding: AppSpacing.tabButtonPadding,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentPrimary : Colors.transparent,
            borderRadius: AppRadii.mdRadius,
          ),
          child: Text(
            label,
            style: AppTypography.tab.copyWith(
              color: isActive
                  ? AppColors.accentOnPrimary
                  : AppColors.headerSub,
            ),
          ),
        ),
      ),
    );
  }
}
