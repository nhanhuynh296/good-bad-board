import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The font families that `pubspec.yaml` declares.
List<String> _declaredFamilies() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  return RegExp(
    r'^\s*- family:\s*(\S+)\s*$',
    multiLine: true,
  ).allMatches(pubspec).map((m) => m.group(1)!).toList();
}

void main() {
  test('should_declare_only_source_sans_3_in_pubspec', () {
    // Arrange / Act
    final families = _declaredFamilies();

    // Assert
    expect(families, ['SourceSans3']);
  });

  test('should_bundle_the_source_sans_3_variable_font', () {
    // Arrange
    final font = File('asset/font/SourceSans3VF-Upright.ttf');

    // Act
    final exists = font.existsSync();

    // Assert
    expect(exists, isTrue);
  });

  test('should_bundle_the_source_sans_3_license', () {
    // Arrange
    final license = File('asset/font/SourceSans3-LICENSE.md');

    // Act
    final exists = license.existsSync();

    // Assert
    expect(exists, isTrue);
  });

  test('should_not_bundle_other_font_files', () {
    // Arrange
    final fonts = Directory('asset/font')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => name.endsWith('.ttf') || name.endsWith('.otf'));

    // Act
    final others = fonts.where((name) => !name.startsWith('SourceSans3'));

    // Assert
    expect(others, isEmpty);
  });
}
