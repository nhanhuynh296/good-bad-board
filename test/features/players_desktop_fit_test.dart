import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';

import '../support/players_harness.dart';

// IMPLEMENTATION 8.7.1 (pending card restyled, R2-Q19) and the layout fit
// of the desktop Players tab in every locale (8.8: en, fr, zh, zh_HK).

void main() {
  setUpPlayersSandbox('players_desktop_fit_test');

  Future<void> addRegistration(WidgetTester tester) => tester.runAsync(
    () => PendingRegistrationRepository.instance.add(
      PendingRegistration.create(
        name: 'Hana Ito',
        contact: 'hana@example.com',
        tier: SkillTier.intermediate,
      ),
    ),
  );

  group('Pending sign-ups card (desktop)', () {
    testWidgets('should_show_the_registration_on_one_44_px_line', (
      tester,
    ) async {
      await addRegistration(tester);
      final h = PlayersHarness(tester);
      await h.pump();

      expect(
        tester
            .getSize(find.byKey(const Key('pending-registrations-card')))
            .height,
        44 + 2,
      );
    });

    testWidgets('should_show_the_title_name_tier_and_contact', (tester) async {
      await addRegistration(tester);
      final h = PlayersHarness(tester);
      await h.pump();

      expect(find.text('Pending self-registrations (1)'), findsOneWidget);
      expect(
        find.text('Hana Ito · Intermediate · hana@example.com'),
        findsOneWidget,
      );
    });

    testWidgets('should_create_the_player_when_approve_is_tapped', (
      tester,
    ) async {
      await addRegistration(tester);
      final h = PlayersHarness(tester);
      await h.pump();

      await tester.runAsync(() async {
        await tester.tap(find.text('Approve'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(
        PlayerRepository.instance.listedPlayers().map((p) => p.name()),
        contains('Hana Ito'),
      );
    });
  });

  group('Layout fit (no overflow)', () {
    final players = [
      testPlayer('Alice', Elo.b1, signInId: 'BC-104'),
      testPlayer(
        'Bartholomew-Maximilian',
        Elo.s1,
        signInId: 'BC-1234567890',
        membership: MembershipStatus.casual,
      ),
      testPlayer('Dave', Elo.c1, membership: MembershipStatus.disabled),
    ];

    for (final locale in const [
      Locale('en'),
      Locale('fr'),
      Locale('zh'),
      Locale('zh', 'HK'),
    ]) {
      for (final width in const [1080.0, 1280.0]) {
        testWidgets(
          'should_fit_the_open_more_panel_at_${width.toInt()}_in_$locale',
          (tester) async {
            await addRegistration(tester);
            final h = PlayersHarness(tester);
            await h.pump(
              players: players,
              size: Size(width, 720),
              locale: locale,
            );
            h.gameData.checkInPlayer(players.first);
            await tester.pump();

            await h.scan('BC-1234567890');
            await h.scan('BC-1234567890');
            await h.tap(h.moreOf('Bartholomew-Maximilian'));

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
