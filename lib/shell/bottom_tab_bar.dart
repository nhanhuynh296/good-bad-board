import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A single tab entry used by [BottomTabBar].
class BottomTab {
  const BottomTab({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
}

/// A 3-tab bottom navigation bar for phone layouts.
///
/// Tabs: Courts (Dashboard), Players, More.
/// The "More" tab opens a bottom sheet showing secondary tabs
/// (Sessions, Schedule, Analytics, Settings).
///
/// Active tabs use the accent color; inactive tabs use [AppColors.textMuted].
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({
    super.key,
    required this.tabs,
  });

  /// The list of 4 tab definitions.
  final List<BottomTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pageBg,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final tab in tabs) Expanded(child: _BottomTabItem(tab: tab)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  const _BottomTabItem({required this.tab});

  final BottomTab tab;

  @override
  Widget build(BuildContext context) {
    final color = tab.isActive ? AppColors.accentPrimary : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tab.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: AppTypography.bottomTabLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
