import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/shell/inset_focus_ring.dart';
import 'package:good_bad_board/shell/top_nav_bar.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// The 56 px desktop top nav (IMPLEMENTATION 8.6.1, ARCHITECTURE §2.1
/// TopNavBar; UAT NAV-01, NAV-09).
///
/// At the left, two lines: "Session" over "{duration} rounds" (R3-Q5,
/// F29). At the right, the [tabs] (Courts, Players, Sessions) and a "⋯"
/// button whose menu lists the [menuTabs] (Analytics, Settings, R2-Q13).
/// The tablet keeps [TopNavBar] (R6-Q7).
class DesktopTopNavBar extends StatelessWidget {
  const DesktopTopNavBar({
    super.key,
    required this.tabs,
    required this.menuTabs,
  });

  final List<TopNavTab> tabs;
  final List<TopNavTab> menuTabs;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        color: AppColors.headerBg,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SessionHeader(),
            const Spacer(),
            const SizedBox(width: 32),
            for (final (index, tab) in tabs.indexed) ...[
              if (index > 0) const SizedBox(width: 4),
              _NavTab(boxKey: Key('top-nav-tab-$index'), tab: tab),
            ],
            const SizedBox(width: 4),
            _MoreButton(tabs: menuTabs),
          ],
        ),
      ),
    );
  }
}

/// The 3 px orange underline of the active tab and the active "⋯" (UX-21).
const _activeLine = BoxDecoration(
  border: Border(bottom: BorderSide(color: AppColors.accentPrimary, width: 3)),
);

/// "Session" over "{duration} rounds" (NAV-01).
class _SessionHeader extends StatelessWidget {
  const _SessionHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Only a duration change rebuilds the header, not a clock tick.
    final duration = context.select<TimerData, Duration>((t) => t.duration);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.shell_session_title,
          style: AppTypography.md.copyWith(color: AppColors.headerText),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.shell_session_header(roundDurationText(l10n, duration)),
          style: AppTypography.helper.copyWith(color: AppColors.headerSub),
        ),
      ],
    );
  }
}

/// A round duration for the header: "10 min" in whole minutes, else
/// `m:ss` ("10:30") (NAV-01).
String roundDurationText(AppLocalizations l10n, Duration duration) {
  final seconds = duration.inSeconds.remainder(60);
  if (seconds == 0) return l10n.shell_duration_minutes(duration.inMinutes);
  return '${duration.inMinutes}:${seconds.toString().padLeft(2, '0')}';
}

class _NavTab extends StatefulWidget {
  const _NavTab({required this.boxKey, required this.tab});

  /// The key of the tab box that draws the underline.
  final Key boxKey;
  final TopNavTab tab;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    return Semantics(
      selected: tab.isActive,
      child: InkWell(
        onTap: tab.onTap,
        onFocusChange: (value) => setState(() => _focused = value),
        splashFactory: NoSplash.splashFactory,
        focusColor: Colors.transparent,
        hoverColor: AppColors.barBg,
        child: Container(
          key: widget.boxKey,
          decoration: tab.isActive ? _activeLine : null,
          child: InsetFocusRing(
            focused: _focused,
            ringKey: const Key('top-nav-focus-ring'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: Text(
                  tab.label,
                  style: AppTypography.body.copyWith(
                    color: tab.isActive
                        ? AppColors.headerText
                        : AppColors.headerSub,
                    fontWeight: tab.isActive
                        ? AppTypography.semibold
                        : AppTypography.regular,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "⋯": a menu with [tabs]; the active style while one of them is open
/// (NAV-09). Esc and a click outside close the menu, and the focus goes
/// back to the button.
class _MoreButton extends StatefulWidget {
  const _MoreButton({required this.tabs});

  final List<TopNavTab> tabs;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = widget.tabs.any((tab) => tab.isActive);
    return Container(
      key: const Key('top-nav-more'),
      decoration: active ? _activeLine : null,
      alignment: Alignment.center,
      child: courtsMenuAnchor(
        focusNode: _focusNode,
        items: [
          for (final tab in widget.tabs)
            (label: tab.label, onPressed: tab.onTap, danger: false),
        ],
        builder: (context, toggle) => Semantics(
          label: l10n.shell_more_menu,
          child: CourtsIconButton(
            icon: Icons.more_horiz_rounded,
            tooltip: l10n.shell_more_menu,
            color: active ? AppColors.headerText : AppColors.headerSub,
            ringColor: AppColors.focusOnDark,
            size: 44,
            focusNode: _focusNode,
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
