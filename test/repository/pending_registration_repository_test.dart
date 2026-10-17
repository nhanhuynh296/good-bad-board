import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';
import 'package:test/test.dart';

import '../support/repository_sandbox.dart';

void main() {
  late RepositorySandbox sandbox;

  setUp(() async => sandbox = await RepositorySandbox.setUp());

  tearDown(() => sandbox.tearDown());

  test('initialize with no existing file starts with an empty cache', () {
    expect(PendingRegistrationRepository.instance.getAll(), isEmpty);
  });

  test('add persists a registration and notifies listeners', () async {
    var notified = false;
    PendingRegistrationRepository.instance.listenable.addListener(
      () => notified = true,
    );
    final reg = PendingRegistration.create(
      name: 'Jane Doe',
      contact: 'jane@example.com',
      tier: SkillTier.intermediate,
    );

    await PendingRegistrationRepository.instance.add(reg);

    final all = PendingRegistrationRepository.instance.getAll();
    expect(all, hasLength(1));
    expect(all.first.id, reg.id);
    expect(notified, isTrue);
  });

  test('delete removes a registration', () async {
    final reg = PendingRegistration.create(
      name: 'Jane Doe',
      contact: 'jane@example.com',
      tier: SkillTier.intermediate,
    );
    await PendingRegistrationRepository.instance.add(reg);

    await PendingRegistrationRepository.instance.delete(reg.id);

    expect(PendingRegistrationRepository.instance.getAll(), isEmpty);
  });

  test(
    'persisted registrations survive a fresh initialize() from disk',
    () async {
      final reg = PendingRegistration.create(
        name: 'Jane Doe',
        contact: 'jane@example.com',
        tier: SkillTier.professional,
      );
      await PendingRegistrationRepository.instance.add(reg);

      // Re-read from disk, as a fresh app launch would.
      PendingRegistrationRepository.instance =
          await PendingRegistrationRepository.initialize(
            rootDir: sandbox.tempDir.path,
          );

      final all = PendingRegistrationRepository.instance.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Jane Doe');
      expect(all.first.tier, SkillTier.professional);
    },
  );
}
