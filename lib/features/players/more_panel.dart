import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/courts/courts_button.dart';
import 'package:good_bad_board/features/players/player_profile_card.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/l10n/membership_l10n.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';

/// The desktop More panel, as drawn on the canvas board "Players · More
/// panel" (IMPLEMENTATION 8.7.6, R6-Q17). It opens under its row, in the
/// same rounded panel (UAT PLY-09).
///
/// Line 1: the sign-in ID field with Save (PLY-15), the level stepper with
/// the Elo code (PLY-05, R2-Q18), the membership control (PLY-06), delete
/// and close. Line 2: the stat tiles, partners and attendance (PLY-12).
/// No control here toggles the check-in.
class MorePanel extends StatelessWidget {
  const MorePanel({
    super.key,
    required this.player,
    required this.stats,
    required this.onLevelDown,
    required this.onLevelUp,
    required this.onMembership,
    required this.onDelete,
    required this.onClose,
    required this.onSaveSignInId,
  });

  final Player player;
  final PlayerProfileStats stats;
  final VoidCallback onLevelDown;
  final VoidCallback onLevelUp;

  /// A membership segment was picked. The page asks first when Disabled
  /// would check the player out.
  final ValueChanged<MembershipStatus> onMembership;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  /// Saves the typed sign-in ID. Returns an error message, or null when
  /// saved.
  final String? Function(String text) onSaveSignInId;

  static const double controlHeight = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.players_details(player.name()),
      child: ColoredBox(
        color: AppColors.pageBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SignInIdEditor(
                    key: ValueKey(player.id),
                    initialValue: player.signInId ?? '',
                    onSave: onSaveSignInId,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _Labelled(
                    label: l10n.players_header_level,
                    child: _LevelStepper(
                      elo: player.elo,
                      onDown: onLevelDown,
                      onUp: onLevelUp,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _Labelled(
                    label: l10n.players_membership_label,
                    child: _MembershipControl(
                      value: player.membership,
                      onPick: onMembership,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    // Lines the buttons up with the fields under the labels.
                    padding: const EdgeInsets.only(top: _Labelled.labelSpace),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SquareButton(
                          key: const Key('more-delete'),
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.error,
                          borderColor: AppColors.error,
                          tooltip: l10n.players_delete_named(player.name()),
                          onPressed: onDelete,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _SquareButton(
                          key: const Key('more-close'),
                          icon: Icons.close_rounded,
                          color: AppColors.textMuted,
                          tooltip: l10n.players_close_details,
                          onPressed: onClose,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatTile(
                    label: l10n.players_current_level,
                    value: player.elo.toDisplayName(),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _StatTile(
                    label: l10n.players_matches,
                    value: '${stats.matchCount}',
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _StatTile(
                    label: l10n.players_diversity,
                    value: '${stats.diversityPercent}%',
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _Section(
                      label: l10n.players_most_frequent_partners,
                      children: [
                        for (final partner in stats.topPartners)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  partner.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body,
                                ),
                              ),
                              Text(
                                '${partner.count}',
                                style: AppTypography.md.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _Section(
                      label: l10n.players_attendance,
                      children: [
                        Text(
                          stats.attendanceSummary,
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A caps label over a control.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  /// The label line and the gap under it.
  static const double labelSpace = 21;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: labelSpace - 6,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            style: AppTypography.statLabel,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// The sign-in ID field and its Save button (PLY-15). The field selects
/// all its text when it gets focus, so a card scanned into it by mistake
/// replaces the ID and shows (F30). The result shows under the field:
/// "Saved." or the refusal that names the player (F23).
class _SignInIdEditor extends StatefulWidget {
  const _SignInIdEditor({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  final String initialValue;
  final String? Function(String text) onSave;

  @override
  State<_SignInIdEditor> createState() => _SignInIdEditorState();
}

class _SignInIdEditorState extends State<_SignInIdEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final FocusNode _focus = FocusNode();
  String? _message;
  bool _saved = false;

  static const _border = OutlineInputBorder(
    borderRadius: AppRadii.mdRadius,
    borderSide: BorderSide(color: AppColors.controlBorder),
  );

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  /// A saved ID shows in the field; the "Saved." text stays.
  @override
  void didUpdateWidget(_SignInIdEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Selects all the text after the tap that gave focus has set its caret.
  void _onFocus() {
    if (!_focus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _save() {
    final error = widget.onSave(_controller.text);
    setState(() {
      _message = error;
      _saved = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = _saved ? l10n.players_id_saved : _message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Labelled(
          label: l10n.players_header_sign_in_id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('player-sign-in-id-field'),
                  controller: _controller,
                  focusNode: _focus,
                  onSubmitted: (_) => _save(),
                  onChanged: (_) {
                    if (_message != null || _saved) {
                      setState(() {
                        _message = null;
                        _saved = false;
                      });
                    }
                  },
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTypography.body.copyWith(
                    fontSize: AppTypography.sizeSubtitle,
                  ),
                  decoration: InputDecoration(
                    constraints: const BoxConstraints.tightFor(
                      height: MorePanel.controlHeight,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    hintText: l10n.sign_in_id,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: _border,
                    enabledBorder: _border,
                    focusedBorder: _border.copyWith(
                      borderSide: const BorderSide(
                        color: AppColors.focusOnLight,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CourtsButton(
                key: const Key('player-sign-in-id-save'),
                label: l10n.save,
                onPressed: _save,
                height: MorePanel.controlHeight,
                background: AppColors.pageBg,
                foreground: AppColors.textPrimary,
                borderColor: AppColors.controlBorder,
                ringColor: AppColors.focusOnLight,
              ),
            ],
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: SizedBox(
                width: 300,
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: _saved ? AppColors.successText : AppColors.error,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "−" "Intermediate (B1)" "+" (PLY-05). A dimmed button does nothing.
class _LevelStepper extends StatelessWidget {
  const _LevelStepper({
    required this.elo,
    required this.onDown,
    required this.onUp,
  });

  final Elo elo;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canDown = elo != Elo.values.first;
    final canUp = elo != Elo.values.last;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          buttonKey: const Key('more-level-down'),
          label: '−',
          semanticsLabel: l10n.players_lower_level,
          enabled: canDown,
          onPressed: onDown,
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                elo.skillTier.localizedLabel(l10n),
                style: AppTypography.subtitle,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(${elo.toDisplayName()})',
                style: AppTypography.body.copyWith(
                  fontSize: AppTypography.sizeSubtitle,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StepButton(
          buttonKey: const Key('more-level-up'),
          label: '+',
          semanticsLabel: l10n.players_raise_level,
          enabled: canUp,
          onPressed: onUp,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.label,
    required this.semanticsLabel,
    required this.enabled,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String semanticsLabel;
  final bool enabled;
  final VoidCallback onPressed;

  static void _doNothing() {}

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: CourtsButton(
        key: buttonKey,
        label: label,
        semanticsLabel: semanticsLabel,
        // A dimmed button takes the tap and does nothing (PLY-09).
        onPressed: enabled ? onPressed : _doNothing,
        height: MorePanel.controlHeight,
        background: AppColors.pageBg,
        foreground: AppColors.textPrimary,
        borderColor: AppColors.controlBorderSoft,
        ringColor: AppColors.focusOnLight,
        horizontalPadding: 14,
      ),
    );
  }
}

/// "Member / Casual / Disabled" in one 40 px segmented control (PLY-06).
class _MembershipControl extends StatelessWidget {
  const _MembershipControl({required this.value, required this.onPick});

  final MembershipStatus value;
  final ValueChanged<MembershipStatus> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MorePanel.controlHeight,
      decoration: BoxDecoration(
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.controlBorderSoft),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md - 1)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final status in MembershipStatus.values)
              Semantics(
                key: Key('more-membership-${status.name}'),
                inMutuallyExclusiveGroup: true,
                checked: status == value,
                button: true,
                child: Material(
                  color: status == value
                      ? AppColors.textPrimary
                      : AppColors.pageBg,
                  child: InkWell(
                    onTap: () => onPick(status),
                    child: Container(
                      height: MorePanel.controlHeight - 2,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      child: Text(
                        status.localizedLabel(l10n),
                        style: AppTypography.button.copyWith(
                          color: status == value
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 40 × 40 icon button: delete (red outline, F23) or close.
class _SquareButton extends StatefulWidget {
  const _SquareButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.borderColor,
  });

  final IconData icon;
  final Color color;
  final Color? borderColor;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<_SquareButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.borderColor;
    return Semantics(
      container: true,
      button: true,
      label: widget.tooltip,
      child: FocusRing(
        focused: _focused,
        color: AppColors.focusOnLight,
        radius: AppRadii.md,
        child: Material(
          color: border == null ? Colors.transparent : AppColors.pageBg,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdRadius,
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: AppRadii.mdRadius,
            child: SizedBox(
              width: MorePanel.controlHeight,
              height: MorePanel.controlHeight,
              child: Icon(widget.icon, size: 18, color: widget.color),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 160 × 64 stat tile: the value (20/600) over a caps label.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadii.mdRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTypography.title.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.statLabel,
          ),
        ],
      ),
    );
  }
}

/// A caps label over a short list (partners, attendance).
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        Text(label.toUpperCase(), style: AppTypography.statLabel),
        ...children,
      ],
    );
  }
}
