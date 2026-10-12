import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should_not_use_material_named_colors_in_the_theme_file', () {
    final source = File('lib/design/app_theme.dart').readAsStringSync();

    final named = RegExp(
      r'\bColors\.(?!transparent\b)\w+',
    ).allMatches(source).map((m) => m.group(0)).toList();

    expect(named, isEmpty);
  });
}
