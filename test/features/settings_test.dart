import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/settings/settings.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

Widget createTestWidget() => const MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SettingsPage()),
);

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('settings_test');
  });

  tearDown(() => sandbox.tearDown());

  // R13-Q2 (Nathan 2026-10-22): the "Membership & self-registration" card
  // is removed. SET-02, SET-03 and SET-04 have no control in Settings now.
  group('SET-02 / SET-04: Membership card removed', () {
    testWidgets('should_not_show_the_membership_card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Membership & self-registration'), findsNothing);
    });

    testWidgets('should_not_show_the_total_members_count', (tester) async {
      await tester.runAsync(() => createTestPlayers(3));
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Total members'), findsNothing);
    });

    testWidgets('should_not_show_the_signup_preview_link', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Preview signup page →'), findsNothing);
    });

    testWidgets('should_not_show_the_level_calibration_note', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(
        find.text(
          'New players self-estimate their level at signup, and organizers '
          'may override any estimate from the Players tab.',
        ),
        findsNothing,
      );
    });
  });

  group('SET-05: Language', () {
    testWidgets('should show each supported language by its native name', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      for (final name in ['English', 'Français', '简体中文', '繁體中文']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('should save the language that the user selects', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(PersistentSetting.instance.getLanguage(), const Locale('fr'));
    });
  });

  group('Removed items', () {
    testWidgets('should not show notifications, fees or invite link', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('Fees outstanding'), findsNothing);
      expect(find.text('Invite link'), findsNothing);
    });
  });

  group('Responsive layout', () {
    testWidgets('should render at phone width without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('English'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
