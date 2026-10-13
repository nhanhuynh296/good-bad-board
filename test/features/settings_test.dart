import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/settings/settings.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
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

  group('SET-02: Membership count', () {
    testWidgets('should display "Total members" count section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Total members'), findsOneWidget);
    });

    testWidgets('should show zero members when no players', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should show the number of listed players', (tester) async {
      await tester.runAsync(() => createTestPlayers(3));
      await tester.pumpWidget(createTestWidget());

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should update the count when the roster changes', (
      tester,
    ) async {
      await tester.runAsync(() => createTestPlayers(3));
      await tester.pumpWidget(createTestWidget());

      await tester.runAsync(
        () => PlayerRepository.instance.add(
          Player.create(firstName: 'New', lastName: 'One', elo: Elo.b1),
        ),
      );
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
    });
  });

  group('Signup preview (SET-03, hidden for this release)', () {
    testWidgets('should_hide_signup_preview_link_by_default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Preview signup page →'), findsNothing);
    });

    testWidgets('should_show_signup_preview_link_when_flag_is_on', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsPage(showSignupPreview: true)),
        ),
      );
      expect(find.text('Preview signup page →'), findsOneWidget);
    });
  });

  group('SET-04: Level calibration note', () {
    testWidgets('should display level calibration note text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(
        find.text(
          'New players self-estimate their level at signup, and organizers '
          'may override any estimate from the Players tab.',
        ),
        findsOneWidget,
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

      expect(find.text('Membership & self-registration'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
