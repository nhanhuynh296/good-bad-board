import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';

import '../support/courts_harness.dart';

/// F16 (IMPLEMENTATION 8.8): the round bar labels at 1280 px in fr, zh and
/// zh_HK. "Discard round {n} and start again", "Start round {n+1}",
/// "Resume round {n}", the counts and "⋯" must show in full; when they do
/// not fit, the discard button uses the short label "Discard round {n}".
///
/// The bundled Source Sans 3 gives Latin text its real width. For Chinese
/// the test loads a system CJK font (one em per glyph, as YaHei and
/// JhengHei) under the fallback names of `AppTheme.light(locale:)`. With no
/// CJK font on the machine the zh tests are skipped: the test font would
/// draw the glyphs too narrow to measure.
void main() {
  setUpCourtsSandbox('courts_label_width_test');

  final cjkFont = const [
    '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc',
    r'C:\Windows\Fonts\msyh.ttc',
  ].map(File.new).where((file) => file.existsSync()).firstOrNull;

  setUpAll(() async {
    if (cjkFont == null) return;
    final bytes = cjkFont.readAsBytesSync();
    for (final family in const ['Microsoft YaHei', 'Microsoft JhengHei']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });

  const width = Size(1280, 720);
  const locales = {
    'en': Locale('en'),
    'fr': Locale('fr'),
    'zh': Locale('zh'),
    'zh_HK': Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
  };

  // With round n+1 saved the bar has the most buttons: "Start round n+1"
  // shows only then (R13-Q5).
  final phases = <String, void Function(CourtsHarness)>{
    'running': (h) => h.toRunningWithNext(),
    'paused': (h) => h.toPausedWithNext(),
    'time_up': (h) => h.toTimeUp(),
  };

  Object? skipFor(Locale locale) =>
      locale.languageCode == 'zh' && cjkFont == null
      ? 'no CJK font on this machine'
      : null;

  Future<CourtsHarness> pumpBar(
    WidgetTester tester,
    Locale locale,
    void Function(CourtsHarness) arrange,
  ) async {
    final h = CourtsHarness(tester)..checkIn(20);
    arrange(h);
    await h.pump(
      size: width,
      locale: locale,
      theme: AppTheme.light(locale: locale),
    );
    return h;
  }

  /// The painted text of every round bar button.
  Iterable<RenderParagraph> buttonTexts(WidgetTester tester) =>
      tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(RoundBarButton),
          matching: find.byType(RichText),
        ),
      );

  /// The painted "{in}/{capacity} in · {waiting} waiting" text.
  RenderParagraph countsText(WidgetTester tester) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const Key('round-bar-counts')),
          matching: find.byType(RichText),
        ),
      );

  for (final MapEntry(key: name, value: locale) in locales.entries) {
    for (final MapEntry(key: phase, value: arrange) in phases.entries) {
      testWidgets(
        'should_show_every_bar_label_in_full_in_${name}_when_$phase',
        skip: skipFor(locale) != null,
        (tester) async {
          await pumpBar(tester, locale, arrange);

          expect(
            buttonTexts(tester).where((p) => p.didExceedMaxLines),
            isEmpty,
          );
        },
      );

      testWidgets(
        'should_show_the_counts_in_full_in_${name}_when_$phase',
        skip: skipFor(locale) != null,
        (tester) async {
          await pumpBar(tester, locale, arrange);

          expect(countsText(tester).didExceedMaxLines, isFalse);
        },
      );

      testWidgets(
        'should_keep_the_round_menu_on_screen_in_${name}_when_$phase',
        skip: skipFor(locale) != null,
        (tester) async {
          await pumpBar(tester, locale, arrange);

          final menu = tester.getRect(
            find.byKey(const Key('round-menu-button')),
          );
          expect(menu.right, lessThanOrEqualTo(width.width));
        },
      );
    }
  }

  testWidgets('should_use_the_full_discard_label_in_en_when_paused', (
    tester,
  ) async {
    await pumpBar(tester, locales['en']!, (h) => h.toPaused());

    expect(find.text('Discard round 1 and start again'), findsOneWidget);
  });

  testWidgets('should_use_the_short_discard_label_in_fr_when_paused', (
    tester,
  ) async {
    await pumpBar(tester, locales['fr']!, (h) => h.toPausedWithNext());

    expect(find.text('Annuler la manche 1'), findsOneWidget);
  });

  // R13-Q3: "Generate next round (n+1)" on the next-round strip shows in
  // full at 1280 px, and the strip has no overflow.
  final stripPhases = <String, void Function(CourtsHarness)>{
    'running': (h) => h.toRunning(),
    'paused': (h) => h.toPaused(),
    'time_up': (h) => h.toTimeUp(),
  };
  for (final MapEntry(key: name, value: locale) in locales.entries) {
    for (final MapEntry(key: phase, value: arrange) in stripPhases.entries) {
      testWidgets(
        'should_show_the_generate_label_in_full_in_${name}_when_$phase',
        skip: skipFor(locale) != null,
        (tester) async {
          await pumpBar(tester, locale, arrange);

          final label = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(const Key('generate-next-round')),
              matching: find.byType(RichText),
            ),
          );
          expect(label.didExceedMaxLines, isFalse);
        },
      );

      testWidgets(
        'should_keep_the_generate_button_on_screen_in_${name}_when_$phase',
        skip: skipFor(locale) != null,
        (tester) async {
          await pumpBar(tester, locale, arrange);

          final button = tester.getRect(
            find.byKey(const Key('generate-next-round')),
          );
          expect(button.right, lessThanOrEqualTo(width.width));
        },
      );
    }
  }
}
