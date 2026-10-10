import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

/// Helper to wrap a widget in a MaterialApp and Scaffold for testing.
Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('AppSectionTitle', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(wrap(const AppSectionTitle(title: 'Section')));
      expect(find.text('Section'), findsOneWidget);
    });

    testWidgets('tight variant uses smaller font', (tester) async {
      await tester.pumpWidget(
        wrap(const AppSectionTitle(title: 'Tight', tight: true)),
      );
      final text = tester.widget<Text>(find.text('Tight'));
      // cardTitleTight is 14px
      expect(text.style!.fontSize, 14);
    });
  });

  group('AppCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrap(const AppCard(child: Text('Hello'))));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AppCard(child: const Text('Tap'), onTap: () => tapped = true)),
      );
      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('renders without onTap', (tester) async {
      await tester.pumpWidget(wrap(const AppCard(child: Text('No tap'))));
      expect(find.text('No tap'), findsOneWidget);
    });
  });

  group('AppStatCell', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        wrap(const AppStatCell(label: 'ELO', value: '1500')),
      );
      // Label is uppercased in the widget
      expect(find.text('ELO'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('accent mode uses accent color for value', (tester) async {
      await tester.pumpWidget(
        wrap(const AppStatCell(label: 'Waitlist', value: '3', isAccent: true)),
      );
      final valueText = tester.widget<Text>(find.text('3'));
      expect(valueText.style!.color, AppColors.accentPrimary);
    });

    testWidgets('non-accent mode uses textPrimary', (tester) async {
      await tester.pumpWidget(
        wrap(const AppStatCell(label: 'Games', value: '7')),
      );
      final valueText = tester.widget<Text>(find.text('7'));
      expect(valueText.style!.color, AppColors.textPrimary);
    });
  });

  group('AppKpiCard', () {
    testWidgets('renders label, value, and delta', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppKpiCard(
            label: 'ACTIVE PLAYERS',
            value: '42',
            delta: '+12%',
            deltaPositive: true,
          ),
        ),
      );
      expect(find.text('ACTIVE PLAYERS'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('+12%'), findsOneWidget);
    });

    testWidgets('delta positive uses green', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppKpiCard(
            label: 'A',
            value: '1',
            delta: '+5%',
            deltaPositive: true,
          ),
        ),
      );
      final deltaText = tester.widget<Text>(find.text('+5%'));
      expect(deltaText.style!.color, AppColors.deltaPositive);
    });

    testWidgets('delta negative uses red', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppKpiCard(
            label: 'A',
            value: '1',
            delta: '-5%',
            deltaPositive: false,
          ),
        ),
      );
      final deltaText = tester.widget<Text>(find.text('-5%'));
      expect(deltaText.style!.color, AppColors.deltaNegative);
    });

    testWidgets('no delta when delta is null', (tester) async {
      await tester.pumpWidget(wrap(const AppKpiCard(label: 'A', value: '1')));
      expect(find.byType(AppKpiCard), findsOneWidget);
      // Only 2 Texts: label + value
      expect(find.byType(Text), findsNWidgets(2));
    });
  });

  group('AppButton', () {
    testWidgets('primary fires onPressed', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        wrap(AppButton.primary(label: 'Save', onPressed: () => pressed = true)),
      );
      await tester.tap(find.text('Save'));
      expect(pressed, isTrue);
    });

    testWidgets('secondary renders', (tester) async {
      await tester.pumpWidget(
        wrap(AppButton.secondary(label: 'Cancel', onPressed: () {})),
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('success renders', (tester) async {
      await tester.pumpWidget(
        wrap(AppButton.success(label: 'Approve', onPressed: () {})),
      );
      expect(find.text('Approve'), findsOneWidget);
    });

    testWidgets('dangerOutline renders', (tester) async {
      await tester.pumpWidget(
        wrap(AppButton.dangerOutline(label: 'Reject', onPressed: () {})),
      );
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('ghost renders', (tester) async {
      await tester.pumpWidget(
        wrap(AppButton.ghost(label: 'Dismiss', onPressed: () {})),
      );
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('icon renders', (tester) async {
      await tester.pumpWidget(
        wrap(AppButton.icon(icon: Icons.refresh, onPressed: () {})),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('onPressed can be null', (tester) async {
      await tester.pumpWidget(wrap(AppButton.primary(label: 'Disabled')));
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('AppChip', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(wrap(const AppChip(label: 'Same level')));
      expect(find.text('Same level'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(AppChip(label: 'Tap me', onTap: () => tapped = true)),
      );
      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('compact and non-compact padding', (tester) async {
      await tester.pumpWidget(wrap(const AppChip(label: 'Compact')));
      final compactChip = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AppChip),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(compactChip.padding, AppSpacing.chipPadding);
    });
  });

  group('AppProgressBar', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(wrap(const AppProgressBar(fraction: 0.75)));
      expect(find.byType(AppProgressBar), findsOneWidget);
    });

    testWidgets('showLabel displays percentage', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressBar(fraction: 0.5, showLabel: true)),
      );
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('fraction 0 renders', (tester) async {
      await tester.pumpWidget(wrap(const AppProgressBar(fraction: 0.0)));
      expect(find.byType(AppProgressBar), findsOneWidget);
    });

    testWidgets('fraction 1 renders', (tester) async {
      await tester.pumpWidget(wrap(const AppProgressBar(fraction: 1.0)));
      expect(find.byType(AppProgressBar), findsOneWidget);
    });

    testWidgets('fraction above 1 is clamped to 100%', (tester) async {
      await tester.pumpWidget(
        wrap(const AppProgressBar(fraction: 1.5, showLabel: true)),
      );
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('AppSearchInput', () {
    testWidgets('renders TextField with placeholder', (tester) async {
      await tester.pumpWidget(
        wrap(const AppSearchInput(placeholder: 'Find player…')),
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('onChanged fires on text entry', (tester) async {
      String? changed;
      await tester.pumpWidget(
        wrap(AppSearchInput(onChanged: (v) => changed = v)),
      );
      await tester.enterText(find.byType(TextField), 'John');
      expect(changed, 'John');
    });

    testWidgets('uses default placeholder when none provided', (tester) async {
      await tester.pumpWidget(wrap(const AppSearchInput()));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, 'Search players…');
    });
  });

  group('AppToggleButton', () {
    testWidgets('shows OFF when value is false', (tester) async {
      await tester.pumpWidget(
        wrap(AppToggleButton(value: false, onChanged: (_) {})),
      );
      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('shows ON when value is true', (tester) async {
      await tester.pumpWidget(
        wrap(AppToggleButton(value: true, onChanged: (_) {})),
      );
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('fires onChanged with toggled value', (tester) async {
      bool? toggled;
      await tester.pumpWidget(
        wrap(AppToggleButton(value: false, onChanged: (v) => toggled = v)),
      );
      await tester.tap(find.text('OFF'));
      expect(toggled, isTrue);
    });

    testWidgets('renders label beside toggle', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppToggleButton(
            value: true,
            onChanged: (_) {},
            label: 'Notifications',
          ),
        ),
      );
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('custom on/off labels', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppToggleButton(
            value: false,
            onChanged: (_) {},
            onLabel: 'Active',
            offLabel: 'Inactive',
          ),
        ),
      );
      expect(find.text('Inactive'), findsOneWidget);
    });
  });
}
