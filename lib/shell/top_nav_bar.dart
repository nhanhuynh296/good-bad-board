import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A single tab entry used by [TopNavBar].
class TopNavTab {
  const TopNavTab({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;
}

/// The tablet top navigation bar: a scrollable row of the 5 tabs, kept as
/// before the 2026-10-17 design (R2-Q23, R6-Q7). The desktop uses
/// `DesktopTopNavBar` (IMPLEMENTATION 8.6.1).
///
/// [isDesktop] picks the larger padding; the shell passes `false`.
///
/// Uses the dark header background ([AppColors.headerBg]).
class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key, required this.tabs, this.isDesktop = true});

  /// The list of tab definitions to render.
  final List<TopNavTab> tabs;

  /// Whether to use desktop padding.
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final hPadding = isDesktop ? AppSpacing.lg : AppSpacing.md;
    final vPadding = isDesktop ? AppSpacing.md : AppSpacing.sm;

    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.headerBg,
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        child: _TabRow(tabs: tabs),
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.tabs});

  final List<TopNavTab> tabs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: AppTabButton(
                label: tab.label,
                isActive: tab.isActive,
                onTap: tab.onTap,
              ),
            ),
        ],
      ),
    );
  }
}
