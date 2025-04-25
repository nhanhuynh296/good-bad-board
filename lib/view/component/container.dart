import 'package:flutter/material.dart';
import 'package:good_bad_board/theme.dart';
import 'package:good_bad_board/view/component/button.dart';

class ShadedContainer extends StatelessWidget {
  final Widget child;
  final bool shaded;

  const ShadedContainer({super.key, required this.child, this.shaded = true});

  @override
  Widget build(BuildContext context) {
    final shadedDecoration = BoxDecoration(
      borderRadius: outlinedBorderRadius,
      boxShadow: [
        Button.buttonBoxShadow.copyWith(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
      ],
    );

    return DecoratedBox(
      decoration: shaded ? shadedDecoration : const BoxDecoration(),
      child: ClipRRect(borderRadius: outlinedBorderRadius, child: child),
    );
  }
}
