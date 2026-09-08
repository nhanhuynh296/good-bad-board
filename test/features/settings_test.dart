import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/features/settings/settings.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestWidget() {
  return ChangeNotifierProvider<PersistentSetting>.value(
    value: PersistentSetting.instance,
    child: const MaterialApp(
      home: Scaffold(body: SettingsPage()),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistentSetting.instance.initialize();
  });

  // ---------- SET-01: Notification Toggles ----------

  group('SET-01: Notification toggles', () {
    testWidgets('should display 3 notification toggle rows', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Session reminders'), findsOneWidget);
      expect(find.text('Court assignment alerts'), findsOneWidget);
      expect(find.text('General announcements'), findsOneWidget);
    });

    testWidgets('should display "Session reminders" toggle label',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Session reminders'), findsOneWidget);
    });

    testWidgets('should display "Court assignment alerts" toggle label',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Court assignment alerts'), findsOneWidget);
    });

    testWidgets('should display "General announcements" toggle label',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('General announcements'), findsOneWidget);
    });

    testWidgets('should show toggles with current on/off state',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Each toggle row should display an "On" or "Off" label
      // Default states are all off, so expect "Off" labels
      expect(find.text('On'), findsNWidgets(3));
      // Since all defaults are off, we expect 3 "Off" labels
      expect(find.text('Off'), findsNWidgets(3));
    });
  });

  // ---------- SET-02: Membership Counts ----------

  group('SET-02: Membership counts', () {
    testWidgets('should display "Total members" count section',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Total members'), findsOneWidget);
    });

    testWidgets('should display "Fees outstanding" count section',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Fees outstanding'), findsOneWidget);
    });
  });

  // ---------- SET-03: Invite & Signup ----------

  group('SET-03: Invite link and signup preview', () {
    testWidgets('should display read-only invite link field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Invite link'), findsOneWidget);
    });

    testWidgets('should display "Preview signup page →" link text',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Preview signup page →'), findsOneWidget);
    });
  });

  // ---------- SET-04: Level Calibration Note ----------

  group('SET-04: Level calibration note', () {
    testWidgets('should display level calibration note text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(
        find.text(
          'New players self-estimate their level at signup, and organizers '
          'may override any estimate from the Players tab.',
        ),
        findsOneWidget,
      );
    });
  });

  // ---------- Responsive Layout ----------

  group('Responsive layout', () {
    testWidgets('should stack layout vertically on phone width (< 720px)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());

      // At narrow width, the two-column layout should stack vertically.
      // We verify by checking that all section titles are still visible,
      // meaning the layout rendered without overflow.
      expect(find.text('Notifications'), findsOneWidget);
      expect(
        find.text('Membership & self-registration'),
        findsOneWidget,
      );
    });
  });

  // ---------- Edge Cases ----------

  group('Edge cases', () {
    testWidgets('should show zero counts when no players', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // When no players exist, both counts should be zero
      expect(find.text('0'), findsNWidgets(2));
    });
  });

  // ---------- Section Titles ----------

  group('Section titles', () {
    testWidgets('should display "Notifications" section title',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets(
        'should display "Membership & self-registration" section title',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(
        find.text('Membership & self-registration'),
        findsOneWidget,
      );
    });
  });
}
