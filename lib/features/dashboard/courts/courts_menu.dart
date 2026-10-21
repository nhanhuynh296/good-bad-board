import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';

/// One menu entry for [courtsMenuAnchor].
typedef CourtsMenuEntry = ({String label, VoidCallback onPressed, bool danger});

/// The shared [MenuAnchor] of the round menu and the slot menu.
Widget courtsMenuAnchor({
  required FocusNode focusNode,
  required List<CourtsMenuEntry> items,
  required Widget Function(BuildContext context, VoidCallback toggle) builder,
}) {
  return MenuAnchor(
    childFocusNode: focusNode,
    style: const MenuStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.pageBg),
      padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
      minimumSize: WidgetStatePropertyAll(Size(200, 0)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: AppRadii.mdRadius,
          side: BorderSide(color: AppColors.controlBorder),
        ),
      ),
    ),
    menuChildren: [
      for (final (index, item) in items.indexed)
        MenuItemButton(
          autofocus: index == 0,
          onPressed: item.onPressed,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(192, 40)),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: AppRadii.smRadius),
            ),
            overlayColor: const WidgetStatePropertyAll(AppColors.surfaceHover),
            textStyle: WidgetStatePropertyAll(
              AppTypography.body.copyWith(fontWeight: AppTypography.semibold),
            ),
            foregroundColor: WidgetStatePropertyAll(
              item.danger ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          child: Text(item.label),
        ),
    ],
    builder: (context, controller, _) => builder(
      context,
      () => controller.isOpen ? controller.close() : controller.open(),
    ),
  );
}
