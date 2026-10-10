import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/player.dart';

/// The name to show for [player] in a UI list — the localised placeholder
/// if they were anonymised (ADR-0001: erased, not removed), otherwise
/// their real name.
String playerDisplayName(Player player, AppLocalizations l10n) =>
    player.isAnonymised ? l10n.anonymised_player : player.name();
