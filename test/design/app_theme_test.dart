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

  test('should_not_define_a_dark_theme_in_lib', () {
    // Arrange
    final darkCode = RegExp(
      r'AppTheme\.dark\b|\bdarkTheme\b|ColorScheme\.dark\b|'
      r'AppColors\.dark\w*|static const Color dark\w*|darkOutlinedBorder',
    );
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    // Act
    final offenders = sources
        .where((f) => darkCode.hasMatch(f.readAsStringSync()))
        .map((f) => f.path);

    // Assert
    expect(offenders, isEmpty);
  });
}
