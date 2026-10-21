import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/shell/bottom_tab_bar.dart';
import 'package:good_bad_board/shell/compact_header.dart';
import 'package:good_bad_board/shell/hamburger_menu.dart';
import 'package:good_bad_board/shell/more_bottom_sheet.dart';
import 'package:good_bad_board/shell/top_nav_bar.dart';

/// Metadata for a single navigation tab.
class TabInfo {
  const TabInfo({
    required this.label,
    required this.localizedLabel,
    required this.icon,
    required this.isPrimary,
    this.localizedShortLabel,
  });

  /// The English label, kept as a stable identifier for the tab.
  ///
  /// Not displayed: the UI shows [localizedLabel] instead.
  final String label;

  /// Returns the label shown in the navigation for the active locale.
  final String Function(AppLocalizations l10n) localizedLabel;

  /// Returns the shorter label used in the phone bottom bar, when it
  /// differs from [localizedLabel].
  final String Function(AppLocalizations l10n)? localizedShortLabel;

  final IconData icon;
  final bool isPrimary;

  /// The label for the phone bottom bar.
  String bottomBarLabel(AppLocalizations l10n) =>
      (localizedShortLabel ?? localizedLabel)(l10n);
}

String _dashboardLabel(AppLocalizations l10n) => l10n.shell_tab_dashboard;
String _courtsLabel(AppLocalizations l10n) => l10n.shell_tab_courts;
String _playersLabel(AppLocalizations l10n) => l10n.shell_tab_players;
String _sessionsLabel(AppLocalizations l10n) => l10n.shell_tab_sessions;
String _analyticsLabel(AppLocalizations l10n) => l10n.shell_tab_analytics;
String _settingsLabel(AppLocalizations l10n) => l10n.settings;

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
  const ResponsiveShell({super.key, required this.navigationShell});

  /// The navigation shell from go_router's StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  /// All 5 tab definitions in branch index order.
  /// Check-in functionality is now integrated into the Players tab (CHK-01…06).
  static const tabs = <TabInfo>[
    TabInfo(
      label: 'Dashboard',
      localizedLabel: _dashboardLabel,
      localizedShortLabel: _courtsLabel,
      icon: Icons.grid_view_rounded,
      isPrimary: true,
    ),
    TabInfo(
      label: 'Players',
      localizedLabel: _playersLabel,
      icon: Icons.people_outline_rounded,
      isPrimary: true,
    ),
    TabInfo(
      label: 'Sessions',
      localizedLabel: _sessionsLabel,
      icon: Icons.tune_rounded,
      isPrimary: false,
    ),
    TabInfo(
      label: 'Analytics',
      localizedLabel: _analyticsLabel,
      icon: Icons.bar_chart_rounded,
      isPrimary: false,
    ),
    TabInfo(
      label: 'Settings',
      localizedLabel: _settingsLabel,
      icon: Icons.settings_outlined,
      isPrimary: false,
    ),
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
    final l10n = AppLocalizations.of(context)!;
    final activeTab = ResponsiveShell.tabs[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompactHeader(
                currentTabLabel: activeTab.localizedLabel(l10n),
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
    final l10n = AppLocalizations.of(context)!;
    final activeTabInfo = ResponsiveShell.tabs[_selectedIndex];
    final isSecondaryActive = !activeTabInfo.isPrimary;
    final bottomTabs = <BottomTab>[];

    // Primary tabs in order
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      if (!tab.isPrimary) continue;
      bottomTabs.add(
        BottomTab(
          label: tab.bottomBarLabel(l10n),
          icon: tab.icon,
          isActive: _selectedIndex == i,
          onTap: () => _onTabSelected(i),
        ),
      );
    }

    // "More" tab for secondary tabs
    bottomTabs.add(
      BottomTab(
        label: l10n.shell_more,
        icon: Icons.more_horiz,
        isActive: isSecondaryActive,
        onTap: _onMoreTap,
      ),
    );

    return BottomTabBar(tabs: bottomTabs);
  }

  Widget _buildHamburgerMenu() {
    final l10n = AppLocalizations.of(context)!;
    final hamburgerTabs = <HamburgerTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      hamburgerTabs.add(
        HamburgerTab(
          label: tab.localizedLabel(l10n),
          isActive: _selectedIndex == i,
          onTap: () => _onTabSelected(i),
        ),
      );
    }

    return HamburgerMenu(
      tabs: hamburgerTabs,
      isOpen: _hamburgerOpen,
      onClose: () => setState(() => _hamburgerOpen = false),
    );
  }

  Widget _buildMoreSheet() {
    final l10n = AppLocalizations.of(context)!;
    final sheetTabs = <MoreSheetTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      if (tab.isPrimary) continue;
      sheetTabs.add(
        MoreSheetTab(
          label: tab.localizedLabel(l10n),
          isActive: _selectedIndex == i,
          onTap: () => _onSecondaryTabTap(i),
        ),
      );
    }

    return MoreBottomSheet(
      tabs: sheetTabs,
      isOpen: _moreSheetOpen,
      onClose: () => setState(() => _moreSheetOpen = false),
    );
  }

  // ── Desktop / Tablet Layout ───────────────────────────────

  Widget _buildDesktopTabletLayout(bool isDesktop) {
    final l10n = AppLocalizations.of(context)!;
    final topTabs = <TopNavTab>[];
    for (var i = 0; i < ResponsiveShell.tabs.length; i++) {
      final tab = ResponsiveShell.tabs[i];
      topTabs.add(
        TopNavTab(
          label: tab.localizedLabel(l10n),
          isActive: _selectedIndex == i,
          onTap: () => _onTabSelected(i),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavBar(tabs: topTabs, isDesktop: isDesktop),
          Expanded(
            child: Padding(
              // The desktop Courts tab draws its own full-width round bar
              // under the nav (IMPLEMENTATION 8.5.1), so it gets no padding.
              padding: isDesktop
                  ? (_selectedIndex == 0
                        ? EdgeInsets.zero
                        : AppSpacing.desktopPadding)
                  : AppSpacing.tabletPadding,
              child: widget.navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}
