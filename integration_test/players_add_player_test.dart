import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players_page.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

/// Regression cover for the add-player dialog blanking the app.
///
/// `showDialog` puts the dialog on the **root** Navigator, but a caller's own
/// `BuildContext` inside the shell resolves to the per-tab Navigator created
/// by `StatefulShellRoute.indexedStack`. Popping from the caller therefore
/// tore `/players` off its branch — leaving an empty Navigator and a blank
/// screen — while the dialog stayed up and the player was never saved.
///
/// These tests drive the real app through go_router, so they fail if the pop
/// ever targets the wrong Navigator again.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Opens the Players tab with the add-player dialog showing.
  Future<void> openAddPlayerDialog(WidgetTester tester) async {
    setDesktopSize(tester);
    await pumpApp(tester);
    await navigateToTab(tester, playersTabIndex);
    expect(find.byType(PlayersPage), findsOneWidget);

    // Desktop: the orange "Add player" button by the scan field (PLY-13).
    await tester.tap(find.text('Add player'));
    await tester.pumpAndSettle();
    expect(find.byType(AddPlayerDialog), findsOneWidget);
  }

  /// Fills every required field of the open dialog.
  Future<void> fillForm(
    WidgetTester tester, {
    required String firstName,
    required String lastName,
  }) async {
    final fields = find.descendant(
      of: find.byType(AddPlayerDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), firstName);
    await tester.enterText(fields.at(1), lastName);

    // Skill level is a required dropdown. byType would need the exact
    // type argument, so match on the raw type instead.
    await tester.tap(
      find.descendant(
        of: find.byType(AddPlayerDialog),
        matching: find.byWidgetPredicate((w) => w is DropdownButtonFormField),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('B1').last);
    await tester.pumpAndSettle();
  }

  group('Add player — the dialog must not tear down the Players tab', () {
    testWidgets('submitting keeps the Players tab on screen', (tester) async {
      await openAddPlayerDialog(tester);
      await fillForm(tester, firstName: 'Wilma', lastName: 'Integration');

      await tester.tap(find.byKey(const Key('add-player-submit')));
      await tester.pumpAndSettle();

      // The dialog closed…
      expect(find.byType(AddPlayerDialog), findsNothing);
      // …and the tab underneath is still mounted. A blank screen shows up
      // here as PlayersPage having been popped off its branch Navigator.
      expect(find.byType(PlayersPage), findsOneWidget);

      await clearAllPlayers();
    });

    testWidgets('submitting adds the player to the list', (tester) async {
      await openAddPlayerDialog(tester);
      await fillForm(tester, firstName: 'Boris', lastName: 'Integration');

      await tester.tap(find.byKey(const Key('add-player-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Boris Integration'), findsWidgets);

      await clearAllPlayers();
    });

    testWidgets('cancelling keeps the Players tab on screen', (tester) async {
      await openAddPlayerDialog(tester);

      await tester.tap(find.byKey(const Key('add-player-cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AddPlayerDialog), findsNothing);
      expect(find.byType(PlayersPage), findsOneWidget);
    });

    testWidgets('an invalid form keeps the dialog open', (tester) async {
      await openAddPlayerDialog(tester);

      // Submit with every field empty.
      await tester.tap(find.byKey(const Key('add-player-submit')));
      await tester.pumpAndSettle();

      expect(find.byType(AddPlayerDialog), findsOneWidget);
      expect(find.byType(PlayersPage), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-player-cancel')));
      await tester.pumpAndSettle();
    });
  });
}
