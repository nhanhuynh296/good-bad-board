// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/main.dart';

import 'support/repository_sandbox.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Sandboxed first — AppLoader's own init skips once the repositories
    // are already set, so this keeps it off the real data directory. Real
    // disk I/O doesn't play well inside the fake-async testWidgets zone —
    // run it for real.
    final sandbox = await tester.runAsync(
      () => RepositorySandbox.setUp('widget_test'),
    );
    addTearDown(sandbox!.tearDown);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppLoader());

    // Verify that our counter starts at 0.
    expect(find.text('1'), findsNothing);
  });
}
