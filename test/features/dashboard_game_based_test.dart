import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/repository_sandbox.dart';

/// Game-based mode on the Dashboard: no countdown, no global Save, Regenerate
/// only until the first lineup exists, and a per-court Save that marks the
/// court PLAYING.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorySandbox sandbox;

  Future<void> setMode(String mode) async {
    SharedPreferences.setMockInitialValues({'gameType': mode});
    await PersistentSetting.instance.initialize();
  }

  setUp(() async {
    await setMode('gameBased');
    sandbox = await RepositorySandbox.setUp('dashboard_game_based_test');
  });

  tearDown(() => sandbox.tearDown());

  Widget wrap(GameData gameData, TimerData timerData) => MultiProvider(
    providers: [
      ChangeNotifierProvider<GameData>.value(value: gameData),
      ChangeNotifierProvider<TimerData>.value(value: timerData),
      ChangeNotifierProvider<PersistentSetting>.value(
        value: PersistentSetting.instance,
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: DashboardPage())),
  );

  /// A [GameData] with [total] checked-in players and one court.
  GameData seed(int total) {
    final gameData = GameData()..setNumberOfCourt(1);
    for (var i = 0; i < total; i++) {
      final player = Player.create(
        firstName: 'Player',
        lastName: '$i',
        elo: Elo.values[i % Elo.values.length],
      );
      PlayerRepository.instance.add(player);
      gameData.addFullPricedPlayer(player);
      gameData.checkInPlayer(player);
    }
    return gameData;
  }

  /// Saves court 0 and rebuilds.
  ///
  /// Driven through [WidgetTester.runAsync] rather than by tapping the button:
  /// saving writes to disk, and a widget test's fake-async zone never
  /// completes real file I/O. The button's wiring to the callback is covered
  /// by the CourtCard tests in `dashboard_test.dart`.
  Future<void> saveCourt(WidgetTester tester, GameData gameData) async {
    await tester.runAsync(
      () => gameData.saveSingleGame(gameData.stagingMatches[0]),
    );
    await tester.pumpAndSettle();
  }

  /// Widens the test surface so the dashboard renders its desktop layout.
  void useDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  // ---------------------------------------------------------------------
  // No countdown in game-based mode
  // ---------------------------------------------------------------------

  testWidgets('should_hide_round_rotation_bar_when_game_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byType(RoundRotationBar), findsNothing);
  });

  testWidgets('should_show_round_rotation_bar_when_time_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    await setMode('timeBased');
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byType(RoundRotationBar), findsOneWidget);

    // The countdown ticks — settle it before the test ends.
    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_not_start_timer_when_game_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    final timerData = TimerData();
    await tester.pumpWidget(wrap(gameData, timerData));

    // Act — generate the first lineup.
    await tester.tap(find.text('Generate Game'));
    await tester.pump();

    // Assert
    expect(timerData.isRunning, isFalse);
  });

  // ---------------------------------------------------------------------
  // Action bar
  // ---------------------------------------------------------------------

  testWidgets('should_hide_global_save_when_game_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byKey(const Key('dashboard-save-all')), findsNothing);
  });

  testWidgets('should_show_global_save_when_time_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    await setMode('timeBased');
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byKey(const Key('dashboard-save-all')), findsOneWidget);

    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_show_generate_before_the_first_game_when_game_based', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.text('Generate Game'), findsOneWidget);
  });

  testWidgets('should_hide_regenerate_once_a_lineup_exists_when_game_based', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.text('Generate Game'), findsNothing);
    expect(find.text('Regenerate'), findsNothing);
  });

  testWidgets('should_keep_regenerate_after_a_lineup_exists_when_time_based', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    await setMode('timeBased');
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.text('Regenerate'), findsOneWidget);

    tester.binding.delayed(const Duration(seconds: 1));
  });

  // ---------------------------------------------------------------------
  // Per-court Save and the PLAYING badge
  // ---------------------------------------------------------------------

  testWidgets('should_show_court_save_button_when_game_based_and_court_full', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byKey(const Key('court-save-button')), findsOneWidget);
  });

  testWidgets('should_hide_court_save_button_when_time_based', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    await setMode('timeBased');
    final gameData = seed(4);
    await gameData.makeGame();

    // Act
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Assert
    expect(find.byKey(const Key('court-save-button')), findsNothing);

    tester.binding.delayed(const Duration(seconds: 1));
  });

  testWidgets('should_show_playing_badge_after_court_saved', (tester) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Act
    await saveCourt(tester, gameData);

    // Assert
    expect(find.text('PLAYING'), findsOneWidget);
  });

  testWidgets('should_hide_court_save_button_once_the_court_is_playing', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Act
    await saveCourt(tester, gameData);

    // Assert
    expect(find.byKey(const Key('court-save-button')), findsNothing);
  });

  testWidgets('should_keep_the_lineup_visible_once_the_court_is_playing', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Act
    await saveCourt(tester, gameData);

    // Assert — all four players are still on court, no open slots.
    expect(find.text('Open slot'), findsNothing);
  });

  testWidgets('should_offer_reroll_again_once_the_court_is_playing', (
    tester,
  ) async {
    // Arrange
    useDesktopSurface(tester);
    final gameData = seed(4);
    await gameData.makeGame();
    await tester.pumpWidget(wrap(gameData, TimerData()));

    // Act
    await saveCourt(tester, gameData);

    // Assert — re-roll is how the organizer ends the game.
    expect(find.text('Re-roll'), findsOneWidget);
  });
}
