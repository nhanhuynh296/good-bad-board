import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import 'courts_harness.dart' show StopClockOnDispose;
import 'prefs_sandbox.dart';
import 'repository_sandbox.dart';

/// Sets up the preferences, a temp-dir repository sandbox and the bundled
/// Source Sans 3 for a desktop Players widget test file. Tests never touch
/// the real data directory (PERSISTENCE.md §2.2).
void setUpPlayersSandbox(String name) {
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
  tearDown(() => sandbox.tearDown());
}

/// A test player with a readable id (its first name).
Player testPlayer(
  String name,
  Elo elo, {
  String? signInId,
  MembershipStatus membership = MembershipStatus.member,
}) => Player(
  firstName: name,
  lastName: 'Test',
  elo: elo,
  id: name,
  signInId: signInId,
  membership: membership,
);

/// Builds the Players tab at desktop size (IMPLEMENTATION 8.7) with the
/// desktop page padding of the shell.
class PlayersHarness {
  PlayersHarness(this.tester);

  final WidgetTester tester;
  final TimerData timer = TimerData()..duration = const Duration(minutes: 10);
  late final GameData gameData = GameData(timer: timer, random: Random(5));

  Future<void> pump({
    List<Player> players = const [],
    int sessionCapacity = 20,
    int courts = 4,
    Size size = const Size(1280, 720),
    Locale locale = const Locale('en'),
  }) async {
    await tester.runAsync(() => PlayerRepository.instance.addAll(players));
    gameData
      ..setSessionCapacity(sessionCapacity)
      ..setNumberOfCourt(courts);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      StopClockOnDispose(
        timer: timer,
        child: ChangeNotifierProvider<GameData>.value(
          value: gameData,
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
                      child: PlayersPage(),
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

  /// Lets a fire-and-forget repository write land.
  Future<void> flush() => tester.pump(const Duration(milliseconds: 50));

  // ── Finders ──────────────────────────────────────────────

  Finder get scanField => find.byKey(const Key('players-scan-field'));

  EditableText get scanEditable => tester.widget<EditableText>(
    find.descendant(of: scanField, matching: find.byType(EditableText)),
  );

  ScanResult get result =>
      tester.widget<ScanResultBox>(find.byType(ScanResultBox)).result;

  Finder rowOf(String name) => find.ancestor(
    of: find.text('$name Test'),
    matching: find.byType(DesktopPlayerRow),
  );

  Finder moreOf(String name) => find.descendant(
    of: rowOf(name),
    matching: find.byKey(const Key('player-more')),
  );

  Finder tierChip(SkillTier tier) => find.byKey(Key('tier-chip-${tier.name}'));

  // ── Actions ──────────────────────────────────────────────

  /// What the barcode scanner does: types the text, then sends Enter.
  Future<void> scan(String text) async {
    await tester.enterText(scanField, text);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  }

  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> tapRow(String name) => tap(
    find.descendant(
      of: rowOf(name),
      matching: find.byKey(const Key('player-row-toggle')),
    ),
  );

  Future<void> openMore(String name) => tap(moreOf(name));
}
