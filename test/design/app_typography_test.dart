import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';

/// The 6 sizes of ARCHITECTURE.md §1.2 (R2-Q20).
final _scale = {50.0, 28.0, 20.0, 16.0, 14.0, 12.0};

/// The 3 weights of ARCHITECTURE.md §1.2.
final _weights = {FontWeight.w400, FontWeight.w600, FontWeight.w800};

List<TextStyle> _themeStyles(TextTheme t) => [
  t.displayLarge!,
  t.displayMedium!,
  t.displaySmall!,
  t.headlineLarge!,
  t.headlineMedium!,
  t.headlineSmall!,
  t.titleLarge!,
  t.titleMedium!,
  t.titleSmall!,
  t.bodyLarge!,
  t.bodyMedium!,
  t.bodySmall!,
  t.labelLarge!,
  t.labelMedium!,
  t.labelSmall!,
];

/// Every Dart source file in lib/ except the typography tokens and
/// generated files.
Iterable<File> _featureSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !f.path.endsWith('.g.dart'))
    .where((f) => !f.path.endsWith('.freezed.dart'))
    .where((f) => !f.path.contains('l10n'))
    .where((f) => !f.path.endsWith('app_typography.dart'));

void main() {
  group('theme text styles', () {
    test('should_use_source_sans_3_for_every_theme_text_style', () {
      // Arrange
      final textTheme = AppTheme.light().textTheme;

      // Act
      final families = _themeStyles(textTheme).map((s) => s.fontFamily).toSet();

      // Assert
      expect(families, {'SourceSans3'});
    });

    test('should_use_only_the_6_scale_sizes_for_every_theme_text_style', () {
      // Arrange
      final textTheme = AppTheme.light().textTheme;

      // Act
      final offScale = _themeStyles(
        textTheme,
      ).map((s) => s.fontSize).where((size) => !_scale.contains(size));

      // Assert
      expect(offScale, isEmpty);
    });

    test('should_use_only_the_3_weights_for_every_theme_text_style', () {
      // Arrange
      final textTheme = AppTheme.light().textTheme;

      // Act
      final offScale = _themeStyles(
        textTheme,
      ).map((s) => s.fontWeight).where((w) => !_weights.contains(w));

      // Assert
      expect(offScale, isEmpty);
    });

    test('should_apply_the_locale_fallback_to_theme_text_styles', () {
      // Arrange
      final theme = AppTheme.light(locale: const Locale('zh'));

      // Act
      final fallback = theme.textTheme.bodyMedium!.fontFamilyFallback;

      // Assert
      expect(fallback, ['Microsoft YaHei']);
    });
  });

  group('fontFamilyFallback', () {
    test('should_fall_back_to_microsoft_yahei_for_chinese', () {
      // Act
      final fallback = AppTypography.fallbackFor(const Locale('zh'));

      // Assert
      expect(fallback, ['Microsoft YaHei']);
    });

    test('should_fall_back_to_microsoft_jhenghei_for_hong_kong_chinese', () {
      // Act
      final fallback = AppTypography.fallbackFor(const Locale('zh', 'HK'));

      // Assert
      expect(fallback, ['Microsoft JhengHei']);
    });

    test('should_have_no_fallback_for_english', () {
      // Act
      final fallback = AppTypography.fallbackFor(const Locale('en'));

      // Assert
      expect(fallback, isEmpty);
    });
  });

  group('typography tokens', () {
    test('should_define_exactly_the_6_scale_sizes', () {
      // Act
      final sizes = AppTypography.scale.toSet();

      // Assert
      expect(sizes, _scale);
    });

    test('should_use_only_scale_sizes_in_the_typography_file', () {
      // Arrange
      final source = File('lib/design/app_typography.dart').readAsStringSync();

      // Act
      final offScale = RegExp(r'fontSize:\s*([\d.]+)')
          .allMatches(source)
          .map((m) => double.parse(m.group(1)!))
          .where((size) => !_scale.contains(size));

      // Assert
      expect(offScale, isEmpty);
    });

    test('should_use_only_the_3_weights_in_the_typography_file', () {
      // Arrange
      final source = File('lib/design/app_typography.dart').readAsStringSync();

      // Act
      final offScale = RegExp(r'FontWeight\.(\w+)')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .where((w) => !{'w400', 'w600', 'w800'}.contains(w));

      // Assert
      expect(offScale, isEmpty);
    });

    test('should_use_800_only_for_the_page_title', () {
      // Arrange
      final source = File('lib/design/app_typography.dart').readAsStringSync();

      // Act
      final uses = RegExp(r'fontWeight:\s*extraBold').allMatches(source);

      // Assert
      expect(uses.length, 1);
    });
  });

  group('feature widgets', () {
    test('should_not_use_a_literal_font_size_outside_the_tokens', () {
      // Arrange
      final literal = RegExp(r'fontSize:\s*[\d.]+');

      // Act
      final offenders = _featureSources()
          .where((f) => literal.hasMatch(f.readAsStringSync()))
          .map((f) => f.path);

      // Assert
      expect(offenders, isEmpty);
    });

    test('should_not_use_a_literal_font_weight_outside_the_tokens', () {
      // Arrange
      final literal = RegExp(r'FontWeight\.\w+');

      // Act
      final offenders = _featureSources()
          .where((f) => literal.hasMatch(f.readAsStringSync()))
          .map((f) => f.path);

      // Assert
      expect(offenders, isEmpty);
    });
  });
}
