import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// A minimal placeholder page shown for tabs that haven't been implemented yet.
///
/// Displays the tab name centered on the page using the design system tokens.
/// Replaced by real feature pages in later stages.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTypography.pageTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.coming_soon,
            style: AppTypography.body.copyWith(
              color: AppColors.textSubtle,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
