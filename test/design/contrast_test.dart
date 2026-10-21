import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';

/// WCAG 2.x contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Text needs 4.5:1 (UX-22).
const _text = 4.5;

/// Borders, icons, focus rings and state fills need 3:1 (UX-22, R2-Q22).
const _nonText = 3.0;

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.min);

  final String name;
  final Color fg;
  final Color bg;
  final double min;
}

/// Every token pair of ARCHITECTURE.md §1.1. Card and row separators
/// (`cardBorder`) are allowed below 3:1 (R2-Q22), so they are not listed.
const _pairs = <_Pair>[
  // ── Surfaces with text ─────────────────────────────────
  _Pair(
    'textPrimary on pageBg',
    AppColors.textPrimary,
    AppColors.pageBg,
    _text,
  ),
  _Pair(
    'textPrimary on cardBg',
    AppColors.textPrimary,
    AppColors.cardBg,
    _text,
  ),
  _Pair(
    'textPrimary on surfaceHover',
    AppColors.textPrimary,
    AppColors.surfaceHover,
    _text,
  ),
  _Pair(
    'textPrimary on surfaceNext',
    AppColors.textPrimary,
    AppColors.surfaceNext,
    _text,
  ),
  _Pair(
    'textPrimary on checkedInBg',
    AppColors.textPrimary,
    AppColors.checkedInBg,
    _text,
  ),
  _Pair(
    'textPrimary on neutralBg',
    AppColors.textPrimary,
    AppColors.neutralBg,
    _text,
  ),
  _Pair(
    'headerText on headerBg',
    AppColors.headerText,
    AppColors.headerBg,
    _text,
  ),
  _Pair('headerText on barBg', AppColors.headerText, AppColors.barBg, _text),
  _Pair(
    'headerText on barTrack',
    AppColors.headerText,
    AppColors.barTrack,
    _text,
  ),

  // ── Text ───────────────────────────────────────────────
  _Pair('textMuted on pageBg', AppColors.textMuted, AppColors.pageBg, _text),
  _Pair('textMuted on cardBg', AppColors.textMuted, AppColors.cardBg, _text),
  _Pair(
    'textMuted on neutralBg',
    AppColors.textMuted,
    AppColors.neutralBg,
    _text,
  ),
  _Pair(
    'textMutedOnCheckedIn on checkedInBg',
    AppColors.textMutedOnCheckedIn,
    AppColors.checkedInBg,
    _text,
  ),
  _Pair(
    'headerSub on headerBg',
    AppColors.headerSub,
    AppColors.headerBg,
    _text,
  ),
  _Pair('headerSub on barBg', AppColors.headerSub, AppColors.barBg, _text),
  _Pair(
    'headerSub on barTrack',
    AppColors.headerSub,
    AppColors.barTrack,
    _text,
  ),

  // ── Action and state ───────────────────────────────────
  _Pair(
    'accentOnPrimary on accentPrimary',
    AppColors.accentOnPrimary,
    AppColors.accentPrimary,
    _text,
  ),
  _Pair(
    'accentPrimary vs barBg',
    AppColors.accentPrimary,
    AppColors.barBg,
    _nonText,
  ),
  _Pair(
    'accentPrimary vs headerBg',
    AppColors.accentPrimary,
    AppColors.headerBg,
    _nonText,
  ),
  _Pair(
    'accentPrimary fill vs barTrack',
    AppColors.accentPrimary,
    AppColors.barTrack,
    _nonText,
  ),
  _Pair(
    'focusOnLight vs pageBg',
    AppColors.focusOnLight,
    AppColors.pageBg,
    _nonText,
  ),
  _Pair(
    'focusOnLight vs cardBg',
    AppColors.focusOnLight,
    AppColors.cardBg,
    _nonText,
  ),
  _Pair(
    'focusOnLight vs surfaceNext',
    AppColors.focusOnLight,
    AppColors.surfaceNext,
    _nonText,
  ),
  _Pair(
    'accentStrong vs warningBg',
    AppColors.accentStrong,
    AppColors.warningBg,
    _nonText,
  ),
  _Pair(
    'focusOnDark vs headerBg',
    AppColors.focusOnDark,
    AppColors.headerBg,
    _nonText,
  ),
  _Pair(
    'focusOnDark vs barBg',
    AppColors.focusOnDark,
    AppColors.barBg,
    _nonText,
  ),
  _Pair(
    'controlBorder vs pageBg',
    AppColors.controlBorder,
    AppColors.pageBg,
    _nonText,
  ),
  _Pair(
    'controlBorder vs cardBg',
    AppColors.controlBorder,
    AppColors.cardBg,
    _nonText,
  ),
  _Pair(
    'controlBorder vs white',
    AppColors.controlBorder,
    AppColors.white,
    _nonText,
  ),
  _Pair(
    'controlBorderSoft vs pageBg',
    AppColors.controlBorderSoft,
    AppColors.pageBg,
    _nonText,
  ),
  _Pair(
    'controlBorderSoft vs cardBg',
    AppColors.controlBorderSoft,
    AppColors.cardBg,
    _nonText,
  ),
  _Pair(
    'controlBorderSoft vs surfaceNext',
    AppColors.controlBorderSoft,
    AppColors.surfaceNext,
    _nonText,
  ),
  _Pair(
    'controlBorderSoft vs surfaceHover',
    AppColors.controlBorderSoft,
    AppColors.surfaceHover,
    _nonText,
  ),
  _Pair('success vs pageBg', AppColors.success, AppColors.pageBg, _nonText),
  _Pair('success vs cardBg', AppColors.success, AppColors.cardBg, _nonText),
  _Pair(
    'success vs checkedInBg',
    AppColors.success,
    AppColors.checkedInBg,
    _nonText,
  ),
  _Pair('white on success', AppColors.white, AppColors.success, _text),
  _Pair(
    'successText on checkedInBg',
    AppColors.successText,
    AppColors.checkedInBg,
    _text,
  ),
  _Pair(
    'warningText on warningBg',
    AppColors.warningText,
    AppColors.warningBg,
    _text,
  ),
  _Pair(
    'warningText on pageBg',
    AppColors.warningText,
    AppColors.pageBg,
    _text,
  ),
  _Pair('error on pageBg', AppColors.error, AppColors.pageBg, _text),
  _Pair('error on errorBg', AppColors.error, AppColors.errorBg, _text),
  _Pair('white on error', AppColors.white, AppColors.error, _text),
  _Pair('errorText on errorBg', AppColors.errorText, AppColors.errorBg, _text),
  _Pair('white on neutral icon', AppColors.white, AppColors.textMuted, _text),
  _Pair(
    'urgentOnDark on barBg',
    AppColors.urgentOnDark,
    AppColors.barBg,
    _text,
  ),

  // ── Round state chips ──────────────────────────────────
  _Pair('READY chip', AppColors.headerText, AppColors.barTrack, _text),
  _Pair('RUNNING chip', AppColors.white, AppColors.success, _text),
  _Pair('PAUSED chip', AppColors.warningText, AppColors.warningBg, _text),
  _Pair('TIME UP chip', AppColors.timeUpText, AppColors.timeUpBg, _text),
  _Pair('TIME UP time on barBg', AppColors.timeUpTime, AppColors.barBg, _text),
  _Pair(
    'CHANGEOVER chip',
    AppColors.accentOnPrimary,
    AppColors.accentPrimary,
    _text,
  ),
];

void main() {
  group('WCAG contrast of the §1.1 token pairs', () {
    for (final pair in _pairs) {
      test('should_meet_${pair.min}_to_1_for_${pair.name}', () {
        // Act
        final ratio = contrastRatio(pair.fg, pair.bg);

        // Assert
        expect(ratio, greaterThanOrEqualTo(pair.min));
      });
    }
  });

  group('contrastRatio', () {
    test('should_return_21_for_black_on_white', () {
      // Act
      final ratio = contrastRatio(const Color(0xFF000000), Colors.white);

      // Assert
      expect(ratio, closeTo(21, 0.01));
    });

    test('should_match_the_documented_ink_on_page_ratio', () {
      // Act
      final ratio = contrastRatio(AppColors.textPrimary, AppColors.pageBg);

      // Assert
      expect(ratio, closeTo(16.45, 0.01));
    });
  });

  group('theme', () {
    test('should_give_primary_fills_readable_text', () {
      // Arrange
      final scheme = AppTheme.light().colorScheme;

      // Act
      final ratio = contrastRatio(scheme.onPrimary, scheme.primary);

      // Assert
      expect(ratio, greaterThanOrEqualTo(_text));
    });

    test('should_give_error_fills_readable_text', () {
      // Arrange
      final scheme = AppTheme.light().colorScheme;

      // Act
      final ratio = contrastRatio(scheme.onError, scheme.error);

      // Assert
      expect(ratio, greaterThanOrEqualTo(_text));
    });

    test('should_give_input_borders_3_to_1_on_the_page', () {
      // Arrange
      final border =
          AppTheme.light().inputDecorationTheme.enabledBorder!
              as OutlineInputBorder;

      // Act
      final ratio = contrastRatio(border.borderSide.color, AppColors.pageBg);

      // Assert
      expect(ratio, greaterThanOrEqualTo(_nonText));
    });

    test('should_give_the_focused_input_a_3_to_1_ring_on_the_page', () {
      // Arrange
      final border =
          AppTheme.light().inputDecorationTheme.focusedBorder!
              as OutlineInputBorder;

      // Act
      final ratio = contrastRatio(border.borderSide.color, AppColors.pageBg);

      // Assert
      expect(ratio, greaterThanOrEqualTo(_nonText));
    });
  });
}
