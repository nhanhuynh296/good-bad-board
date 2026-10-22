import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

/// R45-36 (Nathan, 2026-10-14) fixed the court count at 4. R13-Q1 (Nathan
/// 2026-10-22) turns the Sessions control on again, range 1 to 8. The Courts
/// tab still has no stepper (R2-Q2).
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('release_court_count_test');
  });

  tearDown(() {
    CourtCount.editable = true;
    sandbox.tearDown();
  });

  Widget wrap(Widget page, GameData gameData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<TimerData>.value(value: TimerData()),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: page),
    ),
  );

  void desktop(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  test('should_default_the_court_count_flag_to_on', () {
    expect(CourtCount.editable, isTrue);
  });

  testWidgets('should_hide_the_court_stepper_on_the_dashboard', (tester) async {
    desktop(tester);
    await tester.pumpWidget(wrap(const DashboardPage(), GameData()));

    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  // R2-Q2: the Courts tab has no "COURTS − 4 +" stepper, even with the flag
  // on. Only the Sessions field changes the count (SESS-04).
  testWidgets('should_hide_the_court_stepper_when_the_flag_is_on', (
    tester,
  ) async {
    CourtCount.editable = true;
    desktop(tester);
    await tester.pumpWidget(wrap(const DashboardPage(), GameData()));

    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('should_show_the_court_count_on_desktop_sessions', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(wrap(const SessionsPage(), GameData()));

    expect(find.byKey(const Key('sessions-courts-value')), findsOneWidget);
  });

  testWidgets('should_show_the_courts_field_on_phone_sessions', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const SessionsPage(), GameData()));

    expect(find.byKey(const Key('sessions-courts-field')), findsOneWidget);
  });

  test('should_apply_6_courts_when_a_6_court_template_is_loaded', () {
    final gameData = GameData();

    gameData.loadTemplate(
      const SessionTemplate(
        id: 't',
        name: 'Big night',
        gameType: GameType.timeBased,
        durationMinutes: 10,
        capacity: 24,
        courts: 6,
      ),
    );

    expect(gameData.numberOfCourt, 6);
  });
}
