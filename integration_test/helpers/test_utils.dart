import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/main.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/game_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/session_log_repository.dart';
import 'package:good_bad_board/shell/responsive_shell.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:provider/provider.dart';

// ── Tab indices ───────────────────────────────────────────────
// Branch order in ResponsiveShell.tabs. Named rather than inlined: these
// were previously hardcoded, and "Players" was reached with 2 — which is
// Sessions — so those tests were driving the wrong tab.

/// Branch index of the Dashboard tab.
const int dashboardTabIndex = 0;

/// Branch index of the Players tab.
const int playersTabIndex = 1;

/// Branch index of the Sessions tab.
const int sessionsTabIndex = 2;

// ── Screen size presets ───────────────────────────────────────

/// Desktop reference resolution (1280×800).
const Size desktopSize = Size(1280, 800);

/// Tablet reference resolution — iPad portrait (834×1194).
const Size tabletSize = Size(834, 1194);

/// Phone reference resolution — iPhone 14 (390×844).
const Size phoneSize = Size(390, 844);

/// Set the test surface to desktop resolution.
void setDesktopSize(WidgetTester tester) {
  tester.view.physicalSize = desktopSize;
  tester.view.devicePixelRatio = 1.0;
}

/// Set the test surface to tablet resolution.
void setTabletSize(WidgetTester tester) {
  tester.view.physicalSize = tabletSize;
  tester.view.devicePixelRatio = 1.0;
}

/// Set the test surface to phone resolution.
void setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1.0;
}

/// Returns the current logical width of the test surface.
double getCurrentWidth(WidgetTester tester) => tester.view.physicalSize.width;

/// Resize the surface while the app is already running, then settle.
Future<void> resizeApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpAndSettle();
}

// ── App boot ───────────────────────────────────────────────────

/// Renders the full [AppLoader] widget tree and waits for async
/// initialisation to complete.
///
/// Optionally sets [surfaceSize] before pumping so the app boots at
/// the target breakpoint.  Uses a 10-second timeout on
/// [pumpAndSettle] to avoid hanging if repository initialisation
/// fails.
///
Future<void> pumpApp(WidgetTester tester, {Size? surfaceSize}) async {
  // AppLoader's own init chain stops at the first already-initialised
  // repository, so on the second test in a process it would leave the rest
  // unset. Prime them all here first.
  await _ensureReposReady();
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
  }
  await tester.pumpWidget(const AppLoader());
  // AppLoader shows a CircularProgressIndicator while the
  // FutureBuilder waits on repository initialisation.
  await tester.pumpAndSettle(const Duration(seconds: 10));
}

// ── Player factories (pure data, no side-effects) ──────────────

/// Create a single test player with an auto-generated UUID.
Player testPlayer({
  String firstName = 'Test',
  String lastName = 'Player',
  Elo elo = Elo.b2,
  String? signInId,
}) {
  return Player.create(
    firstName: firstName,
    lastName: lastName,
    elo: elo,
    signInId: signInId,
  );
}

/// Batch-create [count] players with distinct names spread across
/// Elo tiers.
List<Player> createTestPlayers(int count, {int startIndex = 0}) {
  const eloValues = Elo.values;
  return List.generate(count, (i) {
    final idx = startIndex + i;
    return Player.create(
      firstName: 'Player$idx',
      lastName: 'Test',
      elo: eloValues[idx % eloValues.length],
    );
  });
}

// ── Navigation ─────────────────────────────────────────────────

/// Returns the label shown in the bottom bar for a given tab label.
/// Dashboard is abbreviated to "Courts" on phone.
String _bottomBarLabel(String fullLabel) {
  switch (fullLabel) {
    case 'Dashboard':
      return 'Courts';
    default:
      return fullLabel;
  }
}

/// Navigate to the tab at [index] in the [ResponsiveShell].
///
/// Handles all three breakpoints automatically:
/// - Desktop / tablet: taps the tab in [TopNavBar].
/// - Phone: taps the primary tab in [BottomTabBar] or opens "More"
///   and taps the secondary tab there.
Future<void> navigateToTab(WidgetTester tester, int index) async {
  final width = getCurrentWidth(tester);
  final tabLabel = ResponsiveShell.tabs[index].label;

  if (isDesktop(width) || isTablet(width)) {
    // TopNavBar — tap the tab pill.
    await tester.tap(find.text(tabLabel).last);
  } else {
    // Phone: primary tabs are directly in BottomTabBar;
    // secondary tabs are accessed via the "More" button.
    final tab = ResponsiveShell.tabs[index];
    if (tab.isPrimary) {
      final label = _bottomBarLabel(tabLabel);
      await tester.tap(find.text(label).last);
    } else {
      // Tap "More", select from sheet.
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tabLabel).last);
      await tester.pumpAndSettle();
    }
  }
  await tester.pumpAndSettle();
}

// ── Dashboard interaction ──────────────────────────────────────

/// Tap the "Generate Game" button and wait for the result.
Future<void> generateGame(WidgetTester tester) async {
  await tester.tap(find.text('Generate Game'));
  await tester.pumpAndSettle();
}

/// Select a waitlisted player by name.
///
/// Works on both desktop ([WaitlistSidebar]) and tablet/phone
/// ([WaitlistChips]) since both render the player name as text.
///
/// Prefer [selectWaitlistedPlayer] where the exact name does not matter —
/// which players end up on court is a weighted random draw, so no particular
/// name is reliably on the waitlist.
Future<void> selectWaitlistPlayer(
  WidgetTester tester,
  String playerName,
) async {
  // On both layouts the name is rendered as a text widget.
  // Use .last to get the one in the waitlist area rather than
  // potentially in a court slot.
  await tester.tap(find.text(playerName).last);
  await tester.pumpAndSettle();
}

/// Reads the players currently off-court from the live [GameData].
List<Player> waitlistedPlayers(WidgetTester tester) => tester
    .element(find.byType(MaterialApp))
    .read<GameData>()
    .visibleWaitlistedPlayers
    .toList();

/// Select the waitlisted player at [index], whoever that turns out to be, and
/// return them.
///
/// Court assignment is a weighted random draw, so a test cannot assume a
/// given name is on the waitlist — ask the state instead.
Future<Player> selectWaitlistedPlayer(
  WidgetTester tester, {
  int index = 0,
}) async {
  final waiting = waitlistedPlayers(tester);
  expect(
    waiting.length,
    greaterThan(index),
    reason: 'expected at least ${index + 1} waitlisted player(s)',
  );
  final player = waiting[index];
  await selectWaitlistPlayer(tester, player.name());
  return player;
}

/// The name of a player currently seated on a court.
String playerOnCourt(WidgetTester tester, {int index = 0}) {
  final onCourt = tester
      .element(find.byType(MaterialApp))
      .read<GameData>()
      .stagingMatches
      .expand((game) => game.players)
      .toList();
  expect(
    onCourt.length,
    greaterThan(index),
    reason: 'expected at least ${index + 1} player(s) on court',
  );
  return onCourt[index].name();
}

/// Tap an "Open slot" text widget on a specific court.
///
/// [courtNumber] is 1-indexed (matches "COURT N" label).
/// [slotIndex] is 0-indexed within the empty slots visible on screen.
///
/// This is a best-effort helper; test files with complex court layouts
/// may need to write their own slot-finding logic.
Future<void> tapOpenSlot(
  WidgetTester tester,
  int courtNumber,
  int slotIndex,
) async {
  // Find all visible "Open slot" texts and tap the one at slotIndex.
  final allSlots = find.text('Open slot').evaluate().toList();
  if (slotIndex < allSlots.length) {
    await tester.tap(find.text('Open slot').at(slotIndex));
    await tester.pumpAndSettle();
  }
}

// ── Player management interaction ──────────────────────────────

/// Add a player directly to [PlayerRepository] (bypasses UI dialog).
Future<void> addPlayerToRepository(Player player) async {
  await PlayerRepository.instance.add(player);
}

/// Add a batch of players directly to [PlayerRepository].
Future<void> addPlayersToRepository(Iterable<Player> players) async {
  for (final p in players) {
    await PlayerRepository.instance.add(p);
  }
}

/// Add a player to the session via the Players tab UI.
///
/// Navigates to Players tab, finds the player by name, and taps the
/// "Inactive" toggle to make them "Active" (adds to [GameData.players]).
Future<void> addPlayerToSession(WidgetTester tester, String playerName) async {
  await navigateToTab(tester, playersTabIndex); // Players tab

  // Find the player row containing the player's name.
  final playerText = find.text(playerName);
  await tester.ensureVisible(playerText);

  // Find the "Inactive" toggle near this player's name.
  final inactiveToggle = find.descendant(
    of: find.ancestor(of: playerText, matching: find.byType(Row)),
    matching: find.text('Inactive'),
  );

  if (inactiveToggle.evaluate().isNotEmpty) {
    await tester.tap(inactiveToggle.first);
    await tester.pumpAndSettle();
  }
}

/// Add a player directly to [GameData] via Provider (bypasses UI).
///
/// Use this when the Players page cannot find the player because it
/// was built before the player was added to the repository.
void directAddPlayerToSession(WidgetTester tester, Player player) {
  final gameData = tester.element(find.byType(MaterialApp)).read<GameData>();
  gameData.checkInPlayer(player);
}

/// Pump the app with players pre-seeded in the repository and session.
///
/// Players are added to [PlayerRepository] and [GameData] before
/// the first frame, so the Players page and Dashboard see them.
Future<void> pumpAppWithPlayers(
  WidgetTester tester, {
  required int playerCount,
  Size? surfaceSize,
}) async {
  // Ensure RepositoryService is initialised before we touch the repos.
  // (In-process tests may have it already set; fresh processes need this.)
  await _ensureReposReady();

  // The repository outlives an individual test, so without this each test in
  // a file adds another [playerCount] players on top of the last one's — and
  // any assertion that counts rows or names a player becomes meaningless.
  await clearAllPlayers();

  // Seed players BEFORE pumping so PlayersPage sees them.
  final players = createTestPlayers(playerCount);
  for (final p in players) {
    await PlayerRepository.instance.add(p);
  }

  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
  }
  await tester.pumpWidget(const AppLoader());
  await tester.pumpAndSettle(const Duration(seconds: 10));

  // Add all players to the session directly via Provider.
  final gameData = tester.element(find.byType(MaterialApp)).read<GameData>();
  for (final p in players) {
    gameData.checkInPlayer(p);
  }
}

/// A temp directory created once per test process, used in place of the
/// real app-documents directory so integration tests never read or write
/// the developer's real players.json/games.json.
Directory? _testDataDir;

String _sandboxedRootPath() =>
    (_testDataDir ??= Directory.systemTemp.createTempSync(
      'good_bad_board_test_',
    )).path;

/// Points every repository singleton at the sandboxed root directory.
///
/// Each adapter's `.instance` is reassignable — unlike the `late final`
/// caches this replaced, calling this again (e.g. before every test in a
/// file) just gives that test a fresh, empty repository state instead of
/// throwing on a second `initialize()`.
Future<void> _ensureReposReady() async {
  await PersistentSetting.instance.initialize();

  final rootDir = _sandboxedRootPath();
  PlayerRepository.instance = await PlayerRepository.initialize(
    rootDir: rootDir,
  );
  GameRepository.instance = await GameRepository.initialize(rootDir: rootDir);
  SessionLogRepository.instance = await SessionLogRepository.initialize(
    rootDir: rootDir,
  );
  PendingRegistrationRepository.instance =
      await PendingRegistrationRepository.initialize(rootDir: rootDir);
}

// ── State cleanup ──────────────────────────────────────────────

/// Delete all players from [PlayerRepository].
Future<void> clearAllPlayers() async {
  final players = PlayerRepository.instance.listedPlayers().toList();
  for (final p in players) {
    await PlayerRepository.instance.delete(p.id);
  }
}

/// Delete all games from [GameRepository].
Future<void> clearAllGames() async {
  final games = GameRepository.instance.getAll().toList();
  for (final g in games) {
    await GameRepository.instance.delete(g.id);
  }
}
