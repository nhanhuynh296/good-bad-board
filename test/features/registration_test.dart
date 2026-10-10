import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/registration/registration.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';

import '../support/repository_sandbox.dart';

Widget wrap(Widget child, {Size size = const Size(1280, 900)}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    sandbox = await RepositorySandbox.setUp('registration_test');
  });

  tearDown(() => sandbox.tearDown());

  group('REG-03: LevelSelector', () {
    testWidgets(
      'defaults to Intermediate selected, exactly one tier at a time',
      (tester) async {
        var selected = SkillTier.intermediate;
        await tester.pumpWidget(
          wrap(
            StatefulBuilder(
              builder: (context, setState) => LevelSelector(
                selectedTier: selected,
                onTierSelected: (t) => setState(() => selected = t),
              ),
            ),
          ),
        );

        expect(find.text('Amateur'), findsOneWidget);
        expect(find.text('Intermediate'), findsOneWidget);
        expect(find.text('Advanced'), findsOneWidget);
        expect(find.text('Professional'), findsOneWidget);

        await tester.tap(find.text('Advanced'));
        await tester.pumpAndSettle();

        expect(selected, SkillTier.advanced);
      },
    );
  });

  group('REG-01/02/04/05/07: RegistrationPage', () {
    testWidgets('submit is disabled until name and contact are non-blank', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const RegistrationPage()));

      final submitFinder = find.widgetWithText(TextButton, 'Submit');
      expect(tester.widget<TextButton>(submitFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Jane Doe');
      await tester.pump();
      expect(tester.widget<TextButton>(submitFinder).onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, 'jane@example.com');
      await tester.pump();
      expect(tester.widget<TextButton>(submitFinder).onPressed, isNotNull);

      // Whitespace-only contact keeps submit disabled (REG-02).
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.pump();
      expect(tester.widget<TextButton>(submitFinder).onPressed, isNull);
    });

    testWidgets('pending-review note is visible before submission (REG-05)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const RegistrationPage()));

      expect(
        find.textContaining('An organizer reviews every new sign-up'),
        findsOneWidget,
      );
    });

    testWidgets(
      'submitting replaces the form with the confirmation screen (REG-04)',
      (tester) async {
        await tester.pumpWidget(wrap(const RegistrationPage()));

        await tester.enterText(find.byType(TextField).first, 'Jane Doe');
        await tester.enterText(find.byType(TextField).last, 'jane@example.com');
        await tester.pump();

        final submitFinder = find.widgetWithText(TextButton, 'Submit');
        final submitButton = tester.widget<TextButton>(submitFinder);
        expect(submitButton.onPressed, isNotNull);

        // Submitting does real disk I/O (PendingRegistrationRepository.add),
        // which doesn't play well inside the fake-async testWidgets zone —
        // run it for real, then pump to pick up the resulting setState.
        // Wait for the write to land, not for a fixed delay: a busy
        // machine can take longer than any fixed delay.
        await tester.runAsync(() async {
          final written = Completer<void>();
          void onWrite() {
            if (!written.isCompleted) written.complete();
          }

          final repository = PendingRegistrationRepository.instance;
          repository.listenable.addListener(onWrite);
          submitButton.onPressed!();
          await written.future.timeout(const Duration(seconds: 10));
          repository.listenable.removeListener(onWrite);
        });
        await tester.pump();
        await tester.pump();

        expect(find.text('Thanks, Jane!'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Submit'), findsNothing);

        final saved = PendingRegistrationRepository.instance.getAll();
        expect(saved, hasLength(1));
        expect(saved.first.name, 'Jane Doe');
        expect(saved.first.contact, 'jane@example.com');
        expect(saved.first.tier, SkillTier.intermediate);
      },
    );

    testWidgets('stays a single centered column at phone width (REG-07)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const RegistrationPage(), size: const Size(390, 900)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join the club — takes about a minute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays a single centered column at desktop width (REG-07)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const RegistrationPage(), size: const Size(1440, 900)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Join the club — takes about a minute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
