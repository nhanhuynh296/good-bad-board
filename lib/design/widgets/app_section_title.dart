import 'package:flutter/widgets.dart';
import 'package:good_bad_board/design/design.dart';

/// Section heading within a card or page.
///
/// Uses Space Grotesk 700 with two size variants:
/// - Default (15px) — standard card/section titles
/// - Tight (14px) — compact layout variant
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle({super.key, required this.title, this.tight = false});

  final String title;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: tight ? AppTypography.cardTitleTight : AppTypography.cardTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
