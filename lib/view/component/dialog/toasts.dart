import 'package:flutter/material.dart';
import 'package:good_bad_board/core/build_context_extention.dart';
import 'package:good_bad_board/spacing.dart';

extension ShowToast on BuildContext {
  void showSnackBar(SnackBar snackBar) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  void showToast(String message) {
    final snackBar = SnackBar(content: Text(message));
    showSnackBar(snackBar);
  }

  void showErrorToast(String message) {
    final snackBar = SnackBar(
      content: Row(
        spacing: space8,
        children: [Icon(Icons.error, color: colorScheme.error), Text(message)],
      ),
    );
    showSnackBar(snackBar);
  }
}
