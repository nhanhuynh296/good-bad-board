import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/session_template_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import 'courts_harness.dart' show StopClockOnDispose;
import 'prefs_sandbox.dart';
import 'repository_sandbox.dart';

/// Sets up the preferences, a temp-dir repository sandbox and the bundled
/// Source Sans 3 for a desktop Sessions widget test file. Tests never touch
/// the real data directory (PERSISTENCE.md §2.2).
void setUpSessionsSandbox(String name) {
  late RepositorySandbox sandbox;
  setUpAll(() async {
    final bytes = File(
      'asset/font/SourceSans3VF-Upright.ttf',
    ).readAsBytesSync();
    final loader = FontLoader(AppTypography.family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  });
  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp(name);
  });
  tearDown(() {
    CourtCount.editable = true;
    sandbox.tearDown();
  });
}

/// Builds the Sessions tab at desktop size under a 96 px stand-in for the
/// top nav and the session bar, with the desktop page padding of the shell
/// and one shared [TimerData], as `main.dart` does.
class SessionsHarness {
  SessionsHarness(this.tester);

  final WidgetTester tester;
  final TimerData timer = TimerData();
  late final GameData gameData = GameData(timer: timer, random: Random(3));

  /// Checks in [count] new players, Elo spread evenly.
  void checkIn(int count) {
    for (var i = 0; i < count; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.checkInPlayer(player);
    }
  }

  Future<void> pump({
    Size size = const Size(1280, 720),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      StopClockOnDispose(
        timer: timer,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<GameData>.value(value: gameData),
            ChangeNotifierProvider<TimerData>.value(value: timer),
            ChangeNotifierProvider<PersistentSetting>.value(
              value: PersistentSetting.instance,
            ),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              backgroundColor: AppColors.pageBg,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The top nav and the session bar.
                  SizedBox(height: 96),
                  Expanded(
                    child: Padding(
                      padding: AppSpacing.desktopPadding,
                      child: SessionsPage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Saves a template on disk (real async) and rebuilds.
  Future<SessionTemplate> saveTemplate({
    String name = 'Wednesday night',
    Duration duration = const Duration(minutes: 12),
    int capacity = 24,
    int courts = 4,
  }) async {
    await tester.runAsync(
      () => gameData.saveTemplate(
        name,
        GameType.timeBased,
        duration,
        capacity,
        courts,
      ),
    );
    await tester.pump();
    return SessionTemplateRepository.instance.getAll().last;
  }

  // ── Arrange helpers: the round phases (IMPLEMENTATION 8.2) ──

  void toReady() => gameData.generateFirstRound();

  void toRunning() {
    toReady();
    gameData.startFirstRound();
  }

  void toPaused() {
    toRunning();
    gameData.pause();
  }

  void toTimeUp() {
    toRunning();
    timer.elapse(timer.duration);
  }

  /// Taps the widget found by [finder] and lets the frame settle.
  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Taps [finder] with real async, so a repository write can land.
  Future<void> tapAndFlush(Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  /// Types [text] into the field [key] and submits it.
  Future<void> submit(Key key, String text) async {
    await tester.enterText(find.byKey(key), text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// The rosters on the live courts.
  List<List<String>> get rosters => [
    for (final game in gameData.stagingMatches) [...game.playerIds],
  ];
}

// ── Keys of the desktop Sessions tab ───────────────────────────

const durationLess = Key('sessions-duration-less');
const durationMore = Key('sessions-duration-more');
const minutesField = Key('duration-minutes');
const secondsField = Key('duration-seconds');
const capacityField = Key('sessions-capacity-field');
const capacityLess = Key('sessions-capacity-less');
const capacityMore = Key('sessions-capacity-more');
const courtsValue = Key('sessions-courts-value');
const courtsLess = Key('sessions-courts-less');
const courtsMore = Key('sessions-courts-more');
const templateName = Key('template-name');
const saveTemplate = Key('sessions-save-template');

Key loadKey(SessionTemplate t) => Key('template-load-${t.id}');
Key deleteKey(SessionTemplate t) => Key('template-delete-${t.id}');
