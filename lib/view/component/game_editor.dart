import 'package:flutter/material.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

class BlankGame extends StatelessWidget {
  const BlankGame({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!;
    return Center(
      child: Row(
        spacing: textStyle.fontSize!,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: textStyle.fontSize!),
          Text(
            AppLocalizations.of(context)!.generate_some_game_to_start,
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
