import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/main.dart';
import 'package:good_bad_board/repository/data_root.dart';

import 'support/prefs_sandbox.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    mockPreferences();
    tempDir = Directory.systemTemp.createTempSync('app_loader_error');
    File('${tempDir.path}/players.json').writeAsStringSync('{ not json');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  // The load runs real file I/O, so start it inside runAsync.
  Future<void> pumpBrokenLoader(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        AppLoader(dataRoot: DataRoot.directory(tempDir.path)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('should_show_error_text_naming_data_folder_when_load_fails', (
    tester,
  ) async {
    await pumpBrokenLoader(tester);

    expect(find.textContaining(tempDir.path), findsOneWidget);
  });

  testWidgets('should_not_show_main_app_when_load_fails', (tester) async {
    await pumpBrokenLoader(tester);

    expect(find.byType(MyApp), findsNothing);
  });

  testWidgets('should_not_change_corrupt_file_when_load_fails', (tester) async {
    await pumpBrokenLoader(tester);

    expect(
      File('${tempDir.path}/players.json').readAsStringSync(),
      '{ not json',
    );
  });
}
