import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/players/players.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:provider/provider.dart';

import '../support/repository_sandbox.dart';

Widget wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: ChangeNotifierProvider<GameData>.value(
      value: GameData(),
      child: child,
    ),
  ),
);

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    sandbox = await RepositorySandbox.setUp(
      'players_pending_registration_test',
    );
  });

  tearDown(() => sandbox.tearDown());

  group('REG-06: PlayersPage pending-approval queue', () {
    testWidgets('shows a pending registration submitted via the repository', (
      tester,
    ) async {
      await tester.runAsync(
        () => PendingRegistrationRepository.instance.add(
          PendingRegistration.create(
            name: 'New Player',
            contact: 'new@example.com',
            tier: SkillTier.intermediate,
          ),
        ),
      );

      await tester.pumpWidget(wrap(const PlayersPage()));
      await tester.pump();
      await tester.pump();

      expect(find.text('Pending self-registrations (1)'), findsOneWidget);
      expect(find.text('New Player'), findsOneWidget);
    });

    testWidgets(
      'approving creates a real Player at the tier lower-bound Elo and '
      'removes the pending entry',
      (tester) async {
        await tester.runAsync(
          () => PendingRegistrationRepository.instance.add(
            PendingRegistration.create(
              name: 'Jane Doe',
              contact: 'jane@example.com',
              tier: SkillTier.advanced,
            ),
          ),
        );

        await tester.pumpWidget(wrap(const PlayersPage()));
        await tester.pump();
        await tester.pump();

        // Approve triggers real disk I/O (PlayerRepository.add +
        // PendingRegistrationRepository.delete), which doesn't play well
        // inside the fake-async testWidgets zone — invoke and await the
        // real callback directly instead of tapping + guessing a delay.
        final card = tester.widget<PendingRegistrationCard>(
          find.byType(PendingRegistrationCard),
        );
        await tester.runAsync(() async {
          await (card.onApprove as dynamic)(0);
        });
        await tester.pump();
        await tester.pump();

        expect(find.text('Pending self-registrations'), findsNothing);
        final pending = PendingRegistrationRepository.instance.getAll();
        expect(pending, isEmpty);

        final players = PlayerRepository.instance.listedPlayers();
        expect(players, hasLength(1));
        final created = players.first;
        expect(created.firstName, 'Jane');
        expect(created.lastName, 'Doe');
        expect(created.elo, Elo.a2);
      },
    );

    testWidgets(
      'rejecting removes the pending entry without creating a player',
      (tester) async {
        await tester.runAsync(
          () => PendingRegistrationRepository.instance.add(
            PendingRegistration.create(
              name: 'Jane Doe',
              contact: 'jane@example.com',
              tier: SkillTier.advanced,
            ),
          ),
        );

        await tester.pumpWidget(wrap(const PlayersPage()));
        await tester.pump();
        await tester.pump();

        final card = tester.widget<PendingRegistrationCard>(
          find.byType(PendingRegistrationCard),
        );
        await tester.runAsync(() async {
          await (card.onReject as dynamic)(0);
        });
        await tester.pump();
        await tester.pump();

        final pending = PendingRegistrationRepository.instance.getAll();
        expect(pending, isEmpty);
        expect(PlayerRepository.instance.listedPlayers(), isEmpty);
      },
    );

    testWidgets('hides the pending section entirely when there are none', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PlayersPage()));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Pending self-registrations'), findsNothing);
    });
  });
}
