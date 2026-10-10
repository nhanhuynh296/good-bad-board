import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/model/player.dart';

/// Row with [−] button, ELO value display, and [+] button for adjusting a
/// player's skill level.
///
/// Buttons are disabled at tier boundaries:
/// - Minus disabled at [Elo.c2] (lowest tier)
/// - Plus disabled at [Elo.s1] (highest tier)
///
/// Disabled buttons render at 35% opacity per the design spec.
class LevelAdjuster extends StatelessWidget {
  const LevelAdjuster({
    super.key,
    required this.currentLevel,
    required this.onDecrease,
    required this.onIncrease,
  });

  final Elo currentLevel;

  /// Called when the [−] button is tapped. Not called when the button is
  /// disabled (already at the lowest tier).
  final VoidCallback onDecrease;

  /// Called when the [+] button is tapped. Not called when the button is
  /// disabled (already at the highest tier).
  final VoidCallback onIncrease;

  bool get _canDecrease => currentLevel != Elo.values.first;
  bool get _canIncrease => currentLevel != Elo.values.last;

  static const _levelTextStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.accentPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AdjustButton(label: '−', enabled: _canDecrease, onTap: onDecrease),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 82,
          child: Text(
            currentLevel.toDisplayName(),
            textAlign: TextAlign.center,
            style: _levelTextStyle,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _AdjustButton(label: '+', enabled: _canIncrease, onTap: onIncrease),
      ],
    );
  }
}

/// A 22×22 px square button used within [LevelAdjuster].
class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Material(
        color: AppColors.pillBg,
        borderRadius: AppRadii.smRadius,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.smRadius,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
