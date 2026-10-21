import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// A 3 px `#ff6a2b` keyboard focus ring drawn inside [child], for the
/// full-height tabs of the top nav and the session bar link (F07; the
/// canvas uses `outline-offset: -3px`). It shows only for keyboard focus.
class InsetFocusRing extends StatelessWidget {
  const InsetFocusRing({
    super.key,
    required this.focused,
    required this.child,
    this.ringKey,
  });

  final bool focused;
  final Widget child;

  /// The key of the ring box, so tests can find it.
  final Key? ringKey;

  @override
  Widget build(BuildContext context) {
    final visible =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: ringKey,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.focusOnDark, width: 3),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
