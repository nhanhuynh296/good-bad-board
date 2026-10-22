import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// A pill chip showing the level gap for a court.
///
/// Displays text like "Same level" or "2 level gap" using the [AppChip]
/// styling with [AppColors.pillBg] background.
class SpreadPill extends StatelessWidget {
  const SpreadPill({super.key, required this.levelGap});

  /// The level gap between the highest and lowest player on the court.
  final int levelGap;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: AppLocalizations.of(context)!.dashboard_spread(levelGap),
    );
  }
}
