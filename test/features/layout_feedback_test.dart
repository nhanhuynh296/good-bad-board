import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/features/sessions/sessions.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

import '../support/prefs_sandbox.dart';
import '../support/repository_sandbox.dart';

// Layout feedback from Nathan, 2026-10-14.

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void _desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Player _player({String? signInId}) => Player(
  firstName: 'Alice',
  lastName: 'Test',
  elo: Elo.b1,
  id: 'alice',
  signInId: signInId,
);

const _stats = PlayerProfileStats(
  matchCount: 0,
  diversityPercent: 0,
  levelHistory: [],
  topPartners: [],
  attendanceSummary: '',
);

Finder _inkWellOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(InkWell)).first;

Finder _buttonOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(TextButton)).first;

void main() {
  group('Dashboard', () {
    testWidgets('should_put_the_reroll_button_at_the_right_edge_of_a_court', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 460,
              child: CourtCard(courtNumber: 1, players: [], onReroll: () {}),
            ),
          ),
        ),
      );

      final card = tester.getRect(find.byType(CourtCard));
      final reroll = tester.getRect(find.text('Re-roll'));
      expect(card.right - reroll.right, lessThan(32));
    });
  });

  group('Players row', () {
    Future<void> pumpRow(WidgetTester tester, {bool checked = true}) async {
      _desktop(tester);
      await tester.pumpWidget(
        _wrap(
          PlayerRow(
            player: _player(signInId: 'A100'),
            isExpanded: false,
            membership: MembershipStatus.member,
            isCheckedIn: checked,
            onToggleProfile: () {},
          ),
        ),
      );
    }

    testWidgets('should_show_no_check_icon_on_a_checked_in_row', (
      tester,
    ) async {
      await pumpRow(tester);

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('should_show_no_empty_ring_on_a_row_that_is_not_checked_in', (
      tester,
    ) async {
      await pumpRow(tester, checked: false);

      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
    });

    testWidgets('should_give_all_row_controls_the_same_height', (tester) async {
      await pumpRow(tester);

      final heights = [
        '−',
        '+',
        'Member',
        'More',
      ].map((t) => tester.getSize(_inkWellOf(t)).height).toSet();
      expect(heights, {PlayerRow.controlHeight});
    });

    testWidgets('should_put_the_name_and_id_on_one_baseline', (tester) async {
      await pumpRow(tester);

      final name = tester.getRect(find.text('Alice Test'));
      final id = tester.getRect(find.text('A100'));
      expect((name.bottom - id.bottom).abs(), lessThan(4));
    });

    testWidgets('should_center_the_name_with_the_level_text', (tester) async {
      await pumpRow(tester);

      final name = tester.getCenter(find.text('Alice Test'));
      final level = tester.getCenter(find.text('B1'));
      expect((name.dy - level.dy).abs(), lessThan(3));
    });

    testWidgets('should_start_the_name_at_the_name_inset', (tester) async {
      await pumpRow(tester);

      final row = tester.getRect(find.byType(PlayerRow));
      final name = tester.getRect(find.text('Alice Test'));
      // The checked-in row has a 1px border.
      expect(name.left - row.left, 1 + PlayerRow.nameInset);
    });
  });

  group('Player profile', () {
    Future<void> pumpProfile(WidgetTester tester) async {
      _desktop(tester);
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PlayerProfileCard(
              player: _player(),
              stats: _stats,
              onClose: () {},
              onSaveSignInId: (_) => null,
            ),
          ),
        ),
      );
    }

    testWidgets('should_put_the_sign_in_id_on_the_close_button_row', (
      tester,
    ) async {
      await pumpProfile(tester);

      final field = tester.getCenter(
        find.byKey(const Key('player-sign-in-id-field')),
      );
      final close = tester.getCenter(find.byIcon(Icons.close));
      expect((field.dy - close.dy).abs(), lessThan(2));
    });

    testWidgets('should_make_the_save_button_as_tall_as_the_id_field', (
      tester,
    ) async {
      await pumpProfile(tester);

      final field = tester.getSize(
        find.byKey(const Key('player-sign-in-id-field')),
      );
      final save = tester.getSize(_buttonOf('Save'));
      expect(save.height, field.height);
    });

    testWidgets('should_make_the_membership_badge_as_tall_as_the_id_field', (
      tester,
    ) async {
      await pumpProfile(tester);

      final field = tester.getSize(
        find.byKey(const Key('player-sign-in-id-field')),
      );
      final badge = tester.getSize(
        find.byKey(const Key('player-profile-membership')),
      );
      expect(badge.height, field.height);
    });

    testWidgets('should_make_delete_and_close_as_tall_as_the_id_field', (
      tester,
    ) async {
      await pumpProfile(tester);

      final field = tester.getSize(
        find.byKey(const Key('player-sign-in-id-field')),
      );
      final heights = [Icons.delete_outline, Icons.close]
          .map(
            (icon) => tester
                .getSize(
                  find
                      .ancestor(
                        of: find.byIcon(icon),
                        matching: find.byType(InkWell),
                      )
                      .first,
                )
                .height,
          )
          .toSet();
      expect(heights, {field.height});
    });

    testWidgets('should_put_the_close_button_at_the_right_edge', (
      tester,
    ) async {
      await pumpProfile(tester);

      final card = tester.getRect(find.byType(PlayerProfileCard));
      final close = tester.getRect(find.byIcon(Icons.close));
      expect(card.right - close.right, lessThan(40));
    });
  });

  group('Sessions', () {
    late RepositorySandbox sandbox;

    setUp(() async {
      mockPreferences({});
      await PersistentSetting.instance.initialize();
      sandbox = await RepositorySandbox.setUp('layout_feedback_test');
    });

    tearDown(() => sandbox.tearDown());

    Future<void> pumpSessions(WidgetTester tester, GameData gameData) async {
      _desktop(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameData>.value(value: gameData),
            ChangeNotifierProvider<PersistentSetting>.value(
              value: PersistentSetting.instance,
            ),
            ChangeNotifierProvider<TimerData>.value(value: TimerData()),
          ],
          child: _wrap(const SessionsPage()),
        ),
      );
    }

    testWidgets('should_make_save_current_as_tall_as_the_name_field', (
      tester,
    ) async {
      await pumpSessions(tester, GameData());

      final field = tester.getSize(find.byKey(const Key('template-name')));
      // The desktop board (R7-Q3) draws its buttons with an InkWell.
      final save = tester.getSize(_inkWellOf('Save current'));
      expect(save.height, field.height);
    });

    testWidgets('should_give_the_load_button_room_around_its_text', (
      tester,
    ) async {
      final gameData = GameData();
      await tester.runAsync(
        () => gameData.saveTemplate(
          'Monday',
          GameType.timeBased,
          const Duration(minutes: 10),
          16,
          4,
        ),
      );
      await pumpSessions(tester, gameData);
      await tester.pump();

      final load = tester.getSize(_inkWellOf('Load'));
      final text = tester.getSize(find.text('Load'));
      expect(load.height - text.height, greaterThanOrEqualTo(16));
    });
  });
}
