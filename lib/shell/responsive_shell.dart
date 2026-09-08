import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/shell/bottom_tab_bar.dart';
import 'package:good_bad_board/shell/compact_header.dart';
import 'package:good_bad_board/shell/hamburger_menu.dart';
import 'package:good_bad_board/shell/more_bottom_sheet.dart';
import 'package:good_bad_board/shell/top_nav_bar.dart';

/// Metadata for a single navigation tab.
class TabInfo {
  const TabInfo({
    required this.label,
    required this.icon,
    required this.isPrimary,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
}

/// The responsive navigation shell that adapts to the current breakpoint.
///
/// Renders different navigation patterns based on available width:
/// - **Phone** (<720px): [CompactHeader] + page + [BottomTabBar]
///   with [HamburgerMenu] overlay and [MoreBottomSheet] for secondary tabs.
/// - **Tablet** (720–1079px): [TopNavBar] (stacked layout) + page.
/// - **Desktop** (≥1080px): [TopNavBar] (row layout) + page.
///
/// Designed to be used with [StatefulShellRoute.indexedStack] from go_router.
/// The [navigationShell] manages the indexed stack of tab pages.
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({
    super.key,
    required this.navigationShell,
    this.clubName = 'Riverside Badminton Club',
    this.clubNameCompact = 'Riverside BC',
    this.subtitle = '',
  });

  /// The navigation shell from go_router's StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  /// Club name displayed in the header (desktop/tablet).
  final String clubName;

  /// Abbreviated club name for phone header.
  final String clubNameCompact;

  /// Optional subtitle shown below the club name.
  final String subtitle;

  /// All 6 tab definitions in branch index order.
  /// Check-in functionality is now integrated into the Players tab (CHK-01…06).
  static const tabs = <TabInfo>[
    TabInfo(label: 'Dashboard', icon: Icons.grid_view_rounded, isPrimary: true),
    TabInfo(label: 'Players', icon: Icons.people_outline_rounded, isPrimary: true),
    TabInfo(label: 'Sessions', icon: Icons.tune_rounded, isPrimary: false),
    TabInfo(label: 'Schedule', icon: Icons.calendar_today_rounded, isPrimary: false),
    TabInfo(label: 'Analytics', icon: Icons.bar_chart_rounded, isPrimary: false),
    TabInfo(label: 'Settings', icon: Icons.settings_outlined, isPrimary: false),
  ];

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  bool _hamburgerOpen = false;
  bool _moreSheetOpen = false;
  int _previousIndex = -1;

  int get _selectedIndex => widget.navigationShell.currentIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = _selectedIndex;
  }

  @override
  void didUpdateWidget(ResponsiveShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _previousIndex) {
      _hamburgerOpen = false;
      _moreSheetOpen = false;
      _previousIndex = newIndex;
    }
  }

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(index);
  }

  void _onMoreTap() {
    setState(() => _moreSheetOpen = !_moreSheetOpen);
  }

  void _onSecondaryTabTap(int tabIndex) {
    setState(() => _moreSheetOpen = false);
    _onTabSelected(tabIndex);
  }

  void _onHamburgerTap() {
    setState(() => _hamburgerOpen = !_hamburgerOpen);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (isPhone(width)) {
          return _buildPhoneLayout();
        }
        return _buildDesktopTabletLayout(isDesktop(width));
      },
    );
  }

  // ── Phone Layout ──────────────────────────────────────────

  Widget _buildPhoneLayout() {
    final activeTab = ResponsiveShell.tabs[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompactHeader(
                clubName: widget.clubNameCompact,
                currentTabLabel: activeTab.label,
                showHamburger: true,
                onHamburgerTap: _onHamburgerTap,
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.phonePadding,
                  child: widget.navigationShell,
                ),
              ),
              _buildPhoneBottomBar(),
            ],
          ),
          // Overlays
          _buildHamburgerMenu(),
          _buildMoreSheet(),
        ],
      ),
    );
  }

  Widget _buildPhoneBottomBar() {
    final activeTabInfo = ResponsiveShell.tabs[_selectedIndex];
    final isSecondaryActive = !activeTabInfo.isPrimary;
    final bottomTabs = <BottomTab>[];

    // Primary tabs in order
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      if (!tab.isPrimary) continue;
      bottomTabs.add(BottomTab(
        label: _bottomBarLabel(tab.label),
        icon: tab.icon,
        isActive: _selectedIndex == i,
        onTap: () => _onTabSelected(i),
      ));
    }

    // "More" tab for secondary tabs
    bottomTabs.add(BottomTab(
      label: 'More',
      icon: Icons.more_horiz,
      isActive: isSecondaryActive,
      onTap: _onMoreTap,
    ));

    return BottomTabBar(tabs: bottomTabs);
  }

  String _bottomBarLabel(String fullLabel) {
    // Use abbreviated labels for the bottom bar
    switch (fullLabel) {
      case 'Dashboard':
        return 'Courts';
      case 'Players':
        return 'Players';
      default:
        return fullLabel;
    }
  }

  Widget _buildHamburgerMenu() {
    final hamburgerTabs = <HamburgerTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      hamburgerTabs.add(HamburgerTab(
        label: tab.label,
        isActive: _selectedIndex == i,
        onTap: () => _onTabSelected(i),
      ));
    }

    return HamburgerMenu(
      tabs: hamburgerTabs,
      isOpen: _hamburgerOpen,
      onClose: () => setState(() => _hamburgerOpen = false),
    );
  }

  Widget _buildMoreSheet() {
    final sheetTabs = <MoreSheetTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      if (tab.isPrimary) continue;
      sheetTabs.add(MoreSheetTab(
        label: tab.label,
        isActive: _selectedIndex == i,
        onTap: () => _onSecondaryTabTap(i),
      ));
    }

    return MoreBottomSheet(
      tabs: sheetTabs,
      isOpen: _moreSheetOpen,
      onClose: () => setState(() => _moreSheetOpen = false),
    );
  }

  // ── Desktop / Tablet Layout ───────────────────────────────

  Widget _buildDesktopTabletLayout(bool isDesktop) {
    final topTabs = <TopNavTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      topTabs.add(TopNavTab(
        label: tab.label,
        isActive: _selectedIndex == i,
        onTap: () => _onTabSelected(i),
      ));
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavBar(
            clubName: widget.clubName,
            subtitle: widget.subtitle,
            tabs: topTabs,
            isDesktop: isDesktop,
          ),
          Expanded(
            child: Padding(
              padding: isDesktop
                  ? AppSpacing.desktopPadding
                  : AppSpacing.tabletPadding,
              child: widget.navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}
