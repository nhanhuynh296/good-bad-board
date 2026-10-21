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

/// R45-36 (Nathan, 2026-10-14): the court count is fixed at 4 in the
/// release. The Dashboard and Sessions controls are hidden; the code stays.
void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    CourtCount.editable = false;
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('release_court_count_test');
  });

  tearDown(() {
    CourtCount.editable = false;
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

  test('should_default_the_court_count_flag_to_off', () {
    expect(CourtCount.editable, isFalse);
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

  testWidgets('should_hide_the_courts_field_on_sessions', (tester) async {
    desktop(tester);
    await tester.pumpWidget(wrap(const SessionsPage(), GameData()));

    expect(find.byKey(const Key('sessions-courts-field')), findsNothing);
  });

  test('should_keep_4_courts_when_a_6_court_template_is_loaded', () {
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

    expect(gameData.numberOfCourt, 4);
  });
}
