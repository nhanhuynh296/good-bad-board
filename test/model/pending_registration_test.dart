import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:test/test.dart';

void main() {
  test('PendingRegistration.create stamps id and submittedAt', () {
    final reg = PendingRegistration.create(
      name: 'Jane Doe',
      contact: 'jane@example.com',
      tier: SkillTier.intermediate,
    );

    expect(reg.id, isNotEmpty);
    expect(reg.name, 'Jane Doe');
    expect(reg.contact, 'jane@example.com');
    expect(reg.tier, SkillTier.intermediate);
    expect(reg.submittedAt, isNotNull);
  });

  test('PendingRegistration round-trips through JSON', () {
    final reg = PendingRegistration.create(
      name: 'Jane Doe',
      contact: 'jane@example.com',
      tier: SkillTier.advanced,
    );

    final json = reg.toJson();
    final decoded = PendingRegistration.fromJson(json);

    expect(decoded.id, reg.id);
    expect(decoded.name, 'Jane Doe');
    expect(decoded.contact, 'jane@example.com');
    expect(decoded.tier, SkillTier.advanced);
    expect(decoded.submittedAt, reg.submittedAt);
  });

  test('SkillTier lowerBoundElo maps to the conservative Elo per tier', () {
    expect(SkillTier.amateur.lowerBoundElo, Elo.c2);
    expect(SkillTier.intermediate.lowerBoundElo, Elo.b2);
    expect(SkillTier.advanced.lowerBoundElo, Elo.a2);
    expect(SkillTier.professional.lowerBoundElo, Elo.s2);
  });

  test('Elo.skillTier buckets all 8 Elo values into the 4 named tiers', () {
    expect(Elo.c2.skillTier, SkillTier.amateur);
    expect(Elo.c1.skillTier, SkillTier.amateur);
    expect(Elo.b2.skillTier, SkillTier.intermediate);
    expect(Elo.b1.skillTier, SkillTier.intermediate);
    expect(Elo.a2.skillTier, SkillTier.advanced);
    expect(Elo.a1.skillTier, SkillTier.advanced);
    expect(Elo.s2.skillTier, SkillTier.professional);
    expect(Elo.s1.skillTier, SkillTier.professional);
  });
}
