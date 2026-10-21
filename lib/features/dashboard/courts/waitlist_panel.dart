import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';

/// One entry of the [WaitlistPanel].
typedef WaitlistEntry = ({Player player, int roundsPlayed, bool nextIn});

/// The 280 px waitlist panel of the desktop Courts tab (IMPLEMENTATION
/// 8.5.5, ARCHITECTURE §2.4 WaitlistPanel; UAT WL-01, WL-04, NAV-07).
///
/// The header, the search field and the hint stay; the list under them
/// takes the rest of the height and scrolls (F12). With no [onSelect] the
/// entries are not buttons (F11).
class WaitlistPanel extends StatefulWidget {
  const WaitlistPanel({
    super.key,
    required this.entries,
    required this.hint,
    this.selectedPlayerId,
    this.onSelect,
  });

  /// In the waitlist order (WL-01); the panel shows no numbers (R3-Q12).
  final List<WaitlistEntry> entries;

  /// The selection hint, or "Courts change at the next round" (F11).
  /// `null` shows no hint.
  final String? hint;

  final String? selectedPlayerId;
  final void Function(Player player)? onSelect;

  static const double width = 280;

  @override
  State<WaitlistPanel> createState() => _WaitlistPanelState();
}

class _WaitlistPanelState extends State<WaitlistPanel> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Name or sign-in ID contains the text, case-insensitive (WL-04, PLY-04).
  bool _matches(Player player, String query) {
    if (query.isEmpty) return true;
    final name = player.name().toLowerCase();
    final id = (player.signInId ?? '').toLowerCase();
    return name.contains(query) || id.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _search.text.trim();
    final query = text.toLowerCase();
    final shown = [
      for (final entry in widget.entries)
        if (_matches(entry.player, query)) entry,
    ];

    final Widget list;
    if (widget.entries.isEmpty) {
      list = _Empty(l10n.dashboard_waitlist_empty);
    } else if (shown.isEmpty) {
      list = _Empty(l10n.courts_waitlist_no_match(text));
    } else {
      list = ListView.separated(
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final entry = shown[index];
          final onSelect = widget.onSelect;
          return WaitlistPanelItem(
            key: Key('waitlist-item-${entry.player.id}'),
            player: entry.player,
            roundsPlayed: entry.roundsPlayed,
            nextIn: entry.nextIn,
            isSelected: entry.player.id == widget.selectedPlayerId,
            onTap: onSelect == null ? null : () => onSelect(entry.player),
          );
        },
      );
    }

    return Semantics(
      container: true,
      label: l10n.dashboard_waitlist,
      explicitChildNodes: true,
      child: Container(
        width: WaitlistPanel.width,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: AppRadii.xlRadius,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(l10n.dashboard_waitlist, style: AppTypography.subtitle),
                const SizedBox(width: AppSpacing.sm),
                Text('${widget.entries.length}', style: AppTypography.md),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.courts_waitlist_search_label,
              style: AppTypography.statLabel,
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 40,
              child: TextField(
                key: const Key('waitlist-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: l10n.courts_waitlist_search_hint,
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.pageBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(color: AppColors.controlBorder),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(color: AppColors.controlBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.mdRadius,
                    borderSide: BorderSide(
                      color: AppColors.focusOnLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(widget.hint!, style: AppTypography.helper),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(child: list),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Text(
      text,
      style: AppTypography.body.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.textMuted,
      ),
    ),
  );
}

/// One 48 px waitlist entry: name over "{tier} · {n} rounds", and the
/// "Next in" tag (WL-01). Selected: 2 px `#c2410c` outline (UX-21).
class WaitlistPanelItem extends StatefulWidget {
  const WaitlistPanelItem({
    super.key,
    required this.player,
    required this.roundsPlayed,
    required this.nextIn,
    required this.isSelected,
    required this.onTap,
  });

  final Player player;
  final int roundsPlayed;
  final bool nextIn;
  final bool isSelected;

  /// `null` while the live clock runs: not a button (F11).
  final VoidCallback? onTap;

  @override
  State<WaitlistPanelItem> createState() => _WaitlistPanelItemState();
}

class _WaitlistPanelItemState extends State<WaitlistPanelItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rounds = l10n.courts_waitlist_rounds_played(widget.roundsPlayed);
    final tier = widget.player.elo.skillTier.localizedLabel(l10n);
    final content = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: AppRadii.smRadius,
        border: widget.isSelected
            ? Border.all(color: AppColors.accentStrong, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.name(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.md,
                ),
                Text(
                  '$tier · $rounds',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sm,
                ),
              ],
            ),
          ),
          if (widget.nextIn)
            Text(
              l10n.courts_waitlist_next_in,
              style: AppTypography.smBold.copyWith(color: AppColors.success),
            ),
        ],
      ),
    );

    final onTap = widget.onTap;
    return Semantics(
      container: true,
      button: onTap != null,
      selected: widget.isSelected,
      label: l10n.courts_waitlist_item(widget.player.name(), rounds),
      child: ExcludeSemantics(
        child: onTap == null
            ? content
            : FocusRing(
                focused: _focused,
                color: AppColors.focusOnLight,
                radius: AppRadii.sm,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    onFocusChange: (value) => setState(() => _focused = value),
                    borderRadius: AppRadii.smRadius,
                    hoverColor: AppColors.surfaceHover,
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}
