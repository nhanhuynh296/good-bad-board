import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// Shown in place of the registration form once a self-registration has
/// been submitted (REG-04). There is no edit/resubmit — the submission is
/// final and awaits organizer review.
class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.firstName,
    required this.selectedTierLabel,
  });

  final String firstName;
  final String selectedTierLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Thanks, $firstName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're signed up as $selectedTierLabel. An organizer reviews "
            'every new sign-up and may adjust your starting level before '
            "you're added to the roster.",
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
