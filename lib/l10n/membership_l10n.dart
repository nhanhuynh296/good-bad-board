import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';

/// Localised display name for a [MembershipStatus].
extension MembershipStatusL10n on MembershipStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MembershipStatus.member => l10n.players_membership_member,
    MembershipStatus.casual => l10n.players_membership_casual,
    MembershipStatus.disabled => l10n.players_membership_disabled,
  };
}
