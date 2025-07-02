import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extension.dart';
import 'package:good_bad_board/spacing.dart';

extension ShowToast on BuildContext {
  Future<void> showSnackBar(SnackBar snackBar) async {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    await ScaffoldMessenger.of(this).showSnackBar(snackBar).closed;
  }

  Future<void> showToast(String message) {
    final snackBar = SnackBar(content: Text(message));
    return showSnackBar(snackBar);
  }

  Future<void> showErrorToast(String message) {
    final snackBar = SnackBar(
      content: Row(
        spacing: space8,
        children: [
          Icon(Icons.error, color: colorScheme.error),
          Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
    return showSnackBar(snackBar);
  }
}
