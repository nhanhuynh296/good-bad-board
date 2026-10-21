import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/state/game_data.dart';

/// Draws the keyboard focus ring around [child]: 3 px, 2 px outside the
/// box (ARCHITECTURE §2.6, F07). It shows only for keyboard focus, never
/// after a pointer tap.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.focused,
    required this.color,
    required this.radius,
    required this.child,
  });

  final bool focused;

  /// `#ff6a2b` on the dark bars, `#c2410c` on light surfaces (F07).
  final Color color;

  /// The corner radius of [child]. The ring adds its offset to it.
  final double radius;

  final Widget child;

  static const double _width = 3;
  static const double _offset = 2;

  @override
  Widget build(BuildContext context) {
    final visible =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (visible)
          Positioned(
            left: -(_width + _offset),
            top: -(_width + _offset),
            right: -(_width + _offset),
            bottom: -(_width + _offset),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: _width),
                  borderRadius: BorderRadius.circular(
                    radius + _width + _offset,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One button on the Courts tab: a fill, a text colour, an optional border
/// and a focus ring (ARCHITECTURE §2.6). The variants are the factories.
class CourtsButton extends StatefulWidget {
  const CourtsButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.height,
    required this.background,
    required this.foreground,
    required this.ringColor,
    this.borderColor,
    this.icon,
    this.horizontalPadding = 16,
    this.semanticsLabel,
  });

  /// Orange primary on the round bar (44 px).
  const CourtsButton.barPrimary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : height = 44,
       background = AppColors.accentPrimary,
       foreground = AppColors.accentOnPrimary,
       ringColor = AppColors.focusOnDark,
       borderColor = null,
       horizontalPadding = 20,
       semanticsLabel = null;

  /// Outline on the round bar: 1 px `#c9c2b8`, white text (44 px).
  const CourtsButton.barOutline({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : height = 44,
       background = Colors.transparent,
       foreground = AppColors.headerText,
       ringColor = AppColors.focusOnDark,
       borderColor = AppColors.headerSub,
       horizontalPadding = 16,
       semanticsLabel = null;

  /// Text button on the round bar, e.g. "Pause" (44 px).
  const CourtsButton.barText({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : height = 44,
       background = Colors.transparent,
       foreground = AppColors.headerText,
       ringColor = AppColors.focusOnDark,
       borderColor = null,
       horizontalPadding = 16,
       semanticsLabel = null;

  /// Orange primary on the next-round strip (36 px).
  const CourtsButton.stripPrimary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : height = 36,
       background = AppColors.accentPrimary,
       foreground = AppColors.accentOnPrimary,
       ringColor = AppColors.focusOnLight,
       borderColor = null,
       icon = null,
       horizontalPadding = 16,
       semanticsLabel = null;

  /// Outline on the strip: 1 px `#6f6352`, `#fffdfa` fill (36 px).
  const CourtsButton.stripOutline({
    super.key,
    required this.label,
    required this.onPressed,
  }) : height = 36,
       background = AppColors.pageBg,
       foreground = AppColors.textPrimary,
       ringColor = AppColors.focusOnLight,
       borderColor = AppColors.controlBorder,
       icon = null,
       horizontalPadding = 12,
       semanticsLabel = null;

  /// Amber outline on the edit strip: "Discard & regenerate" (36 px).
  const CourtsButton.stripAmber({
    super.key,
    required this.label,
    required this.onPressed,
  }) : height = 36,
       background = Colors.transparent,
       foreground = AppColors.warningText,
       ringColor = AppColors.focusOnLight,
       borderColor = AppColors.warningText,
       icon = null,
       horizontalPadding = 12,
       semanticsLabel = null;

  /// Secondary on a court card: "Re-roll" (36 px, 1 px `#8f826e`).
  const CourtsButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticsLabel,
  }) : height = 36,
       background = AppColors.pageBg,
       foreground = AppColors.textPrimary,
       ringColor = AppColors.focusOnLight,
       borderColor = AppColors.controlBorderSoft,
       horizontalPadding = 12;

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color background;
  final Color foreground;
  final Color ringColor;
  final Color? borderColor;
  final IconData? icon;
  final double horizontalPadding;
  final String? semanticsLabel;

  @override
  State<CourtsButton> createState() => _CourtsButtonState();
}

class _CourtsButtonState extends State<CourtsButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.borderColor;
    final text = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: AppTypography.button.copyWith(color: widget.foreground),
    );
    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      button: widget.semanticsLabel != null,
      child: FocusRing(
        focused: _focused,
        color: widget.ringColor,
        radius: AppRadii.md,
        child: Material(
          color: widget.background,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdRadius,
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            borderRadius: AppRadii.mdRadius,
            child: Container(
              height: widget.height,
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: widget.foreground),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  text,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A square icon button with a focus ring: the round bar and slot "⋯", the
/// edit strip "×". The hit area is at least 40 × 40 (F27).
class CourtsIconButton extends StatefulWidget {
  const CourtsIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.ringColor,
    required this.tooltip,
    this.size = 40,
    this.iconSize = 20,
    this.focusNode,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color ringColor;
  final String tooltip;
  final double size;
  final double iconSize;

  /// Given by a menu anchor, so the focus goes back here when its menu
  /// closes (F06).
  final FocusNode? focusNode;

  @override
  State<CourtsIconButton> createState() => _CourtsIconButtonState();
}

class _CourtsIconButtonState extends State<CourtsIconButton> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CourtsIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.focusNode ?? _ownNode;
    if (old != _node) {
      old?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted && _focused != _node.hasFocus) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusRing(
      focused: _focused,
      color: widget.ringColor,
      radius: AppRadii.sm,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: IconButton(
          focusNode: _node,
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          padding: EdgeInsets.zero,
          iconSize: widget.iconSize,
          color: widget.color,
          style: IconButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.smRadius,
            ),
            minimumSize: Size.square(widget.size),
          ),
          icon: Icon(widget.icon),
        ),
      ),
    );
  }
}

/// A button on the round bar (ARCHITECTURE §2.3 RoundBar). Tests find the
/// state buttons by this type.
class RoundBarButton extends StatelessWidget {
  const RoundBarButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : _kind = _BarKind.primary,
       icon = null;

  const RoundBarButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
  }) : _kind = _BarKind.outline,
       icon = null;

  const RoundBarButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : _kind = _BarKind.text;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final _BarKind _kind;

  @override
  Widget build(BuildContext context) => switch (_kind) {
    _BarKind.primary => CourtsButton.barPrimary(
      label: label,
      onPressed: onPressed,
    ),
    _BarKind.outline => CourtsButton.barOutline(
      label: label,
      onPressed: onPressed,
    ),
    _BarKind.text => CourtsButton.barText(
      label: label,
      onPressed: onPressed,
      icon: icon,
    ),
  };
}

enum _BarKind { primary, outline, text }

/// The localised message for a failed Courts action. A [LineupError] gets
/// its own text; anything else gets one generic text, never its own
/// (R45-02).
String courtsErrorMessage(AppLocalizations l10n, Object error) =>
    switch (error) {
      NoCourts() => l10n.dashboard_error_no_courts,
      NotEnoughPlayers(:final count) => l10n.dashboard_error_not_enough_players(
        Game.playerPerCourt,
        count,
      ),
      UnbalancedCourts(:final courtNumbers) =>
        l10n.dashboard_error_unbalanced_courts(
          courtNumbers.length,
          courtNumbers.join(', '),
          Game.playerPerCourt,
        ),
      NothingToSave() => l10n.dashboard_error_nothing_to_save,
      _ => l10n.dashboard_error_generic,
    };

/// Shows [error] as a bottom message (ARCHITECTURE §2.8: errors only).
void showCourtsError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  if (messenger == null || l10n == null) return;
  messenger.showSnackBar(
    SnackBar(content: Text(courtsErrorMessage(l10n, error))),
  );
}

/// Runs [action] and shows its error, if any, as a bottom message.
Future<void> runCourtsAction(
  BuildContext context,
  Future<Object?> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) showCourtsError(context, error);
  }
}

/// Runs a round start that logs round n ([GameData.startNextNow],
/// [GameData.saveNextRound], [GameData.exitEditNext]). A failed write is
/// kept in [GameData.roundLogError], and the Courts page shows it once
/// (RND-06, R45-01), so the error is not shown here again.
void runRoundStart(Future<bool> Function() start) {
  start().then<void>((_) {}, onError: (Object _) {});
}
