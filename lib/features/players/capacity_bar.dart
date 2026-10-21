import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Capacity progress bar and remaining count text (CHK-01).
class CapacityBar extends StatelessWidget {
  const CapacityBar({
    required this.checkedIn,
    required this.capacity,
    required this.remaining,
    super.key,
  });

  final int checkedIn;
  final int capacity;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final fraction = capacity > 0 ? checkedIn / capacity : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.players_capacity_left(checkedIn, capacity, remaining),
          style: AppTypography.body.copyWith(
            fontWeight: AppTypography.semibold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadii.fullRadius,
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.pillBg,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// At-capacity warning banner (CHK-04).
class AtCapacityBanner extends StatelessWidget {
  const AtCapacityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Text(
        AppLocalizations.of(context)!.players_at_capacity_banner,
        style: AppTypography.body.copyWith(
          color: AppColors.warningText,
          fontWeight: AppTypography.semibold,
        ),
      ),
    );
  }
}
