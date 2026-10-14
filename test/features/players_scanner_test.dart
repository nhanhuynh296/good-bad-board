import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

import '../support/repository_sandbox.dart';

Player _player(
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

void main() {
  late GameData gameData;
  late RepositorySandbox sandbox;

  setUp(() async {
    sandbox = await RepositorySandbox.setUp('players_scanner_test');
  });

  tearDown(() => sandbox.tearDown());

  Future<void> pumpPage(
    WidgetTester tester, {
    required List<Player> players,
    int sessionCapacity = 20,
    bool showImport = false,
  }) async {
    await tester.runAsync(() => PlayerRepository.instance.addAll(players));
    gameData = GameData()
      ..setSessionCapacity(sessionCapacity)
      ..setNumberOfCourt(4);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChangeNotifierProvider.value(
            value: gameData,
            child: PlayersPage(showImportButton: showImport),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final searchField = find.byType(TextField).first;
  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText).first);

  /// What the barcode scanner does: types the ID, then sends Enter.
  Future<void> scan(WidgetTester tester, String id) async {
    await tester.enterText(searchField, id);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  }

  Finder rowOf(String name) => find.ancestor(
    of: find.text('$name Test'),
    matching: find.byType(PlayerRow),
  );

  group('S2 — scanner flow', () {
    testWidgets('should_focus_the_search_field_when_the_page_opens', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      expect(editable(tester).focusNode.hasFocus, isTrue);
    });

    testWidgets('should_check_in_the_player_when_id_and_enter_are_sent', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice, _player('Bob', Elo.a2)]);

      await scan(tester, 'A100');

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_keep_the_scanned_text_after_a_scan', (tester) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await scan(tester, 'A100');

      expect(editable(tester).controller.text, 'A100');
    });

    testWidgets('should_select_all_the_text_after_a_scan', (tester) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await scan(tester, 'A100');
      await tester.pump();

      expect(
        editable(tester).controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
    });

    testWidgets('should_keep_the_one_result_listed_after_a_scan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'A100'),
          _player('Bob', Elo.a2, signInId: 'B200'),
        ],
      );

      await scan(tester, 'A100');

      expect(find.byType(PlayerRow), findsOneWidget);
    });

    testWidgets('should_keep_focus_in_the_search_field_after_a_scan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await scan(tester, 'A100');
      await tester.pump();

      expect(editable(tester).focusNode.hasFocus, isTrue);
    });

    testWidgets('should_show_the_player_name_in_a_snackbar_after_a_scan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await scan(tester, 'A100');

      expect(find.text('Alice Test checked in'), findsOneWidget);
    });

    testWidgets('should_check_in_when_the_done_action_is_sent_instead', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice]);

      await tester.enterText(searchField, 'A100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_match_the_id_ignoring_case_and_spaces', (tester) async {
      final alice = _player('Alice', Elo.b1, signInId: 'ab12');
      await pumpPage(tester, players: [alice]);

      await scan(tester, '  AB12 ');

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_check_out_a_player_who_is_already_checked_in', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice]);
      gameData.checkInPlayer(alice);
      await tester.pump();

      await scan(tester, 'A100');

      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_say_checked_out_after_a_second_scan', (tester) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice]);
      gameData.checkInPlayer(alice);
      await tester.pump();

      await scan(tester, 'A100');

      expect(find.text('Alice Test checked out'), findsOneWidget);
    });

    testWidgets('should_keep_the_text_and_say_no_player_when_id_unknown', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await scan(tester, 'ZZZ');

      expect(find.text('No player with ID ZZZ'), findsOneWidget);
      expect(editable(tester).controller.text, 'ZZZ');
    });

    testWidgets('should_toggle_the_one_result_of_a_partial_id', (tester) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice, _player('Bob', Elo.a2)]);

      await scan(tester, 'A10');

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_toggle_the_one_result_of_a_name', (tester) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice, _player('Bob', Elo.a2)]);

      await scan(tester, 'ali');

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_change_nobody_when_many_results_are_listed', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'A100'),
          _player('Alan', Elo.a2, signInId: 'A200'),
        ],
      );

      await scan(tester, 'A');

      expect(gameData.checkedInCount, 0);
    });

    testWidgets('should_say_how_many_match_when_many_results_are_listed', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'A100'),
          _player('Alan', Elo.a2, signInId: 'A200'),
        ],
      );

      await scan(tester, 'A');

      expect(find.text('2 players match — nothing changed'), findsOneWidget);
    });

    testWidgets('should_toggle_the_exact_id_when_another_id_starts_with_it', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: '12');
      final bob = _player('Bob', Elo.a2, signInId: '123');
      await pumpPage(tester, players: [alice, bob]);

      await scan(tester, '12');

      expect([alice, bob].map(gameData.isPlayerCheckedIn), [isTrue, isFalse]);
    });

    testWidgets('should_refuse_the_scan_when_the_session_is_at_capacity', (
      tester,
    ) async {
      final full = [
        _player('Alice', Elo.b1),
        _player('Bob', Elo.a2),
        _player('Dave', Elo.c1),
        _player('Erin', Elo.s1),
      ];
      final carol = _player('Carol', Elo.b1, signInId: 'C300');
      await pumpPage(
        tester,
        players: [...full, carol],
        sessionCapacity: GameData.minSessionCapacity,
      );
      full.forEach(gameData.checkInPlayer);
      await tester.pump();

      await scan(tester, 'C300');

      expect(gameData.isPlayerCheckedIn(carol), isFalse);
      expect(
        find.text('Session at capacity — cannot check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_keep_the_text_when_the_session_is_at_capacity', (
      tester,
    ) async {
      final full = [
        _player('Alice', Elo.b1),
        _player('Bob', Elo.a2),
        _player('Dave', Elo.c1),
        _player('Erin', Elo.s1),
      ];
      await pumpPage(
        tester,
        players: [
          ...full,
          _player('Carol', Elo.b1, signInId: 'C300'),
        ],
        sessionCapacity: GameData.minSessionCapacity,
      );
      full.forEach(gameData.checkInPlayer);
      await tester.pump();

      await scan(tester, 'C300');

      expect(editable(tester).controller.text, 'C300');
    });

    testWidgets('should_not_check_in_a_disabled_player_by_scan', (
      tester,
    ) async {
      final dave = _player(
        'Dave',
        Elo.b1,
        signInId: 'D400',
        membership: MembershipStatus.disabled,
      );
      await pumpPage(tester, players: [dave]);

      await scan(tester, 'D400');

      expect(gameData.isPlayerCheckedIn(dave), isFalse);
      expect(
        find.text('Dave Test is disabled — cannot check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_ignore_enter_when_the_field_is_empty', (tester) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );

      await tester.enterText(searchField, '');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('S2 — search by name or ID', () {
    testWidgets('should_list_a_player_whose_sign_in_id_contains_the_text', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'ZED99'),
          _player('Bob', Elo.a2),
        ],
      );

      await tester.enterText(searchField, 'zed');
      await tester.pumpAndSettle();

      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('Bob Test'), findsNothing);
    });

    testWidgets('should_still_list_a_player_whose_name_contains_the_text', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'ZED99'),
          _player('Bob', Elo.a2),
        ],
      );

      await tester.enterText(searchField, 'bob');
      await tester.pumpAndSettle();

      expect(find.text('Bob Test'), findsOneWidget);
    });
  });

  group('D1 — tap row toggles check-in', () {
    testWidgets('should_check_in_when_an_unchecked_row_is_tapped', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);

      await tester.tap(find.text('Alice Test'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    });

    testWidgets('should_check_out_when_a_checked_in_row_is_tapped', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);
      gameData.checkInPlayer(alice);
      await tester.pump();

      await tester.tap(find.text('Alice Test'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_do_nothing_when_a_disabled_row_is_tapped', (
      tester,
    ) async {
      final dave = _player(
        'Dave',
        Elo.b1,
        membership: MembershipStatus.disabled,
      );
      await pumpPage(tester, players: [dave]);

      await tester.tap(find.text('Dave Test'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(dave), isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('should_show_the_capacity_message_when_row_tap_is_refused', (
      tester,
    ) async {
      final full = [
        _player('Alice', Elo.b1),
        _player('Bob', Elo.a2),
        _player('Dave', Elo.c1),
        _player('Erin', Elo.s1),
      ];
      await pumpPage(
        tester,
        players: [...full, _player('Carol', Elo.b1)],
        sessionCapacity: GameData.minSessionCapacity,
      );
      full.forEach(gameData.checkInPlayer);
      await tester.pump();

      await tester.tap(find.text('Carol Test'));
      await tester.pump();

      expect(
        find.text('Session at capacity — cannot check in'),
        findsOneWidget,
      );
    });

    testWidgets('should_not_show_a_checked_in_column_header', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      expect(find.text('CHECKED IN'), findsNothing);
    });

    testWidgets('should_not_show_in_or_out_pills_on_the_row', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      expect(find.text('Out'), findsNothing);
    });

    testWidgets('should_open_the_profile_without_checking_in_on_more_tap', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Current Level'), findsOneWidget);
      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_close_the_profile_when_more_is_tapped_again', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Current Level'), findsNothing);
    });

    testWidgets('should_show_a_down_chevron_closed_and_an_up_chevron_open', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    });

    testWidgets('should_not_check_in_when_the_level_plus_is_tapped', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_raise_the_level_when_the_level_plus_is_tapped', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      await tester.tap(find.text('+'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        PlayerRepository.instance.byId('Alice')!.elo,
        Elo.values[Elo.b1.index + 1],
      );
    });

    testWidgets('should_do_nothing_when_a_dimmed_level_minus_is_tapped', (
      tester,
    ) async {
      final lowest = _player('Alice', Elo.values.first);
      await pumpPage(tester, players: [lowest]);

      await tester.tap(find.text('−'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(lowest), isFalse);
      expect(find.text('Current Level'), findsNothing);
    });

    testWidgets('should_do_nothing_when_a_dimmed_level_plus_is_tapped', (
      tester,
    ) async {
      final highest = _player('Alice', Elo.values.last);
      await pumpPage(tester, players: [highest]);

      await tester.tap(find.text('+'));
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(highest), isFalse);
      expect(find.text('Current Level'), findsNothing);
    });

    testWidgets('should_not_check_in_when_the_membership_pill_is_tapped', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);

      await tester.tap(find.text('Member'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });

    testWidgets('should_expose_the_row_as_a_checked_toggle_button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);
      gameData.checkInPlayer(alice);
      await tester.pump();

      final semantics = tester.getSemantics(
        find.descendant(
          of: rowOf('Alice'),
          matching: find.byKey(const Key('player-row-toggle')),
        ),
      );

      expect(
        semantics.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );
      handle.dispose();
    });

    testWidgets('should_draw_the_accent_bar_only_on_a_checked_in_row', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(
        tester,
        players: [
          alice,
          _player('Bob', Elo.a2),
          _player('Dave', Elo.c1, membership: MembershipStatus.disabled),
        ],
      );
      gameData.checkInPlayer(alice);
      await tester.pump();

      Finder bar(String name) => find.descendant(
        of: rowOf(name),
        matching: find.byKey(const Key('player-row-bar')),
      );

      expect(
        [
          bar('Alice').evaluate().length,
          bar('Bob').evaluate().length,
          bar('Dave').evaluate().length,
        ],
        [1, 0, 0],
      );
    });

    testWidgets('should_fill_a_checked_in_row_with_the_success_background', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1);
      await pumpPage(tester, players: [alice]);
      gameData.checkInPlayer(alice);
      await tester.pump();

      final material = tester.widget<Material>(
        find
            .descendant(of: rowOf('Alice'), matching: find.byType(Material))
            .first,
      );

      expect(material.color, AppColors.successBg);
    });

    testWidgets('should_show_the_name_in_subtle_text_on_a_disabled_row', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [
          _player('Dave', Elo.c1, membership: MembershipStatus.disabled),
        ],
      );

      final name = tester.widget<Text>(find.text('Dave Test'));
      expect(name.style?.color, AppColors.textSubtle);
    });

    testWidgets('should_hide_the_import_button_by_default', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      expect(find.text('Import'), findsNothing);
    });

    testWidgets('should_show_the_import_button_when_the_flag_is_on', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1)],
        showImport: true,
      );

      expect(find.text('Import'), findsOneWidget);
    });
  });

  group('S1 — edit the sign-in ID', () {
    Future<void> openProfile(WidgetTester tester, String name) async {
      await tester.tap(
        find.descendant(of: rowOf(name), matching: find.text('More')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> saveId(WidgetTester tester, String text) async {
      await tester.enterText(
        find.byKey(const Key('player-sign-in-id-field')),
        text,
      );
      await tester.tap(find.byKey(const Key('player-sign-in-id-save')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('should_save_the_new_sign_in_id_trimmed', (tester) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'OLD')],
      );
      await openProfile(tester, 'Alice');

      await saveId(tester, '  NEW1 ');

      expect(PlayerRepository.instance.byId('Alice')!.signInId, 'NEW1');
    });

    testWidgets('should_store_no_id_when_the_field_is_emptied', (tester) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'OLD')],
      );
      await openProfile(tester, 'Alice');

      await saveId(tester, '   ');

      expect(PlayerRepository.instance.byId('Alice')!.signInId, isNull);
    });

    testWidgets('should_refuse_an_id_used_by_another_player', (tester) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'A100'),
          _player('Bob', Elo.a2, signInId: 'B200'),
        ],
      );
      await openProfile(tester, 'Alice');

      await saveId(tester, 'b200');

      expect(PlayerRepository.instance.byId('Alice')!.signInId, 'A100');
      expect(
        find.text('Sign In ID "b200" is already used by Bob Test'),
        findsOneWidget,
      );
    });

    testWidgets('should_accept_the_unchanged_id_of_the_same_player', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.b1, signInId: 'A100')],
      );
      await openProfile(tester, 'Alice');

      await saveId(tester, 'A100');

      expect(find.textContaining('already used'), findsNothing);
    });

    testWidgets('should_not_change_other_fields_when_the_id_is_saved', (
      tester,
    ) async {
      await pumpPage(
        tester,
        players: [_player('Alice', Elo.c1, signInId: 'OLD')],
      );
      await openProfile(tester, 'Alice');

      await saveId(tester, 'NEW1');

      final saved = PlayerRepository.instance.byId('Alice')!;
      expect(
        [saved.elo, saved.firstName, saved.membership],
        [Elo.c1, 'Alice', MembershipStatus.member],
      );
    });

    testWidgets('should_not_show_the_level_progression_block', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await openProfile(tester, 'Alice');

      expect(find.text('LEVEL PROGRESSION'), findsNothing);
    });
  });

  group('R1 — scanner keeps focus after clicks', () {
    // Flutter only unfocuses a text field on an outside tap on desktop.
    final desktop = TargetPlatformVariant.only(TargetPlatform.windows);

    /// A scanner types into whatever has focus, then sends Enter. This
    /// sets the text and sends the key, so a field without focus gets nothing.
    Future<void> scanWithKeys(WidgetTester tester, String id) async {
      editable(tester).controller.text = id;
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
    }

    bool searchHasFocus(WidgetTester tester) =>
        editable(tester).focusNode.hasFocus;

    testWidgets('should_refocus_the_search_after_a_row_tap', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      await tester.tap(find.text('Alice Test'));
      await tester.pump();
      await tester.pump();

      expect(searchHasFocus(tester), isTrue);
    }, variant: desktop);

    testWidgets('should_check_in_by_scan_after_a_row_tap', (tester) async {
      final bob = _player('Bob', Elo.a2, signInId: 'B200');
      await pumpPage(tester, players: [_player('Alice', Elo.b1), bob]);
      await tester.tap(find.text('Alice Test'));
      await tester.pump();
      await tester.pump();

      await scanWithKeys(tester, 'B200');

      expect(gameData.isPlayerCheckedIn(bob), isTrue);
    }, variant: desktop);

    testWidgets('should_clear_a_stale_query_on_a_row_tap', (tester) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await tester.enterText(searchField, 'Ali');
      await tester.pump();

      await tester.tap(find.text('Alice Test'));
      await tester.pump();

      expect(editable(tester).controller.text, isEmpty);
    }, variant: desktop);

    testWidgets('should_refocus_the_search_after_a_level_chip_tap', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      await tester.tap(find.text(Elo.b1.toDisplayName()).first);
      await tester.pump();
      await tester.pump();

      expect(searchHasFocus(tester), isTrue);
    }, variant: desktop);

    testWidgets('should_refocus_the_search_after_a_profile_is_closed', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(searchHasFocus(tester), isTrue);
    }, variant: desktop);

    testWidgets('should_scan_after_a_profile_is_opened_and_closed', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      await pumpPage(tester, players: [alice]);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      await scanWithKeys(tester, 'A100');

      expect(gameData.isPlayerCheckedIn(alice), isTrue);
    }, variant: desktop);

    testWidgets('should_refocus_the_search_after_the_add_dialog_closes', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-player-cancel')));
      await tester.pumpAndSettle();

      expect(searchHasFocus(tester), isTrue);
    }, variant: desktop);

    testWidgets('should_not_steal_focus_while_the_add_dialog_is_open', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(searchHasFocus(tester), isFalse);
    }, variant: desktop);

    testWidgets('should_not_steal_focus_from_the_sign_in_id_field', (
      tester,
    ) async {
      await pumpPage(tester, players: [_player('Alice', Elo.b1)]);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('player-sign-in-id-field')));
      await tester.pumpAndSettle();

      expect(searchHasFocus(tester), isFalse);
    });
  });

  group('R4 — Enter handling', () {
    testWidgets('should_check_in_both_players_of_two_fast_scans', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'A100');
      final bob = _player('Bob', Elo.a2, signInId: 'B200');
      await pumpPage(tester, players: [alice, bob]);

      await scan(tester, 'A100');
      await scan(tester, 'B200');

      expect(
        [alice, bob].map(gameData.isPlayerCheckedIn),
        everyElement(isTrue),
      );
    });

    testWidgets('should_ignore_enter_while_an_ime_composition_is_active', (
      tester,
    ) async {
      final alice = _player('Alice', Elo.b1, signInId: 'ni');
      await pumpPage(tester, players: [alice]);
      editable(tester).controller.value = const TextEditingValue(
        text: 'ni',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      await tester.showKeyboard(searchField);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(gameData.isPlayerCheckedIn(alice), isFalse);
    });
  });

  group('R5 — duplicate sign-in IDs', () {
    testWidgets('should_say_the_id_is_used_by_two_players', (tester) async {
      await pumpPage(
        tester,
        players: [
          _player('Alice', Elo.b1, signInId: 'D1'),
          _player('Bob', Elo.a2, signInId: 'd1'),
        ],
      );

      await scan(tester, 'D1');

      expect(find.text('ID D1 is used by 2 players'), findsOneWidget);
    });

    testWidgets('should_check_nobody_in_when_the_id_is_shared', (tester) async {
      final alice = _player('Alice', Elo.b1, signInId: 'D1');
      final bob = _player('Bob', Elo.a2, signInId: 'D1');
      await pumpPage(tester, players: [alice, bob]);

      await scan(tester, 'D1');

      expect(gameData.checkedInCount, 0);
    });
  });
}
