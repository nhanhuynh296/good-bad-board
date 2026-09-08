import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A compact header bar used on phone layouts.
///
/// Displays the club name and current tab label on the left,
/// with an optional hamburger menu button on the right.
///
/// Dark background matching [AppColors.headerBg].
class CompactHeader extends StatelessWidget {
  const CompactHeader({
    super.key,
    this.clubName = 'Riverside BC',
    this.currentTabLabel = '',
    this.showHamburger = true,
    this.onHamburgerTap,
  });

  /// The club name (abbreviated for phone).
  final String clubName;

  /// Label for the currently active tab, shown below the club name.
  final String currentTabLabel;

  /// Whether to show the hamburger menu button.
  final bool showHamburger;

  /// Called when the hamburger button is tapped.
  final VoidCallback? onHamburgerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              // Club name + tab label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      clubName,
                      style: AppTypography.clubNameCompact,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentTabLabel.isNotEmpty)
                      Text(
                        currentTabLabel,
                        style: AppTypography.headerTabLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Hamburger button (optional)
              if (showHamburger)
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onHamburgerTap,
                      borderRadius: AppRadii.mdRadius,
                      child: const Icon(
                        Icons.menu,
                        color: AppColors.headerText,
                        size: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
