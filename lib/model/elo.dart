import 'package:good_bad_board/model/player.dart';

/// The 4 named skill tiers shown to players at self-registration (REG-01)
/// and used to bucket the Analytics level-distribution chart (ANA-09). The
/// app's internal [Elo] enum has 8 finer-grained values
/// (c2,c1,b2,b1,a2,a1,s2,s1) used elsewhere for matchmaking.
enum SkillTier {
  amateur,
  intermediate,
  advanced,
  professional;

  String get label => switch (this) {
    SkillTier.amateur => 'Amateur',
    SkillTier.intermediate => 'Intermediate',
    SkillTier.advanced => 'Advanced',
    SkillTier.professional => 'Professional',
  };
}

extension EloSkillTier on Elo {
  SkillTier get skillTier => switch (index) {
    0 || 1 => SkillTier.amateur,
    2 || 3 => SkillTier.intermediate,
    4 || 5 => SkillTier.advanced,
    _ => SkillTier.professional,
  };
}

extension SkillTierElo on SkillTier {
  /// The conservative (lower-bound) [Elo] value within this tier — used to
  /// seed a new [Player] created from an approved self-registration.
  Elo get lowerBoundElo => switch (this) {
    SkillTier.amateur => Elo.c2,
    SkillTier.intermediate => Elo.b2,
    SkillTier.advanced => Elo.a2,
    SkillTier.professional => Elo.s2,
  };
}
