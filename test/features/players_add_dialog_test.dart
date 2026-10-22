import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/view/component/dialog/add_player.dart';

import '../support/repository_sandbox.dart';

void main() {
  late RepositorySandbox sandbox;
  Player? result;
  var closed = false;

  setUp(() async {
    sandbox = await RepositorySandbox.setUp('players_add_dialog_test');
    result = null;
    closed = false;
  });

  tearDown(() => sandbox.tearDown());

  Future<void> openDialog(
    WidgetTester tester, {
    List<Player> existing = const [],
  }) async {
    await tester.runAsync(() => PlayerRepository.instance.addAll(existing));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<Player>(
                  context: context,
                  builder: (_) => const AddPlayerDialog(),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    required String first,
    required String last,
    String signInId = '',
  }) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), first);
    await tester.enterText(fields.at(1), last);
    await tester.enterText(fields.at(2), signInId);
    await tester.tap(find.byType(DropdownButtonFormField<Elo>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-player-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('should_trim_the_name_and_sign_in_id', (tester) async {
    await openDialog(tester);

    await fill(tester, first: '  Ann ', last: ' Lee  ', signInId: '  X9 ');

    expect(
      [result!.firstName, result!.lastName, result!.signInId],
      ['Ann', 'Lee', 'X9'],
    );
  });

  testWidgets('should_store_null_when_the_sign_in_id_is_blank', (tester) async {
    await openDialog(tester);

    await fill(tester, first: 'Ann', last: 'Lee', signInId: '   ');

    expect(result!.signInId, isNull);
  });

  testWidgets('should_refuse_a_blank_first_name', (tester) async {
    await openDialog(tester);

    await fill(tester, first: '   ', last: 'Lee');

    expect(closed, isFalse);
  });

  testWidgets('should_refuse_a_duplicate_name_with_the_exists_message', (
    tester,
  ) async {
    await openDialog(
      tester,
      existing: [
        Player(firstName: 'Ann', lastName: 'Lee', elo: Elo.b1, id: 'p1'),
      ],
    );

    await fill(tester, first: ' ann', last: 'LEE ');

    expect(closed, isFalse);
    expect(
      find.text('A player named "Ann Lee" already exists'),
      findsOneWidget,
    );
  });

  testWidgets('should_refuse_a_sign_in_id_used_by_another_player', (
    tester,
  ) async {
    await openDialog(
      tester,
      existing: [
        Player(
          firstName: 'Bob',
          lastName: 'Ray',
          elo: Elo.b1,
          id: 'p1',
          signInId: 'B200',
        ),
      ],
    );

    await fill(tester, first: 'Ann', last: 'Lee', signInId: 'b200');

    expect(closed, isFalse);
    expect(
      find.text('Sign In ID "b200" is already used by Bob Ray'),
      findsOneWidget,
    );
  });
}
