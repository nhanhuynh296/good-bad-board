import 'package:flutter/material.dart';
import 'package:good_bad_board/spacing.dart';

void showToast(BuildContext context, String message) {
  final snackBar = SnackBar(content: Text(message));
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showErrorToast(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Row(
      spacing: space8,
      children: [const Icon(Icons.error, color: Colors.red), Text(message)],
    ),
  );
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
