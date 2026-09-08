import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PersistentSetting.instance.initialize();
  });

  group('SET-01: Notification Toggles', () {
    test('should default session reminders to off', () {
      expect(PersistentSetting.instance.getSessionReminders(), isFalse);
    });

    test('should persist and retrieve session reminders toggle', () async {
      await PersistentSetting.instance.setSessionReminders(true);
      expect(PersistentSetting.instance.getSessionReminders(), isTrue);

      await PersistentSetting.instance.setSessionReminders(false);
      expect(PersistentSetting.instance.getSessionReminders(), isFalse);
    });

    test(
      'should persist and retrieve court alerts toggle independently',
      () async {
        await PersistentSetting.instance.setCourtAlerts(true);
        expect(PersistentSetting.instance.getCourtAlerts(), isTrue);
        // Verify independence from other notification toggles.
        expect(PersistentSetting.instance.getSessionReminders(), isFalse);
        expect(PersistentSetting.instance.getGeneralAnnouncements(), isFalse);

        await PersistentSetting.instance.setCourtAlerts(false);
        expect(PersistentSetting.instance.getCourtAlerts(), isFalse);
      },
    );

    test(
      'should persist and retrieve general announcements toggle independently',
      () async {
        await PersistentSetting.instance.setGeneralAnnouncements(true);
        expect(PersistentSetting.instance.getGeneralAnnouncements(), isTrue);
        // Verify independence from other notification toggles.
        expect(PersistentSetting.instance.getSessionReminders(), isFalse);
        expect(PersistentSetting.instance.getCourtAlerts(), isFalse);

        await PersistentSetting.instance.setGeneralAnnouncements(false);
        expect(PersistentSetting.instance.getGeneralAnnouncements(), isFalse);
      },
    );
  });

  group('SET-03: Invite Link', () {
    test('should return default invite link when none stored', () {
      final link = PersistentSetting.instance.getInviteLink();
      expect(link, isNotNull);
      expect(link, isNotEmpty);
    });

    test('should return stored invite link', () async {
      const testLink = 'https://example.com/join/session-abc';
      await PersistentSetting.instance.setInviteLink(testLink);
      expect(PersistentSetting.instance.getInviteLink(), equals(testLink));
    });
  });

  group('SESS-05/06: Template Persistence', () {
    test('should persist a template and retrieve it', () async {
      const template = SessionTemplate(
        name: 'Morning Session',
        modeIndex: 0,
        durationMinutes: 30,
        capacity: 16,
        courts: 4,
      );

      await PersistentSetting.instance.persistTemplate(template);
      final templates = PersistentSetting.instance.loadTemplates();

      expect(templates, hasLength(1));
      expect(templates.first.name, equals('Morning Session'));
      expect(templates.first.modeIndex, equals(0));
      expect(templates.first.durationMinutes, equals(30));
      expect(templates.first.capacity, equals(16));
      expect(templates.first.courts, equals(4));
    });

    test('should persist multiple templates and retrieve all', () async {
      const template1 = SessionTemplate(
        name: 'Morning Session',
        modeIndex: 0,
        durationMinutes: 30,
        capacity: 16,
        courts: 4,
      );
      const template2 = SessionTemplate(
        name: 'Evening Session',
        modeIndex: 1,
        durationMinutes: 60,
        capacity: 20,
        courts: 5,
      );

      await PersistentSetting.instance.persistTemplate(template1);
      await PersistentSetting.instance.persistTemplate(template2);
      final templates = PersistentSetting.instance.loadTemplates();

      expect(templates, hasLength(2));
      expect(templates[0].name, equals('Morning Session'));
      expect(templates[1].name, equals('Evening Session'));
    });

    test('should return empty list when no templates persisted', () {
      final templates = PersistentSetting.instance.loadTemplates();
      expect(templates, isEmpty);
    });
  });
}
