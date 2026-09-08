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

/// The top navigation bar shown on desktop and tablet.
///
/// **Desktop**: club name + subtitle + tab row in a single horizontal bar.
/// **Tablet**: club name on top, scrollable tab row below.
///
/// The [isDesktop] parameter is computed by the owning [ResponsiveShell]
/// and avoids duplicating breakpoint logic.
///
/// Uses the dark header background ([AppColors.headerBg]).
class TopNavBar extends StatelessWidget {
  const TopNavBar({
    super.key,
    this.clubName = 'Riverside Badminton Club',
    this.subtitle = '',
    required this.tabs,
    this.isDesktop = true,
  });

  /// The club name displayed as the header title.
  final String clubName;

  /// Optional subtitle text shown beside or below the club name.
  final String subtitle;

  /// The list of tab definitions to render.
  final List<TopNavTab> tabs;

  /// Whether to use the desktop layout (single row) versus tablet (stacked).
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
        child: isDesktop ? _buildDesktopRow() : _buildTabletColumn(),
      ),
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      children: [
        // Club name + subtitle
        Expanded(
          flex: 2,
          child: _ClubNameBlock(clubName: clubName, subtitle: subtitle),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Tab row
        Expanded(flex: 5, child: _TabRow(tabs: tabs)),
      ],
    );
  }

  Widget _buildTabletColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ClubNameBlock(clubName: clubName, subtitle: subtitle),
        const SizedBox(height: AppSpacing.sm),
        _TabRow(tabs: tabs),
      ],
    );
  }
}

/// The club name + subtitle block shown within the header.
class _ClubNameBlock extends StatelessWidget {
  const _ClubNameBlock({required this.clubName, required this.subtitle});

  final String clubName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(clubName, style: AppTypography.clubName),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.headerSubtitle),
        ],
      ],
    );
  }
}

/// The horizontal row of [AppTabButton] widgets, scrollable on tablet.
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
