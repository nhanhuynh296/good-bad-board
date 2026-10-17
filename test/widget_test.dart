// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/main.dart';
import 'package:good_bad_board/repository/data_root.dart';

import 'support/repository_sandbox.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // AppLoader requires a DataRoot, so the test gives it the sandbox
    // directory and never the real data directory. Real disk I/O does not
    // play well inside the fake-async testWidgets zone, so run it for real.
    final sandbox = await tester.runAsync(
      () => RepositorySandbox.setUp('widget_test'),
    );
    addTearDown(sandbox!.tearDown);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      AppLoader(dataRoot: DataRoot.directory(sandbox.tempDir.path)),
    );

    // Verify that our counter starts at 0.
    expect(find.text('1'), findsNothing);
  });
}
