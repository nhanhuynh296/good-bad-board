import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/repository/session_template_repository.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

/// The desktop Sessions tab in the real app (canvas board "Sessions",
/// R7-Q3; UAT SESS-02, SESS-03, SESS-05, SESS-06 with F25).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openSessions(WidgetTester tester) async {
    setDesktopSize(tester);
    await pumpApp(tester);
    for (final template in SessionTemplateRepository.instance.getAll()) {
      await SessionTemplateRepository.instance.delete(template.id);
    }
    await navigateToTab(tester, sessionsTabIndex);
  }

  testWidgets('one minute more updates the header of the top nav', (
    tester,
  ) async {
    await openSessions(tester);

    await tester.tap(find.byKey(const Key('sessions-duration-more')));
    await tester.pumpAndSettle();

    expect(find.text('11 min rounds'), findsOneWidget);
  });

  testWidgets('one player more updates the session bar counts', (tester) async {
    await openSessions(tester);

    await tester.tap(find.byKey(const Key('sessions-capacity-more')));
    await tester.pumpAndSettle();

    expect(find.textContaining('0/21 in'), findsOneWidget);
  });

  testWidgets('a saved template can be deleted after the confirm', (
    tester,
  ) async {
    await openSessions(tester);
    await tester.enterText(find.byKey(const Key('template-name')), 'Friday');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sessions-save-template')));
    await tester.pumpAndSettle();
    final template = SessionTemplateRepository.instance.getAll().single;

    await tester.tap(find.byKey(Key('template-delete-${template.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('courts-confirm-action')));
    await tester.pumpAndSettle();

    expect(find.text('No templates yet'), findsOneWidget);
  });

  testWidgets('a template load sets the duration at once', (tester) async {
    await openSessions(tester);
    await tester.enterText(find.byKey(const Key('template-name')), 'Long');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sessions-duration-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sessions-save-template')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sessions-duration-less')));
    await tester.pumpAndSettle();
    final template = SessionTemplateRepository.instance.getAll().single;

    await tester.tap(find.byKey(Key('template-load-${template.id}')));
    await tester.pumpAndSettle();

    expect(find.text('11 min rounds'), findsOneWidget);
  });
}
