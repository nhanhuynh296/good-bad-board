import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';

/// Localized display text for [SkillTier], kept on the widget side so the
/// model stays free of UI strings.
extension SkillTierL10n on SkillTier {
  /// The tier's name in the current locale (e.g. "Intermediate").
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    SkillTier.amateur => l10n.registration_tier_amateur,
    SkillTier.intermediate => l10n.registration_tier_intermediate,
    SkillTier.advanced => l10n.registration_tier_advanced,
    SkillTier.professional => l10n.registration_tier_professional,
  };

  /// A one-line description of the tier in the current locale.
  String localizedDescription(AppLocalizations l10n) => switch (this) {
    SkillTier.amateur => l10n.registration_tier_amateur_description,
    SkillTier.intermediate => l10n.registration_tier_intermediate_description,
    SkillTier.advanced => l10n.registration_tier_advanced_description,
    SkillTier.professional => l10n.registration_tier_professional_description,
  };
}
